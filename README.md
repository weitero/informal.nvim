# informal.nvim

Effortlessly skip formatting on selected code blocks in Neovim.

![informal.nvim demo](https://raw.githubusercontent.com/weitero/informal.nvim/main/assets/demo.gif)

> **Note**: This is a placeholder GIF. Please replace it with a real demonstration of the plugin.

`informal.nvim` is a Lua-based Neovim plugin that simplifies adding pragma comments to your code, allowing you to prevent formatters from altering specific lines or blocks.

## ✨ Features

-   **Visual Selection**: Add ignore comments to lines selected in Visual mode (`v`, `V`, `<C-v>`).
-   **Normal Mode**: Quickly add an ignore comment to the current line in Normal mode.
-   **Formatter Integration**: Automatically detects formatter names when [`conform.nvim`](https://github.com/stevearc/conform.nvim) is installed.
-   **Customizable**: Easily override default settings to add support for new formatters or customize pragma comments.
-   **Built-in Support**: Comes with pre-configured settings for `stylua` (Lua) and `ruff_format` (Python).

## 📋 Requirements

-   Neovim >= 0.7.0
-   (Optional) [`conform.nvim`](https://github.com/stevearc/conform.nvim): Used to detect the correct formatter for the current buffer. If not found, the plugin falls back to a predefined list.

## 📦 Installation

Install `informal.nvim` using your favorite plugin manager.

With `lazy.nvim`:

```lua
{
  "weitero/informal.nvim",
  opts = {},
}
```

## 🚀 Usage

The primary way to use `informal.nvim` is by selecting code and using a keymap to add the ignore comments.

1.  **Select code**:
    -   In **Visual mode**, select one or more lines.
    -   In **Normal mode**, place your cursor on the line you want to ignore.
2.  **Add comments**:
    -   Press `<leader>c` (default keymap) to add the appropriate pragma comments.

### Examples

#### Single Line (Normal Mode or Visual Mode)

When used on a single line, `informal.nvim` adds an inline or preceding comment.

**Lua (`stylua`)**:

```lua
-- Before
local a = 1

-- After pressing <leader>c
-- stylua: ignore
local a = 1
```

**Python (`ruff_format`)**:

```python
# Before
a = 1

# After pressing <leader>c
a = 1  # fmt: skip
```

#### Multiple Lines (Visual Mode)

When used on a block of code, `informal.nvim` surrounds it with block-style comments.

**Lua (`stylua`)**:

```lua
-- Before (lines selected in Visual mode)
local a = 1
local b = 2

-- After pressing <leader>c
-- stylua: ignore start
local a = 1
local b = 2
-- stylua: ignore end
```

## ⚙️ Configuration

You can customize `informal.nvim` by passing an `opts` table to the `setup()` function.

### Default Configuration

Here are the default settings for the plugin:

```lua
{
  -- If `conform.nvim` is not available, `informal.nvim` uses this table
  -- to determine which formatter to use for a given filetype.
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_format" },
  },

  -- Override or add pragma comments for different formatters.
  pragma_comments = {},

  -- Keymap for adding comments. Set to `false` to disable.
  keymaps = {
    add_comments = "<leader>c",
  },
}
```

### Customizing Formatters

To add support for a new language or formatter, update the `formatters_by_ft` table.

```lua
-- In your lazy.nvim setup
opts = {
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_format" },
    -- Add a new filetype and formatter
    typescript = { "prettier" },
  },
}
```

### Customizing Pragma Comments

You can define custom pragma comments for any formatter using the `pragma_comments` table. This is useful for formatters not supported by default or for overriding existing settings.

There are three types of pragma comments:
-   `inline`: Appended to the end of a line.
-   `before`: Inserted on the line before the code.
-   `blockwise`: A pair of comments that surround a block of code (`{start, end}`).

```lua
-- In your lazy.nvim setup
opts = {
  pragma_comments = {
    -- Example for Prettier (JavaScript/TypeScript)
    prettier = {
      inline = "prettier-ignore",
      before = "prettier-ignore",
    },
    -- Example for a fictional formatter
    my_formatter = {
      inline = "-- my-fmt-ignore-line",
      before = "-- my-fmt-ignore-line",
      blockwise = { "-- my-fmt-ignore-start", "-- my-fmt-ignore-end" },
    },
  },
}
```

### Built-in Pragma Comments

| Formatter     | Language | Type        | Comment                               |
| ------------- | -------- | ----------- | ------------------------------------- |
| `stylua`      | Lua      | `before`    | `-- stylua: ignore`                   |
|               |          | `blockwise` | `-- stylua: ignore start`, `-- stylua: ignore end` |
| `ruff_format` | Python   | `inline`    | `# fmt: skip`                         |
|               |          | `blockwise` | `# fmt: off`, `# fmt: on`             |

## 📝 TODO

-   [ ] Support easy removal of pragma comments.

## 📄 License

This plugin is licensed under the MIT License. See [LICENSE](./LICENSE) for more details.