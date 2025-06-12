local M = {}
local defaults = {
  force_block_ignore = false,
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff" },
  },
}
M.opts = {}
function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", {}, defaults, opts or {})
end
return M
