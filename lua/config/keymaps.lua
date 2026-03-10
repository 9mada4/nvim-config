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
vim.keymap.set("n", "<leader>mg", "<cmd>Glow<CR>", { desc = "Markdown preview" })

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
vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit<CR>", { desc = "Open LazyGit" })
