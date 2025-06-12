local M = {}
function M.setup_keymaps()
  local config = require("informal.config")
  local ignore = require("informal.ignore")
  local actions = { add_comments = ignore.add_comments }
  for name, keymap in pairs(config.opts.keymaps) do
    if keymap and keymap ~= false then
      local action = actions[name]
      if action then
        vim.keymap.set("v", keymap, action, { remap = false, silent = true })
      end
    end
  end
end
return M
