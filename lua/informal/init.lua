local config = require("informal.config")
local ignore = require("informal.ignore")
local M = {}
M.setup = config.setup
M.add_comments = ignore.add_comments
M.add_comments_inline = ignore.add_comments_inline
M.add_comments_before = ignore.add_comments_before
M.add_comments_blockwise = ignore.add_comments_blockwise
return M
