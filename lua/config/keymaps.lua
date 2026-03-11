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

local image_extensions = {
  png = true,
  jpg = true,
  jpeg = true,
  gif = true,
  webp = true,
  bmp = true,
  tif = true,
  tiff = true,
  svg = true,
  heic = true,
}

local function is_image_file(path)
  local ext = vim.fn.fnamemodify(path, ":e"):lower()
  return image_extensions[ext] == true
end

local function encode_uri_path(path)
  local encoded = path:gsub("%%", "%%25")
  encoded = encoded:gsub(" ", "%%20")
  encoded = encoded:gsub("#", "%%23")
  encoded = encoded:gsub("%?", "%%3F")
  return encoded
end

local function resolve_image_path()
  local current = vim.fn.expand("%:p")
  if current ~= "" and vim.fn.filereadable(current) == 1 and is_image_file(current) then
    return current
  end

  local under_cursor = vim.fn.expand("<cfile>")
  if under_cursor == "" then
    return nil
  end

  local base = vim.fn.expand("%:p:h")
  local absolute = vim.fn.fnamemodify(base .. "/" .. under_cursor, ":p")
  if vim.fn.filereadable(absolute) == 1 and is_image_file(absolute) then
    return absolute
  end

  return nil
end

-- 画像ファイルを既定のアプリで表示
vim.keymap.set("n", "<leader>mi", function()
  local path = resolve_image_path()
  if not path then
    vim.notify("Image file not found (current file or <cfile>)", vim.log.levels.WARN)
    return
  end
  vim.ui.open(path)
end, { desc = "Image: open file" })

-- 画像ファイルをブラウザでプレビュー
vim.keymap.set("n", "<leader>mb", function()
  local path = resolve_image_path()
  if not path then
    vim.notify("Image file not found (current file or <cfile>)", vim.log.levels.WARN)
    return
  end

  local html = ([[<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Image Preview</title>
  <style>
    html, body { margin: 0; background: #111; }
    body { min-height: 100vh; display: grid; place-items: center; }
    img { max-width: 100vw; max-height: 100vh; object-fit: contain; }
  </style>
</head>
<body>
  <img src="file://%s" alt="preview">
</body>
</html>
]]):format(encode_uri_path(path))

  local preview_file = vim.fn.tempname() .. ".html"
  vim.fn.writefile(vim.split(html, "\n"), preview_file)
  vim.ui.open(preview_file)
end, { desc = "Image: browser preview" })

-- Git diff をポップアップ表示 Spc gd
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

-- ショートカットをポップアップ Spc + ?
vim.keymap.set("n", "<leader>?", function()
  local sep = package.config:sub(1, 1)
  local path = vim.fn.stdpath("config") .. sep .. "shortcuts.md"

  if vim.fn.filereadable(path) ~= 1 then
    vim.notify("memo file not found: " .. path, vim.log.levels.WARN, {
      title = "Memo",
    })
    return
  end

  local lines = vim.fn.readfile(path)
  local content = table.concat(lines, "\n")

  vim.notify(content, vim.log.levels.INFO, {
    title = "Shortcut Memo",
    timeout = 10000,
  })
end, { desc = "Show memo popup" })

-- Terminal.appでショートカットが使えるようにする
-- vim.keymap.set("t", "<C-[>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })
-- vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], { desc = "Terminal move left" })
-- vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]], { desc = "Terminal move down" })
-- vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]], { desc = "Terminal move up" })
-- vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]], { desc = "Terminal move right" })
--
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
