---@mod key-menu Main entry point

local ui = require('key-menu.ui')
local config = require('key-menu.config')
local state = require('key-menu.state')

local M = {}

---Setup the plugin configuration.
---@param opts? KeyMenuOptions
function M.setup(opts)
  config.setup(opts)
end

---Open the key menu window.
---@param prefix string
function M.open_window(prefix)
  ui.open_window(prefix)
end

---Set a mapping that opens the key menu.
---@param mode string|string[] Mode short-name (e.g., 'n', 'v').
---@param lhs string Left-hand side of the mapping.
---@param opts? table Options for vim.keymap.set.
function M.set(mode, lhs, opts)
  opts = opts or {}
  local cb = function() ui.open_window(lhs) end
  state.open_window_callbacks[cb] = true
  vim.keymap.set(mode, lhs, cb, opts)
end

return M
