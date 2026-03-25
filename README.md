# Neovim setup
## todo
- [ ] Windowsセットアップ手順追記

https://youtu.be/80zZQLe0NNg?si=i35CENhmjsgItoPy
zz, zb, zt
## 1. Install Neovim (include `Font`, `lazygit`)
### Windows
工事中

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
```powershell
$NVIM_CONFIG_DIR = nvim --headless --clean "+lua io.write(vim.fn.stdpath('config'))" +qa

New-Item -ItemType Directory -Force -Path $NVIM_CONFIG_DIR | Out-Null

if (-not (Test-Path (Join-Path $NVIM_CONFIG_DIR ".git"))) {
  git clone https://github.com/9mada4/nvim-config.git $NVIM_CONFIG_DIR
} else {
  git -C $NVIM_CONFIG_DIR pull
}
```

## 4. Open Neovim
nvim

## 5. Force IME OFF when returning to Terminal.app (optional)
- Note: この手順は macOS + Hammerspoon 向けです。Windows ではスキップ可能です。

### Install
```zsh
brew install --cask hammerspoon
```
### Configure
```zsh
mkdir -p ~/.hammerspoon
nvim ~/.hammerspoon/init.lua
```
- Paste this -> `:wq`
```lua
-- ~/.hammerspoon/init.lua

local terminalWatcher = hs.application.watcher.new(function(appName, eventType, appObject)
    -- アプリが「アクティブ（最前面）」になったとき
    if eventType == hs.application.watcher.activated then
        -- 名前ではなくBundle IDで判定（言語設定に左右されない）
        if appObject:bundleID() == "com.apple.Terminal" then
            -- IMEを「ABC（英数）」に切り替え
            -- hs.keycodes.setLayout("ABC") が一般的ですが、うまくいかない場合は以下を試してください
            hs.keycodes.currentSourceID("com.apple.keylayout.ABC")
        end
    end
end)

terminalWatcher:start()

-- jj → Esc (Google日本語入力のときだけ)
local lastJTime = 0
local jjInterval = 0.25
local deleteDown = hs.eventtap.event.newKeyEvent({}, "delete", true)
local deleteUp   = hs.eventtap.event.newKeyEvent({}, "delete", false)
local escDown = hs.eventtap.event.newKeyEvent({}, "escape", true)
local escUp   = hs.eventtap.event.newKeyEvent({}, "escape", false)
local jjEscape = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e)
    -- Google日本語入力でないなら何もしない
    if hs.keycodes.currentSourceID() ~= "com.google.inputmethod.Japanese.base" then
        return false
    end
    local key = hs.keycodes.map[e:getKeyCode()]
    if key == "j" then
        local now = hs.timer.secondsSinceEpoch()
        if now - lastJTime < jjInterval then
            lastJTime = 0
            deleteDown:post()
            deleteUp:post()
            escDown:post()
            escUp:post()
            hs.keycodes.currentSourceID("com.apple.keylayout.ABC")
            return true
        end
        lastJTime = now
    end
    return false
end)

jjEscape:start()
```
### Preferences
- Check this
  - ☑ Launch Hammerspoon at login
  - ☑ Check for updates
- `Enable Accessibility`

### Reload config
- `Hammerspoon menu` -> `Reload Config`


## 6. Custom LazyGit (optional: LazyGit 利用者向け)
1. open LazyGit config

- macOS/Linux: `~/.config/lazygit/config.yml` (or `~/Library/Application Support/lazygit/config.yml` on some macOS setups)
- Windows: `%APPDATA%\\lazygit\\config.yml`

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
