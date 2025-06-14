local M = {}
function M.is_visual_mode()
  local current_mode = vim.fn.mode()
  return current_mode == "v" or current_mode == "V" or current_mode == "\22"
end
function M.get_formatters()
  local formatters_by_ft = require("informal.config").opts.formatters_by_ft
  local ft = vim.bo.filetype
  local formatters = formatters_by_ft[ft]
  if not formatters then
    return {}
  end
  return formatters
end
function M.get_range()
  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")
  local start_line = start_pos[2]
  local end_line = end_pos[2]
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  return start_line, end_line
end
function M.set_proper_indentation(reference_lnum)
  local indent_level = vim.fn.indent(reference_lnum)
  local indent = string.rep(" ", indent_level)
  return indent
end
return M
