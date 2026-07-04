---@diagnostic disable: undefined-global, undefined-field

local function load_config()
  package.loaded["nui-diagnostic.config"] = nil
  return require("nui-diagnostic.config")
end

describe("nui-diagnostic.config", function()
  local config

  before_each(function()
    config = load_config()
  end)

  it("returns defaults as a deep copy", function()
    local defaults = config.defaults()
    defaults.popup.width = 123

    assert.are.same(50, config.defaults().popup.width)
  end)

  it("deep merges user options", function()
    local opts = config.setup({
      popup = { width = 60 },
      code_actions = { enabled = false },
    })

    assert.are.same(60, opts.popup.width)
    assert.are.same(80, opts.popup.max_width)
    assert.is_false(opts.code_actions.enabled)
    assert.are.same(9, opts.code_actions.max_items)
  end)

  it("resolves severity aliases", function()
    assert.is_nil(config.resolve_severity(nil))
    assert.are.same(vim.diagnostic.severity.ERROR, config.resolve_severity(vim.diagnostic.severity.ERROR))
    assert.are.same(vim.diagnostic.severity.ERROR, config.resolve_severity("error"))
    assert.are.same(vim.diagnostic.severity.ERROR, config.resolve_severity("ERROR"))
    assert.are.same(vim.diagnostic.severity.ERROR, config.resolve_severity("err"))
    assert.are.same(vim.diagnostic.severity.WARN, config.resolve_severity("warn"))
    assert.are.same(vim.diagnostic.severity.WARN, config.resolve_severity("warning"))
    assert.are.same(vim.diagnostic.severity.INFO, config.resolve_severity("INFO"))
    assert.are.same(vim.diagnostic.severity.HINT, config.resolve_severity("hint"))
    assert.is_nil(config.resolve_severity("unknown"))
    assert.is_nil(config.resolve_severity({}))
  end)

  it("normalizes positional open options", function()
    local opts = config.normalize_open_opts(2, "error", 1)

    assert.are.same(2, opts.count)
    assert.are.same(vim.diagnostic.severity.ERROR, opts.severity)
  end)

  it("preserves severity from table options", function()
    local opts = config.normalize_open_opts({ count = 3, severity = "warn" }, nil, 1)

    assert.are.same(3, opts.count)
    assert.are.same(vim.diagnostic.severity.WARN, opts.severity)
  end)

  it("lets positional severity override table severity", function()
    local opts = config.normalize_open_opts({ count = 3, severity = "warn" }, "error", 1)

    assert.are.same(3, opts.count)
    assert.are.same(vim.diagnostic.severity.ERROR, opts.severity)
  end)

  it("uses the provided default count", function()
    local next_opts = config.normalize_open_opts(nil, nil, 1)
    local open_opts = config.normalize_open_opts(nil, nil, 0)

    assert.are.same(1, next_opts.count)
    assert.are.same(0, open_opts.count)
  end)
end)
