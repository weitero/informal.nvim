local M = {}
local defaults = {
  force_block_ignore = false,
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_format" },
  },
  pragma_comments = {},
  keymaps = {
    add_comments = "<leader>ig",
    add_comments_inline = "<leader>ii",
    add_comments_before = "<leader>ib",
    add_comments_blockwise = "<leader>iw",
    add_comments_all = "<leader>ia",
  },
}
M.opts = {}
function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", {}, defaults, opts or {})
  require("informal.keymaps").setup_keymaps(M.opts.keymaps)
end
return M
