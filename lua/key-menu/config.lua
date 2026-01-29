---@mod key-menu.config Configuration for key-menu.nvim

local M = {}

---@class KeyMenuOptions
---@field leader_names table<string, any> Tree structure for leader names.

---@type KeyMenuOptions
M.opts = {
  leader_names = {},
}

---Setup the configuration.
---@param opts? KeyMenuOptions
function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
end

return M
