---@diagnostic disable: undefined-global

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local uv = vim.uv or vim.loop

local function exists(path)
  return path and path ~= "" and uv.fs_stat(path) ~= nil
end

vim.opt.runtimepath:prepend(root)

local plenary_path = vim.env.PLENARY_PATH
if not exists(plenary_path) then
  local sibling = vim.fn.fnamemodify(root .. "/../plenary.nvim", ":p")
  if exists(sibling) then
    plenary_path = sibling
  end
end

if exists(plenary_path) then
  vim.opt.runtimepath:prepend(plenary_path)
end
