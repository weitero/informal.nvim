local config = require("informal.config")
local pragma_comments = require("informal.pragma_comments")
local utils = require("informal.utils")
local M = {}
function M.get_formatters()
  local ft = vim.bo.filetype
  local formatters = config.opts.formatters_by_ft[ft]
  if not formatters then
    return {}
  end
  return formatters
end
function M.add_comments()
  if not utils.is_visual_mode() then
    return
  end
  local start_line, end_line = utils.get_range()
  local formatters = M.get_formatters()
  if not formatters then
    return
  end
  for _, formatter in ipairs(formatters) do
    local formatter_pragma_comments = pragma_comments[formatter]
    if start_line == end_line then
      local indent = utils.set_proper_indentation(start_line)
      local comment_string = indent .. formatter_pragma_comments[1]
      vim.api.nvim_buf_set_lines(0, start_line - 1, start_line - 1, true, { comment_string })
    else
      local indent_start = utils.set_proper_indentation(start_line)
      local indent_end = utils.set_proper_indentation(end_line)
      local comment_string = formatter_pragma_comments[2]
      vim.api.nvim_buf_set_lines(0, start_line - 1, start_line - 1, true, { indent_start .. comment_string[1] })
      vim.api.nvim_buf_set_lines(0, end_line + 1, end_line + 1, true, { indent_end .. comment_string[2] })
    end
  end
end
return M
