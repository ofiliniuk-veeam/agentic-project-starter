---
name: spec
description: Draft or revise a feature specification (Infra-style, with rule IDs) and its @draft Gherkin scenarios before implementing significant behavior. Use when new behavior is requested or existing behavior must change.
argument-hint: "<feature description or SPEC-NNN to revise>"
---

Draft a specification for: $ARGUMENTS

1. **Understand.** Read `docs/product/PRD.md`, `docs/glossary.md`, related ADRs, contracts, existing specs and features, and the relevant code. Note which `PRD-NNN` requirements this serves. If none fits, say so; adding a requirement is a PRD change and needs the human (AGENTS.md §3).
2. **Choose the ID.** New spec: run `tools/trace.sh next spec` and copy `specs/000-template.md` to `specs/NNN-slug.md`. Revising an **accepted** spec: do not edit it yet. Write the proposed change as a diff in your reply and follow AGENTS.md §3.2. For an accepted spec, mark new rules `[draft]`, and only after approval.
3. **Write the spec** following `docs/standards/specification-style.md`.
   - Infra data types for definitions.
   - One checkable obligation per `- **SPEC-NNN-Rn:**` rule.
   - Numbered Infra-style algorithms for nontrivial behavior.
   - Explicit invariants, failures with reason codes, and boundaries.
   
   Put new domain terms in `docs/glossary.md`.
4. **Illustrate.** Create `features/NNN-slug.feature` from the template, with `@draft` at the feature level.
   - One `Rule:` block per rule, tagged `@SPEC-NNN-Rn`.
   - One `@SPEC-NNN-Snn` ID per scenario.
   - Cover success, rejection, boundary, and failure cases as risk warrants.
   - Rules that Gherkin cannot express well get a planned `verifies:` test instead; name it in the spec's Verification section.
5. **Review.** Run the `spec-reviewer` subagent on the spec and feature file. Fix clear defects; list the rest as open questions.
6. **Trace.** Run `tools/trace.sh matrix` and `tools/trace.sh check`, and fix any errors you introduced.
7. **Report** to the human:
   - the rules and scenarios drafted, by ID;
   - open questions and ambiguities that need their decision;
   - the reviewer's unresolved findings;
   - that acceptance happens via `/accept`.
   
   Do not implement until the human accepts.
