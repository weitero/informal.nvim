local M = {}
function M.is_visual_mode()
  local current_mode = vim.fn.mode()
  return current_mode == "v" or current_mode == "V" or current_mode == "\22"
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
return M
