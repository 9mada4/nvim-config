# Neovim setup
- [ ] コードブロック背景
- [ ] ショートカットメモ表示機能 mdを作ってnoiceで表示
- [ ] 写真表示機能
    - [ ] ファイルを表示
    - [ ] ブラウザプレビュー
https://youtu.be/80zZQLe0NNg?si=i35CENhmjsgItoPy
zz, zb, zt
## 1. Install Neovim (include `Font`, `lazygit`)

```zsh
brew install nvim
brew install --cask font-fira-code-nerd-font
brew install lazygit
brew install gh
brew install pngpaste
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
1. add this to LazyGit config here 
`~/Library/Application\ Support/lazygit/config.yml`
- do this
```zsh
nvim ~/Library/Application Support/lazygit/config.yml
```
- paste this
```txt
customCommands:
  - key: "R"
    context: "global"
    description: "Pull with rebase"
    command: "git pull --rebase"
    stream: true
  - key: "G"
    context: "files"
    description: "Generate commit message and open editor"
    subprocess: true
    command: 'MSG="$($(nvim --headless --clean +''lua io.write(vim.fn.stdpath("config"))'' +qa)/scripts/generate-commit-msg.sh)" && git commit -e -m "$MSG"'
```
2. Then use this `R`, `G` 

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
./scripts/save-tree.sh
```
