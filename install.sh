#!/usr/bin/env bash
set -euo pipefail

# claude-code-skills のインストーラ。
# commands/ を ~/.claude/commands/ へ、skills/ を ~/.claude/skills/ へコピーする。
# 同名ファイル/ディレクトリがある場合は上書き前に確認する。

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_DEST="$HOME/.claude/commands"
SKILLS_DEST="$HOME/.claude/skills"

mkdir -p "$COMMANDS_DEST" "$SKILLS_DEST"

confirm_overwrite() {
  local target="$1"
  if [ -e "$target" ]; then
    read -r -p "既に存在します: $target を上書きしますか？ [y/N] " reply
    case "$reply" in
      [yY]*) return 0 ;;
      *) return 1 ;;
    esac
  fi
  return 0
}

echo "== コマンドをインストール ($COMMANDS_DEST) =="
for f in "$REPO_DIR"/commands/*.md; do
  name="$(basename "$f")"
  dest="$COMMANDS_DEST/$name"
  if confirm_overwrite "$dest"; then
    cp "$f" "$dest"
    echo "  ✓ $name"
  else
    echo "  - $name をスキップ"
  fi
done

echo "== スキルをインストール ($SKILLS_DEST) =="
for d in "$REPO_DIR"/skills/*/; do
  name="$(basename "$d")"
  dest="$SKILLS_DEST/$name"
  if confirm_overwrite "$dest"; then
    rm -rf "$dest"
    cp -r "$d" "$dest"
    echo "  ✓ $name"
  else
    echo "  - $name をスキップ"
  fi
done

echo "完了しました。"
