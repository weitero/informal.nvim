local function split_lines(text)
  local lines = {}
  for line in (text .. "\n"):gmatch("(.-)\n") do
    table.insert(lines, line)
  end
  return lines
end

local function deep_copy(value)
  if type(value) ~= "table" then
    return value
  end
  local out = {}
  for k, v in pairs(value) do
    out[k] = deep_copy(v)
  end
  return out
end

local function deep_extend_force(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" and type(dst[k]) == "table" then
      deep_extend_force(dst[k], v)
    else
      dst[k] = deep_copy(v)
    end
  end
  return dst
end

local function make_vim_mock(initial)
  local state = {
    mode = initial.mode or "n",
    current_line = initial.current_line or 1,
    visual_start = initial.visual_start or 1,
    visual_end = initial.visual_end or 1,
    lines = deep_copy(initial.lines or {}),
    keymaps = {},
    notifications = {},
    cursor = { 1, 0 },
    last_snippet = nil,
    bo = {
      filetype = initial.filetype or "lua",
      commentstring = initial.commentstring or "-- %s",
    },
  }

  local function set_lines(start_idx, end_idx, new_lines)
    local result = {}
    local total = #state.lines
    for i = 1, start_idx do
      if i <= total then
        table.insert(result, state.lines[i])
      end
    end
    for _, line in ipairs(new_lines) do
      table.insert(result, line)
    end
    for i = end_idx + 1, total do
      table.insert(result, state.lines[i])
    end
    state.lines = result
  end

  local vim_mock = {
    bo = state.bo,
    api = {},
    fn = {},
    keymap = {},
    snippet = {},
  }

  function vim_mock.deepcopy(value)
    return deep_copy(value)
  end

  function vim_mock.tbl_deep_extend(mode, ...)
    assert(mode == "force", "only force mode is supported in tests")
    local args = { ... }
    local out = deep_copy(args[1] or {})
    for i = 2, #args do
      deep_extend_force(out, args[i] or {})
    end
    return out
  end

  vim_mock.log = { levels = { WARN = "WARN" } }

  function vim_mock.notify(message, level)
    table.insert(state.notifications, { message = message, level = level })
  end

  function vim_mock.cmd(_)
    state.mode = "n"
  end

  function vim_mock.fn.mode()
    return state.mode
  end

  function vim_mock.fn.line(mark)
    if mark == "." then
      return state.current_line
    end
    return 1
  end

  function vim_mock.fn.getpos(mark)
    if mark == "v" then
      return { 0, state.visual_start, 1, 0 }
    end
    if mark == "." then
      return { 0, state.visual_end, 1, 0 }
    end
    if mark == "$" then
      local line = state.lines[state.current_line] or ""
      return { 0, state.current_line, #line + 1, 0 }
    end
    return { 0, 1, 1, 0 }
  end

  function vim_mock.fn.indent(lnum)
    local line = state.lines[lnum] or ""
    local spaces = line:match("^(%s*)") or ""
    return #spaces
  end

  function vim_mock.api.nvim_buf_get_lines(_, start_idx, end_idx, _)
    local out = {}
    for i = start_idx + 1, end_idx do
      table.insert(out, state.lines[i] or "")
    end
    return out
  end

  function vim_mock.api.nvim_buf_set_lines(_, start_idx, end_idx, _, new_lines)
    set_lines(start_idx, end_idx, new_lines)
  end

  function vim_mock.api.nvim_buf_set_text(_, srow, scol, erow, ecol, chunks)
    assert(srow == erow, "tests only support single-line edits")
    local line_no = srow + 1
    local line = state.lines[line_no] or ""
    local prefix = line:sub(1, scol)
    local suffix = line:sub(ecol + 1)
    local middle = table.concat(chunks, "\n")
    state.lines[line_no] = prefix .. middle .. suffix
  end

  function vim_mock.api.nvim_win_set_cursor(_, pos)
    state.cursor = { pos[1], pos[2] }
    state.current_line = pos[1]
  end

  function vim_mock.keymap.set(modes, lhs, rhs, opts)
    table.insert(state.keymaps, { modes = modes, lhs = lhs, rhs = rhs, opts = opts })
  end

  function vim_mock.snippet.expand(snippet)
    state.last_snippet = snippet
    local row = state.cursor[1]
    local pieces = split_lines(snippet)
    set_lines(row - 1, row, pieces)
  end

  return vim_mock, state
end

local function reset_modules()
  for name, _ in pairs(package.loaded) do
    if name:match("^informal") or name == "conform" then
      package.loaded[name] = nil
    end
  end
end

local function setup_runtime(vim_mock)
  _G.vim = vim_mock
  local repo = "/Users/akio/repos/informal.nvim"
  package.path = repo .. "/lua/?.lua;" .. repo .. "/lua/?/init.lua;" .. package.path
end

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error((message or "assert_eq failed") .. "\nexpected: " .. tostring(expected) .. "\nactual:   " .. tostring(actual))
  end
end

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

local tests = {}

local function add_test(name, fn)
  table.insert(tests, { name = name, fn = fn })
end

add_test("auto single-line prefers before comment", function()
  local vim_mock, state =
    make_vim_mock({ lines = { "local a = 1" }, mode = "n", filetype = "lua", commentstring = "-- %s" })
  setup_runtime(vim_mock)
  reset_modules()

  local config = require("informal.config")
  local ignore = require("informal.ignore")
  config.setup({})
  ignore.add_comments()

  assert_eq(state.lines[1], "-- stylua: ignore")
  assert_eq(state.lines[2], "local a = 1")
end)

add_test("auto single-line falls back to inline", function()
local vim_mock, state =
    make_vim_mock({ lines = { "local a = 1" }, mode = "n", filetype = "lua", commentstring = "-- %s" })
  setup_runtime(vim_mock)
  reset_modules()

  local config = require("informal.config")
  local ignore = require("informal.ignore")
  config.setup({
    formatters_by_ft = { lua = { "my_fmt" } },
    pragma_comments = { my_fmt = { inline = "fmt: skip" } },
  })

  ignore.add_comments()
  assert_eq(state.lines[1], "local a = 1 -- fmt: skip")
end)

add_test("auto visual selection inserts blockwise comments", function()
  local vim_mock, state = make_vim_mock({
    lines = { "local a = 1", "local b = 2" },
    mode = "v",
    visual_start = 1,
    visual_end = 2,
    filetype = "lua",
    commentstring = "-- %s",
  })
  setup_runtime(vim_mock)
  reset_modules()

  local config = require("informal.config")
  local ignore = require("informal.ignore")
  config.setup({})

  ignore.add_comments()
  assert_eq(state.lines[1], "-- stylua: ignore start")
  assert_eq(state.lines[2], "local a = 1")
  assert_eq(state.lines[3], "local b = 2")
  assert_eq(state.lines[4], "-- stylua: ignore end")
end)

add_test("explicit all expands snippet at file top", function()
  local vim_mock, state = make_vim_mock({
    lines = { "const a = 1" },
    mode = "n",
    filetype = "javascript",
    commentstring = "// %s",
  })
  setup_runtime(vim_mock)
  reset_modules()

  local config = require("informal.config")
  local ignore = require("informal.ignore")
  config.setup({ formatters_by_ft = { javascript = { "biome" } } })

  ignore.add_comments_all({ target = "lint", reason = "test" })

  assert_true(state.last_snippet ~= nil, "all mode should expand snippet")
  assert_true(state.lines[1]:find("biome%-ignore%-all"), "top line should include all suppression")
end)

add_test("missing template values skips formatter insertion", function()
  local vim_mock, state = make_vim_mock({
    lines = { "x = 1" },
    mode = "n",
    filetype = "python",
    commentstring = "# %s",
  })
  setup_runtime(vim_mock)
  reset_modules()

  local config = require("informal.config")
  local ignore = require("informal.ignore")
  config.setup({
    formatters_by_ft = { python = { "my_fmt" } },
    pragma_comments = { my_fmt = { before = "needs {target}" } },
  })

  ignore.add_comments_before()
  assert_eq(state.lines[1], "x = 1")
end)

add_test("explicit before uses snippet expansion when placeholders exist", function()
  local vim_mock, state = make_vim_mock({
    lines = { "const a = 1" },
    mode = "n",
    filetype = "javascript",
    commentstring = "// %s",
  })
  setup_runtime(vim_mock)
  reset_modules()

  local config = require("informal.config")
  local ignore = require("informal.ignore")
  config.setup({ formatters_by_ft = { javascript = { "biome" } } })

  ignore.add_comments_before({ target = "lint", reason = "r" })

  assert_true(state.last_snippet ~= nil, "snippet should be expanded")
  assert_true(state.last_snippet:find("biome%-ignore"), "snippet should contain biome ignore")
end)

add_test("explicit blockwise snippet mirrors placeholders", function()
  local vim_mock, state = make_vim_mock({
    lines = { "const a = 1", "const b = 2" },
    mode = "v",
    visual_start = 1,
    visual_end = 2,
    filetype = "javascript",
    commentstring = "// %s",
  })
  setup_runtime(vim_mock)
  reset_modules()

  local config = require("informal.config")
  local ignore = require("informal.ignore")
  config.setup({ formatters_by_ft = { javascript = { "biome" } } })

  ignore.add_comments_blockwise({ target = "lint", reason = "r" })

  assert_true(state.last_snippet ~= nil, "blockwise should expand snippet")
  assert_true(state.last_snippet:find("biome%-ignore%-start"), "start comment must exist")
  assert_true(state.last_snippet:find("biome%-ignore%-end"), "end comment must exist")
  assert_true(state.last_snippet:find("%${1:"), "target placeholder should be linked")
  assert_true(state.last_snippet:find("%${2:"), "reason placeholder should be linked")
end)

add_test("config.setup registers default keymaps", function()
  local vim_mock, state = make_vim_mock({ lines = { "a" }, mode = "n", filetype = "lua" })
  setup_runtime(vim_mock)
  reset_modules()

  local config = require("informal.config")
  config.setup({})

  local lhs = {}
  for _, km in ipairs(state.keymaps) do
    lhs[km.lhs] = true
  end
  assert_true(lhs["<leader>ig"], "missing auto keymap")
  assert_true(lhs["<leader>ii"], "missing inline keymap")
  assert_true(lhs["<leader>ib"], "missing before keymap")
  assert_true(lhs["<leader>iw"], "missing blockwise keymap")
  assert_true(lhs["<leader>ia"], "missing all keymap")
end)

add_test("pragma comment overrides merge with defaults", function()
  local vim_mock = make_vim_mock({ lines = { "a" }, mode = "n", filetype = "lua" })
  setup_runtime(vim_mock)
  reset_modules()

  local config = require("informal.config")
  local pragma = require("informal.pragma_comments")
  config.setup({
    pragma_comments = {
      stylua = { before = "-- custom ignore" },
    },
  })

  assert_eq(pragma.stylua.before, "-- custom ignore")
  assert_eq(pragma.stylua.blockwise[1], "stylua: ignore start")
end)

add_test("resolve_pragma_comment respects commentstring fallback", function()
  local vim_mock, _ = make_vim_mock({ lines = { "a" }, mode = "n", filetype = "lua", commentstring = "" })
  setup_runtime(vim_mock)
  reset_modules()

  local utils = require("informal.utils")
  assert_eq(utils.resolve_pragma_comment("fmt: skip"), "fmt: skip")

  vim.bo.commentstring = "-- %s"
  assert_eq(utils.resolve_pragma_comment("fmt: skip"), "-- fmt: skip")
end)

local passed = 0
for _, t in ipairs(tests) do
  local ok, err = pcall(t.fn)
  if ok then
    io.write("PASS  " .. t.name .. "\n")
    passed = passed + 1
  else
    io.write("FAIL  " .. t.name .. "\n")
    io.write(err .. "\n")
  end
end

io.write(string.format("\n%d/%d tests passed\n", passed, #tests))
if passed ~= #tests then
  os.exit(1)
end
