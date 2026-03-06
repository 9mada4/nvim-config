# Neovim setup

## 1. Install Neovim (include `Font`, `lazygit`)
```zsh
brew install nvim
brew install --cask font-fira-code-nerd-font
brew install lazygit
```
- Nerd Fontをいれる (参考: https://formulae.brew.sh/cask/font-fira-code-nerd-font )

## 2. Clone config
1.
```zsh
git clone git@github.com:9mada4/nvim-config.git ~/.config/nvim
```
or
1. unzip nvim-config-main.zip 
```zsh
cd ~/Downloads
mkdir -p ~/.config
mv nvim-config-main ~/.config/nvim
```
2. `ls ~/.config` -> nvim ok

## 3. Open Neovim
nvim

## 4. Set Font
- Terminal.app で，`設定 > プロファイル > フォント` から `FiraCode Nerd Font Mono` へ変更

## 5. IME auto OFF when returning to Terminal (optional)

### Install
```zsh
brew install --cask hammerspoon
```

### Configure
```zsh
mkdir -p ~/.hammerspoon
nvim ~/.hammerspoon/init.lua
```
Paste this -> `:wq`
```zsh
local terminals = {
  Terminal = true,
  iTerm2 = true,
  WezTerm = true,
}

hs.application.watcher.new(function(appName, eventType)
  if eventType == hs.application.watcher.deactivated then
    if terminals[appName] then
      hs.keycodes.setMethod("ABC")
    end
  end
end):start()
```
### Reload config
`Hammerspoon menu` -> `Reload Config`
