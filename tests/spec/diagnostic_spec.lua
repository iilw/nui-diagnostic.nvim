---@diagnostic disable: undefined-global, undefined-field

local function load_modules()
  package.loaded["nui-diagnostic.config"] = nil
  package.loaded["nui-diagnostic.diagnostic"] = nil

  local config = require("nui-diagnostic.config")
  config.setup()

  return require("nui-diagnostic.diagnostic")
end

describe("nui-diagnostic.diagnostic", function()
  local diagnostic

  before_each(function()
    diagnostic = load_modules()
  end)

  it("converts diagnostic text to one line", function()
    assert.are.same("a b c", diagnostic.one_line("a\nb\r\nc"))
    assert.are.same("", diagnostic.one_line(nil))
  end)

  it("formats diagnostics with default metadata", function()
    local line = diagnostic.format({
      severity = vim.diagnostic.severity.ERROR,
      message = "unused variable",
      code = "W123",
      source = "lua_ls",
    })

    assert.are.same(" ERROR: unused variable#W123 [lua_ls]", line)
  end)

  it("omits empty source", function()
    local line = diagnostic.format({
      severity = vim.diagnostic.severity.WARN,
      message = "warning",
      source = "",
    })

    assert.are.same(" WARN: warning", line)
  end)

  it("uses a fallback label for unknown severity", function()
    local line = diagnostic.format({
      severity = 999,
      message = "message",
    })

    assert.are.same(" DIAGNOSTIC: message", line)
  end)

  it("supports custom formatting", function()
    local line = diagnostic.format({ message = "hello" }, {
      format = function(item)
        return "custom: " .. item.message
      end,
    })

    assert.are.same("custom: hello", line)
  end)

  it("renders a single diagnostic without an index", function()
    local lines = diagnostic.lines({
      { severity = vim.diagnostic.severity.INFO, message = "info" },
    })

    assert.are.same({ " INFO: info" }, lines)
  end)

  it("renders multiple diagnostics with indexes", function()
    local lines = diagnostic.lines({
      { severity = vim.diagnostic.severity.ERROR, message = "first" },
      { severity = vim.diagnostic.severity.HINT, message = "second" },
    })

    assert.are.same({
      " [1] ERROR: first",
      " [2] HINT: second",
    }, lines)
  end)

  it("limits rendered diagnostics", function()
    local lines = diagnostic.lines({
      { severity = vim.diagnostic.severity.ERROR, message = "first" },
      { severity = vim.diagnostic.severity.WARN, message = "second" },
    }, { max_items = 1 })

    assert.are.same({ " [1] DIAGNOSTIC: first" }, lines)
  end)
end)
