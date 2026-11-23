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

### 使い方
- Neovim の `<Space>gg` で Neogit を開きます。
- ステータス画面の上部2行に主要操作のヒントを表示します。`s` でステージし、`c` でCommitメニュー、`p` / `P` / `Z` でPull / Push / Stashメニューを開きます。Pull --rebaseはPullメニューの `-r` をONにして取得元 (`p` / `u` など) を選びます。
- `c → c` は通常のコミット編集です。`c → g` (Gen-Rule) は既存の日本語ルール文だけを生成し、LLMを起動しません。`c → G` (Gen-Rule+LLM) は同じルールの件名・本文にLLMの補足説明を加えます。どちらもステージ済みの変更のみが対象で、Commitメニューのフラグ (`-a` など) は適用しません。
- 生成は非同期で行い、完了後に通常のコミット編集画面を開きます。LLMが失敗した場合もルール文を保持して通知します。生成中にステージ内容が変わった場合はやり直しを促します。生成だけでコミットは確定しません。
- `c → G` の編集画面では `<Space>gm` で生成済み補足文を再確認できます。LLMは再起動しません。本文には挿入済みなので、Enter / `q` / Escでプレビューを閉じます。従来の `NVIM_GENERATE_COMMIT_MSG=1` による外部Git編集の非同期プレビューも維持しています（こちらはEnterでカーソル位置へ挿入）。
- コミット編集画面（`gitcommit`）では、2行目にコメント以外の本文があると、保存時（`:w` / `:wq` / `:x` / `ZZ` / Ctrl-c Ctrl-c）と未変更での `:q` 時に件名の後へ空行を自動で挿入します。Gitは最初の空行までを件名として扱うため、件名と本文がつながるのを防ぎます。
- 編集画面で `:wq` または `Ctrl-c Ctrl-c` でコミットを確定し、`Ctrl-c Ctrl-k` で中止します。

モデルと実行ファイルは同梱されており、Ollama と Python は不要です。対応環境は macOS 14 以降の Apple Silicon、または Windows x64(Visual C++ ランタイムが必要)です。クローンは約 650 MB 増え、初回利用時に約 580 MB のキャッシュを作成します。ライセンスと入手元・チェックサムは同梱のライセンスファイルとマニフェストを参照してください。

プロンプトは `scripts/commit-msg-llm.lua` 冒頭の `system_prompt` で調整できます。ファイルごとに差分の各変更箇所(ハンク)を取り出し、Tree-sitterで変更前後の関数・設定ブロック・見出しセクションを切り出して、差分と一緒に渡します。ステージ済みの変更はHEADとインデックス、未ステージの変更はインデックスと作業ファイルを参照します。パーサーがない場合やブロックが大きすぎる場合は周辺行を使います。参考情報は変更前後それぞれ最大2,048バイトに収め、差分自体は省略しません。

モデルは変更箇所ごとに日本語の一文を生成し、コード側でファイル名を付けて改行で結合します。変更ファイルは3件に制限せず、削除されたコードも対象にします。160字を超える文・生成途中の文・8,192バイトのプロンプト上限を超える変更箇所がある場合、そのファイルの要約は候補から除外します。変更箇所の数に応じて生成時間が増えます。生成文には変更の誤読や単位の誤推測が残るため、編集画面で内容を確認・修正してから確定してください。

Commitメニューの拡張には[公式のPopup Builder](https://github.com/NeogitOrg/neogit/blob/master/doc/neogit.txt#L2230)を使います。上部ヒントには項目追加の標準APIがないため、`disable_hint` とNeovimの仮想行APIを組み合わせています。キーはNeogitの設定から取得し、Status表示・再表示・更新時に描画します。Neogit本体は変更せず、バッファの行番号や選択範囲にも影響しません。狭いウィンドウでは右端が省略されます。検証は `nvim --clean --headless -i NONE -l tests/neogit.lua`（インストール済みNeogit/plenary、一時リポジトリ、LLM応答のみスタブ）と `nvim --clean --headless -l tests/commit-msg.lua` で実行できます。

### Neogitポップアップの選択と日本語説明

- 各ポップアップ（`?` のヘルプを含む）でカーソルを動かすと、カーソル下の操作・スイッチが強調表示されます。
- `Enter` / `Space` で選択中の項目を実行します。キーを直接押した場合と同じ動作です。
- ポップアップ下端に `Enter/Space 実行 | ? 日本語で説明 | q 閉じる` のヒントを表示します。
- `?` で選択中の項目の日本語説明（何が起きるか・注意・相当するgitコマンド）を表示し、`q` / `Esc` で閉じます。説明がない状態で `q` を押すとポップアップを閉じます。
- 説明文は `lua/config/neogit_help_ja.lua` に追加できます。未登録の項目は英語の説明と「説明未登録」を表示します。
- ステータス画面で下へスクロールした後に `k` / `gg` で先頭へ戻ると、上部ヒントが再表示されます。
- 検証: `nvim --clean --headless -i NONE -l tests/neogit-popup.lua`

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
