---
name: accept
description: Accept drafted artifacts after explicit human approval — PRD requirements, a spec, @draft scenarios, or a Proposed ADR — and record the decision.
argument-hint: "<IDs to accept, e.g. SPEC-003 or ADR-0002 or PRD-004>"
disable-model-invocation: true
---

The human is accepting: $ARGUMENTS

Running this command is the human's approval for exactly these IDs, nothing more.

1. **Summarize.** For each ID, show what will become normative: the rules, scenarios (with their Given/When/Then), requirement text, or decision. Point out anything still marked as an open question, ambiguity, or reviewer finding. If something is unresolved, ask whether to accept anyway before editing.
2. **Check consistency.** A spec may be accepted only if the requirements it relies on are accepted (or are being accepted now). Scenarios may be accepted only for accepted rules. Report any violation instead of working around it.
3. **Apply.**
   - **Spec:** `Status: Accepted`, plus `Approved-by` and `Approved-on` (today's date).
   - **Scenarios:** remove `@draft` from the accepted feature, rules, or scenarios only.
   - **ADR:** `Status: Accepted` and approval fields. If it supersedes an ADR, set that ADR's status to `Superseded by ADR-NNNN`. Update the index in `docs/architecture/adr/README.md`.
   - **PRD requirement:** set its Status column to `Accepted`.
   
   The guard hook will ask for confirmation on each edit. That is expected.
4. **Record.** Append one entry to `docs/DECISION-LOG.md` using the format in that file. "Approved by" is the human who ran this command, via `/accept` in this conversation.
5. **Verify.** Run `tools/trace.sh matrix` and `tools/trace.sh check`. Report the new errors and warnings, e.g. accepted rules now needing implementation.
6. **Report** what is now accepted, by ID, and what work it unblocks.
