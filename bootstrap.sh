#!/bin/sh
# Full fresh-machine bootstrap for AGY + uv Python environments.
# Safe to re-run (idempotent). Requires network access.
# Usage: ./bootstrap.sh [--skip-launchd] [--no-verify]
set -eu

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
APPLY_ARGS=""
RUN_VERIFY=1

for arg in "$@"; do
    case "$arg" in
        --skip-launchd) APPLY_ARGS="$APPLY_ARGS --skip-launchd" ;;
        --no-verify) RUN_VERIFY=0 ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

export PATH="$HOME/.local/bin:$PATH"

echo "==> Step 1/5: Ensure uv is installed"
if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi
uv --version

echo "==> Step 2/5: Apply tracked config files"
# shellcheck disable=SC2086
"$REPO_DIR/apply.sh" $APPLY_ARGS

echo "==> Step 3/5: Install and pin managed Python"
PY_VER=$(tr -d '[:space:]' < "$REPO_DIR/manifests/python-version.txt")
uv python install "$PY_VER"
uv python pin "$PY_VER" --global

echo "==> Step 4/5: Install global CLI tools"
while IFS= read -r tool; do
    tool=$(printf '%s' "$tool" | sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//')
    [ -z "$tool" ] && continue
    echo "    installing tool: $tool"
    uv tool install "$tool"
done < "$REPO_DIR/manifests/uv-tools.txt"

echo "==> Step 5/5: Pre-warm offline package cache"
PKGS=$(sed 's/#.*//' "$REPO_DIR/manifests/uv-prewarm.txt" | tr '\n' ' ')
if [ -n "$(printf '%s' "$PKGS" | tr -d '[:space:]')" ]; then
    # shellcheck disable=SC2086
    "$HOME/.local/bin/uv-warm" $PKGS
fi

if [ "$RUN_VERIFY" -eq 1 ]; then
    echo "==> Running offline verification"
    "$REPO_DIR/verify.sh"
fi

echo "==> bootstrap.sh complete"
