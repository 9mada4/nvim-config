# Neovim setup
https://youtu.be/80zZQLe0NNg?si=i35CENhmjsgItoPy
## 1. Install Neovim (include `Font`, `lazygit`)
```zsh
brew install nvim
brew install --cask font-fira-code-nerd-font
brew install lazygit
brew install gh
```
- Nerd Fontをいれる (参考: https://formulae.brew.sh/cask/font-fira-code-nerd-font )

## 2. Clone config
1. Clone
```zsh
git clone git@github.com:9mada4/nvim-config.git ~/.config/nvim
```

**or**

1. unzip nvim-config-main.zip 
```zsh
cd ~/Downloads
mkdir -p ~/.config
mv nvim-config-main ~/.config/nvim
```
2. `ls ~/.config` -> nvim ok

**or**

1. pull
```
cd ~/.config/nvim
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
```zsh
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

## How to update
Finder > `⌘ + Shift + .` > drag `~/.config/nvim/lua` to upload file this repo

