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

local function build_template_options(formatter_pragma_comments)
  local global_options = require("informal.config").opts.template_options or {}
  local formatter_options = formatter_pragma_comments.template_options or {}
  return vim.tbl_deep_extend("force", {}, global_options, formatter_options)
end

local function has_placeholders(template)
  return type(template) == "string" and template:find("{[%w_]+}") ~= nil
end

local function collect_template_keys_in_order(template)
  local ordered = {}
  local seen = {}
  for key in template:gmatch("{([%w_]+)}") do
    if not seen[key] then
      table.insert(ordered, key)
      seen[key] = true
    end
  end
  return ordered
end

local function escape_snippet_text(value)
  local escaped = tostring(value or "")
  escaped = escaped:gsub("\\", "\\\\")
  escaped = escaped:gsub("%$", "\\$")
  escaped = escaped:gsub("}", "\\}")
  return escaped
end

local function escape_snippet_choice_item(value)
  local escaped = escape_snippet_text(value)
  escaped = escaped:gsub(",", "\\,")
  escaped = escaped:gsub("|", "\\|")
  return escaped
end

local function build_choice_items(default_value, available_values)
  local unique = {}
  local seen = {}
  if default_value and default_value ~= "" then
    table.insert(unique, default_value)
    seen[default_value] = true
  end
  for _, item in ipairs(available_values) do
    if not seen[item] then
      table.insert(unique, item)
      seen[item] = true
    end
  end
  return unique
end

local function render_template_with_defaults(template, defaults, invocation_values)
  if type(template) ~= "string" then
    return template
  end

  local rendered = template
  local keys = collect_template_keys(template)
  for key in pairs(keys) do
    local value = invocation_values[key] or defaults[key]
    if not value or value == "" then
      return nil
    end
    rendered = rendered:gsub("{" .. key .. "}", value)
  end
  return rendered
end

local function build_placeholder_for_key(idx, key, defaults, options, invocation_values)
  local default_value = invocation_values[key] or defaults[key] or key
  local available_values = options[key]
  if type(available_values) == "table" and #available_values > 0 then
    local choice_items = build_choice_items(default_value, available_values)
    local escaped_items = {}
    for _, item in ipairs(choice_items) do
      table.insert(escaped_items, escape_snippet_choice_item(item))
    end
    return string.format("${%d|%s|}", idx, table.concat(escaped_items, ","))
  end
  return string.format("${%d:%s}", idx, escape_snippet_text(default_value))
end

local function build_linked_template_snippets(start_template, end_template, defaults, options, invocation_values)
  local ordered_keys = collect_template_keys_in_order(start_template)
  local seen = {}
  for _, key in ipairs(ordered_keys) do
    seen[key] = true
  end
  for _, key in ipairs(collect_template_keys_in_order(end_template)) do
    if not seen[key] then
      table.insert(ordered_keys, key)
      seen[key] = true
    end
  end

  local start_snippet = start_template
  local end_snippet = end_template
  for idx, key in ipairs(ordered_keys) do
    local placeholder = build_placeholder_for_key(idx, key, defaults, options, invocation_values)
    start_snippet = start_snippet:gsub("{" .. key .. "}", placeholder)
    end_snippet = end_snippet:gsub("{" .. key .. "}", placeholder)
  end

  return start_snippet, end_snippet
end

local function build_template_snippet(template, defaults, options, invocation_values)
  if type(template) ~= "string" then
    return template
  end

  local snippet = template
  local ordered_keys = collect_template_keys_in_order(template)
  for idx, key in ipairs(ordered_keys) do
    local default_value = invocation_values[key] or defaults[key] or key
    local placeholder
    local available_values = options[key]
    if type(available_values) == "table" and #available_values > 0 then
      local choice_items = build_choice_items(default_value, available_values)
      local escaped_items = {}
      for _, item in ipairs(choice_items) do
        table.insert(escaped_items, escape_snippet_choice_item(item))
      end
      placeholder = string.format("${%d|%s|}", idx, table.concat(escaped_items, ","))
    else
      placeholder = string.format("${%d:%s}", idx, escape_snippet_text(default_value))
    end
    snippet = snippet:gsub("{" .. key .. "}", placeholder)
  end

  return snippet
end

local function can_expand_snippet()
  return vim.snippet and type(vim.snippet.expand) == "function"
end

local function ensure_normal_mode_for_snippet()
  if utils.is_visual_mode() then
    vim.cmd("normal! <Esc>")
  end
end

local function expand_snippet_at(line, col, snippet)
  ensure_normal_mode_for_snippet()
  vim.api.nvim_win_set_cursor(0, { line, col })
  vim.snippet.expand(snippet)
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
      local template_defaults = build_template_defaults(formatter_pragma_comments)
      local template_options = build_template_options(formatter_pragma_comments)
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
        local rendered_before =
          render_template_with_defaults(formatter_pragma_comments.before, template_defaults, invocation_values)
        if not rendered_before then
          goto continue
        end

        if
          mode
          and start_line == end_line
          and has_placeholders(formatter_pragma_comments.before)
          and can_expand_snippet()
        then
          local before_snippet = build_template_snippet(
            formatter_pragma_comments.before,
            template_defaults,
            template_options,
            invocation_values
          )
          local snippet_comment = utils.resolve_pragma_comment(before_snippet)
          local indent = utils.set_proper_indentation(start_line)
          vim.api.nvim_buf_set_lines(0, start_line - 1, start_line - 1, true, { "" })
          expand_snippet_at(start_line, 0, indent .. snippet_comment)
          goto continue
        end

        for line = end_line, start_line, -1 do
          add_before_comment(line, rendered_before)
        end
      elseif selected_mode == "inline" and formatter_pragma_comments.inline then
        local rendered_inline =
          render_template_with_defaults(formatter_pragma_comments.inline, template_defaults, invocation_values)
        if not rendered_inline then
          goto continue
        end

        if
          mode
          and start_line == end_line
          and has_placeholders(formatter_pragma_comments.inline)
          and can_expand_snippet()
        then
          local inline_snippet = build_template_snippet(
            formatter_pragma_comments.inline,
            template_defaults,
            template_options,
            invocation_values
          )
          local snippet_comment = utils.resolve_pragma_comment(inline_snippet)
          local line_text = vim.api.nvim_buf_get_lines(0, start_line - 1, start_line, false)[1] or ""
          expand_snippet_at(start_line, #line_text, " " .. snippet_comment)
          goto continue
        end

        for line = start_line, end_line do
          add_inline_comment(line, rendered_inline)
        end
      elseif selected_mode == "blockwise" and formatter_pragma_comments.blockwise then
        if
          mode
          and (has_placeholders(formatter_pragma_comments.blockwise[1]) or has_placeholders(
            formatter_pragma_comments.blockwise[2]
          ))
          and can_expand_snippet()
        then
          local start_snippet, end_snippet = build_linked_template_snippets(
            formatter_pragma_comments.blockwise[1],
            formatter_pragma_comments.blockwise[2],
            template_defaults,
            template_options,
            invocation_values
          )
          local start_snippet_comment = utils.resolve_pragma_comment(start_snippet)
          local end_snippet_comment = utils.resolve_pragma_comment(end_snippet)
          local indent_start = utils.set_proper_indentation(start_line)
          local indent_end = utils.set_proper_indentation(end_line)
          local selected_lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

          local snippet_lines = { indent_start .. start_snippet_comment }
          for _, body_line in ipairs(selected_lines) do
            table.insert(snippet_lines, body_line)
          end
          table.insert(snippet_lines, indent_end .. end_snippet_comment)
          local block_snippet = table.concat(snippet_lines, "\n") .. "$0"

          vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, true, { "" })
          expand_snippet_at(start_line, 0, block_snippet)
          goto continue
        end

        local rendered_start =
          render_template_with_defaults(formatter_pragma_comments.blockwise[1], template_defaults, invocation_values)
        local rendered_end =
          render_template_with_defaults(formatter_pragma_comments.blockwise[2], template_defaults, invocation_values)
        if not rendered_start or not rendered_end then
          goto continue
        end

        add_blockwise_comments(start_line, end_line, { rendered_start, rendered_end })
      elseif selected_mode == "all" and formatter_pragma_comments.all then
        local rendered_all =
          render_template_with_defaults(formatter_pragma_comments.all, template_defaults, invocation_values)
        if not rendered_all then
          goto continue
        end

        if mode and has_placeholders(formatter_pragma_comments.all) and can_expand_snippet() then
          local all_snippet = build_template_snippet(
            formatter_pragma_comments.all,
            template_defaults,
            template_options,
            invocation_values
          )
          local all_snippet_comment = utils.resolve_pragma_comment(all_snippet)
          vim.api.nvim_buf_set_lines(0, 0, 0, true, { "" })
          expand_snippet_at(1, 0, all_snippet_comment)
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
