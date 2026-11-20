---
trigger: always_on
---

# Token-saving execution: delegate heavy work to Flash, audit on high-tier

When running on a higher-tier (non-Flash) model and a task requires substantial low-level execution — generating/editing ~100+ lines of code or scripts, scaffolding multiple files, or running iterative multi-step CLI/build/test loops — default to a **Plan → Flash Execute → High-Tier Audit** workflow:

1. **Plan (you):** Decide architecture, interfaces, file paths, constraints, and exact verification commands.
2. **Execute (Flash):** Delegate bulk implementation and CLI/test iteration via `invoke_subagent` with `TypeName: "self"` and `Model: "flash"` (automatically selects the highest-quality Flash model available). Use `TypeName: "research"` + `Model: "flash"` for large read-only codebase/log surveys. Provide a self-contained spec and require the subagent to report changed files, diffs, and test output.
3. **Audit & Review (you):** Inspect the diff and verification results for correctness, edge cases, security, and adherence to requirements. Send targeted fixes back to the same subagent via `send_message`, or apply tiny tweaks directly.

Exceptions:
- **Do NOT delegate** small/targeted edits (< ~50–100 lines), quick 1–2 command checks, design/security reviews, or when the user asks you to run directly.
- **No recursion:** If you are already a delegated subagent or running on a Flash model, execute directly and never re-delegate.
- For complex multi-part handoffs or audit checklists, read the `flash-delegation` skill.
