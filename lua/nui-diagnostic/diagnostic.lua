local config = require("nui-diagnostic.config")

local M = {}


--- @param text string
--- @return string
function M.one_line(text)
    local line = (text or ""):gsub("\r\n", " "):gsub("\n", " ")
    return line
end

--- @param diagnostic vim.Diagnostic
--- @param opts? table
function M.format(diagnostic, opts)
  opts = opts or config.get().diagnostics

  if type(opts.format) == "function" then
    return opts.format(diagnostic)
  end

  local severity_names = opts.severity_names or {}
  local severity = severity_names[diagnostic.severity] or "DIAGNOSTIC"
  local message = M.one_line(diagnostic.message)
  local suffix = ""

  if diagnostic.code then
    suffix = suffix .. string.format("#%s", diagnostic.code)
  end

  if diagnostic.source and diagnostic.source ~= "" then
    suffix = suffix .. string.format(" [%s]",diagnostic.source)
  end

  return string.format(" %s: %s%s", severity, message, suffix)
end

--- @param diagnostics vim.Diagnostic[]
--- @param opts? table
function M.lines(diagnostics, opts)
  opts = opts or config.get().diagnostics
  local lines = {} --- @type string[]
  local max_items = opts.max_items or #diagnostics

  for idx, diagnostic in ipairs(diagnostics) do
    if idx > max_items then
      break
    end

    local line = M.format(diagnostic, opts)
    if #diagnostics > 1 then
      line = string.format(" [%d]%s", idx, line)
    end
    table.insert(lines,line)
  end

  return lines
end

return M
