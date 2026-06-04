local config = require("nui-diagnostic.config")
local diagnostic = require("nui-diagnostic.diagnostic")
local Popup = require("nui.popup")

local M = {}

local state = {
  autocmd_ids = {},
  keymaps = {},
  popups = {},
  bufnr = nil
}

local function popup_width(lines, opts)
  local width = opts.popup.width

  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end

  local screen_max_width = math.max(20, vim.o.columns - 4)
  return math.min(width, opts.popup.max_width, screen_max_width)
end

local function make_popup(lines, width, row, title, opts)
  local height = math.min(#lines, opts.popup.max_height)

  local popup = Popup({
    relative = "cursor",
    position = {
      col = opts.popup.position.col,
      row = row
    },
    size = {
      width = width,
      height = height
    },
    border = {
      style = opts.popup.border_style,
      text = {
        top = title,
        top_align = "left"
      }
    },
    win_options = opts.popup.win_options
  })

  popup:mount()
  vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, lines)

  return popup
end

---@param actions NuiDiagnosticActionTuple[]
local function action_lines(actions)
  local lines = {}

  for idx, action_tuple in ipairs(actions) do
    table.insert(lines, string.format(" [%d] %s", idx, action_tuple.action.title or "Untitled action"))
  end

  if #lines == 0 then
    table.insert(lines, "No code actions")
  end

  return lines
end

local function clear_autocmds()
  for _, autocmd_id in ipairs(state.autocmd_ids) do
    pcall(vim.api.nvim_del_autocmd, autocmd_id)
  end
  state.autocmd_ids = {}
end

local function clear_keymaps()
  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    state.keymaps = {}
    return
  end

  for _, key in ipairs(state.keymaps) do
    pcall(vim.keymap.del, "n", key, { buffer = state.bufnr })
  end

  state.keymaps = {}
end

function M.close()
  clear_autocmds()
  clear_keymaps()

  for _, popup in ipairs(state.popups) do
    pcall(function ()
      popup:unmount()
    end)
  end

  state.popups = {}
  state.bufnr = nil
end

function M.is_open()
  for _, popup in ipairs(state.popups) do
    if popup.winid and vim.api.nvim_win_is_valid(popup.winid) then
      return true
    end
  end

  return false
end

--- @param opts {
  --- diagnostics: vim.Diagnostic[],
  --- actions: NuiDiagnosticActionTuple[],
  --- on_action: fun(action:NuiDiagnosticActionTuple),
  --- bufnr?: integer,
  --- }
function M.open(opts)
  M.close()

  local plugin_opts = config.get()
  local diagnostics = opts.diagnostics or {}
  local actions = opts.actions or {}
  local diag_lines = {}

  if plugin_opts.diagnostics.enabled then
    diag_lines = diagnostic.lines(diagnostics, plugin_opts.diagnostics)
  end

  local code_action_lines = {}
  if plugin_opts.code_actions.enabled then
    code_action_lines = action_lines(actions)
  end

  if #diag_lines == 0 and #code_action_lines == 0 then return end

  local all_lines = vim.list_extend(vim.deepcopy(diag_lines), code_action_lines)
  local width = popup_width(all_lines, plugin_opts)

  if #diag_lines > 0 then
    local popup = make_popup(diag_lines, width, plugin_opts.popup.position.row, "Diagnostic ", plugin_opts)
    table.insert(state.popups, popup)
  end

  if #code_action_lines > 0 then
    local row = #diag_lines > 0 and plugin_opts.popup.position.row + #diag_lines + 2 or plugin_opts.popup.position.row
    local popup = make_popup(code_action_lines, width, row, "Code actions", plugin_opts)
    table.insert(state.popups, popup)
  end

  local keys = plugin_opts.code_actions.keys or {}
  for idx, action_tuple in ipairs(actions) do
    local key = keys[idx]
    if not key then
      break
    end

    vim.keymap.set("n", key, function ()
      M.close()
      opts.on_action(action_tuple)
    end, { buffer = state.bufnr, nowait = true, silent = true })
    table.insert(state.keymaps, key)
  end

  if plugin_opts.close.key then
    vim.keymap.set("n", plugin_opts.close.key, M.close, { buffer = state.bufnr, nowait = true, silent = true })
    table.insert(state.keymaps, plugin_opts.close.key)
  end

  vim.defer_fn(function ()
    if not M.is_open() then
      return
    end

    for _, event in ipairs(plugin_opts.close.events or {}) do
      local autocmd_id = vim.api.nvim_create_autocmd(event, {
        buffer = state.bufnr,
        callback = M.close,
      })
      table.insert(state.autocmd_ids, autocmd_id)
    end
  end,50)
end

return M
