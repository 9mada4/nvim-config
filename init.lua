vim.g.mapleader = " "

-- lazy.nvim bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  if vim.fn.executable("git") ~= 1 then
    vim.notify("lazy.nvim bootstrap requires 'git' on PATH", vim.log.levels.ERROR)
    return
  end
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup(require("plugins.pluginlist"))

require("config.options")
require("config.keymaps")
