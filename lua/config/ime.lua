local os_config = require("config.os")

if not os_config.is_windows then
  return
end

local uv = vim.uv or vim.loop
local joinpath = vim.fs and vim.fs.joinpath or function(...)
  return table.concat({ ... }, package.config:sub(1, 1))
end

local imectl = joinpath(vim.fn.stdpath("config"), "tools", "win-x64", "imectl.exe")

if not uv or not uv.fs_stat or not uv.fs_stat(imectl) then
  return
end

local group = vim.api.nvim_create_augroup("windows-ime-off", { clear = true })

local function ime_off()
  if vim.system then
    vim.system({ imectl, "off" }, { text = true }, function(result)
      if result.code ~= 0 and result.stderr and result.stderr ~= "" then
        vim.schedule(function()
          vim.notify(vim.trim(result.stderr), vim.log.levels.DEBUG, {
            title = "IME",
          })
        end)
      end
    end)
    return
  end

  local output = vim.fn.system({ imectl, "off" })
  if vim.v.shell_error ~= 0 and output ~= "" then
    vim.schedule(function()
      vim.notify(vim.trim(output), vim.log.levels.DEBUG, {
        title = "IME",
      })
    end)
  end
end

vim.api.nvim_create_autocmd("InsertLeave", {
  group = group,
  callback = ime_off,
  desc = "Turn Windows IME off on InsertLeave",
})
