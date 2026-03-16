local config = require("informal.config")
local M = {}

local default_pragma_comments = {
  ruff_format = { inline = "fmt: skip", blockwise = { "fmt: off", "fmt: on" } },
  stylua = { before = "stylua: ignore", blockwise = { "stylua: ignore start", "stylua: ignore end" } },
  biome = {
    all = "biome-ignore-all {target}: {reason}",
    before = "biome-ignore {target}: {reason}",
    blockwise = { "biome-ignore-start {target}: {reason}", "biome-ignore-end {target}: {reason}" },
    template_defaults = {
      target = "lint",
      reason = "suppressed by informal.nvim",
    },
    template_options = {
      target = {
        "lint",
        "assist",
        "syntax",
      },
    },
  },
}

setmetatable(M, {
  __index = function(_, key)
    if config.opts.pragma_comments then
      return vim.tbl_deep_extend("force", default_pragma_comments, config.opts.pragma_comments)[key]
    end
    return vim.deepcopy(default_pragma_comments)[key]
  end,
})
return M
