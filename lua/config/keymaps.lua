-- Insertモードで jj → Normalへ戻る
vim.keymap.set("i", "jj", "<Esc>", { noremap = true, silent = true })

-- Visual modeで，K/J により選択中の行を上下に移動して再選択する
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")

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
