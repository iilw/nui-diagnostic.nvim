local config = require("nui-diagnostic.config")
local code_action = require('nui-diagnostic.code_action')
local popup = require('nui-diagnostic.popup')

local M = {}

local function line_diagnostics(bufnr, lnum, severity)
  local query = { lnum = lnum }
  if severity then
    query.severity = severity
  end

  return vim.diagnostic.get(bufnr, query)
end

--- @param diagnostics vim.Diagnostic[]
local function lsp_diagnostics(diagnostics)
 return vim.tbl_map(function (item)
  return item.user_data and item.user_data.lsp or item
 end, diagnostics)
end

local function make_code_action_params(bufnr, win, lnum, severity)
  return function (client)
    local params = vim.lsp.util.make_range_params(win, client.offset_encoding)
    params.context = {
      triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked,
      diagnostics = lsp_diagnostics(line_diagnostics(bufnr, lnum, severity))
    }
    return params
  end
end

local function setup_keymaps(opts)
  if not opts.keymaps.enabled then return end

  vim.keymap.set("n", opts.keymaps.next, function ()
    M.next()
  end, { desc = "Next diagnostic with code actions"})

  vim.keymap.set("n", opts.keymaps.prev, function ()
    M.prev()
  end, { desc = "Prev diagnostic with code actions"})

  vim.keymap.set("n", opts.keymaps.next_error, function ()
    M.next({ severity = "ERROR" })
  end, { desc = "Next error diagnostic with code actions"})

  vim.keymap.set("n", opts.keymaps.prev, function ()
    M.prev( { severity = "ERROR" })
  end, { desc = "Prev error diagnostic with code actions"})

end

function M.setup(opts)
  local resolved = config.setup(opts)
  setup_keymaps(resolved)
  return resolved
end

function M.close()
  popup.close()
end

function M.is_open()
  return popup.is_open()
end

function M.open(opts_or_count, severity)
  local opts = config.normalize_open_opts(opts_or_count, severity, 0)
  local plugin_opts = config.get()
  local bufnr = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local lnum = vim.api.nvim_win_get_cursor(win)[1] - 1
  local diagnostics = line_diagnostics(bufnr, lnum, opts.severity)

  if not plugin_opts.code_actions.enabled then
    popup.open({
      bufnr = bufnr,
      diagnostics = diagnostics,
      actions = {},
      on_action = function() end,
    })
  end

  local params = make_code_action_params(bufnr, win, lnum, opts.severity)
  local code_action_opts = vim.tbl_extend("force", plugin_opts.code_actions, { notify = plugin_opts.notify })

  code_action.request(bufnr, params, code_action_opts, function (action_tuples)
    popup.open({
      bufnr = bufnr,
      diagnostics = diagnostics,
      actions = action_tuples,
      on_action = function (action_tuple)
        code_action.run_action(action_tuple, code_action_opts)
      end
    })
  end)
end

function M.next(opts_or_count, severity)
  local opts = config.normalize_open_opts(opts_or_count, severity, 1)
  opts.count = opts.count or 1

  local jump_opts = { count = opts.count }
  if opts.severity then
    jump_opts.severity = opts.severity
  end

  vim.diagnostic.jump(jump_opts)
  vim.defer_fn(function ()
    M.open({ severity = opts.severity })
  end,50)
end

function M.prev(opts_or_count, severity)
  local opts = config.normalize_open_opts(opts_or_count, severity, -1)
  opts.count = -math.abs(opts.count or 1)

  local jump_opts = { count = opts.count }
  if opts.severity then
    jump_opts.severity = opts.severity
  end

  vim.diagnostic.jump(jump_opts)
  vim.defer_fn(function ()
    M.open({ severity = opts.severity })
  end, 50)
end

return M
