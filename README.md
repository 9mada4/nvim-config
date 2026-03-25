# Neovim setup
## 目次
- [todo](#todo)
- [1. Install Neovim (include `Font`, `lazygit`)](#1-install-neovim-include-font-lazygit)
- [2. Set Font](#2-set-font)
- [3. Clone(pull) config](#3-clonepull-config)
- [4. Open Neovim](#4-open-neovim)
- [5. IME setting (optional)](#5-ime-setting-optional)
- [6. Custom LazyGit](#6-custom-lazygit-optional-lazygit-利用者向け)
- [7. First setup checklist](#7-first-setup-checklist)
- [How to update](#how-to-update)
- [If you require SSH](#if-you-require-ssh)
- [Folder structure](#folder-structure)
## todo
- [x] Windowsセットアップ手順追記
- [ ] IME自動切り替え実装
  - [x] luaから.ps1ファイルを呼び出せるようにしたらいけそう。
  - [ ] 通知をオフ
  - [ ] ｊｊが入力されたらback２回にescを送信したら、.ps1も呼び出されていけそう。
  - [ ] macOSもターミナル上でキー送信で対応か？

https://youtu.be/80zZQLe0NNg?si=i35CENhmjsgItoPy <br>
zz, zb, zt
## 1. Install Neovim (include `Font`, `lazygit`)
### Windows
Windows 11（PowerShell）での初回導入を想定した前提ツール（詳細インストール手順は省略）:

- 必須
  - Neovim: 本設定を起動する本体
    - 確認: `nvim --version`
    ```
    winget install -e --id Neovim.Neovim
    ```
  - Git: config clone / lazy.nvim bootstrap に必要
    - 確認: `git --version`
    ```
    winget install -e --id Git.Git
    ```
- 推奨
  - Nerd Font (e.g. FiraCode Nerd Font): アイコン崩れ防止
    - 確認: ターミナルのフォント選択肢に表示されること
    ```
    winget install -e --id DEVCOM.JetBrainsMonoNerdFont
    ```
  - ripgrep: `<leader>fg` (Telescope live_grep) に必要
    - 確認: `rg --version`
    ```
    winget install BurntSushi.ripgrep.MSVC
    ```
- 任意
  - lazygit: `<leader>gg` を使う場合
    - 確認: `lazygit --version`
    ```
    winget install -e --id JesseDuffield.lazygit
    ```
  - glow: Markdownプレビュー `<leader>mg` を使う場合
    - 確認: `glow --version`
    ```
    winget install -e --id charmbracelet.glow    # markdownプレビュー用
    ```
  - gh: GitHub CLI を使う場合
    - 確認: `gh --version`
    ```
    winget install -e --id GitHub.cli    # octo.nvim用
    ```
  - Node.js / npm: 一部機能で利用
    - 確認: `node --version`, `npm --version`
    ```
    winget install -e --id JesseDuffield.lazygit
    ```
### macOS
```zsh
brew install nvim
brew install --cask font-fira-code-nerd-font
brew install lazygit
brew install gh
brew install pngpaste
brew install glow
brew install ripgrep
```
- Nerd Fontをいれる (参考: https://formulae.brew.sh/cask/font-fira-code-nerd-font )

## 2. Set Font
- macOS (Terminal.app)
  - `設定 > プロファイル > フォント` から `FiraCode Nerd Font Mono` へ変更
- Windows (Windows Terminal)
  1. Windows Terminal を開く
  2. `設定` (`Ctrl + ,`) を開く
  3. 対象プロファイル（例: PowerShell）を選択
  4. `外観` > `フォント フェイス` を `JetBrainsMono Nerd Font`（または導入済みの Nerd Font）に変更
  5. `保存` を押して新しいタブを開き直す

## 3. Clone(pull) config
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

## 5. IME setting (optional)
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

動作確認時は `lua/config/ime.lua` のデバッグ通知で `InsertLeave fired` と PowerShell の終了コード（必要に応じて stdout/stderr）を確認できます。

## 6. Custom LazyGit (optional: LazyGit 利用者向け)
1. open LazyGit config

- macOS/Linux:
```
~/.config/lazygit/config.yml` (or `~/Library/Application Support/lazygit/config.yml` on some macOS setups)
```
- Windows: 
  ```powershell
  mkdir $env:APPDATA\lazygit
  cd $env:APPDATA\lazygit
  nvim config.yml
  ```

2. add custom commands (choose your shell variant)

`POSIX shell (zsh/bash/sh)`:
```yaml
customCommands:
  - key: "R"
    context: "global"
    description: "Pull with rebase"
    command: "git pull --rebase"
    output: log
  - key: "G"
    context: "files"
    description: "Generate commit message and open editor"
    output: terminal
    command: |
      MSG="$(nvim --clean --headless +'lua dofile(vim.fn.stdpath("config") .. "/scripts/generate-commit-msg.lua")' +qa 2>&1)"
      [ -n "$MSG" ] || { echo "failed to generate commit message"; exit 1; }
      git commit -e -m "$MSG"
```

`PowerShell (Windows)`:
```yaml
customCommands:
  - key: "R"
    context: "global"
    description: "Pull with rebase"
    command: "git pull --rebase"
    output: log
  - key: "G"
    context: "files"
    description: "Generate commit message and open editor"
    output: terminal
    command: |
      $MSG = (nvim --clean --headless "+lua dofile(vim.fn.stdpath('config') .. '/scripts/generate-commit-msg.lua')" +qa 2>&1 | Out-String).Trim()
      if ([string]::IsNullOrWhiteSpace($MSG)) { Write-Host "failed to generate commit message"; exit 1 }
      git commit -e -m "$MSG"
```

3. usage
- `<leader>gg` opens LazyGit in Neovim
- In LazyGit, press `R` or `G` after applying the matching customCommands block above

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
