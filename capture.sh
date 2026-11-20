#!/bin/sh
# Capture live AGY + uv config changes from $HOME back into this repo.
set -eu

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

echo "==> Capturing AGY global rules"
if [ -d "$HOME/.gemini/config/rules" ]; then
    mkdir -p "$REPO_DIR/agy/rules"
    for f in "$HOME/.gemini/config/rules"/*.md; do
        [ -e "$f" ] || continue
        cp "$f" "$REPO_DIR/agy/rules/$(basename "$f")"
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

echo "==> Capturing uv.toml and global Python version"
if [ -f "$HOME/.config/uv/uv.toml" ]; then
    cp "$HOME/.config/uv/uv.toml" "$REPO_DIR/uv/uv.toml"
fi
if [ -f "$HOME/.config/uv/.python-version" ]; then
    cp "$HOME/.config/uv/.python-version" "$REPO_DIR/manifests/python-version.txt"
fi

echo "==> Capture complete. Repo status:"
git -C "$REPO_DIR" status -s
