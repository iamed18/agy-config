---
name: agy-config-sync
description: >-
  Manage, update, capture, and verify the user's global Antigravity (AGY) and uv
  configuration repository (iamed18/agy-config). Use when the user asks to save
  or sync global rules/skills/uv settings to agy-config, add pre-warmed Python
  packages or global CLI tools, or re-deploy config on this machine.
---

# Syncing Global AGY Configuration (`agy-config`)

## 1. Locate the local checkout
Check in order:
1. `~/.agy-config`
2. `~/.gemini/antigravity/scratch/agy-config`

If neither exists, ask the user where they want it cloned (`https://github.com/iamed18/agy-config`).

## 2. Common workflows

### Capture live machine changes into the repo
When the user has edited or added global rules (`~/.gemini/config/rules/`), global skills (`~/.gemini/config/skills/`), or `~/.config/uv/uv.toml`:
1. Run `./capture.sh` inside the `agy-config` repo.
2. Run `git status` and `git diff` to review every change.
3. Commit with a clear message (push to `origin` only when the user asks).

### Add a pre-warmed Python package
1. Append the package name to `manifests/uv-prewarm.txt`.
2. Add it to the pre-warmed list in `agy/rules/python-uv.md`.
3. Run `uv-warm <pkg>` (requires network, so run that single command unsandboxed).
4. Run `./apply.sh` and `./verify.sh` (sandboxed).

### Add a global Python CLI tool
1. Append the tool name to `manifests/uv-tools.txt`.
2. Update `agy/rules/python-uv.md` if agents should know it is on `PATH`.
3. Run `uv tool install <tool>` (unsandboxed).
4. Run `./apply.sh` and `./verify.sh` (sandboxed).

### Apply repo changes to this machine
- Config files (`rules`, `skills`, `uv.toml`, `~/.zshenv`, `bin/`, `launchd`):
  run `./apply.sh` (requires unsandboxed execution if updating `~/.gemini/config/` or `launchd`; inside the sandbox, you can write `~/.gemini/config/` files via `write_file` and verify with `./verify.sh`).
- Full bootstrap including network installs:
  run `./bootstrap.sh` (unsandboxed).

## 3. Validation
Always run `./verify.sh` (sandboxed) after modifying config or manifests to confirm `PATH`, `uv.toml`, CLI tools, and offline project + PEP 723 script resolution all pass.
