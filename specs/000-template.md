# SPEC-NNN: Feature title

Status: Draft
Approved-by: —
Approved-on: —
Related PRD: PRD-NNN
Related ADRs: —
Contracts: —
Feature file: `features/NNN-slug.feature`

> Copy to `specs/NNN-slug.md` (`tools/trace.sh next spec`). Write in the style of `docs/standards/specification-style.md` (Infra terminology and algorithms). Once `Accepted`, every change follows `AGENTS.md` §3.

## Goal and scope

What user-visible capability this spec defines, and its boundaries.

## Definitions

Feature-local terms only; project-wide terms live in `docs/glossary.md`.

A **thing** is a [struct](https://infra.spec.whatwg.org/#struct) with the following items:
- **id**, a string of …

## Normative requirements

- **SPEC-NNN-R1:** The system MUST … (PRD-NNN)
- **SPEC-NNN-R2:** If …, the system MUST NOT … and MUST return failure with reason `"…"`.

Markers on a rule line: `[draft]` (proposed addition to an accepted spec), `[deprecated]`, `[waiver: reason]` (accepted gap in verification).

## Algorithms

To **do the thing**, given a thing *thing*, run these steps:
1. If *thing* …, then return failure with reason `"…"`.
2. Let *result* be …
3. Return *result*.

## Invariants

- At all times, …

## Failure and boundary behavior

| Condition | Observable outcome | Rule |
| --- | --- | --- |

## Observability

What a client or user can determine, and through which interface.

## Verification

- Gherkin: `features/NNN-slug.feature`
- Other (property, concurrency, contract tests): files annotated `verifies: SPEC-NNN-Rn`

## Out of scope and open questions

-
