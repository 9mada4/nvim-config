# Neovim setup
https://youtu.be/80zZQLe0NNg?si=i35CENhmjsgItoPy
zz, zb, zt
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


## 6. Safe `pull --rebase`
1. add this to LazyGit config here 
`~/Library/Application Support/jesseduffield/lazygit/config.yml`
- do this
```
nvim ~/Library/Application Support/jesseduffield/lazygit/config.yml
```
- paste this
```
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
    command: 'MSG="$(./scripts/generate-commit-msg.sh)" && git commit -e -m "$MSG"'
```
2. Then use this `R`, `G` 

## How to update
Finder > `⌘ + Shift + .` > drag `~/.config/nvim/lua` to upload file this repo

## If you require SSH
1. make `~/.ssh/config`
``` zsh
nvim ~/.ssh/config
```

2. paste this
You should change YOURKEY_ID
```
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

