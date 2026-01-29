---@mod key-menu.state Shared state for key-menu.nvim

local M = {}

---@type table<function, boolean> Set of callbacks that open the window.
local open_window_callbacks = {}
do
  -- Make open_window_callbacks have weak key refs.
  local mt = {}
  mt.__mode = 'k'
  setmetatable(open_window_callbacks, mt)
end

M.open_window_callbacks = open_window_callbacks

return M
