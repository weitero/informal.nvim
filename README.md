# informal.nvim

Effortlessly skip formatting on selected code blocks in Neovim.

![informal.nvim demo](https://raw.githubusercontent.com/weitero/informal.nvim/main/assets/demo.gif)

> **Note**: This is a placeholder GIF. Please replace it with a real demonstration of the plugin.

`informal.nvim` is a Lua-based Neovim plugin that simplifies adding pragma comments to your code, allowing you to prevent formatters from altering specific lines or blocks.

## ✨ Features

- **Visual Selection**: Add ignore comments to lines selected in Visual mode (`v`, `V`, `<C-v>`).
- **Normal Mode**: Quickly add an ignore comment to the current line in Normal mode.
- **Formatter Integration**: Automatically detects formatter names when [`conform.nvim`](https://github.com/stevearc/conform.nvim) is installed.
- **Customizable**: Easily override default settings to add support for new formatters or customize pragma comments.
- **Built-in Support**: Comes with pre-configured settings for `stylua` (Lua) and `ruff_format` (Python).

## 📋 Requirements

- Neovim >= 0.7.0
- (Optional) [`conform.nvim`](https://github.com/stevearc/conform.nvim): Used to detect the correct formatter for the current buffer. If not found, the plugin falls back to a predefined list.

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

1. Select code in Visual mode, or place your cursor on a line in Normal mode.
2. Press `<leader>ig` (default) to use automatic mode selection.
3. Press `<leader>ii` to force `inline` comments.
4. Press `<leader>ib` to force `before` comments.
5. Press `<leader>iw` to force `blockwise` comments.
6. Press `<leader>ia` to force `all` comments (inserted at top of file).

By default, mode selection is automatic:

- Single line: prefers `before`, falls back to `inline`.
- Multi-line selection: uses `blockwise`.
- `all` is never selected automatically; it is explicit-only via keybinding/API.

### Examples

#### Single Line (Normal Mode or Visual Mode)

When used on a single line, `informal.nvim` adds an inline or preceding comment.

**Lua (`stylua`)**:

```lua
-- Before
local a = 1

-- After pressing <leader>ig
-- stylua: ignore
local a = 1
```

**Python (`ruff_format`)**:

```python
# Before
a = 1

# After pressing <leader>ig
a = 1  # fmt: skip
```

#### Multiple Lines (Visual Mode)

When used on a block of code, `informal.nvim` surrounds it with block-style comments.

**Lua (`stylua`)**:

```lua
-- Before (lines selected in Visual mode)
local a = 1
local b = 2

-- After pressing <leader>ig
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

  -- Optional global defaults used by pragma templates with placeholders.
  -- Example placeholders: {target}, {reason}
  template_defaults = {},

  -- Optional global selectable values for template placeholders.
  -- When present, explicit modes show these values in a picker.
  template_options = {},

  -- Override or add pragma comments for different formatters.
  pragma_comments = {},

  -- Keymap for adding comments. Set to `false` to disable.
  keymaps = {
    add_comments = "<leader>ig",
    add_comments_inline = "<leader>ii",
    add_comments_before = "<leader>ib",
    add_comments_blockwise = "<leader>iw",
    add_comments_all = "<leader>ia",
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

- `inline`: Appended to the end of a line.
- `before`: Inserted on the line before the code.
- `blockwise`: A pair of comments that surround a block of code (`{start, end}`).
- `all`: Inserted at the top of the file. This mode is explicit-only.

Pragma comments can also be templates. Any placeholder in `{name}` format will
be replaced at runtime.

- In automatic mode, placeholders use configured defaults only.
- In explicit modes (`inline`, `before`, `blockwise`, `all`), missing
  placeholders prompt for input.
- If `template_options` are configured for a placeholder (e.g. `target`), the
  prompt shows available values and also allows a custom value.
- For Biome `target`, custom values must start with `lint`, `assist`, or
  `syntax`.

```lua
-- In your lazy.nvim setup
opts = {
  template_defaults = {
    reason = "temporary suppression",
  },
  template_options = {
    target = { "lint", "assist", "syntax" },
  },
  pragma_comments = {
    -- Example for Biome (file-wide disable pragma)
    biome = {
      all = "biome-ignore-all {target}: {reason}",
      before = "biome-ignore {target}: {reason}",
      blockwise = {
        "biome-ignore-start {target}: {reason}",
        "biome-ignore-end {target}: {reason}",
      },
      template_defaults = {
        target = "lint",
      },
      template_options = {
        target = {
          "lint",
          "lint/suspicious",
          "lint/suspicious/noDebugger",
        },
      },
    },
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

| Formatter     | Language | Type        | Comment                                            |
| ------------- | -------- | ----------- | -------------------------------------------------- |
| `stylua`      | Lua      | `before`    | `-- stylua: ignore`                                |
|               |          | `blockwise` | `-- stylua: ignore start`, `-- stylua: ignore end` |
| `ruff_format` | Python   | `inline`    | `# fmt: skip`                                      |
|               |          | `blockwise` | `# fmt: off`, `# fmt: on`                          |
| `biome`       | JS/TS    | `before`    | `// biome-ignore lint: reason`                     |
|               |          | `blockwise` | `// biome-ignore-start/end lint: reason`           |
|               |          | `all`       | `// biome-ignore-all lint: reason`                 |

## 📝 TODO

- [ ] Support easy removal of pragma comments.

## 📄 License

This plugin is licensed under the MIT License. See [LICENSE](./LICENSE) for more details.
