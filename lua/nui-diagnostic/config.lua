local M = {}

local defaults = {
  popup = {
    width = 50,
    max_width = 80,
    max_height = 12,
    border_style = "rounded",
    position = {
      row = 1,
      col = 0
    },
    win_options = {
      wrap = false,
      winblend = 0
    }
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
    }
  },
  code_actions = {
    enabled = true,
    max_items = 9,
    include_disabled = false,
    kinds = nil,
    sort = nil,
    keys = { "1", "2", "3", "4", "5", "6", "7", "8", "9"}
  },
  close = {
    key = "<Esc>",
    events = { "BufLeave", "CursorMoved", "InsertEnter" }
  },
  keymaps = {
    enabled = false,
    next = "]d",
    prev = "[d",
    next_error = "]e",
    prev_error = "[e"
  },
  notify = true
}

local severity_aliases = {
  error = vim.diagnostic.severity.ERROR,
  err = vim.diagnostic.severity.ERROR,
  warn = vim.diagnostic.severity.WARN,
  warning = vim.diagnostic.severity.WARN,
  info = vim.diagnostic.severity.INFO,
  hint = vim.diagnostic.severity.HINT,
}


local options = vim.deepcopy(defaults)

function M.setup(opts)
  options = vim.tbl_deep_extend("force",vim.deepcopy(defaults), opts or {})
  return options
end

function M.get()
  return options
end

function M.defaults()
  return vim.deepcopy(defaults)
end

function M.resolve_severity(severity)
  if severity == nil or type(severity) == 'number' then
    return severity
  end

  if type(severity) ~= "string" then
    return nil
  end

  return severity_aliases[severity:lower()]
end

function M.normalize_open_opts(opts_or_count, severity, default_count)
  local opts

  if type(opts_or_count) == 'table' then
    opts = vim.deepcopy(opts_or_count)
  else
    opts = {
      count = opts_or_count,
      severity = severity
    }
  end

  opts.count = opts.count or default_count or 1
  opts.severity = M.resolve_severity(severity)

  return opts
end

return M
