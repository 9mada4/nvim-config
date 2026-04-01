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
    winget install -e --id OpenJS.NodeJS.LTS
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

<h2 id="set-font">2. Set Font</h2>
- macOS (Terminal.app)
  - `設定 > プロファイル > フォント` から `FiraCode Nerd Font Mono` へ変更
- Windows (Windows Terminal)
  1. Windows Terminal を開く
  2. `設定` (`Ctrl + ,`) を開く
  3. 対象プロファイル（例: PowerShell）を選択
  4. `外観` > `フォント フェイス` を `JetBrainsMono Nerd Font`（または導入済みの Nerd Font）に変更
  5. `保存` を押して新しいタブを開き直す

<h2 id="clone-config">3. Clone config</h2>
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

<h2 id="open-neovim">4. Open Neovim</h2>
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

<h2 id="ime-setting">5. IME setting</h2>
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

<h2 id="custom-lazygit">6. Custom LazyGit</h2>
(optional: LazyGit users)
1. open LazyGit config

- macOS/Linux:
```
~/.config/lazygit/config.yml (or ~/Library/Application Support/lazygit/config.yml on some macOS setups)
```

- Windows:
```powershell
$LG = (lazygit --print-config-dir).Trim()
New-Item -ItemType Directory -Force -Path $LG | Out-Null
```

2. apply customCommands

`POSIX shell (macOS/Linux: zsh/bash/sh)`:
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
- In LazyGit, press `R` or `G` after applying the matching block above
- check config dir: `lazygit --print-config-dir`

<h2 id="first-setup-checklist">7. First setup checklist</h2>
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
