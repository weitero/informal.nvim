local pragma_comments = require("informal.pragma_comments")
local utils = require("informal.utils")
local M = {}

local function get_line_range()
  if utils.is_visual_mode() then
    return utils.get_range()
  end
  local line = vim.fn.line(".")
  return line, line
end

local function add_before_comment(line, comment)
  local indent = utils.set_proper_indentation(line)
  local comment_string = indent .. utils.resolve_pragma_comment(comment)
  vim.api.nvim_buf_set_lines(0, line - 1, line - 1, true, { comment_string })
end

local function add_inline_comment(line, comment)
  local line_text = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1] or ""
  local comment_string = " " .. utils.resolve_pragma_comment(comment)
  vim.api.nvim_buf_set_text(0, line - 1, #line_text, line - 1, #line_text, { comment_string })
end

local function add_blockwise_comments(start_line, end_line, blockwise)
  local indent_start = utils.set_proper_indentation(start_line)
  local indent_end = utils.set_proper_indentation(end_line)
  vim.api.nvim_buf_set_lines(0, start_line - 1, start_line - 1, true, {
    indent_start .. utils.resolve_pragma_comment(blockwise[1]),
  })
  vim.api.nvim_buf_set_lines(0, end_line + 1, end_line + 1, true, {
    indent_end .. utils.resolve_pragma_comment(blockwise[2]),
  })
end

function M.add_comments(mode)
  if not utils.is_visual_mode() and not utils.is_normal_mode() then
    return
  end

  local start_line, end_line = get_line_range()
  local formatters = utils.get_formatters()
  if not formatters then
    return
  end

  for _, formatter in ipairs(formatters) do
    local formatter_pragma_comments = pragma_comments[formatter]
    if formatter_pragma_comments then
      local selected_mode = mode
      if not selected_mode then
        if start_line == end_line then
          if formatter_pragma_comments.before then
            selected_mode = "before"
          elseif formatter_pragma_comments.inline then
            selected_mode = "inline"
          end
        else
          selected_mode = "blockwise"
        end
      end

      if selected_mode == "before" and formatter_pragma_comments.before then
        for line = end_line, start_line, -1 do
          add_before_comment(line, formatter_pragma_comments.before)
        end
      elseif selected_mode == "inline" and formatter_pragma_comments.inline then
        for line = start_line, end_line do
          add_inline_comment(line, formatter_pragma_comments.inline)
        end
      elseif selected_mode == "blockwise" and formatter_pragma_comments.blockwise then
        add_blockwise_comments(start_line, end_line, formatter_pragma_comments.blockwise)
      end
    end
  end
end

function M.add_comments_inline()
  M.add_comments("inline")
end

function M.add_comments_before()
  M.add_comments("before")
end

function M.add_comments_blockwise()
  M.add_comments("blockwise")
end

return M
