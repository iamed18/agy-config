#!/bin/sh
# Idempotently deploy tracked AGY + uv config files to $HOME (no network required).
# Usage: ./apply.sh [--skip-launchd]
set -eu

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SKIP_LAUNCHD=0
for arg in "$@"; do
    case "$arg" in
        --skip-launchd) SKIP_LAUNCHD=1 ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

echo "==> Deploying uv config"
mkdir -p "$HOME/.config/uv"
cp "$REPO_DIR/uv/uv.toml" "$HOME/.config/uv/uv.toml"

echo "==> Installing helper scripts to ~/.local/bin"
mkdir -p "$HOME/.local/bin"
install -m 0755 "$REPO_DIR/bin/uv-warm" "$HOME/.local/bin/uv-warm"
install -m 0755 "$REPO_DIR/bin/uv-prune" "$HOME/.local/bin/uv-prune"
if [ -f "$REPO_DIR/bin/agy-secret-guard" ]; then
    install -m 0755 "$REPO_DIR/bin/agy-secret-guard" "$HOME/.local/bin/agy-secret-guard"
fi

echo "==> Updating managed block in ~/.zshenv"
BEGIN_MARK="# >>> agy-config >>>"
END_MARK="# <<< agy-config <<<"
ZSHENV="$HOME/.zshenv"
TMP_ZSHENV=$(mktemp "${TMPDIR:-/tmp}/zshenv.XXXXXX")
trap 'rm -f "$TMP_ZSHENV"' EXIT

if [ -f "$ZSHENV" ]; then
    awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
        $0 == b { skip = 1; next }
        $0 == e { skip = 0; next }
        !skip { print }
    ' "$ZSHENV" > "$TMP_ZSHENV"
fi

{
    cat "$TMP_ZSHENV"
    printf '%s\n' "$BEGIN_MARK"
    cat "$REPO_DIR/shell/zshenv"
    printf '%s\n' "$END_MARK"
} > "$ZSHENV"

echo "==> Deploying AGY global rules, hooks, skills, and agents"
mkdir -p "$HOME/.gemini/config/rules" "$HOME/.gemini/config/skills" "$HOME/.gemini/config/agents"
if [ -f "$REPO_DIR/agy/hooks.json" ]; then
    cp "$REPO_DIR/agy/hooks.json" "$HOME/.gemini/config/hooks.json"
fi
if [ -d "$REPO_DIR/agy/rules" ]; then
    for f in "$REPO_DIR"/agy/rules/*.md; do
        [ -e "$f" ] || continue
        cp "$f" "$HOME/.gemini/config/rules/$(basename "$f")"
    done
fi
if [ -d "$REPO_DIR/agy/skills" ]; then
    for d in "$REPO_DIR"/agy/skills/*; do
        [ -d "$d" ] || continue
        name=$(basename "$d")
        rm -rf "$HOME/.gemini/config/skills/$name"
        cp -R "$d" "$HOME/.gemini/config/skills/$name"
    done
fi
if [ -d "$REPO_DIR/agy/agents" ]; then
    for entry in "$REPO_DIR"/agy/agents/*; do
        [ -e "$entry" ] || continue
        name=$(basename "$entry")
        if [ -d "$entry" ]; then
            rm -rf "$HOME/.gemini/config/agents/$name"
            cp -R "$entry" "$HOME/.gemini/config/agents/$name"
        elif [ -f "$entry" ]; then
            cp "$entry" "$HOME/.gemini/config/agents/$name"
        fi
    done
fi

if [ -d "$REPO_DIR/git-hooks" ]; then
    echo "==> Deploying global git hooks (~/.config/git/hooks)"
    mkdir -p "$HOME/.config/git/hooks"
    for hook in "$REPO_DIR"/git-hooks/*; do
        [ -f "$hook" ] || continue
        install -m 0755 "$hook" "$HOME/.config/git/hooks/$(basename "$hook")"
    done
    git config --global core.hooksPath "$HOME/.config/git/hooks"
fi

if [ "$(uname -s)" = "Darwin" ]; then
    echo "==> Rendering launchd plist"
    PLIST_DEST="$HOME/Library/LaunchAgents/com.local.uv-prune.plist"
    mkdir -p "$HOME/Library/LaunchAgents"
    sed "s|__HOME__|$HOME|g" "$REPO_DIR/launchd/com.local.uv-prune.plist.tmpl" > "$PLIST_DEST"

    if [ "$SKIP_LAUNCHD" -eq 0 ]; then
        UID_NUM=$(id -u)
        echo "==> Loading launchd agent com.local.uv-prune (gui/$UID_NUM)"
        launchctl bootout "gui/$UID_NUM/com.local.uv-prune" 2>/dev/null || true
        launchctl bootstrap "gui/$UID_NUM" "$PLIST_DEST"
    else
        echo "==> Skipping launchctl load (--skip-launchd)"
    fi
else
    echo "==> Non-macOS host detected; skipping launchd setup"
fi

echo "==> apply.sh complete"
