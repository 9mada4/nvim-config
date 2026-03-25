local os_config = require("config.os")

if not os_config.is_windows then
  return
end

local debug = true

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

local function notify_debug(msg, level)
  if not debug then
    return
  end
  vim.notify(msg, level or vim.log.levels.INFO, { title = "IME" })
end

local function join_lines(lines)
  if not lines then
    return ""
  end

  local out = {}
  for _, line in ipairs(lines) do
    if line and line ~= "" then
      table.insert(out, line)
    end
  end
  return table.concat(out, "\n")
end

vim.api.nvim_create_autocmd("InsertLeave", {
  group = group,
  desc = "Send NonConvert key to turn IME off on Windows",
  callback = function()
    notify_debug("InsertLeave fired")

    if vim.system then
      vim.system(cmd, { text = true }, function(obj)
        local stdout = vim.trim(obj.stdout or "")
        local stderr = vim.trim(obj.stderr or "")
        local code = obj.code or -1
        local parts = { ("PowerShell exit code: %d"):format(code) }

        if stdout ~= "" then
          table.insert(parts, "stdout: " .. stdout)
        end
        if stderr ~= "" then
          table.insert(parts, "stderr: " .. stderr)
        end

        vim.schedule(function()
          local level = code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
          notify_debug(table.concat(parts, "\n"), level)
        end)
      end)
      return
    end

    local stdout_lines = {}
    local stderr_lines = {}

    local job_id = vim.fn.jobstart(cmd, {
      stdout_buffered = true,
      stderr_buffered = true,
      on_stdout = function(_, data)
        stdout_lines = data or {}
      end,
      on_stderr = function(_, data)
        stderr_lines = data or {}
      end,
      on_exit = function(_, code)
        local stdout = vim.trim(join_lines(stdout_lines))
        local stderr = vim.trim(join_lines(stderr_lines))
        local parts = { ("PowerShell exit code: %d"):format(code or -1) }

        if stdout ~= "" then
          table.insert(parts, "stdout: " .. stdout)
        end
        if stderr ~= "" then
          table.insert(parts, "stderr: " .. stderr)
        end

        vim.schedule(function()
          local level = code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
          notify_debug(table.concat(parts, "\n"), level)
        end)
      end,
    })

    if job_id <= 0 then
      notify_debug("Failed to start PowerShell job", vim.log.levels.ERROR)
    end
  end,
})
