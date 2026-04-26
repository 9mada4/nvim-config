# Neovim setup
## 目次
- [todo](#todo)
- [1. Install Neovim (include `Font`, `lazygit`)](#install-neovim)
- [2. Set Font](#set-font)
- [3. Clone config](#clone-config)
- [4. Open Neovim](#open-neovim)
- [5. IME setting (optional)](#ime-setting)
- [6. Custom LazyGit (optional: LazyGit users)](#custom-lazygit)
- [7. First setup checklist](#first-setup-checklist)
- [How to update](#how-to-update)
- [If you require SSH](#if-you-require-ssh)
- [Folder structure](#folder-structure)

## todo
- [x] Windowsセットアップ手順追記
- [x] IME自動切り替え実装
  - [x] luaから.ps1ファイルを呼び出せるようにしたらいけそう。
  - [x] 通知をオフ
  - [ ] ｊｊが入力されたらback２回にescを送信したら、.ps1も呼び出されていけそう。
- [ ] macOSもターミナル上でキー送信で対応か？
- [x] Lazy.gitの動作確認
  - [x] swapファイルが残る
  - [x] Windowsのセットアップ手順を簡略化

https://youtu.be/80zZQLe0NNg?si=i35CENhmjsgItoPy <br>
zz, zb, zt

<h2 id="install-neovim"></h2>

## 1. Install Neovim (include `Font`, `Lazygit`)

### Windows
Windows 11（PowerShell）での初回導入を想定した前提ツール（詳細インストール手順は省略）:


```powershell
winget install -e --id Neovim.Neovim
winget install -e --id Git.Git
winget install -e --id DEVCOM.JetBrainsMonoNerdFont
winget install BurntSushi.ripgrep.MSVC
winget install -e --id JesseDuffield.lazygit
winget install -e --id charmbracelet.glow    # markdownプレビュー用
winget install -e --id GitHub.cli    # octo.nvim用
winget install -e --id OpenJS.NodeJS.LTS
```
- Nodejsは管理者必要かも

### macOS

```zsh
brew install nvim
brew install --cask font-fira-code-nerd-font
brew install --cask font-udev-gothic-nf
brew install lazygit
brew install gh
brew install pngpaste
brew install glow
brew install ripgrep
brew install codex
```

<h2 id="set-font"></h2>

## 2. Set Font
- macOS (Terminal.app)
  - Nerd Fontをいれる (参考: `https://formulae.brew.sh/cask/font-fira-code-nerd-font`)
  - UDEV Gothic NFLG をいれる (参考: `https://formulae.brew.sh/cask/font-udev-gothic-nf`) 
  - `設定 > プロファイル > フォント > 変更` → 左上で `等幅` へ変更し
  - `FiraCode Nerd Font Mono` や `UDEV Gothic NFLG` へ変更

- Windows (Windows Terminal)

  1. https://github.com/yuru7/udev-gothic/releases/ で`Nerd Fonts 合成版`のzipファイルをダウンロード
  2. 設定 > フォント > `UDEV Gothic NFLG Regular`をインストール
  3. Windows Terminal を開く
  2. `設定` (`Ctrl + ,`) を開く
  3. 対象プロファイル（例: PowerShell）を選択
  4. `外観` > `フォント フェイス` を `UDEV Gothic NFLG Regular`に変更
  5. `保存` を押して新しいタブを開き直す

<h2 id="clone-config"></h2>

## 3. Clone config
`macOS`:
```
NVIM_CONFIG_DIR="$(nvim --headless --clean +'lua io.write(vim.fn.stdpath("config"))' +qa)"

mkdir -p "$NVIM_CONFIG_DIR"

if [ ! -d "$NVIM_CONFIG_DIR/.git" ]; then
  git clone https://github.com/9mada4/nvim-config.git "$NVIM_CONFIG_DIR"
else
  git -C "$NVIM_CONFIG_DIR" pull
fi
```

`Windows 11 (PowerShell)`:
- 設定ディレクトリの設定->確認
```powershell
$NVIM_CONFIG_DIR = nvim --headless --clean "+lua io.write(vim.fn.stdpath('config'))" +qa
$NVIM_CONFIG_DIR
```
- クローン(既にフォルダがあったら失敗するかも？)
```powershell
New-Item -ItemType Directory -Force -Path $NVIM_CONFIG_DIR | Out-Null

if (-not (Test-Path (Join-Path $NVIM_CONFIG_DIR ".git"))) {
  git clone https://github.com/9mada4/nvim-config.git $NVIM_CONFIG_DIR
} else {
  git -C $NVIM_CONFIG_DIR pull
}
```
- 確認
```
Get-ChildItem -Force $NVIM_CONFIG_DIR
```

<h2 id="open-neovim"></h2>

## 4. Open Neovim
- macOS
```zsh
cd ~/.config/nvim
nvim
```
- Windows

```powershell
cd ~\AppData\Local\nvim
nvim
```
`:Lazy`->`shift+s`(S)で読み込み

<h2 id="ime-setting"></h2>

## 5. IME setting
(optional)
Windows terminal Neovim では、InsertLeave 時に PowerShell で「無変換」キーを送信して IME OFF を行います。

- Script: `tools/windows/send-nonconvert.ps1`
- Trigger: `InsertLeave` only
- Scope: Windows only（macOS/Linux では何もしない）
- Dependencies: PowerShell が必要
- Not required: Python / `pynvim` / remote plugin / custom exe

重要な前提:

- Windows の IME 設定で「無変換」キーを「IME-オフ」に割り当ててください。
- この割り当てをしていない場合、この機能は動きません。

手動確認:

```powershell
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\tools\windows\send-nonconvert.ps1
```

- 既存の Hammerspoon 方式（legacy）はこちらを参照してください: [docs/hammerspoon-ime-terminal.md](docs/hammerspoon-ime-terminal.md)

<h2 id="custom-lazygit"></h2>

## 6. Custom LazyGit
(optional: LazyGit users)
1. create a symlink to the repo-managed config

- macOS:
```
cd ~/.config/nvim
mkdir -p "$(lazygit --print-config-dir)"
ln -sfn "$PWD/tools/lazygit/config.mac.yml" "$(lazygit --print-config-dir)/config.yml"
```

- Windows:
```powershell
$LG = (lazygit --print-config-dir).Trim()
New-Item -ItemType Directory -Force -Path $LG | Out-Null
```

2. apply repo-managed files

`macOS`:
- repo-managed config: [`tools/lazygit/config.mac.yml`](/Users/Kuma/.config/nvim/tools/lazygit/config.mac.yml)
- after the first symlink, `git pull` updates the LazyGit config automatically
- if colors still look disabled outside Neovim, check whether `NO_COLOR` is set in your shell startup files

`Windows (repo-managed files)`:
```powershell
cd $env:LOCALAPPDATA\nvim
```
```powershell
Copy-Item .\tools\lazygit\commit-with-generated-msg.cmd "$LG\commit-with-generated-msg.cmd" -Force

$CFG = Get-Content .\tools\lazygit\config.windows.yml -Raw
$CFG = $CFG.Replace('__LAZYGIT_DIR__', $LG)
Set-Content "$LG\config.yml" -Value $CFG -Encoding utf8
```

3. usage
- `<leader>gg` opens LazyGit in Neovim
- In LazyGit, press `R` or `G` after applying the matching setup above
- check config dir: `lazygit --print-config-dir`

<h2 id="first-setup-checklist"></h2>

## 7. First setup checklist
- `nvim --version` / `git --version` が通る
- Step 3 実行後に `nvim` で起動できる
- 初回起動で lazy.nvim / plugins の自動セットアップが完了する
- `:checkhealth` を実行し，致命的エラーがない
- （任意）`rg --version`, `lazygit --version`, `glow --version` が必要に応じて通る

## How to update
Finder > `⌘ + Shift + .` > drag `$NVIM_CONFIG_DIR/lua` to upload file this repo

## If you require SSH
1. make `~/.ssh/config`
``` zsh
nvim ~/.ssh/config
```
2. paste this
You should change YOURKEY_ID
```text
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/YOURKEY_ID
  IdentitiesOnly yes
  AddKeysToAgent yes
  UseKeychain yes
```
3. set YOURKEY_ID to Keychain
``` zsh
ssh-add --apple-use-keychain ~/.ssh/YOURKEY_ID
```
4. check
``` zsh
ssh-add -l
ssh -T git@github.com
```
## Folder structure

Run this:

``` zsh
nvim --clean --headless +"lua dofile(vim.fn.stdpath('config') .. '/scripts/save-tree.lua')" +qa
```

Output: `docs/STRUCTURE.txt`
