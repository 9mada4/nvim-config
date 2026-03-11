# Neovim setup
- [x] ショートカットメモ表示機能 mdを作ってnoiceで表示
- [x] 写真表示機能
    - [x] ファイルを表示
    - [x] ブラウザプレビュー
https://youtu.be/80zZQLe0NNg?si=i35CENhmjsgItoPy
zz, zb, zt
## 1. Install Neovim (include `Font`, `lazygit`)

```zsh
brew install nvim
brew install --cask font-fira-code-nerd-font
brew install lazygit
brew install gh
brew install pngpaste
brew install glow
```
- Nerd Fontをいれる (参考: https://formulae.brew.sh/cask/font-fira-code-nerd-font )

## 2. Clone config
```zsh
NVIM_CONFIG_DIR="$(nvim --headless --clean +'lua io.write(vim.fn.stdpath(\"config\"))' +qa)"
```

1. Clone
```zsh
git clone git@github.com:9mada4/nvim-config.git "$NVIM_CONFIG_DIR"
```
**or**

1. unzip nvim-config-main.zip 
```zsh
cd ~/Downloads
mkdir -p "$(dirname "$NVIM_CONFIG_DIR")"
mv nvim-config-main "$NVIM_CONFIG_DIR"
```
2. `ls "$(dirname "$NVIM_CONFIG_DIR")"` -> nvim ok

**or**

1. pull
```
cd "$NVIM_CONFIG_DIR"
git pull
```
## 3. Open Neovim
nvim

## 4. Set Font
- Terminal.app で，`設定 > プロファイル > フォント` から `FiraCode Nerd Font Mono` へ変更

## 5. Force IME OFF when returning to Terminal.app (optional)

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
```
### Preferences
- Check this
  - ☑ Launch Hammerspoon at login
  - ☑ Check for updates
- `Enable Accessibility`

### Reload config
- `Hammerspoon menu` -> `Reload Config`


## 6. Custom LazyGit
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
