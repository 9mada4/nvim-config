local os_config = require("config.os")

if not os_config.is_windows then
  return
end

local uv = vim.uv or vim.loop
if not uv or not uv.fs_stat then
  return
end

local joinpath = vim.fs and vim.fs.joinpath or function(...)
  return table.concat({ ... }, package.config:sub(1, 1))
end

local script = joinpath(vim.fn.stdpath("config"), "tools", "windows", "send-nonconvert.ps1")
if not uv.fs_stat(script) then
  return
end

local shell = nil
if vim.fn.executable("powershell") == 1 then
  shell = "powershell"
elseif vim.fn.executable("pwsh") == 1 then
  shell = "pwsh"
else
  return
end

local cmd = {
  shell,
  "-NoProfile",
  "-NonInteractive",
  "-ExecutionPolicy",
  "Bypass",
  "-File",
  script,
}

local group = vim.api.nvim_create_augroup("windows-ime-off", { clear = true })

vim.api.nvim_create_autocmd("InsertLeave", {
  group = group,
  desc = "Send NonConvert key to turn IME off on Windows",
  callback = function()
    if vim.system then
      vim.system(cmd, { text = true }, function() end)
      return
    end

    vim.fn.jobstart(cmd)
  end,
})
