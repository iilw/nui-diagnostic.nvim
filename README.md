# nui-diagnostic.nvim

A small Neovim plugin that jumps between diagnostics and shows the current diagnostic together with available LSP code actions in `nui.nvim` popups.

![nui-diagnostic-gif](https://github.com/user-attachments/assets/ba5e4cc7-7828-4486-89a8-646ca3710deb)

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

## Commands

Commands are registered by `require("nui-diagnostic").setup()`:

| Command | Description |
| --- | --- |
| `:NuiDiagnosticNext [severity]` | Jump to the next diagnostic and open popups. |
| `:NuiDiagnosticPrev [severity]` | Jump to the previous diagnostic and open popups. |
| `:NuiDiagnosticOpen [severity]` | Open popups for diagnostics at the current cursor line. |
| `:NuiDiagnosticClose` | Close active popups. |

`severity` is optional. String aliases are case-insensitive and include `error`, `err`, `warn`, `warning`, `info`, and `hint`.

## Lua API

```lua
local diagnostic = require("nui-diagnostic")

diagnostic.next()
diagnostic.prev()
diagnostic.open()
diagnostic.close()

-- Filter by severity.
diagnostic.next({ severity = "ERROR" })
diagnostic.prev({ severity = "warn" })
diagnostic.open({ severity = vim.diagnostic.severity.INFO })

-- Positional form is also supported.
diagnostic.next(2, "error")
diagnostic.prev(1, "warn")
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
    severity_names = {
      [vim.diagnostic.severity.ERROR] = "ERROR",
      [vim.diagnostic.severity.WARN] = "WARN",
      [vim.diagnostic.severity.INFO] = "INFO",
      [vim.diagnostic.severity.HINT] = "HINT",
    },
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
    events = { "BufLeave", "CursorMoved", "InsertEnter" },
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

Notes:

- `diagnostics.format(diagnostic)` can override the displayed diagnostic line.
- `diagnostics.severity_names` controls the default severity labels shown in the diagnostic popup.
- `code_actions.max_items` limits the number of displayed actions.
- `code_actions.include_disabled = true` shows disabled LSP actions; disabled actions are hidden by default.
- `code_actions.kinds` filters action kinds and prefixes, for example `{ "quickfix", "refactor" }`.
- `code_actions.sort` receives `NuiDiagnosticActionTuple` entries and can reorder actions before display.
- `code_actions.keys` are assigned to visible actions in display order.

## Health check

```vim
:checkhealth nui-diagnostic
```

## License

MIT
