local config = require("informal.config")
local M = {}

local default_pragma_comments = {
  ruff = { "# fmt: skip", { "# fmt: off", "# fmt: on" } },
  stylua = { "-- stylua: ignore", { "-- stylua: ignore start", "-- stylua: ignore end" } },
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
