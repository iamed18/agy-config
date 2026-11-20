---
name: flash-delegation
description: >-
  Structured playbook for delegating heavy code generation, scripting, and
  multi-step CLI execution to Flash subagents (Model="flash") while reserving
  higher-tier models for planning, auditing, and code review. Use when
  orchestrating a substantial implementation or multi-part Flash handoff.
---

# Flash Delegation & High-Tier Audit Playbook

## 1. Choosing the right subagent
- **Code/script generation, refactors, test/CLI loops:**
  `invoke_subagent(TypeName="self", Model="flash", Role="Flash Implementer", Prompt=...)`
- **Large read-only codebase/log/doc exploration:**
  `invoke_subagent(TypeName="research", Model="flash", Role="Flash Researcher", Prompt=...)`
- **Parallel independent workstreams:**
  Launch multiple Flash subagents with **disjoint file ownership** (default `Workspace="inherit"`), or use `Workspace="share"` if they need isolated working trees.

## 2. Handoff Brief Template
Give the Flash subagent everything it needs to succeed in one pass so you avoid back-and-forth turns:

```text
You are executing an implementation task delegated by a senior reviewer. Do not re-delegate.

Goal:
- <1-2 sentence objective>

Files to create/modify:
- <exact absolute paths>

Requirements & interfaces:
- <function signatures, CLI flags, data schemas, edge cases, constraints>
- <relevant repo conventions / rules>

Verification:
- Run <exact test/lint/smoke commands> and ensure they exit 0.

Report back with:
1. Files created/modified
2. Concise summary of implementation choices or any deviations
3. Exact verification commands run and their output
```

## 3. High-Tier Audit Checklist
When the Flash subagent finishes, perform a focused review before replying to the user:
1. **Inspect the diff:** Read changed files or run `git diff --stat` / `git diff` (do not blindly trust the summary).
2. **Correctness & edge cases:** Verify logic, error handling, types, and boundary conditions against the original spec.
3. **Security & hygiene:** Check for hardcoded paths/secrets, overly broad permissions, or unintended changes outside scope.
4. **Verification proof:** Confirm tests/checks actually ran and cover the new behavior.
5. **Iterate cheaply:** For non-trivial fixes, message the *existing* Flash subagent via `send_message` with exact line-level feedback rather than spawning a new subagent. For 1–5 line tweaks, edit directly.
