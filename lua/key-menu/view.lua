---@mod key-menu.view View logic for preparing display data

local utils = require('key-menu.utils')
local keys = require('key-menu.keys')
local config = require('key-menu.config')
local state = require('key-menu.state')

local M = {}

local LC_CMD = '<cmd>'
local LC_CR = '<cr>'

---Get the name of a leader key sequence from config.
---@param prefix string The key sequence.
---@return string # The name, or empty string.
function M.get_leader_name(prefix)
  local keystroke, result
  local tree = config.opts.leader_names or {}
  while tree and #prefix > 0 do
    keystroke, prefix = keys.peel(prefix)
    local node = tree[keystroke] or {}
    -- Assuming tree structure is { "name", subtree } or similar?
    -- Original code: result, tree = unpack(tree[keystroke] or {})
    result, tree = unpack(node)
  end
  if #prefix == 0 and result then
    return result
  else
    return ''
  end
end

---Get a pretty description for a mapping.
---@param mapping table
---@return string
function M.get_pretty_description(mapping)
  if mapping.desc then
    return mapping.desc
  elseif mapping.rhs then
    local lowercase = string.lower(mapping.rhs)
    if utils.starts_with(LC_CMD, lowercase) and utils.ends_with(LC_CR, lowercase) then
      return ':' .. mapping.rhs:sub(#LC_CMD + 1, #mapping.rhs - #LC_CR)
    else
      return mapping.rhs
    end
  elseif mapping.callback and not state.open_window_callbacks[mapping.callback] then
    return '(Callback)'
  else
    return ''
  end
end

local pretty_keystroke_dict = {
  [" "] = '␠',
}

---Format a modified keystroke (e.g., CTRL-A).
---@param keystroke string
---@return string?
function M.modified_keystroke(keystroke)
  local n = vim.fn.char2nr(keystroke)
  if 1 <= n and n <= 26 then
    return string.format('CTRL-%s', vim.fn.nr2char(vim.fn.char2nr('A') - 1 + n))
  end
  if n == 29 then
    return 'CTRL-]'
  end
  return nil
end

---Get a pretty representation of a keystroke.
---@param keystroke string
---@return string
function M.get_pretty_keystroke(keystroke)
  return pretty_keystroke_dict[keystroke]
      or M.modified_keystroke(keystroke)
      or keystroke
end

---@class MenuItem
---@field keystroke string Display string for key.
---@field description string Description string.

---Prepare items for the menu display.
---@param prefix string Current prefix.
---@param prefix_keys table<string, table[]>
---@param complete_keys table<string, table>
---@return MenuItem[]
function M.get_pretty_items(prefix, prefix_keys, complete_keys)
  local all_keystrokes_set = {}
  for key, _ in pairs(prefix_keys) do all_keystrokes_set[key] = true end
  for key, _ in pairs(complete_keys) do all_keystrokes_set[key] = true end

  local sorted_keystrokes = vim.tbl_keys(all_keystrokes_set)
  table.sort(sorted_keystrokes, utils.keystroke_comparator)

  local items = {}
  for _, keystroke in ipairs(sorted_keystrokes) do
    local pretty_keystroke = M.get_pretty_keystroke(keystroke)
    local mapping = complete_keys[keystroke] -- May be nil

    local pretty_description
    if mapping then
      pretty_description = utils.truncate(
        M.get_pretty_description(mapping),
        40 -- XXX: Magic number, screen columns
      )
    else
      -- It must be a prefix key if not a complete mapping (or both)
      -- Original logic: assert(prefix_keys[keystroke])
      pretty_description = M.get_leader_name(prefix .. keystroke)
    end

    local is_prefix_key = prefix_keys[keystroke] or (mapping and state.open_window_callbacks[mapping.callback])
    if is_prefix_key then pretty_description = pretty_description .. '…' end

    table.insert(items, {keystroke = pretty_keystroke, description = pretty_description})
  end
  return items
end

return M
