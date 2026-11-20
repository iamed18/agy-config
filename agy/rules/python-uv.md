---
trigger: always_on
---

# Python: always use uv

`uv`, `uvx`, `ruff`, `mypy`, `uv-warm`, and `uv-prune` are on `PATH` (in `~/.local/bin` via `~/.zshenv`). Managed Python 3.13 is the default (`python-downloads = "manual"`); shared cache is `~/.cache/uv` (pruned weekly by launchd).

- Never use pip, `python -m venv`, virtualenv, conda, or `/usr/bin/python3`.
- One-off script (no project): put deps in a PEP 723 header and run `uv run --offline --no-project script.py`. Quick check: `uv run --offline --no-project --with <pkg> python -c "..."`.
- Project: `uv init` once, `uv add --offline <pkg>`, run with `uv run --offline <cmd>`. Do not activate the venv. Commit `pyproject.toml` and `uv.lock`; gitignore `.venv`.
- Combine *sandboxed* steps in one command where possible (e.g. `uv add --offline x && uv run --offline main.py`).
- The sandbox has no network. Pre-warmed packages work sandboxed with `--offline`: `numpy`, `pandas`, `requests`, `matplotlib`, `pytest`, `scipy`, `httpx`, `pydantic`, `pyyaml`, `beautifulsoup4`, `rich`, `tqdm`.
- For uncached packages, run only that single `uv add <pkg>` (or `uv-warm <pkgs...>`) unsandboxed, then run `uv run --offline ...` sandboxed. Always warm new packages with `uv-warm` (uses `uv add` for universal lock metadata, not `--with`).
- If `~/.cache/uv` is not writable, export `UV_CACHE_DIR=/tmp/uv-cache` and retry.
