local M = {}
M.defaults = {
  force_block_ignore = false,
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff" },
  },
}
return M
