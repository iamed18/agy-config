#!/bin/sh
# Offline verification of AGY + uv environment setup.
set -eu

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

echo "==> Checking PATH & binaries"
for bin in uv uvx uv-warm uv-prune; do
    command -v "$bin" >/dev/null 2>&1 || { echo "FAIL: $bin not on PATH" >&2; exit 1; }
done
while IFS= read -r tool; do
    tool=$(printf '%s' "$tool" | sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//')
    [ -z "$tool" ] && continue
    command -v "$tool" >/dev/null 2>&1 || { echo "FAIL: tool $tool not on PATH" >&2; exit 1; }
done < "$REPO_DIR/manifests/uv-tools.txt"

echo "==> Checking uv.toml and AGY customizations"
cmp -s "$REPO_DIR/uv/uv.toml" "$HOME/.config/uv/uv.toml" || {
    echo "FAIL: ~/.config/uv/uv.toml differs from repo uv/uv.toml" >&2
    exit 1
}
[ -f "$HOME/.gemini/config/rules/python-uv.md" ] || { echo "FAIL: missing python-uv.md rule" >&2; exit 1; }
[ -f "$HOME/.gemini/config/skills/agy-config-sync/SKILL.md" ] || { echo "FAIL: missing agy-config-sync skill" >&2; exit 1; }

if [ "$(uname -s)" = "Darwin" ]; then
    [ -f "$HOME/Library/LaunchAgents/com.local.uv-prune.plist" ] || {
        echo "FAIL: missing launchd plist" >&2
        exit 1
    }
fi

echo "==> Testing offline project + PEP 723 script resolution"
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/agy-verify.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT

PKGS=$(sed 's/#.*//' "$REPO_DIR/manifests/uv-prewarm.txt" | tr '\n' ' ')
uv init --directory "$TMP_DIR" --no-readme -q
# shellcheck disable=SC2086
uv add --directory "$TMP_DIR" --offline $PKGS -q
uv run --directory "$TMP_DIR" --offline python -c "import numpy, pandas, scipy, httpx, pydantic; print('offline project ok')"

cat > "$TMP_DIR/oneoff.py" <<'EOF'
# /// script
# requires-python = ">=3.13"
# dependencies = ["scipy", "pydantic", "httpx"]
# ///
import scipy, pydantic, httpx
print("offline script ok:", scipy.__version__, pydantic.__version__, httpx.__version__)
EOF
(cd "$TMP_DIR" && uv run --offline --no-project "$TMP_DIR/oneoff.py")

echo "==> All checks passed!"
