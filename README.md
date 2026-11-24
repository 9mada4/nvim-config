# Neovim setup
## 目次
- [todo](#todo)
- [1. Install Neovim (include `Font`)](#install-neovim)
- [2. Set Font](#set-font)
- [3. Clone config](#clone-config)
- [4. Open Neovim](#open-neovim)
- [5. Codex image shortcut](#codex-image-shortcut)
- [6. IME setting (optional)](#ime-setting)
- [7. Neogit](#neogit)
- [8. First setup checklist](#first-setup-checklist)
- [How to update](#how-to-update)
- [If you require SSH](#if-you-require-ssh)
- [Folder structure](#folder-structure)

## todo

<h2 id="install-neovim"></h2>

## 1. Install Neovim (include `Font`)

### Windows
Windows 11(PowerShell)での初回導入を想定した前提ツール(詳細インストール手順は省略):


```powershell
winget install -e --id Neovim.Neovim
winget install -e --id Git.Git
winget install -e --id DEVCOM.JetBrainsMonoNerdFont
winget install BurntSushi.ripgrep.MSVC
winget install -e --id charmbracelet.glow    # markdownプレビュー用
winget install -e --id GitHub.cli    # octo.nvim用
winget install -e --id OpenJS.NodeJS.LTS
winget install --source winget --exact --id tree-sitter.tree-sitter-cli
```
- Nodejsは管理者必要かも

### macOS

```zsh
brew install nvim
brew install --cask font-fira-code-nerd-font
brew install --cask font-udev-gothic-nf
brew install gh
brew install pngpaste
brew install glow
brew install ripgrep
brew install codex
brew install daipeihust/tap/im-select
```
- pngpaste: 画像コピペ用, gh: github, glow: md preview用, ripgrep: テキスト検索用
- im-select: Neovim 起動時・フォーカス復帰時・挿入モード終了時の英数切り替え用

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
  3. 対象プロファイル(例: PowerShell)を選択
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
# 1. 設定ディレクトリのパスを設定(環境変数を使うのが一番確実！)
$NVIM_CONFIG_DIR = "$env:LOCALAPPDATA\nvim"
Write-Host "Config Directory: $NVIM_CONFIG_DIR"

# 2. フォルダの作成(すでにあってもエラーになりません)
New-Item -ItemType Directory -Force -Path $NVIM_CONFIG_DIR | Out-Null

# 3. クローンまたは更新の判定
if (-not (Test-Path (Join-Path $NVIM_CONFIG_DIR ".git"))) {
    # 注意: フォルダ内に .git はないが他のファイルがある場合、下の clone は失敗します。
    # その場合は、あらかじめ手動で nvim フォルダを削除するか中身を空にしてください。
    git clone https://github.com/9mada4/nvim-config.git $NVIM_CONFIG_DIR
} else {
    git -C $NVIM_CONFIG_DIR pull
}

# 4. 完了確認
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

Markdown のブラウザプレビューで `mermaid version 10.2.3` のエラーが出る場合は、`:Lazy build markdown-preview.nvim` で Mermaid 11 を導入し、Neovim を再起動してください。プラグイン本体に更新がない場合、`Sync` だけでは再ビルドされません。

<h2 id="codex-image-shortcut"></h2>

## 5. Codex image shortcut
macOS の Shortcuts.app(ショートカット.app)で、クリップボードの画像を特定のパスへ同じファイル名で上書き保存できるようにしておきます。Shortcuts.app 側の詳細設定は割愛します。

この設定では、保存先を次のファイルとして扱います。

```zsh
$HOME/Pictures/Screenshot/screenshotToText.png
```

ターミナルで環境変数を設定する．`~/.zshrc` に設定を追加して永続化．

```zsh
echo 'export CHAPPY_SCREENSHOT_PATH="$HOME/Pictures/Screenshot/screenshotToText.png"' >> ~/.zshrc
```

確認:

```zsh
echo "$CHAPPY_SCREENSHOT_PATH"
mkdir -p "$(dirname "$CHAPPY_SCREENSHOT_PATH")"
cd "$(dirname "$CHAPPY_SCREENSHOT_PATH")"
ls -l "$CHAPPY_SCREENSHOT_PATH"
```

`CHAPPY_SCREENSHOT_PATH` は画像ファイルのパスなので、`cd "$CHAPPY_SCREENSHOT_PATH"` ではなく `cd "$(dirname "$CHAPPY_SCREENSHOT_PATH")"` を使います。

Neovim 内の Codex では次のショートカットを使えます。

- `<leader>cc`: Codex を開閉
- `<leader>cf`: Codex へ移動
- `<leader>ci`: `$CHAPPY_SCREENSHOT_PATH` の画像パスを Codex に送信
- Visual mode の `<leader>cs`: 選択範囲を Codex に送信

`<leader>ci` は、環境変数が未設定の場合も `$HOME/Pictures/Screenshot/screenshotToText.png` を既定値として使います。

Codex CLI に直接打つコマンド:

- `Ctrl-J`: 入力欄で改行
- `/model`: モデル変更
- `/new`: 新規チャット
- `Spc+ci`: 画像パス送信
- `/vim`: Vim モード切替
- `/exit`: Codex 終了

<h2 id="ime-setting"></h2>

## 6. IME setting
(optional)

### macOS

`im-select` をインストールすると、`lua/config/ime.lua` が次のタイミングで入力ソースを ABC（英数）へ切り替えます。

- Neovim 起動時（`VimEnter`）
- Neovim にフォーカスが戻ったとき（`FocusGained`、挿入モード中も対象）
- 挿入モード終了時（`InsertLeave`）

切り替え時だけコマンドを実行するため、常駐プロセスやキー入力の監視は不要です。日本語は手動で切り替えて入力でき、挿入モードに入る際の日本語入力の自動復元は行いません。

前提と対象範囲:

- macOS の入力ソースに「ABC」を登録してください。
- ターミナルがフォーカス通知を Neovim に送る必要があります。標準ターミナル.appとChatGPT.app内のCodexでは確認済みです。
- `im-select` が未インストールなら何もしません。PATH にない場合は Homebrew の標準パスも検索します。

手動確認:

```zsh
im-select com.apple.keylayout.ABC
```

Neovim を再起動し、日本語入力に切り替えてから別アプリへ移動し、戻ったときに英数になることを確認してください。

#### Google日本語入力中の `jj` で Normal モードへ戻る

日本語入力中は `j` がIMEの未確定文字になり、Neovim の `jj` マッピングに届きません。そこで Google日本語入力のローマ字テーブルで `jj` を ESC 文字（U+001B）に変換し、`DirectInput` 属性で即確定させます。Neovim は ESC を受け取って Normal モードへ戻り、上記の `InsertLeave` で英数に切り替わります。キー監視の常駐プロセスは不要です。

```zsh
python3 ~/.config/nvim/tools/macos/google-japanese-input/jj-esc.py            # 設定（自動バックアップ）
python3 ~/.config/nvim/tools/macos/google-japanese-input/jj-esc.py --status   # 確認
python3 ~/.config/nvim/tools/macos/google-japanese-input/jj-esc.py --remove   # 元の「っ」+ j に戻す
```

- 設定ファイル `~/Library/Application Support/Google/JapaneseInput/config1.db` を書き換え、変換エンジンを再起動します。バックアップは同じ場所に `config1.db.bak-日時` で作られます。
- 未確定文字がない状態の `jj` は即座に Esc になります。`かjj` のように未確定文字がある場合は Enter で確定すると、「か」が入力されてから Normal に戻ります。
- Google日本語入力全体の設定なので、他のアプリで `jj` を打つと制御文字が入ります。`っj` が必要な語（例: バッジ）は `xtu` などで入力してください。
- 設定画面でローマ字テーブルを編集・保存すると `DirectInput` 属性が消えるため、その後はスクリプトを再実行してください。
- macOS のターミナル上の Neovim で動作を確認済みです。
- 同梱の `romanji-hiragana.tsv` は Mozc の標準ローマ字テーブルです（`LICENSE.mozc`）。

### Windows

Windows terminal Neovim では、InsertLeave 時に PowerShell で「無変換」キーを送信して IME OFF を行います。

- Script: `tools/windows/send-nonconvert.ps1`
- Trigger: `InsertLeave` only
- Scope: Windows only（Linux では何もしない）
- Dependencies: PowerShell が必要
- Not required: Python / `pynvim` / remote plugin / custom exe

重要な前提:

- Windows の IME 設定で「無変換」キーを「IME-オフ」に割り当ててください。
- この割り当てをしていない場合、この機能は動きません。

手動確認:

```powershell
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\tools\windows\send-nonconvert.ps1
```

- 既存の Hammerspoon 方式(legacy)はこちらを参照してください: [docs/hammerspoon-ime-terminal.md](docs/hammerspoon-ime-terminal.md)

<h2 id="neogit"></h2>

## 7. Neogit

Neovim で `<Space>gg` を押すと Neogit のステータス画面が開きます。

### 基本操作

ステータス画面でよく使うキーです。画面の上2行にも主なキーが表示されます。

| キー | 操作 |
| --- | --- |
| `Tab` | 差分の開閉 |
| `s` / `u` | ステージ / ステージ解除 |
| `x` | 変更を破棄 |
| `c` | Commit メニュー |
| `p` / `P` / `Z` | Pull / Push / Stash メニュー |
| `?` | ヘルプ |
| `q` | 閉じる |

`git pull --rebase` をしたいときは、`p` → `-r` でスイッチをオンにし、取得元(`p` や `u`)を選びます。

### メニューの操作

メニューでは、キーを直接押すほかに、カーソルで項目を選んで実行することもできます。

| キー | 操作 |
| --- | --- |
| `Enter` / `Space` | 選択中の項目を実行 |
| `?` | 選択中の項目の説明を日本語で表示 |
| `q` / `Esc` | 説明を閉じる。説明が出ていなければメニューを閉じる |

説明文は `lua/config/neogit_help_ja.lua` で追加・編集できます。まだ説明がない項目には、英語の説明と「説明未登録」が表示されます。

### コミット

`s` で変更をステージしてから `c` を押し、次のどれかを選びます。

| キー | メッセージの作り方 |
| --- | --- |
| `c` | 自分で書く |
| `g` (Gen-Rule) | ルールに沿って自動生成する(LLM は使わない) |
| `G` (Gen-Rule+LLM) | `g` の内容に、LLM が書いた補足文を加える |

どれを選んでもコミットメッセージの編集画面が開きます。内容を確認・修正してから、コミットするか中止するかを選びます。

| キー | 操作 |
| --- | --- |
| `:wq` / `Ctrl-c Ctrl-c` | コミットする |
| `Ctrl-c Ctrl-k` | 中止する |
| `<Space>gm` | LLM の補足文をもう一度見る(`G` で補足文を生成できたときのみ) |

`g` と `G` を使うときの注意点です。

- 対象はステージ済みの変更だけです。Commit メニューの `-a` などのスイッチは無視されます。
- 生成中も Neovim を操作できます。生成が終わると編集画面が開きます。
- LLM の生成に失敗した場合は、ルールで作ったメッセージだけが入ります。
- 生成中にステージの内容を変えると中断されるので、もう一度生成してください。
- LLM の文には誤りが混ざることがあります。特に変更内容や数値の単位は必ず確認してください。

件名のすぐ下の行に本文を書いた場合は、保存時や `:q` で閉じるときに、件名と本文の間へ空行が自動で入ります。空行がないと、Git が本文まで件名とみなすためです。

### LLM について

モデルと実行ファイルはリポジトリに同梱しているので、Ollama や Python は不要です。

- 対応環境: macOS 14 以降の Apple Silicon、または Windows x64(Visual C++ ランタイムが必要)
- 容量: クローンに約 650 MB、初回利用時に作られるキャッシュに約 580 MB
- ライセンス、入手元、チェックサム: 同梱のライセンスファイルとマニフェストを参照

補足文は、変更箇所ごとに1文ずつ生成し、ファイル名を付けて並べたものです。変更箇所が多いほど時間がかかります。次のどれかに当てはまる変更箇所があると、そのファイルの補足文は省かれます。

- 生成された文が160字を超えた
- 文が途中で切れた
- プロンプトが8,192バイトを超えた

LLM には差分のほかに、変更箇所を含む関数や見出しなどの前後の内容も、参考として渡します(変更前・変更後それぞれ最大2,048バイト)。範囲は Tree-sitter で決め、パーサーがない場合やブロックが大きすぎる場合は周辺の行を使います。指示文を変えたいときは、`scripts/commit-msg-llm.lua` の `system_prompt` を編集してください。

### 開発メモ

- Neogit 本体は変更していません。Commit メニューの `g` / `G` は[公式の Popup Builder](https://github.com/NeogitOrg/neogit/blob/master/doc/neogit.txt#L2230) で追加しています。
- ステータス画面の上2行は、Neogit 標準のヒントを `disable_hint` で消し、代わりに仮想行で表示しています。キーは Neogit の設定に合わせて変わります。ウィンドウが狭いと右端が切れます。
- 環境変数 `NVIM_GENERATE_COMMIT_MSG=1` を付けて Neovim を Git のエディタとして起動すると、Neogit の外でも LLM の補足文を使えます。`<Space>gm` で開き、Enter でカーソル位置に挿入します。ステージ済みの変更がなければ、未ステージの変更が対象になります。

テストは次のコマンドで実行します。

```zsh
nvim --clean --headless -i NONE -l tests/neogit.lua
nvim --clean --headless -i NONE -l tests/neogit-popup.lua
nvim --clean --headless -l tests/commit-msg.lua
```

<h2 id="first-setup-checklist"></h2>

## 8. First setup checklist
- `nvim --version` / `git --version` が通る
- Step 3 実行後に `nvim` で起動できる
- 初回起動で lazy.nvim / plugins の自動セットアップが完了する
- `:checkhealth` を実行し，致命的エラーがない
- (任意)`rg --version`, `glow --version` が必要に応じて通る

## How to update
Finder > `⌘ + Shift + .` > drag `$NVIM_CONFIG_DIR/lua` to upload file this repo

### `:Lazy` に `Breaking Changes` と表示された場合

`Sync` 後の更新履歴に出るオレンジ色の `Breaking Changes` はエラーではなく、
プラグイン側が破壊的変更として印を付けたコミットです。青色の
`updated from ... to ...` が表示されていれば、そのプラグインの更新自体は完了しています。
たとえば nvim-lspconfig の `` drop `lsp/rls.lua` `` は、廃止済みの Rust Language
Server (RLS) 用設定が削除されたという更新履歴です。この設定では RLS を使用して
いないため、追加の変更は不要です。

実際の起動エラーがないことは、Lazy の画面を閉じてから次のコマンドで確認できます。

```zsh
nvim --headless "+checkhealth vim.lsp" +qa
```

失敗する場合は、`nvim --version` で Neovim 0.11.3 以降を使用していることを確認した後、
`:Lazy sync` を再実行してください。エラーメッセージが表示されていない場合、
`Breaking Changes` の表示だけを理由にプラグインをダウングレードする必要はありません。

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
