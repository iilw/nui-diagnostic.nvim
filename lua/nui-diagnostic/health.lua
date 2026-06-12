local M = {}

local function has_module(name)
  local ok = pcall(require, name)
  return ok
end


function M.check()
  vim.health.start("nui-diagnostic.nvim")

  if vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Neovim >= 0.10")
  else
    vim.health.warn("Neovim >= 0.10 is recommended")
  end

  if has_module("nui.popup") then
    vim.health.ok("nui.nvim is available")
  else
    vim.health.warn("nui.nvim is required but was not found on runtimepath")
  end

  local clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
  if #clients > 0 then
    vim.health.ok(string.format("%d LSP client(s) attached to current buffer", #clients))
  else
    vim.health.warn("No LSP clients attached to current buffer")
  end

  if vim.diagnostic.is_enabled() then
    vim.health.ok("Diagnostics are enabled")
  else
    vim.health.warn("Diagnostics are disabled")
  end
end

return M
