---@mod key-menu.ui UI and Window management

local utils = require('key-menu.utils')
local keys = require('key-menu.keys')
local view = require('key-menu.view')
local state = require('key-menu.state')

local function set_default_highlights()
  vim.api.nvim_set_hl(0, 'KeyMenuNormal', { link = 'NormalFloat', default = true })
  vim.api.nvim_set_hl(0, 'KeyMenuFloatBorder', { link = 'FloatBorder', default = true })
end

set_default_highlights()

local hl_group = vim.api.nvim_create_augroup('KeyMenuHighlights', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
  group = hl_group,
  callback = set_default_highlights,
})

local M = {}

---Map a key to No-Op in the buffer.
---@param buf number Buffer handle.
---@param keystroke string Key to map.
local function map_to_nop(buf, keystroke)
  vim.api.nvim_buf_set_keymap(buf, 'n', keystroke, '', {nowait=true})
end

---Shadow all global mappings in the buffer to prevent pass-through.
---@param buf number Buffer handle.
local function shadow_all_global_mappings(buf)
  -- We only need to worry about normal mode.
  local chars = 'abcdefghijklmnopqrstuvwxyz'
             .. 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
             .. '0123456789'
             .. '~!#$%^&*()_+`-=[]{}|\\;"\'<>,.?/'

  for i = 1, #chars do
    local char = chars:sub(i, i)
    map_to_nop(buf, char)
    map_to_nop(buf, string.format('<C-%s>', char))
    map_to_nop(buf, string.format('<A-%s>', char))
  end
end

---Open the key-menu window.
---@param prefix string The initial key prefix.
function M.open_window(prefix)
  local mode = vim.fn.mode()
  -- Pretty ugly. Is there a better way to do this?
  prefix = vim.api.nvim_replace_termcodes(prefix, true, true, true)

  local original_buf = vim.api.nvim_get_current_buf()
  local orig_buf_keymap = vim.api.nvim_buf_get_keymap(original_buf, mode)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'keymenu')

  shadow_all_global_mappings(buf)

  local horizontal_padding = 1
  local horizontal_spacing = 3

  local anchor, row, col
  if vim.fn.screenrow() > vim.o.lines / 2 then
    anchor, row, col = 'SW', 0, 1
  else
    anchor, row, col = 'NW', 1, 1
  end

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'cursor',
    anchor = anchor,
    row = row, col = col,
    width = 1, height = 1,
    style = 'minimal',
    border = 'rounded',
  })
  local border_width = 1

  vim.api.nvim_win_set_option(win, 'winhighlight', table.concat({
    'Normal:KeyMenuNormal',
    'FloatBorder:KeyMenuFloatBorder',
  }, ','))

  local close_window = function()
    if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end
  end

  local all_mappings = {}
  all_mappings = keys.shadow(all_mappings, keys.normalize_keymap(vim.api.nvim_get_keymap(mode)))
  all_mappings = keys.shadow(all_mappings, keys.normalize_keymap(orig_buf_keymap))
  all_mappings = vim.tbl_filter(keys.is_not_nop, all_mappings)
  all_mappings = vim.tbl_filter(keys.is_not_hidden, all_mappings)

  local mappings = keys.prefix_mappings_starting_with(prefix, all_mappings)

  local function get_command_line_text()
    local keystrokes = vim.tbl_map(view.get_pretty_keystroke, keys.get_keystrokes(prefix))
    table.insert(keystrokes, '') 
    return table.concat(keystrokes, ' → ')
  end

  local redraw = function(prefix_keys, complete_keys)
    local max_num_rows = 10

    ::start_redraw::

    local command_line_text = get_command_line_text()
    local pretty_keystrokes_so_far = string.rep(' ', horizontal_padding)
                                  .. command_line_text
                                  .. string.rep(' ', horizontal_padding)
    local cursor_col = horizontal_padding + vim.api.nvim_strwidth(command_line_text) + 1
    local min_width = vim.api.nvim_strwidth(pretty_keystrokes_so_far)

    local items = view.get_pretty_items(prefix, prefix_keys, complete_keys)

    local num_rows, num_cols
    if #items == 0 then
      num_rows = 1
      num_cols = 0
    elseif #items < max_num_rows then
      num_cols = 1
      num_rows = #items
    else
      num_cols = math.ceil(#items / max_num_rows)
      num_rows = math.ceil(#items / num_cols)
    end

    local get_col_num = function(item_num) return math.ceil(item_num / num_rows) end
    local get_row_num = function(item_num) return 1 + (item_num-1) % num_rows end
    local sep = ' → '
    local sep_width = vim.api.nvim_strwidth(sep)

    local col_widths = {}
    local keystroke_widths = {}
    local description_widths = {}
    local function _set_to_at_least(widths_by_col, col_num, value)
      if not widths_by_col[col_num] then widths_by_col[col_num] = 0 end
      widths_by_col[col_num] = math.max(widths_by_col[col_num], value)
    end
    for item_num = 1, #items do
      local item = items[item_num]
      local col_num = get_col_num(item_num)

      local keystroke_width = vim.api.nvim_strwidth(item.keystroke)
      local description_width = vim.api.nvim_strwidth(item.description)
      _set_to_at_least(keystroke_widths, col_num, keystroke_width)
      _set_to_at_least(description_widths, col_num, description_width)

      local display_width = keystroke_widths[col_num] + sep_width + description_widths[col_num]
      _set_to_at_least(col_widths, col_num, display_width)
    end

    local no_mappings_string = '(no mappings)'

    local col_starts = {}
    local width
    if #items > 0 then
      width = horizontal_padding + 1
      for col_num = 1, num_cols do
        col_starts[col_num] = width
        width = width + horizontal_spacing + col_widths[col_num]
      end
      width = width - horizontal_spacing + horizontal_padding - 1
      width = math.max(width, min_width)
    else
      width = math.max(2 * horizontal_padding + vim.api.nvim_strwidth(no_mappings_string), min_width)
    end

    local max_width = vim.o.columns - 2 * border_width
    if width > max_width then
      max_num_rows = max_num_rows + 1
      goto start_redraw
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    vim.api.nvim_win_set_config(win, {width = width, height = num_rows + 2})

    local blank_lines = {}
    for _ = 1, num_rows + 2 do
      table.insert(blank_lines, string.rep(' ', width))
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, blank_lines)

    local row_offset = (anchor == 'NW' and 1) or -1

    if #items > 0 then
      for item_num = #items, 1, -1 do
        local item = items[item_num]
        local row_num = get_row_num(item_num)
        local col_num = get_col_num(item_num)
        local keystroke_width = vim.api.nvim_strwidth(item.keystroke)
        local description_width = vim.api.nvim_strwidth(item.description)
        local keystroke_col_width = keystroke_widths[col_num]
        local keystroke_start = col_starts[col_num] + (keystroke_col_width - keystroke_width)
        local keystroke_end = keystroke_start + keystroke_width - 1
        local sep_start = keystroke_end + 1
        local sep_end = sep_start + sep_width - 1
        local description_start = sep_end + 1
        local description_end = description_start + description_width - 1

        vim.api.nvim_buf_set_text(buf, row_num + row_offset, description_start-1, row_num + row_offset, description_end, {item.description})
        vim.api.nvim_buf_set_text(buf, row_num + row_offset, sep_start-1, row_num + row_offset, sep_end, {sep})
        vim.api.nvim_buf_set_text(buf, row_num + row_offset, keystroke_start-1, row_num + row_offset, keystroke_end, {item.keystroke})
      end
    else
      vim.api.nvim_buf_set_text(buf, 1 + row_offset, horizontal_padding, 1 + row_offset, horizontal_padding + vim.api.nvim_strwidth(no_mappings_string), {no_mappings_string})
    end

    if anchor == 'NW' then
      vim.api.nvim_buf_set_lines(buf, 0, 1, false, {pretty_keystrokes_so_far})
      vim.api.nvim_buf_set_lines(buf, 1, 2, false, {string.rep('─', width)})
      vim.fn.setcursorcharpos(1, cursor_col)
    else
      vim.api.nvim_buf_set_lines(buf, -2, -1, false, {pretty_keystrokes_so_far})
      vim.api.nvim_buf_set_lines(buf, -3, -2, false, {string.rep('─', width)})
      vim.fn.setcursorcharpos(num_rows + 2, cursor_col)
    end
  end

  local remove_local_mappings = nil
  local add_local_mappings = nil
  local add_default_mappings = nil

  local full_update = function()
    if remove_local_mappings then
      remove_local_mappings()
      remove_local_mappings = nil
    end
    add_default_mappings()

    local prefix_keys, complete_keys = keys.compute_keys(prefix, mappings)
    add_local_mappings(prefix_keys, complete_keys)

    redraw(prefix_keys, complete_keys)
  end

  add_local_mappings = function(prefix_keys, complete_keys)
    local opts_ = {buffer=buf, nowait=true}

    remove_local_mappings = function()
      for keystroke, _ in pairs(prefix_keys) do
        map_to_nop(buf, keystroke)
      end
      for keystroke, _ in pairs(complete_keys) do
        map_to_nop(buf, keystroke)
      end
    end

    local make_next_key_cb = function(keystroke)
      return function()
        prefix = prefix .. keystroke
        mappings = prefix_keys[keystroke] or {}
        full_update()
      end
    end

    for keystroke, _ in pairs(prefix_keys) do
      vim.keymap.set('n', keystroke, make_next_key_cb(keystroke), opts_)
    end

    for keystroke, mapping in pairs(complete_keys) do
      if state.open_window_callbacks[mapping.callback] then
        vim.keymap.set('n', keystroke, make_next_key_cb(keystroke), opts_)
      else
        local cb = function()
          close_window()
          if mapping.callback then
            mapping.callback()
          elseif mapping.rhs then
            local feedkeys_mode = ''
            if mapping.noremap then
              feedkeys_mode = feedkeys_mode .. 'n'
            else
              feedkeys_mode = feedkeys_mode .. 'm'
            end
            local rhs = vim.api.nvim_replace_termcodes(mapping.rhs, true, true, true)
            vim.api.nvim_feedkeys(rhs, feedkeys_mode, false)
          else
            print(string.format('Error: mapping "%s" has no callback and no RHS', mapping.lhs))
          end
        end
        vim.keymap.set('n', keystroke, cb, opts_)
      end
    end
  end

  local backspace = function()
    local keystrokes = keys.get_keystrokes(prefix)
    if #keystrokes < 1 then
      close_window()
    else
      prefix = table.concat(vim.list_slice(keystrokes, 1, #keystrokes - 1))
      mappings = keys.prefix_mappings_starting_with(prefix, all_mappings)
      full_update()
    end
  end

  add_default_mappings = function()
    vim.keymap.set('n', '<Esc>', close_window, {buffer=buf, nowait=true})
    vim.keymap.set('n', '<C-[>', close_window, {buffer=buf, nowait=true})
    vim.keymap.set('n', '<C-c>', close_window, {buffer=buf, nowait=true})
    vim.keymap.set('n', '<BS>', backspace, {buffer=buf, nowait=true})
    vim.keymap.set('n', '<C-h>', backspace, {buffer=buf, nowait=true})
  end

  vim.api.nvim_create_autocmd("BufLeave", {buffer=buf, callback=close_window})
  vim.api.nvim_create_autocmd("VimResized", {buffer=buf, callback=full_update})

  full_update()
end

return M
