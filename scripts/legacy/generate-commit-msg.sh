#!/bin/zsh

# =========================================
# generate-commit-msg.sh
# 変更ファイルの種類と操作内容から，
# Conventional Commits 風のコミットメッセージを1行生成する
#
# コマンド
# 使い方:
#   ~/.config/nvim/scripts/generate-commit-msg.sh
# 権限が必要なとき:
#   chmod +x ~/.config/nvim/scripts/generate-commit-msg.sh
#
# 想定:
# - LazyGit customCommands から呼ぶ
# - staged changes を優先
# - staged がなければ unstaged changes にフォールバック
# =========================================

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# staged を優先，なければ unstaged を使う
if ! git diff --cached --quiet; then
  changes="$(git diff --cached --name-status)"
  files="$(git diff --cached --name-only)"
elif ! git diff --quiet; then
  changes="$(git diff --name-status)"
  files="$(git diff --name-only)"
else
  echo "変更がありません"
  exit 1
fi

# 件数
count="$(printf '%s\n' "$files" | sed '/^$/d' | wc -l | tr -d ' ')"

# フラグ
has_readme=0
has_docs=0
has_ci=0
has_build=0
has_config=0
has_script=0
has_lua=0
has_code=0

has_added=0
has_deleted=0
has_renamed=0
has_modified=0

first_target=""

# 変更種別判定
while IFS=$'\t' read -r git_status path1 path2; do
  [ -z "${git_status:-}" ] && continue

  case "$git_status" in
    A*) has_added=1; target="$path1" ;;
    D*) has_deleted=1; target="$path1" ;;
    R*) has_renamed=1; target="${path2:-$path1}" ;;
    M*|C*) has_modified=1; target="$path1" ;;
    *) target="$path1" ;;
  esac

  [ -z "$first_target" ] && first_target="$target"
done <<EOF
$changes
EOF

# パス種別判定
while IFS= read -r f; do
  [ -z "$f" ] && continue

  case "$f" in
    README.md|*/README.md) has_readme=1; has_docs=1 ;;
    docs/*|*.md|*.txt) has_docs=1 ;;
  esac

  case "$f" in
    .github/*|.gitlab-ci.yml|.circleci/*) has_ci=1 ;;
  esac

  case "$f" in
    package.json|package-lock.json|pnpm-lock.yaml|yarn.lock|Makefile|Dockerfile|docker-compose.yml|docker-compose.yaml|*.toml)
      has_build=1
      ;;
  esac

  case "$f" in
    *.json|*.yaml|*.yml|*.toml|*.ini|*.conf)
      has_config=1
      ;;
  esac

  case "$f" in
    scripts/*|*.sh)
      has_script=1
      ;;
  esac

  case "$f" in
    *.lua|init.lua|lua/*)
      has_lua=1
      has_code=1
      ;;
    *.py|*.js|*.ts|*.tsx|*.jsx|*.c|*.cpp|*.h|*.java|*.rs|*.go)
      has_code=1
      ;;
  esac
done <<EOF
$files
EOF

# prefix 推定
prefix="chore"

if [ "$has_ci" -eq 1 ]; then
  prefix="ci"
elif [ "$has_build" -eq 1 ]; then
  prefix="build"
elif [ "$has_docs" -eq 1 ] && [ "$has_code" -eq 0 ] && [ "$has_script" -eq 0 ] && [ "$has_lua" -eq 0 ]; then
  prefix="docs"
elif [ "$has_added" -eq 1 ] && [ "$has_code" -eq 1 ]; then
  prefix="feat"
elif [ "$has_code" -eq 1 ] || [ "$has_script" -eq 1 ] || [ "$has_lua" -eq 1 ]; then
  prefix="chore"
elif [ "$has_config" -eq 1 ]; then
  prefix="chore"
fi

# scope 推定
scope=""
if [ "$has_lua" -eq 1 ]; then
  scope="(nvim)"
elif [ "$has_script" -eq 1 ]; then
  scope="(scripts)"
elif [ "$has_docs" -eq 1 ] && [ "$has_readme" -eq 1 ]; then
  scope="(readme)"
fi

# 本文生成
subject=""

if [ "$count" -eq 1 ]; then
  base="$(basename "$first_target")"

  if [ "$has_renamed" -eq 1 ]; then
    subject="${base}をリネーム"
  elif [ "$has_deleted" -eq 1 ]; then
    subject="${base}を削除"
  elif [ "$has_added" -eq 1 ]; then
    case "$prefix" in
      docs) subject="${base}を追加" ;;
      feat) subject="${base}を追加" ;;
      *)    subject="${base}を追加" ;;
    esac
  else
    if [ "$has_readme" -eq 1 ]; then
      subject="READMEを更新"
    elif [ "$has_script" -eq 1 ]; then
      subject="${base}を更新"
    elif [ "$has_lua" -eq 1 ]; then
      subject="${base}を更新"
    else
      subject="${base}を更新"
    fi
  fi
else
  if [ "$has_renamed" -eq 1 ]; then
    subject="複数ファイルを整理"
  elif [ "$has_added" -eq 1 ] && [ "$has_script" -eq 1 ]; then
    subject="スクリプトを追加"
  elif [ "$has_readme" -eq 1 ] && [ "$has_script" -eq 1 ]; then
    subject="READMEとスクリプトを更新"
  elif [ "$has_docs" -eq 1 ] && [ "$has_code" -eq 0 ]; then
    subject="文書を更新"
  elif [ "$has_lua" -eq 1 ]; then
    subject="Neovim設定を更新"
  else
    subject="複数ファイルを更新"
  fi
fi

echo "${prefix}${scope}: ${subject}"
