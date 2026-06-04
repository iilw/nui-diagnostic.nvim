# nui-diagnostic.nvim

A small Neovim plugin that jumps between diagnostics and shows the current diagnostic together with available LSP code actions in `nui.nvim` popups.

## Features

- Jump to next/previous diagnostics and immediately show context.
- Show diagnostic messages in a popup.
- Show available LSP code actions in a second popup.
- Execute actions with number keys.
- Close popups with `<Esc>` or cursor movement.
- Optional built-in keymaps.
- User commands for manual use.
- Configurable diagnostic formatting and popup appearance.

## Requirements

- Neovim 0.10+
- [`nui.nvim`](https://github.com/MunifTanjim/nui.nvim)
- An LSP client that publishes diagnostics and/or code actions

## Installation

### `lazy.nvim`

```lua
{
    "iilw/nui-diagnostic.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {}
}
```

### `vim.pack`

```lua
vim.pack.add({
  "https://github.com/MunifTanjim/nui.nvim",
  "https://github.com/iilw/nui-diagnostic.nvim",
})

require("nui-diagnostic").setup({})
```

## Usage

built-in mappings:

```lua
require("nui-diagnostic").setup({
  keymaps = {
    enabled = true,
  },
})
```

Or manual keymaps:

```lua
vim.keymap.set("n", "]d", function()
  require("nui-diagnostic").next()
end)

vim.keymap.set("n", "[d", function()
  require("nui-diagnostic").prev()
end)

vim.keymap.set("n", "]e", function()
  require("nui-diagnostic").next({ severity = "ERROR" })
end)

vim.keymap.set("n", "[e", function()
  require("nui-diagnostic").prev({ severity = "ERROR" })
end)

```

## Configuration

Default options:

```lua
require("nui-diagnostic").setup({
  popup = {
    width = 50,
    max_width = 80,
    max_height = 12,
    border_style = "rounded",
    position = { row = 1, col = 0 },
    win_options = {
      wrap = false,
      winblend = 0,
    },
  },
  diagnostics = {
    enabled = true,
    max_items = nil,
    format = nil,
  },
  code_actions = {
    enabled = true,
    max_items = 9,
    include_disabled = false,
    kinds = nil,
    sort = nil,
    keys = { "1", "2", "3", "4", "5", "6", "7", "8", "9" },
  },
  close = {
    key = "<Esc>",
    events = { "CursorMoved", "InsertEnter", "BufLeave" },
  },
  keymaps = {
    enabled = true,
    next = "]d",
    prev = "[d",
    next_error = "]e",
    prev_error = "[e",
  },
  notify = true,
})
```

## Health check

```vim
:checkhealth nui-diagnostic
```

## License

MIT
