local config = require("informal.config")
local ignore = require("informal.ignore")
local M = {}
M.setup = config.setup
M.add_comemnts = ignore.add_comments
return M
