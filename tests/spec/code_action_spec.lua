---@diagnostic disable: undefined-global, undefined-field

local function action_titles(action_tuples)
  local titles = {}
  for _, tuple in ipairs(action_tuples) do
    table.insert(titles, tuple.action.title)
  end
  table.sort(titles)
  return titles
end

local function load_code_action()
  package.loaded["nui-diagnostic.code_action"] = nil
  return require("nui-diagnostic.code_action")
end

describe("nui-diagnostic.code_action", function()
  local code_action
  local original_buf_request_all
  local original_get_client_by_id
  local original_apply_workspace_edit
  local original_notify
  local request_results
  local requested
  local clients
  local notifications
  local applied_edits

  before_each(function()
    original_buf_request_all = vim.lsp.buf_request_all
    original_get_client_by_id = vim.lsp.get_client_by_id
    original_apply_workspace_edit = vim.lsp.util.apply_workspace_edit
    original_notify = vim.notify

    request_results = {}
    requested = nil
    clients = {}
    notifications = {}
    applied_edits = {}

    vim.lsp.buf_request_all = function(bufnr, method, params, callback)
      requested = { bufnr = bufnr, method = method, params = params }
      callback(request_results)
    end

    vim.lsp.get_client_by_id = function(client_id)
      return clients[client_id]
    end

    vim.lsp.util.apply_workspace_edit = function(edit, offset_encoding)
      table.insert(applied_edits, { edit = edit, offset_encoding = offset_encoding })
    end

    vim.notify = function(message, level)
      table.insert(notifications, { message = message, level = level })
    end

    code_action = load_code_action()
  end)

  after_each(function()
    vim.lsp.buf_request_all = original_buf_request_all
    vim.lsp.get_client_by_id = original_get_client_by_id
    vim.lsp.util.apply_workspace_edit = original_apply_workspace_edit
    vim.notify = original_notify
    package.loaded["nui-diagnostic.code_action"] = nil
  end)

  it("filters requested actions by type, disabled state, and kind", function()
    request_results = {
      [2] = {
        result = {
          { title = "fix", kind = "quickfix" },
          { title = "extract", kind = "quickfix.extract" },
          { title = "refactor", kind = "refactor" },
          { title = "disabled", kind = "quickfix", disabled = { reason = "not available" } },
          "not an action",
          { title = "missing kind" },
        },
      },
      [5] = {
        err = { message = "boom" },
        result = {
          { title = "other", kind = "quickfix" },
        },
      },
    }

    local received
    code_action.request(10, { context = {} }, { kinds = { "quickfix" } }, function(action_tuples)
      received = action_tuples
    end)

    assert.are.same(10, requested.bufnr)
    assert.are.same(vim.lsp.protocol.Methods.textDocument_codeAction, requested.method)
    assert.are.same({ "extract", "fix", "other" }, action_titles(received))
    assert.are.same(1, #notifications)
    assert.matches("boom", notifications[1].message, 1, true)
  end)

  it("can include disabled actions", function()
    request_results = {
      [1] = {
        result = {
          { title = "disabled", kind = "quickfix", disabled = { reason = "not available" } },
        },
      },
    }

    local received
    code_action.request(10, {}, { include_disabled = true }, function(action_tuples)
      received = action_tuples
    end)

    assert.are.same(1, #received)
    assert.are.same("disabled", received[1].action.title)
  end)

  it("sorts actions before applying max_items", function()
    request_results = {
      [1] = {
        result = {
          { title = "c" },
          { title = "a" },
          { title = "b" },
        },
      },
    }

    local received
    code_action.request(10, {}, {
      max_items = 2,
      sort = function(left, right)
        return left.action.title < right.action.title
      end,
    }, function(action_tuples)
      received = action_tuples
    end)

    assert.are.same({ "a", "b" }, vim.tbl_map(function(tuple)
      return tuple.action.title
    end, received))
  end)

  it("suppresses request notifications when requested", function()
    request_results = {
      [1] = { err = { message = "boom" } },
    }

    code_action.request(10, {}, { notify = false }, function() end)

    assert.are.same({}, notifications)
  end)

  it("notifies when the action client is unavailable", function()
    code_action.run_action({ client_id = 99, action = { title = "fix" } })

    assert.are.same(1, #notifications)
    assert.matches("no longer available", notifications[1].message, 1, true)
  end)

  it("does not run disabled actions", function()
    clients[1] = {
      offset_encoding = "utf-16",
      request = function()
        error("disabled action should not request commands")
      end,
    }

    code_action.run_action({
      client_id = 1,
      action = {
        title = "disabled",
        disabled = { reason = "not valid here" },
        edit = { changes = {} },
        command = "do.thing",
      },
    })

    assert.are.same({}, applied_edits)
    assert.are.same(1, #notifications)
    assert.matches("not valid here", notifications[1].message, 1, true)
  end)

  it("applies workspace edits and string commands", function()
    local command_request
    clients[1] = {
      offset_encoding = "utf-16",
      request = function(_, method, params, callback)
        command_request = { method = method, params = params }
        callback(nil)
      end,
    }

    local edit = { changes = { file = {} } }
    code_action.run_action({
      client_id = 1,
      action = {
        title = "fix",
        edit = edit,
        command = "do.thing",
      },
    })

    assert.are.same({ { edit = edit, offset_encoding = "utf-16" } }, applied_edits)
    assert.are.same(vim.lsp.protocol.Methods.workspace_executeCommand, command_request.method)
    assert.are.same({ command = "do.thing" }, command_request.params)
  end)

  it("runs table commands with arguments", function()
    local command_request
    clients[1] = {
      offset_encoding = "utf-8",
      request = function(_, method, params, callback)
        command_request = { method = method, params = params }
        callback(nil)
      end,
    }

    code_action.run_action({
      client_id = 1,
      action = {
        title = "fix",
        command = { command = "do.thing", arguments = { 1, 2 } },
      },
    })

    assert.are.same(vim.lsp.protocol.Methods.workspace_executeCommand, command_request.method)
    assert.are.same({ command = "do.thing", arguments = { 1, 2 } }, command_request.params)
  end)

  it("notifies command errors", function()
    clients[1] = {
      offset_encoding = "utf-8",
      request = function(_, _, _, callback)
        callback({ message = "failed" })
      end,
    }

    code_action.run_action({
      client_id = 1,
      action = { title = "fix", command = "do.thing" },
    })

    assert.are.same(1, #notifications)
    assert.matches("failed", notifications[1].message, 1, true)
  end)
end)
