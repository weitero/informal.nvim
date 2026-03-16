local M = {}
function M.setup_keymaps(keymaps)
  local ignore = require("informal.ignore")
  local actions = {
    add_comments = ignore.add_comments,
    add_comments_inline = ignore.add_comments_inline,
    add_comments_before = ignore.add_comments_before,
    add_comments_blockwise = ignore.add_comments_blockwise,
  }
  for name, keymap in pairs(keymaps) do
    if keymap and keymap ~= false then
      local action = actions[name]
      if action then
        vim.keymap.set({ "n", "v" }, keymap, action, { remap = false, silent = true })
      end
    end
  end
end
return M
