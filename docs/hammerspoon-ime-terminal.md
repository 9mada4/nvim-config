# Force IME OFF when returning to Terminal.app (optional, legacy)

> この手順は旧方式（Hammerspoon）です。  
> 現在の README 本文では `im-select` ベースの設定を案内しています。

- Note: この手順は macOS + Hammerspoon 向けです。Windows ではスキップ可能です。

## Install
```zsh
brew install --cask hammerspoon
```

## Configure
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

## Preferences
- Check this
  - ☑ Launch Hammerspoon at login
  - ☑ Check for updates
- `Enable Accessibility`

## Reload config
- `Hammerspoon menu` -> `Reload Config`
