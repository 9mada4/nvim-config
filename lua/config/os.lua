local M = {}

local uname = vim.loop.os_uname()
local sysname = (uname and uname.sysname or ""):lower()

M.is_windows = sysname:find("windows") ~= nil
M.is_macos = sysname == "darwin"
M.is_linux = sysname == "linux"

function M.is_unix()
  return M.is_macos or M.is_linux
end

function M.name()
  if M.is_windows then
    return "windows"
  end
  if M.is_macos then
    return "macos"
  end
  if M.is_linux then
    return "linux"
  end
  return "unknown"
end

return M
