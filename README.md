# informal.nvim

A Neovim plugin to make it easier to skip formatting selected code. Written in Lua.

> [!NOTE]
> This plugin is still a work in progress.

## Features

- Add pragma comments (pre-defined, can be overridden) to selected lines in V-mode

## Requirements

- (Optional) [`conform.nvim`](https://github.com/stevearc/conform.nvim):
if `conform.nvim` is found it will be used to determine formatter names.
Otherwise will fall back to a predefined table. See [Default settings](default-settings).

## Installation

Using `lazy.nvim`:

```lua
{
  'weitero/informal.nvim',
  opts = {},
}
```

## Usage

Select code in V-mode (`v`, `V`, or `<Ctrl-v>`) and press `<leader>c` (default key binding).
Or in Normal mode, press `<leader>c` (this is similar to selecting one line in
V-mode).

- example when multiple lines are selected:

```lua
-- when using stylua

-- before
-- (two lines selected in V-mode)

local a = 1
local b = 2

-- after `<leader>c`
-- (pragma comments added)

-- stylua: ignore start
local a = 1
local b = 2
-- stylua: ignore end
```

- example when one line is selected:

```lua
-- when using stylua

-- before
-- (one line selected in V-mode)

local a = 1

-- after `<leader>c`
-- (pragma comments added)

-- stylua: ignore 
local a = 1
```

```py
# when using ruff_format

# before
# (one line selected in V-mode)

a = 1

# after `<leader>c`
# (pragma comments added)

a = 1 # fmt: skip
```

- example in Normal mode:

```lua
-- when using stylua

-- before
-- (Normal mode, cursor at the first line (doesn't matter where))

local a = 1|
local b = 2

-- after `<leader>c`
-- (pragma comments added)

-- stylua: ignore
local a = 1|
local b = 2
```

> [!NOTE]
> Block-skipping is only available when multiple lines are selected.


## Configuration

### Default settings

```lua
{
  force_block_ignore = false, -- not used

  -- Use `conform.nvim` if available to get formatter names.
  -- Otherwise fallback to this pre-defined table.
  formatters_by_ft = {
    lua = { 'stylua' },
    python = { 'ruff_format' }
    -- more could be added, for example:
    -- another_language = { 'another_formatter' }
  }

  -- Override default pragma comments or add new ones
  pragma_comments = {},

  keymaps = {
    add_comments = '<leader>c' -- set to `false` to disable
  }
}
```

### Override or add pragma comments

Three types of pragma comments are supported:

1. inline: to be added at the end of a line
2. before: to be added before a line and occupy an entire line
3. blockwise: to surround a code block

To configure:

```lua
pragma_comments = {
  my_formatter = { -- Replace `my_formatter` with your formatter name
    -- If any of the three types of pragma comments is not supported by the formatter,
    -- drop the corresponding line(s). For example, `stylua` does not support `inline`
    -- so `inline = 'pragma_comment_inline'` should be removed when configuring it.
    inline = 'pragma_comment_inline', -- Replace this string
    before = 'pragma_comment_before', -- Replace this string
    blockwise = {
       -- Replace both
      'pragma_comment_start',
      'pragma_comment_end'
    },
  }
} 
```

The following languages/formatters are configured by default:

- Lua
  - `stylua`: (before) `-- stylua: ignore`, (blockwise) `-- stylua: ignore start` and `-- stylua: ignore end`
- Python
  - `ruff_format`: (inline) `# fmt: skip`, (blockwise) `# fmt: off` and `# fmt: on`
 
## TODOs

- [x] Support Normal mode
- [ ] Support easy removal of pragma comments
