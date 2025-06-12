local M = {}

M.pragma_comments = {
  ruff = { "# fmt: skip", { "# fmt: off", "# fmt: on" } },
  stylua = { "-- stylua: ignore", { "-- stylua: ignore start", "-- stylua: ignore end" } },
}

return M
