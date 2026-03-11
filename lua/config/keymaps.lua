-- Insertモードで jj → Normalへ戻る
vim.keymap.set("i", "jj", "<Esc>", { noremap = true, silent = true })

-- Visual modeで，K/J により選択中の行を上下に移動して再選択する
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")

-- 最後に検索した語を使って，確認しながら置換する
-- 例: /status で検索したあと <leader>sr
vim.keymap.set("n", "<leader>sr", [[:%s//gc<Left><Left><Left>]], {
  noremap = true,
  desc = "Replace last search with confirm",
})

-- Markdownプレビューをブラウザで表示
vim.keymap.set("n", "<leader>mg", function()
  if vim.fn.executable("glow") ~= 1 then
    vim.notify("'glow' is not installed or not on PATH", vim.log.levels.WARN)
    return
  end
  vim.cmd("Glow")
end, { desc = "Markdown preview" })

-- Git diff をポップアップ表示
vim.keymap.set("n", "<leader>gd", function()
  local file = vim.fn.expand("%")
  if file == "" then
    vim.notify("No file is open", vim.log.levels.WARN)
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)

  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  vim.fn.termopen({ "git", "diff", "--", file })

  vim.bo[buf].bufhidden = "wipe"
  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<C-[>", "<cmd>close<CR>", { buffer = buf, silent = true })
end, { desc = "Git diff popup" })

-- =========================
-- Telescope
-- =========================

-- Space ff : ファイル検索
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<CR>")

-- Space fg : プロジェクト全文検索
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<CR>")

-- Space fb : 開いているバッファ一覧
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<CR>")

-- Space fh : Vimヘルプ検索
vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<CR>")

-- =========================
-- LazyGit
-- =========================

-- Space gg : lazygit UI を開く
vim.keymap.set("n", "<leader>gg", function()
  if vim.fn.executable("lazygit") ~= 1 then
    vim.notify("'lazygit' is not installed or not on PATH", vim.log.levels.WARN)
    return
  end
  vim.cmd("LazyGit")
end, { desc = "Open LazyGit" })
