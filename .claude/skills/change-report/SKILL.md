---
name: change-report
description: Produce the final change report required by AGENTS.md §8 for the current work — behavior, IDs, documents changed, checks run, risks, pending approvals. Use at the end of any meaningful change or before opening a PR.
argument-hint: "[optional base ref, default: merge-base with main]"
---

Write the AGENTS.md §8 change report for the current work. Base ref: $ARGUMENTS (default: `git merge-base HEAD main`, falling back to `HEAD`).

Gather evidence first; do not report from memory.

1. `git diff --stat <base>` and `git status` for the changed files. Classify each changed file per AGENTS.md §3.1: normative, draft, descriptive, code, test.
2. For each normative change, find its entry in `docs/DECISION-LOG.md`. Flag any normative change **without** an entry.
3. Run `tools/trace.sh check` and the project's test and Gherkin commands (`tests/README.md`). Record exact commands and outcomes. If a check cannot run, say "not run" and why.

Then report in this structure, in plain language, with IDs:

- **Behavior:** what now works, mapped to PRD → SPEC rules → scenarios.
- **Normative changes:** each with its approval and log entry, or flagged as missing.
- **Draft and descriptive changes:** specs, ADRs, scenarios, and map files created, changed, or deleted.
- **Code:** significant files and modules.
- **Architecture/contracts:** impact; ADRs proposed.
- **Checks:** passed / failed / not run, with commands.
- **Unverified properties and risks.**
- **Waiting for the human:** decisions and approvals needed, as a numbered list.
