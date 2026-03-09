#!/bin/zsh

# =========================================
# generate-commit-msg.sh
# staged 済みの変更内容を見て，
# 簡単なコミットメッセージを1行自動生成するためのスクリプト
#
# コマンド
# 使い方:
#   ./scripts/generate-commit-msg.sh
# 権限が必要なとき:
#   chmod +x ~/.config/nvim/scripts/genrate-commit-msg.sh
#
# このスクリプトは LazyGit の customCommands から呼ぶ想定
# 未stageの変更は見ず，staged changes のみを対象にする
# =========================================

set -euo pipefail

# Git ルートへ移動
cd "$(git rev-parse --show-toplevel)"

# staged changes がなければ終了
if git diff --cached --quiet; then
  echo "staged changes がありません"
  exit 1
fi

# staged ファイル一覧を取得
staged_files="$(git diff --cached --name-only)"
added_files="$(git diff --cached --diff-filter=A --name-only)"

# 判定用フラグ
has_readme=0
docs_only=1
has_lua=0
has_shell=0
count=0

# staged ファイルを1つずつ確認
while IFS= read -r f; do
  [ -z "$f" ] && continue
  count=$((count + 1))

  case "$f" in
    README.md) has_readme=1 ;;
  esac

  case "$f" in
    *.md|*.txt) ;;
    *) docs_only=0 ;;
  esac

  case "$f" in
    *.lua|init.lua|.luarc.json) has_lua=1 ;;
  esac

  case "$f" in
    *.sh) has_shell=1 ;;
  esac
done <<EOF
$staged_files
EOF

# コミットメッセージを簡易生成
if [ "$docs_only" -eq 1 ]; then
  if [ "$has_readme" -eq 1 ] && [ "$count" -eq 1 ]; then
    echo "docs: READMEを更新"
  else
    echo "docs: 文書を更新"
  fi
  exit 0
fi

if [ "$has_lua" -eq 1 ]; then
  echo "chore: Neovim設定を更新"
  exit 0
fi

if [ "$has_shell" -eq 1 ] && [ -z "$added_files" ]; then
  echo "chore: スクリプトを更新"
  exit 0
fi

if [ -n "$added_files" ]; then
  echo "feat: 機能を追加"
  exit 0
fi

echo "chore: 各種設定を更新"
