# agy-config

Declarative, idempotent global configuration for Antigravity (AGY) and `uv`-based Python environments on macOS.

## What this configures
- **`uv` + managed Python (`3.13`)**: Installed to `~/.local/bin` and `~/.local/share/uv/python`, with `only-managed`, `python-downloads = "manual"`, APFS `link-mode = "clone"`, and `compile-bytecode = false` in `~/.config/uv/uv.toml`.
- **Agent shell `PATH` & quiet output**: Managed block in `~/.zshenv` puts `~/.local/bin` on `PATH` for non-interactive agent shells and sets `UV_NO_PROGRESS=1`.
- **Pre-installed CLI tools** (`manifests/uv-tools.txt`): `ruff`, `mypy` installed via `uv tool install`.
- **Pre-warmed offline package cache** (`manifests/uv-prewarm.txt`): Warmed via `bin/uv-warm` in both universal project mode (`uv add`) and script mode (`uv run --no-project --with`) so sandboxed offline runs work on the first turn.
- **Automated weekly cleanup**: `bin/uv-prune` + `launchd` user agent (`com.local.uv-prune`, Sundays 03:00) prunes `~/.cache/uv` and removes scratch `.venv` folders untouched for >30 days.
- **Global AGY customizations**:
  - `agy/rules/python-uv.md` → `~/.gemini/config/rules/python-uv.md` (`always_on`)
  - `agy/rules/vcs-commit-attribution.md` → `~/.gemini/config/rules/vcs-commit-attribution.md` (`always_on`)
  - `agy/rules/flash-delegation.md` → `~/.gemini/config/rules/flash-delegation.md` (`always_on`)
  - `agy/skills/agy-config-sync/SKILL.md` → `~/.gemini/config/skills/agy-config-sync/SKILL.md`
  - `agy/skills/flash-delegation/SKILL.md` → `~/.gemini/config/skills/flash-delegation/SKILL.md`

## Fresh machine onboarding

```sh
git clone https://github.com/iamed18/agy-config.git ~/.agy-config
cd ~/.agy-config
./bootstrap.sh
```

`bootstrap.sh` is idempotent: it installs `uv` (if missing), runs `./apply.sh`, installs the pinned Python and CLI tools, pre-warms the offline package cache, and runs `./verify.sh`.

## Updating config over time

| Task | Command |
|---|---|
| Pull remote updates & apply locally (offline-safe) | `git pull && ./apply.sh` |
| Capture live changes from `~/.gemini/config/{rules,skills}` & `~/.config/uv/uv.toml` into this repo | `./capture.sh && git diff` |
| Add a new pre-warmed package | Append to `manifests/uv-prewarm.txt`, run `uv-warm <pkg>`, update `agy/rules/python-uv.md`, then `./apply.sh` |
| Add a new global CLI tool | Append to `manifests/uv-tools.txt`, run `uv tool install <tool>`, update `agy/rules/python-uv.md`, then `./apply.sh` |
| Re-run offline verification | `./verify.sh` |

You can also ask AGY directly (e.g. *"sync my global config to agy-config"* or *"add polars to agy-config prewarm"*), which triggers the `agy-config-sync` skill.
