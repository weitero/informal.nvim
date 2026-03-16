local pragma_comments = require("informal.pragma_comments")
local utils = require("informal.utils")
local M = {}
local last_template_values = {}

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

local function add_top_of_file_comment(comment)
  local comment_string = utils.resolve_pragma_comment(comment)
  local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
  if first_line == comment_string then
    return
  end
  vim.api.nvim_buf_set_lines(0, 0, 0, true, { comment_string })
end

local function collect_template_keys(template)
  local keys = {}
  for key in template:gmatch("{([%w_]+)}") do
    keys[key] = true
  end
  return keys
end

local function build_template_defaults(formatter_pragma_comments)
  local global_defaults = require("informal.config").opts.template_defaults or {}
  local formatter_defaults = formatter_pragma_comments.template_defaults or {}
  return vim.tbl_deep_extend("force", {}, global_defaults, formatter_defaults)
end

local function resolve_template_value(formatter, key, mode, defaults, invocation_values, resolved_values)
  if resolved_values[key] and resolved_values[key] ~= "" then
    return resolved_values[key]
  end

  local formatter_cache = last_template_values[formatter] or {}
  local default_value = invocation_values[key] or formatter_cache[key] or defaults[key]

  if mode then
    local prompt = string.format("informal.nvim %s %s: ", formatter, key)
    local input_value = vim.fn.input(prompt, default_value or "")
    if not input_value or input_value == "" then
      input_value = default_value
    end
    if not input_value or input_value == "" then
      return nil
    end
    resolved_values[key] = input_value
    last_template_values[formatter] = last_template_values[formatter] or {}
    last_template_values[formatter][key] = input_value
    return input_value
  end

  if default_value and default_value ~= "" then
    resolved_values[key] = default_value
    return default_value
  end

  return nil
end

local function render_template(formatter, template, mode, formatter_pragma_comments, invocation_values, resolved_values)
  if type(template) ~= "string" then
    return template
  end

  local keys = collect_template_keys(template)
  local rendered = template
  local defaults = build_template_defaults(formatter_pragma_comments)

  for key in pairs(keys) do
    local value = resolve_template_value(formatter, key, mode, defaults, invocation_values, resolved_values)
    if not value then
      if mode then
        vim.notify(
          string.format("informal.nvim: missing template value '%s' for formatter '%s'", key, formatter),
          vim.log.levels.WARN
        )
      end
      return nil
    end
    rendered = rendered:gsub("{" .. key .. "}", value)
  end

  return rendered
end

function M.add_comments(mode, values)
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
      local invocation_values = values or {}
      local resolved_values = {}
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
        local rendered_before = render_template(
          formatter,
          formatter_pragma_comments.before,
          mode,
          formatter_pragma_comments,
          invocation_values,
          resolved_values
        )
        if not rendered_before then
          goto continue
        end
        for line = end_line, start_line, -1 do
          add_before_comment(line, rendered_before)
        end
      elseif selected_mode == "inline" and formatter_pragma_comments.inline then
        local rendered_inline = render_template(
          formatter,
          formatter_pragma_comments.inline,
          mode,
          formatter_pragma_comments,
          invocation_values,
          resolved_values
        )
        if not rendered_inline then
          goto continue
        end
        for line = start_line, end_line do
          add_inline_comment(line, rendered_inline)
        end
      elseif selected_mode == "blockwise" and formatter_pragma_comments.blockwise then
        local rendered_start = render_template(
          formatter,
          formatter_pragma_comments.blockwise[1],
          mode,
          formatter_pragma_comments,
          invocation_values,
          resolved_values
        )
        local rendered_end = render_template(
          formatter,
          formatter_pragma_comments.blockwise[2],
          mode,
          formatter_pragma_comments,
          invocation_values,
          resolved_values
        )
        if not rendered_start or not rendered_end then
          goto continue
        end
        add_blockwise_comments(start_line, end_line, { rendered_start, rendered_end })
      elseif selected_mode == "all" and formatter_pragma_comments.all then
        local rendered_all = render_template(
          formatter,
          formatter_pragma_comments.all,
          mode,
          formatter_pragma_comments,
          invocation_values,
          resolved_values
        )
        if not rendered_all then
          goto continue
        end
        add_top_of_file_comment(rendered_all)
      end
    end
    ::continue::
  end
end

function M.add_comments_inline(values)
  M.add_comments("inline", values)
end

function M.add_comments_before(values)
  M.add_comments("before", values)
end

function M.add_comments_blockwise(values)
  M.add_comments("blockwise", values)
end

function M.add_comments_all(values)
  M.add_comments("all", values)
end

return M
