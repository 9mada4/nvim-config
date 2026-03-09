#!/bin/zsh

# =========================================
# save-tree.sh
# Neovim設定フォルダの構造を tree で可視化し，
# STRUCTURE.txt に自動保存するためのスクリプト
#
# 使い方:
#   ./scripts/save-tree.sh
#   ./scripts/save-tree.sh ~/.config/nvim
#
# 第1引数を省略した場合は，現在のディレクトリを対象にする
# =========================================

set -e

# 対象フォルダ
# 第1引数があればそれを使い，なければ現在のディレクトリを使う
ROOT="${1:-.}"

# 出力先ファイル
OUT="${ROOT}/STRUCTURE.txt"

# 対象フォルダへ移動
cd "$ROOT"

# tree の結果を STRUCTURE.txt に保存
{
  echo "Project tree"
  echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""

  tree -a \
    -I '.git|node_modules|.DS_Store|lazy-lock.json' \
    --dirsfirst
} > "$OUT"

# 保存完了メッセージ
echo "saved: $OUT"
