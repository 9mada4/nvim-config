-- 行番号
vim.opt.number = true

-- タブとインデント
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- 検索設定
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true

-- クリップボード連携（利用可能な環境のみ）
if vim.fn.has("clipboard") == 1 then
  vim.opt.clipboard = "unnamedplus"
end

-- 24bitカラー
vim.opt.termguicolors = true

-- git commit message では swap ファイルを作らない
vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  callback = function()
    vim.opt_local.swapfile = false
  end,
})
