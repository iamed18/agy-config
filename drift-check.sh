#!/bin/sh
# Read-only drift check comparing this host's live AGY + uv config against this repo.
# Exits 0 if in sync, 1 if drift is detected.
set -u

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DRIFT=0

report_drift() {
    printf 'DRIFT: %s\n' "$1"
    DRIFT=1
}

report_ok() {
    printf 'OK:    %s\n' "$1"
}

check_file() {
    label="$1"
    repo_file="$2"
    live_file="$3"
    if [ ! -f "$live_file" ]; then
        report_drift "$label missing on host ($live_file)"
    elif ! cmp -s "$repo_file" "$live_file"; then
        report_drift "$label differs ($live_file vs $repo_file)"
        diff -u "$repo_file" "$live_file" | head -n 40 || true
    else
        report_ok "$label"
    fi
}

echo "=== 1. Git repository state ==="
if [ -n "$(git -C "$REPO_DIR" status --porcelain 2>/dev/null)" ]; then
    report_drift "Uncommitted changes in $REPO_DIR"
    git -C "$REPO_DIR" status -s
else
    report_ok "Working tree clean ($REPO_DIR)"
fi
AHEAD=$(git -C "$REPO_DIR" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
if [ "$AHEAD" -gt 0 ] 2>/dev/null; then
    report_drift "Local branch is $AHEAD commit(s) ahead of upstream"
else
    report_ok "No unpushed local commits"
fi

echo "=== 2. uv config & Python version ==="
check_file "uv.toml" "$REPO_DIR/uv/uv.toml" "$HOME/.config/uv/uv.toml"
check_file ".python-version" "$REPO_DIR/manifests/python-version.txt" "$HOME/.config/uv/.python-version"

echo "=== 3. Helper scripts (~/.local/bin) ==="
check_file "bin/uv-warm" "$REPO_DIR/bin/uv-warm" "$HOME/.local/bin/uv-warm"
check_file "bin/uv-prune" "$REPO_DIR/bin/uv-prune" "$HOME/.local/bin/uv-prune"

echo "=== 4. ~/.zshenv managed block ==="
TMP_BLOCK=$(mktemp "${TMPDIR:-/tmp}/zshenv-block.XXXXXX")
TMP_PLIST=$(mktemp "${TMPDIR:-/tmp}/plist-render.XXXXXX")
trap 'rm -f "$TMP_BLOCK" "$TMP_PLIST"' EXIT

if [ -f "$HOME/.zshenv" ]; then
    awk '
        $0 == "# >>> agy-config >>>" { in_block = 1; next }
        $0 == "# <<< agy-config <<<" { in_block = 0; next }
        in_block { print }
    ' "$HOME/.zshenv" > "$TMP_BLOCK"
    if [ ! -s "$TMP_BLOCK" ]; then
        report_drift "~/.zshenv is missing the managed agy-config block"
    elif ! cmp -s "$REPO_DIR/shell/zshenv" "$TMP_BLOCK"; then
        report_drift "~/.zshenv managed block differs from shell/zshenv"
        diff -u "$REPO_DIR/shell/zshenv" "$TMP_BLOCK" | head -n 40 || true
    else
        report_ok "~/.zshenv managed block"
    fi
else
    report_drift "~/.zshenv does not exist"
fi

echo "=== 5. AGY global rules (~/.gemini/config/rules) ==="
for f in "$REPO_DIR"/agy/rules/*.md; do
    [ -e "$f" ] || continue
    name=$(basename "$f")
    check_file "rule/$name" "$f" "$HOME/.gemini/config/rules/$name"
done
if [ -d "$HOME/.gemini/config/rules" ]; then
    for f in "$HOME/.gemini/config/rules"/*.md; do
        [ -e "$f" ] || continue
        name=$(basename "$f")
        if [ ! -f "$REPO_DIR/agy/rules/$name" ]; then
            report_drift "Untracked global rule on host: $f"
        fi
    done
fi

echo "=== 6. AGY global skills (~/.gemini/config/skills) ==="
for d in "$REPO_DIR"/agy/skills/*; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    live_d="$HOME/.gemini/config/skills/$name"
    if [ ! -d "$live_d" ]; then
        report_drift "skill/$name missing on host ($live_d)"
    elif ! diff -rq "$d" "$live_d" >/dev/null 2>&1; then
        report_drift "skill/$name differs ($live_d vs $d)"
        diff -ru "$d" "$live_d" | head -n 40 || true
    else
        report_ok "skill/$name"
    fi
done
if [ -d "$HOME/.gemini/config/skills" ]; then
    for d in "$HOME/.gemini/config/skills"/*; do
        [ -d "$d" ] || continue
        name=$(basename "$d")
        if [ ! -d "$REPO_DIR/agy/skills/$name" ]; then
            report_drift "Untracked global skill on host: $d"
        fi
    done
fi

echo "=== 7. Global uv CLI tools (manifests/uv-tools.txt) ==="
INSTALLED_TOOLS=$("$HOME/.local/bin/uv" tool list 2>/dev/null | awk '/^[a-zA-Z0-9._-]+ v/ { print $1 }')
while IFS= read -r tool; do
    tool=$(printf '%s' "$tool" | sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//')
    [ -z "$tool" ] && continue
    if printf '%s\n' "$INSTALLED_TOOLS" | grep -qx "$tool"; then
        report_ok "uv tool: $tool"
    else
        report_drift "Manifest tool not installed: $tool"
    fi
done < "$REPO_DIR/manifests/uv-tools.txt"
for inst in $INSTALLED_TOOLS; do
    if ! sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//' "$REPO_DIR/manifests/uv-tools.txt" | grep -qx "$inst"; then
        report_drift "Untracked uv tool installed on host: $inst"
    fi
done

echo "=== 8. launchd plist (macOS) ==="
if [ "$(uname -s)" = "Darwin" ]; then
    sed "s|__HOME__|$HOME|g" "$REPO_DIR/launchd/com.local.uv-prune.plist.tmpl" > "$TMP_PLIST"
    check_file "launchd/com.local.uv-prune.plist" "$TMP_PLIST" "$HOME/Library/LaunchAgents/com.local.uv-prune.plist"
fi

echo "=== 9. Offline verification (verify.sh) ==="
if "$REPO_DIR/verify.sh" >/dev/null 2>&1; then
    report_ok "verify.sh (offline cache & PATH)"
else
    report_drift "verify.sh failed"
fi

echo "=== Summary ==="
if [ "$DRIFT" -eq 0 ]; then
    echo "NO DRIFT DETECTED"
    exit 0
else
    echo "DRIFT DETECTED"
    exit 1
fi
