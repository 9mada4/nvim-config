# Neogit 日本語説明・選択実行 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Neogit ポップアップでカーソル下の項目を選択・実行（`<CR>`/`<Space>`）し、`?` で日本語説明を出す。ステータス上部ヒントの消失を直す。

**Architecture:** `FileType NeogitPopup` でバッファローカルのキーと CursorMoved 強調を追加する `lua/config/neogit_popup.lua`。説明文は `lua/config/neogit_help_ja.lua` の表。ヒント修正は既存 `lua/config/neogit.lua` の `setup_hints` に autocmd を足す。

**Tech Stack:** Neovim Lua API, Neogit（インストール済み、本体は変更しない）

**Spec:** `docs/superpowers/specs/2026-11-23-neogit-japanese-help-design.md`

## Global Constraints
- Neogit 本体と内部 state を書き換えない。既存キーの動作を変えない。
- 実行は Neogit のキーを `nvim_feedkeys(keys, "m", false)` で送る。
- テストは `nvim --clean --headless -i NONE -l tests/<file>.lua`（既存 `tests/neogit.lua` と同じ方式）。

## Review Focus
- アクション列が横に複数ある行で、右側の列にカーソルがあるとき右側の操作が選ばれること。
- 見出し・空行・無効アクション（`_`）上で `<CR>`/`?` を押しても何も実行されずエラーも出ないこと。
- `-r` のような 2 文字キーのスイッチが `<CR>` でトグルされること。
- 説明フロートを開いたまま `q` で閉じてもポップアップ自体は閉じないこと。
- ステータスで下にスクロールし `gg` で戻るとヒント 2 行が再表示されること。

---

### Task 1: ステータスヒントの再表示

**Files:**
- Modify: `lua/config/neogit.lua`（`setup_hints`）
- Test: `tests/neogit.lua`

- [ ] **Step 1: 失敗するテスト追加** — 十分な行数のファイルを unstaged にしてステータスを開き、`vim.cmd("normal! G")` → `vim.cmd("normal! gg")` → 自動コマンド処理後 `check(vim.fn.winsaveview().topfill == 2, "hints return after scrolling back to top")`。
- [ ] **Step 2: 実行して失敗を確認** — `nvim --clean --headless -i NONE -l tests/neogit.lua` → topfill が 0 で FAIL。
- [ ] **Step 3: 実装** — `setup_hints` に `WinScrolled`/`CursorMoved` autocmd を追加。現在バッファが NeogitStatus で `topline == 1` かつ `topfill < ヒント行数` なら `winrestview({topfill = n})`。ヒント行数は `update_hints` で使う `lines` の数（2）を `M.hint_rows` として公開。
- [ ] **Step 4: テスト通過を確認**（同コマンド、`checks passed`）。
- [ ] **Step 5: Commit**

### Task 2: ポップアップの選択・実行・説明

**Files:**
- Create: `lua/config/neogit_popup.lua`, `lua/config/neogit_help_ja.lua`, `tests/neogit-popup.lua`
- Modify: `lua/plugins/editor/neogit.lua`（config で `require("config.neogit_popup").setup()`）

**Interfaces:**
- `neogit_popup.item_under_cursor(buf, popup) -> {kind="action"|"switch"|"option"|"config", keys=string, description=string, cli=string|nil, popup=string} | nil`
- `neogit_popup.run(buf)` / `neogit_popup.explain(buf)` / `neogit_popup.setup()`
- `neogit_help_ja.lookup(item) -> {title=string, body=string[]}`（未登録時は英語 description +「説明未登録」）
- 表の形: `actions[popup_name][key]`, `args["--flag"]`

- [ ] **Step 1: 失敗するテスト** — 既存テストと同じ一時リポジトリ準備で Pull ポップアップを開き:
  - 右列の操作行にカーソルを置き `item_under_cursor` が右列の key を返す。
  - `-r --rebase` 行で `run` → 再描画後その行に `--rebase` が有効ハイライト（`popup.state.args` の該当 switch.enabled が true）。
  - `p` 行で `explain` → 新しい float ウィンドウが開き、本文に日本語が含まれる。float で `q` → float は閉じ、ポップアップバッファは残る。
  - 見出し行で `run`/`explain` → ウィンドウ数・ポップアップ状態が変化しない。
  - ステータスで `?`（HelpPopup）を開き同様に `explain` が float を出す。
- [ ] **Step 2: 実行して失敗を確認** — `nvim --clean --headless -i NONE -l tests/neogit-popup.lua` → module not found で FAIL。
- [ ] **Step 3: 実装 `item_under_cursor`** — 現在インスタンスは `require("neogit.lib.popup").instance`。まず `popup.buffer.ui:get_interactive_component_under_cursor()` で Switch/Option/Config（`options.tag`, `options.value`）。なければ行テキストから、`popup.state.actions` の各アクション（keys あり・callback あり）について `table.concat(keys, ",") .. " " .. description` の出現開始列を `string.find(plain)` で求め、カーソル列以下で最大のもの。
- [ ] **Step 4: 実装 `run`/`explain`/`setup`** — `run` はスイッチ/オプションは `key_prefix..key`、config は `id`、アクションは `keys[1]` を feedkeys。`explain` は `nvim_open_win` の float（border rounded, 幅は内容に合わせ最大 80%）、`q`/`<Esc>` で閉じる。`setup` は `FileType NeogitPopup` で `<CR>`/`<Space>`/`?` をバッファローカルに map し、CursorMoved で選択項目を extmark（`Visual` ハイライト）で強調。
- [ ] **Step 5: 説明表を書く** — Commit, Pull, Push, Stash, Help の全アクションと、それらの主要スイッチ（`--rebase`, `--force-with-lease`, `--force`, `--all`, `--amend` 系など）。各項目: 何が起きるか / 注意 / 相当 git コマンド。
- [ ] **Step 6: テスト通過を確認**（両テストファイル）。
- [ ] **Step 7: README の Neogit 節に操作を追記し Commit**
