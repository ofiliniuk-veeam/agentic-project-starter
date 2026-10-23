# How We Work

Status: Accepted

This project is built with Claude Code. The human owns intent and agents write the code:

- **PRD and ADRs** are mandatory. Agents maintain them, and every change to intent goes through human approval and the decision log.
- **Specifications** use the language of the [WHATWG Infra Standard](https://infra.spec.whatwg.org/) (`specification-style.md`).
- **Gherkin** scenarios are the primary format for describing and checking behavior.
- **The project map** (requirements → rules → scenarios → tests → code, plus architecture and flows) can be regenerated at any moment (`traceability.md`, `/map`).

Agent rules are in `AGENTS.md`, which `CLAUDE.md` imports.

## Feature cycle

`/spec` → `spec-reviewer` → `/accept` → implement → `/map` → `/change-report`

## Where things live

| Path | Purpose |
| --- | --- |
| `AGENTS.md` | Agent rules: sources of truth, change control, workflow, verification, reporting |
| `CLAUDE.md` | Imports `AGENTS.md` for Claude Code; keep project rules in `AGENTS.md` |
| `docs/product/PRD.md` | Requirements `PRD-NNN` |
| `docs/architecture/adr/` | Decisions `ADR-NNNN` and their index |
| `docs/architecture/overview.md` | Architecture as it is (C4), with evidence labels |
| `docs/contracts/` | Externally relied-upon interfaces and compatibility rules |
| `docs/glossary.md` | Domain vocabulary |
| `docs/standards/` | This guide, spec style (Infra), IDs and traceability |
| `docs/map/` | Project map: generated traceability matrix, runtime flows |
| `docs/DECISION-LOG.md` | Append-only record of approved normative changes |
| `specs/` | Feature specs with rules `SPEC-NNN-Rn` |
| `features/` | Gherkin scenarios `@SPEC-NNN-Snn`; `@draft` until accepted |
| `tests/` | Step definitions and tests |
| `tools/trace.sh` | Traceability check, matrix generator, next-ID helper |
| `.claude/` | Guardrail hooks, skills (`/spec`, `/adr`, `/accept`, `/map`, `/change-report`), `spec-reviewer` subagent |

## How the human stays informed

- **Before a change.** The guard hook asks for confirmation before any edit to a normative artifact, including removing `@draft` or changing a status.
- **After each agent turn.** The stop hook lists normative files changed since the last report. If accepted material changed without a decision-log entry, it sends the agent back once.
- **In history.** `docs/DECISION-LOG.md` records who approved what and why; git records the diff.
- **At merge**, once CI is set up: `tools/trace.sh check` and the Gherkin runner gate merges.

## New project setup

1. Copy the starter without its history:

   ```sh
   git clone --depth 1 <starter-url> my-project && cd my-project
   rm -rf .git && git init -b main
   ```

   Alternatively, create the repository from it as a template on the Git host.
2. Replace `README.md` placeholders with the project name and description.
3. Install `jq`. The guard hook falls back to conservative prompts without it.
4. Start Claude Code in the project and approve the project hooks if asked (`/hooks`).
5. Fill `docs/product/PRD.md` with the product owner and accept the first requirements.
6. Have the agent propose the early ADRs listed in `docs/architecture/adr/README.md` (stack, Gherkin runner, CI). Accept them with `/accept`.
7. Wire the Gherkin runner per `tests/README.md`. When CI is set up, run it and `tools/trace.sh check` as merge gates.

## Deliberately not included

- No language, framework, app skeleton, or deployment infrastructure.
- No Gherkin runner or step definitions until the stack is chosen.
- No CI that pretends to run tests.
- No accepted requirements or scenarios.
