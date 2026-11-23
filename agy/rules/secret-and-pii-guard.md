---
trigger: always_on
---

# Secret, `.env`, and PII Leak Prevention

Whenever writing code, configs, docs, tests, or git commit/tag messages in any repository attached to a remote origin (`git remote` is non-empty):

- **Never reproduce any part of `.env`:** Do not copy, quote, or reuse API keys, secrets, webhook URLs/IDs/tokens, custom user-agents, or non-credential `.env` settings (such as compliance/restricted-trading ticker lists) into tracked files, examples, tests, or commit messages. Use clearly synthetic placeholders (e.g., `ACME`, `ops@example.com`, `123456789012345678`).
- **Never hardcode host or private org PII:** Do not commit the local OS username, home/checkout paths (`/Users/<user>`, `/home/<user>`), local machine hostname, or private chat/Discord server or channel names into code, deployment manifests, docs, tests, or commit messages.
  - Resolve OS users dynamically at runtime (`getpass.getuser()`, `$SUDO_USER`, `$HOME`) or stamp committed templates (`__RUN_USER__`, `__HOME__`) into gitignored local files at install time.
- **Never stage secrets or local state:** Never stage `.env` (except `.env.example`/`.env.sample`), private keys (`*.pem`, `*.key`), local databases (`*.db`, `*.sqlite*`), or host-rendered service plists.
- **Respect `agy-secret-guard`:** Both Antigravity's global `PreToolUse` hook (`~/.gemini/config/hooks.json`) and global Git hooks (`~/.config/git/hooks/`) run `~/.local/bin/agy-secret-guard` on `git commit`, `git push`, and `git tag` in remote-attached repos. Never bypass it (`--no-verify` or `AGY_SECRET_GUARD_BYPASS=1`) unless the user explicitly inspects and authorizes a verified false positive.
- **Keep private denylists local:** Store machine-specific sensitive terms (private server/channel names, employer/restricted tickers) strictly in `~/.config/agy-secret-guard/denylist.txt` (`chmod 600`, untracked), never inside shared rules or `agy-config`.
