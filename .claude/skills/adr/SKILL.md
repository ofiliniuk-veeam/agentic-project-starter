---
name: adr
description: Propose an Architecture Decision Record for a material technical decision (stack, runner, boundaries, infrastructure, security posture), or supersede an existing one.
argument-hint: "<decision to record, or ADR-NNNN to supersede>"
---

Propose an ADR for: $ARGUMENTS

1. Read `docs/architecture/adr/README.md`, the existing ADRs, the PRD constraints, and the affected specs and contracts. Check that the decision is material. Local, reversible implementation choices do not need an ADR; say so and stop.
2. Run `tools/trace.sh next adr`, copy `docs/architecture/adr/0000-template.md` to `docs/architecture/adr/NNNN-slug.md`, and keep `Status: Proposed`.
3. Fill every section with evidence.
   - Name at least two realistic alternatives.
   - Label unverified claims as assumptions.
   - Never invent historical motivation.
   - Give concrete "Revisit when" triggers.
4. If this supersedes an accepted ADR, set `Supersedes: ADR-NNNN` in the new ADR. Do **not** edit the old ADR yet; its status change happens on acceptance (AGENTS.md §3.2).
5. Add a row to the index in `docs/architecture/adr/README.md` and run `tools/trace.sh matrix`.
6. Present the decision, trade-offs, and the question the human must answer. Acceptance happens via `/accept ADR-NNNN`.
