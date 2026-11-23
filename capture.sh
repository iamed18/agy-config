#!/bin/sh
# Capture live AGY + uv config changes from $HOME back into this repo.
set -eu

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

echo "==> Capturing AGY global rules and hooks"
if [ -d "$HOME/.gemini/config/rules" ]; then
    mkdir -p "$REPO_DIR/agy/rules"
    for f in "$HOME/.gemini/config/rules"/*.md; do
        [ -e "$f" ] || continue
        cp "$f" "$REPO_DIR/agy/rules/$(basename "$f")"
    done
fi
if [ -f "$HOME/.gemini/config/hooks.json" ]; then
    cp "$HOME/.gemini/config/hooks.json" "$REPO_DIR/agy/hooks.json"
fi
if [ -f "$HOME/.local/bin/agy-secret-guard" ]; then
    mkdir -p "$REPO_DIR/bin"
    install -m 0755 "$HOME/.local/bin/agy-secret-guard" "$REPO_DIR/bin/agy-secret-guard"
fi
if [ -d "$HOME/.config/git/hooks" ]; then
    mkdir -p "$REPO_DIR/git-hooks"
    for hook in pre-commit commit-msg pre-push; do
        if [ -f "$HOME/.config/git/hooks/$hook" ]; then
            install -m 0755 "$HOME/.config/git/hooks/$hook" "$REPO_DIR/git-hooks/$hook"
        fi
    done
fi

echo "==> Capturing AGY global skills"
if [ -d "$HOME/.gemini/config/skills" ]; then
    mkdir -p "$REPO_DIR/agy/skills"
    for d in "$HOME/.gemini/config/skills"/*; do
        [ -d "$d" ] || continue
        name=$(basename "$d")
        rm -rf "$REPO_DIR/agy/skills/$name"
        cp -R "$d" "$REPO_DIR/agy/skills/$name"
    done
fi

echo "==> Capturing AGY global agents"
if [ -d "$HOME/.gemini/config/agents" ]; then
    mkdir -p "$REPO_DIR/agy/agents"
    for entry in "$HOME/.gemini/config/agents"/*; do
        [ -e "$entry" ] || continue
        name=$(basename "$entry")
        if [ -d "$entry" ]; then
            rm -rf "$REPO_DIR/agy/agents/$name"
            cp -R "$entry" "$REPO_DIR/agy/agents/$name"
        elif [ -f "$entry" ]; then
            cp "$entry" "$REPO_DIR/agy/agents/$name"
        fi
    done
fi

echo "==> Capturing uv.toml and global Python version"
if [ -f "$HOME/.config/uv/uv.toml" ]; then
    cp "$HOME/.config/uv/uv.toml" "$REPO_DIR/uv/uv.toml"
fi
if [ -f "$HOME/.config/uv/.python-version" ]; then
    cp "$HOME/.config/uv/.python-version" "$REPO_DIR/manifests/python-version.txt"
fi

echo "==> Capture complete. Repo status:"
git -C "$REPO_DIR" status -s
