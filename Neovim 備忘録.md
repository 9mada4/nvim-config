# Neovim 備忘録
- このファイルの場所
```bash
cd ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/Obsidian_iCloud
```

## 1. NeoVimのインストール
```bash
brew install neovim
```

## 2. 操作に慣れる
https://youtu.be/80zZQLe0NNg?si=i35CENhmjsgItoPy

## 3. 設定ファイルの作成
- 設定ファイルの存在確認（恐らくない）
```bash
ls ~/.config/nvim
```
- 設定ディレクトリを作成
```bash
mkdir -p ~/.config/nvim
```
- 設定ファイルを作る
```bash
touch ~/.config/nvim/init.lua
```

## 4. 基本設定(lazy.nvim含む)の適用
###### (1) neovimで開く
```bash
nvim ~/.config/nvim/init.lua
```
###### (2) 以下をペースト(Lua)
```Lua
-- =========================
-- 0. Leader key
-- =========================

vim.g.mapleader = " "

-- =========================
-- 1. lazy.nvim bootstrap
-- =========================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

    {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("nvim-tree").setup({
                view = { width = 30 },
                filters = { dotfiles = false },
            })
            vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>")
        end,
    },

})

-- =========================
-- 2. options.lua
-- =========================

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

-- Macとクリップボード共有
vim.opt.clipboard = "unnamedplus"

-- 24bitカラー
vim.opt.termguicolors = true

-- =========================
-- 3. keymaps.lua
-- =========================

-- Insertモードで jj で Normalへ戻る
vim.keymap.set("i", "jj", "<Esc>", { noremap = true, silent = true })
```
###### (3) 保存して再起動
- 保存
```vim
:w
```
- 再読み込み
```vim
:source %
```
###### (4) 動作確認
1. Neovimを起動
2. lazy.nvimの起動確認
```vim
:Lazy
```
3. UIが開けばOK．`:q`で閉じる．
![[Pasted image 20260302160151.png]]
4. nvim-tree確認
	Space + e でツリー開くか
5. 次のように表示されればよい．(アイコンは文字化けしているはず)
	![[Pasted image 20260303185339.png]]

## 5. フォント設定

- Nerd Fontをいれる (参考: https://formulae.brew.sh/cask/font-fira-code-nerd-font )
```bash
brew install --cask font-fira-code-nerd-font
```

- Terminal.app で，`設定 > プロファイル > フォント` から変更

|                 設定画面                 |               フォント選択画面               |
| :----------------------------------: | :----------------------------------: |
| ![[Pasted image 20260303200304.png]] | ![[Pasted image 20260303200431.png]] |
## 6. 設定ファイル分割

- 目的: `4.2.` の設定ファイルを次のように分割する．
```code
~/.config/nvim
├── init.lua
└── lua
    ├── config
    │   ├── options.lua
    │   └── keymaps.lua
    └── plugins
        ├── pluginlist.lua
        ├── ui
        │   ├── nvim-tree.lua
        │   └── lualine.lua
        ├── editor
        │   ├── telescope.lua
        │   └── gitsigns.lua
        └── coding
            ├── lsp.lua
            ├── cmp.lua
            └── treesitter.lua
```

###### (0) Neovim 設定ディレクトリへ移動
```bash
cd ~/.config/nvim
```
- 確認（`/Users/*****/.config/nvim` となればOK）
```bash
pwd
```

###### (1) ディレクトリ一括作成（`ls -R`で確認）
```bash
mkdir -p lua/config \
         lua/plugins/ui \
         lua/plugins/editor \
         lua/plugins/coding
ls -R
```
###### (2) 以下を実行して 各`.lua` を作成（ -> Neovim起動）
|     ui      |    ui     |   editor    | editor     | coding       |
| :---------: | :-------: | :---------: | ---------- | ------------ |
| ① nvim-tree | ② lualine | ③ telescope | ④ gitsigns | ⑤ treesitter |

```bash
cat > ~/.config/nvim/init.lua << 'EOF'
vim.g.mapleader = " "

-- lazy.nvim bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
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
EOF





cat > lua/config/options.lua << 'EOF'
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

-- Macとクリップボード共有
vim.opt.clipboard = "unnamedplus"

-- 24bitカラー
vim.opt.termguicolors = true
EOF

cat > lua/config/keymaps.lua << 'EOF'
-- Insertモードで jj → Normalへ戻る
vim.keymap.set("i", "jj", "<Esc>", { noremap = true, silent = true })

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
EOF

cat > lua/plugins/pluginlist.lua << 'EOF'
return {
  require("plugins.ui.nvim-tree"),
  require("plugins.ui.lualine"),
  require("plugins.editor.telescope"),
  require("plugins.editor.gitsigns"),
  require("plugins.coding.treesitter"),
}
EOF





cat > lua/plugins/ui/nvim-tree.lua << 'EOF'
return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("nvim-tree").setup({})
    vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>")
  end,
}
EOF

cat > lua/plugins/ui/lualine.lua << 'EOF'
return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("lualine").setup({})
  end,
}
EOF

cat > lua/plugins/editor/telescope.lua << 'EOF'
return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim"
  },
  config = function()
    require("telescope").setup({})
  end,
}
EOF

cat > lua/plugins/editor/gitsigns.lua << 'EOF'
return {
  "lewis6991/gitsigns.nvim",
  config = function()
    require("gitsigns").setup()
  end,
}
EOF

cat > lua/plugins/coding/treesitter.lua << 'EOF'
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  opts = {
    ensure_installed = { "lua", "bash", "json", "markdown" },
    highlight = {
      enable = true,
    },
    indent = {
      enable = true,
    },
  },
}
EOF

nvim
```

###### (3) Sync含めて完全同期
`:Lazy` -> `Shift + s`
- update, install, clean, build を全部やる
## 7. Treesitterの言語追加
- 設定が難しいらしい https://qiita.com/getty104/items/7a920a874d18ac6763e2
- `lua/plugins/coding/treesitter.lua` に直接追加
- md のシンタクスハイライトが死んでるらしい(ブチ切れ)
	https://leaysgur.github.io/posts/2024/04/16/092858/
## 8. GitHub管理
###### (1) ローカル初期化
```bash
cd ~/.config/nvim
git init
git add .
git commit -m "Initial commit"
```

###### (2) GitHubでprivate repo作成（例: nvim-config）
https://github.com 

###### (3) remote登録
- 要変更: YOURNAME
```bash
git remote add origin git@github.com:YOURNAME/nvim-config.git
git remote -v
```
- 出力例:
```Code
origin  git@github.com:yourname/nvim-config.git (fetch)
origin  git@github.com:yourname/nvim-config.git (push)
```
###### (4) push
```bash
git branch -M main
git push -u origin main
```
