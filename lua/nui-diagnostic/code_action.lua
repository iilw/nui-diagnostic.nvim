local methods = vim.lsp.protocol.Methods

--- @class NuiDiagnosticActionTuple
--- @field action lsp.CodeAction
--- @field client_id integer

local M = {}

local function notify(message, level, opts)
  if opts and opts.notify == false then return end
  vim.notify(message,level)
end

local function action_kind_matches(action, kinds)
  if not kinds or #kinds == 0 then return true end

  if not action.kind then return false end

  for _, kind in ipairs(kinds) do
    if action.kind == kind or vim.startswith(action.kind, kind .. ".") then
      return true
    end
  end

  return false
end

local function should_include_action(action, opts)
  if type(action) ~= "table" then
    return false
  end

  if action.disabled and not opts.include_disabled then
    return false
  end
  return action_kind_matches(action, opts.kinds)
end

--- @param action_tuple NuiDiagnosticActionTuple
--- @param opts? table
function M.run_action(action_tuple, opts)
  opts = opts or {}

  local client = vim.lsp.get_client_by_id(action_tuple.client_id)
  if not client then
    notify("nui-diagnostic: LSP client is no longer available", vim.log.levels.WARN, opts)
    return
  end

  local action = action_tuple.action

  if action.disabled then
    local reason = type(action.disabled) == "table" and action.disabled.reason or "disabled"
    notify("nui-diagnostic: code action is disabled: " .. reason, vim.log.levels.WARN, opts)
    return
  end

  if action.edit then
    vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
  end

  local command = action.command
  if not command then
    return
  end

  local params
  if type(command) == "string" then
    params = { command = command }
  else
    params = {
      command = command.command,
      arguments = command.arguments or {},
    }
  end

  if not params.command then
    return
  end

  client:request(methods.workspace_executeCommand, params, function(err)
    if err then
      notify("nui-diagnostic: LSP command error: " .. err.message, vim.log.levels.ERROR, opts)
    end
  end)
end


--- @param bufnr integer
--- @param params any
--- @param opts table
--- @param callback fun(action_tuples: NuiDiagnosticActionTuple[])
function M.request(bufnr, params, opts, callback)
  opts = opts or {}

  vim.lsp.buf_request_all(bufnr, methods.textDocument_codeAction, params, function (results)
    local action_tuples = {} --- @type NuiDiagnosticActionTuple[]

    for client_id, res in pairs(results or {}) do
      if res.err then
        notify("nui-diagnostic: code action request failed: " .. res.err.message, vim.log.levels.WARN, opts)
      end

      if type(res.result) == 'table' then
        for _, action in ipairs(res.result) do
          if should_include_action(action, opts) then
            table.insert(action_tuples, {
              action = action,
              client_id = client_id
            })
          end
        end
      end
    end

    if type(opts.sort) == "function" then
      table.sort(action_tuples, opts.sort)
    end

    if opts.max_items and #action_tuples > opts.max_items then
      local limited = {}
      for idx = 1, opts.max_items do
        limited[idx] = action_tuples[idx]
      end
      action_tuples = limited
    end

    callback(action_tuples)
  end)
end

return M
