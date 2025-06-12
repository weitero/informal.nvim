local M = {}
local defaults = {
  force_block_ignore = false,
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff" },
  },
  pragma_comments = {},
  keymaps = { add_comments = "<leader>c" },
}
M.opts = {}
function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", {}, defaults, opts or {})
  require("informal.keymaps").setup_keymaps(M.opts.keymaps)
end
return M
