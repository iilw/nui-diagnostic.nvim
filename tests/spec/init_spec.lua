---@diagnostic disable: undefined-global, undefined-field

local function clear_modules()
  package.loaded["nui-diagnostic"] = nil
  package.loaded["nui-diagnostic.config"] = nil
  package.loaded["nui-diagnostic.code_action"] = nil
  package.loaded["nui-diagnostic.popup"] = nil
end

describe("nui-diagnostic", function()
  local original_create_user_command
  local original_keymap_set
  local original_get_current_buf
  local original_get_current_win
  local original_win_get_cursor
  local original_diagnostic_get
  local original_diagnostic_jump
  local original_defer_fn
  local original_make_range_params

  local commands
  local keymaps
  local diagnostics
  local jumps
  local popup_calls
  local close_calls
  local code_action_requests
  local run_action_calls
  local plugin

  local function load_plugin()
    clear_modules()

    package.loaded["nui-diagnostic.popup"] = {
      open = function(opts)
        table.insert(popup_calls, opts)
      end,
      close = function()
        close_calls = close_calls + 1
      end,
      is_open = function()
        return true
      end,
    }

    package.loaded["nui-diagnostic.code_action"] = {
      request = function(bufnr, params, opts, callback)
        table.insert(code_action_requests, {
          bufnr = bufnr,
          params = params,
          opts = opts,
        })
        callback({ { action = { title = "fix" }, client_id = 1 } })
      end,
      run_action = function(action_tuple, opts)
        table.insert(run_action_calls, { action_tuple = action_tuple, opts = opts })
      end,
    }

    plugin = require("nui-diagnostic")
    return plugin
  end

  before_each(function()
    original_create_user_command = vim.api.nvim_create_user_command
    original_keymap_set = vim.keymap.set
    original_get_current_buf = vim.api.nvim_get_current_buf
    original_get_current_win = vim.api.nvim_get_current_win
    original_win_get_cursor = vim.api.nvim_win_get_cursor
    original_diagnostic_get = vim.diagnostic.get
    original_diagnostic_jump = vim.diagnostic.jump
    original_defer_fn = vim.defer_fn
    original_make_range_params = vim.lsp.util.make_range_params

    commands = {}
    keymaps = {}
    diagnostics = {}
    jumps = {}
    popup_calls = {}
    close_calls = 0
    code_action_requests = {}
    run_action_calls = {}

    vim.api.nvim_create_user_command = function(name, callback, opts)
      commands[name] = { callback = callback, opts = opts }
    end

    vim.keymap.set = function(mode, lhs, rhs, opts)
      table.insert(keymaps, { mode = mode, lhs = lhs, rhs = rhs, opts = opts })
    end

    vim.api.nvim_get_current_buf = function()
      return 7
    end

    vim.api.nvim_get_current_win = function()
      return 11
    end

    vim.api.nvim_win_get_cursor = function()
      return { 5, 0 }
    end

    vim.diagnostic.get = function(bufnr, opts)
      return diagnostics[bufnr .. ":" .. opts.lnum .. ":" .. tostring(opts.severity)] or {}
    end

    vim.diagnostic.jump = function(opts)
      table.insert(jumps, opts)
    end

    vim.defer_fn = function(callback)
      callback()
    end

    vim.lsp.util.make_range_params = function(win, offset_encoding)
      return { textDocument = { uri = "file:///test.lua" }, range = {}, win = win, offset_encoding = offset_encoding }
    end

    plugin = load_plugin()
  end)

  after_each(function()
    vim.api.nvim_create_user_command = original_create_user_command
    vim.keymap.set = original_keymap_set
    vim.api.nvim_get_current_buf = original_get_current_buf
    vim.api.nvim_get_current_win = original_get_current_win
    vim.api.nvim_win_get_cursor = original_win_get_cursor
    vim.diagnostic.get = original_diagnostic_get
    vim.diagnostic.jump = original_diagnostic_jump
    vim.defer_fn = original_defer_fn
    vim.lsp.util.make_range_params = original_make_range_params
    clear_modules()
  end)

  it("registers commands and default keymaps", function()
    plugin.setup()

    assert.is_truthy(commands.NuiDiagnosticNext)
    assert.is_truthy(commands.NuiDiagnosticPrev)
    assert.is_truthy(commands.NuiDiagnosticOpen)
    assert.is_truthy(commands.NuiDiagnosticClose)
    assert.are.same({ "]d", "[d", "]e", "[e" }, vim.tbl_map(function(map)
      return map.lhs
    end, keymaps))
  end)

  it("can disable built-in keymaps", function()
    plugin.setup({ keymaps = { enabled = false } })

    assert.are.same({}, keymaps)
    assert.is_truthy(commands.NuiDiagnosticNext)
  end)

  it("does not request code actions or open popups when there are no diagnostics", function()
    plugin.setup({ keymaps = { enabled = false } })

    plugin.open()

    assert.are.same({}, code_action_requests)
    assert.are.same({}, popup_calls)
  end)

  it("opens diagnostics without requesting actions when code actions are disabled", function()
    diagnostics["7:4:nil"] = {
      { message = "problem", severity = vim.diagnostic.severity.WARN },
    }
    plugin.setup({ keymaps = { enabled = false }, code_actions = { enabled = false } })

    plugin.open()

    assert.are.same({}, code_action_requests)
    assert.are.same(1, #popup_calls)
    assert.are.same(7, popup_calls[1].bufnr)
    assert.are.same({}, popup_calls[1].actions)
  end)

  it("requests actions and passes LSP diagnostics to params", function()
    local lsp_diagnostic = { message = "lsp diagnostic" }
    diagnostics["7:4:nil"] = {
      { message = "problem", user_data = { lsp = lsp_diagnostic } },
    }
    plugin.setup({ keymaps = { enabled = false } })

    plugin.open()

    assert.are.same(1, #code_action_requests)
    local params = code_action_requests[1].params({ offset_encoding = "utf-16" })
    assert.are.same(11, params.win)
    assert.are.same("utf-16", params.offset_encoding)
    assert.are.same(vim.lsp.protocol.CodeActionTriggerKind.Invoked, params.context.triggerKind)
    assert.are.same({ lsp_diagnostic }, params.context.diagnostics)
    assert.are.same(1, #popup_calls)

    popup_calls[1].on_action(popup_calls[1].actions[1])
    assert.are.same(1, #run_action_calls)
    assert.are.same("fix", run_action_calls[1].action_tuple.action.title)
  end)

  it("jumps to next diagnostics and opens after the jump", function()
    diagnostics["7:4:1"] = {
      { message = "error", severity = vim.diagnostic.severity.ERROR },
    }
    plugin.setup({ keymaps = { enabled = false } })

    plugin.next(2, "error")

    assert.are.same({ { count = 2, severity = vim.diagnostic.severity.ERROR } }, jumps)
    assert.are.same(1, #code_action_requests)
  end)

  it("jumps to previous diagnostics with a negative count", function()
    diagnostics["7:4:2"] = {
      { message = "warning", severity = vim.diagnostic.severity.WARN },
    }
    plugin.setup({ keymaps = { enabled = false } })

    plugin.prev(3, "warn")

    assert.are.same({ { count = -3, severity = vim.diagnostic.severity.WARN } }, jumps)
    assert.are.same(1, #code_action_requests)
  end)

  it("dispatches command severity arguments", function()
    diagnostics["7:4:1"] = {
      { message = "error", severity = vim.diagnostic.severity.ERROR },
    }
    plugin.setup({ keymaps = { enabled = false } })

    commands.NuiDiagnosticNext.callback({ args = "error" })
    commands.NuiDiagnosticClose.callback()

    assert.are.same({ { count = 1, severity = vim.diagnostic.severity.ERROR } }, jumps)
    assert.are.same(1, close_calls)
  end)
end)
