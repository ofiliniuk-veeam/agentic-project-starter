# Agent Engineering Rules

This project uses **specification-driven agentic engineering**. Agents plan, implement, test, refactor, and document autonomously **within** accepted product intent, architectural decisions, contracts, and specified behavior. The human owner controls intent and is informed of every change to it.

Optimize for correct, maintainable, verifiable outcomes, not volume of code or the appearance of passing checks.

The key words MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY are interpreted as described in BCP 14 (RFC 2119, RFC 8174) when, and only when, they appear in all capitals.

## 1. Sources of truth

| Artifact | Class | Authority |
| --- | --- | --- |
| `docs/product/PRD.md` | Normative | Product goals, requirements `PRD-NNN`, scope |
| `docs/architecture/adr/` | Normative once `Accepted` | Decisions `ADR-NNNN`, rationale, alternatives, consequences |
| `docs/contracts/` | Normative | Schemas, APIs, protocols, error codes, invariants |
| `specs/` | Normative once `Accepted` | Feature behavior rules `SPEC-NNN-Rn` |
| `features/` | Normative unless `@draft` | Gherkin examples `SPEC-NNN-Snn` of required behavior |
| `docs/glossary.md` | Normative | Domain vocabulary |
| `docs/standards/` | Normative | How specs, Gherkin, IDs, and traces are written |
| `docs/architecture/overview.md`, `docs/map/` | Descriptive | The system as it actually is; the project map |
| `README.md` | Descriptive | Project entry point: what it is, how to build and run it |
| `docs/DECISION-LOG.md` | Record | Append-only history of approved normative changes |
| Source code | Descriptive | What actually runs; may deviate from intent |
| Tests / CI | Evidence | Checked properties only, never proof of total correctness |

Precedence when they conflict: PRD > accepted ADRs and contracts > accepted specs > accepted scenarios > code and tests. Gherkin examples illustrate rules; they do not replace them.

Do not silently resolve contradictions. Report the conflict, name the affected IDs and files, and ask for a decision.

## 2. Standards

- How humans and agents work together, and project setup: `docs/standards/workflow.md`.
- Specs are written in the language of the [Infra Standard](https://infra.spec.whatwg.org/): `docs/standards/specification-style.md`.
- IDs, statuses, and annotations: `docs/standards/traceability.md`. Every new rule, scenario, and implementation MUST be traceable as defined there.
- Code that implements a rule carries an `implements: SPEC-NNN-Rn` comment. Tests that check a rule outside Gherkin carry `verifies: SPEC-NNN-Rn`.

## 3. Change control

The human MUST always know about every change to intent. This section defines how.

### 3.1 What agents may change

| Artifact state | Agent may | Requirements |
| --- | --- | --- |
| Descriptive (`README.md`, `overview.md`, `docs/map/`, code comments) | Create, update, delete | Keep them true to the code; list updates in the final report |
| Draft (`Draft` spec, `Proposed` ADR, `@draft` scenario, new glossary term) | Create, update, delete | List every change in the final report |
| Normative (PRD, contracts, standards, `AGENTS.md`, `.claude/`, `tools/`, templates, accepted ADRs/specs/scenarios, existing glossary terms) | **Propose only** | Procedure 3.2 |
| `docs/DECISION-LOG.md` | Append entries | Never edit or delete existing entries |

Accepted IDs are never deleted or reused. Retire them as `Deprecated` / `Superseded by ADR-NNNN` / `[deprecated]`.

### 3.2 Procedure for a normative change

1. **Propose.** State what changes (IDs, files, old → new), why, and the evidence. Show the impact: dependent rules, scenarios, code, and contracts, from `docs/map/traceability.md`.
2. **Get explicit approval** from the human for this specific change in the current conversation or PR. Approval for one change does not extend to others.
3. **Apply.** Update `Status`, `Approved-by`, and `Approved-on`. Update linked artifacts in the same change.
4. **Record.** Append an entry to `docs/DECISION-LOG.md`.
5. **Verify.** Run `tools/trace.sh matrix` and `tools/trace.sh check`.
6. **Report** per §8.

### 3.3 Guardrails

`.claude/settings.json` installs two hooks:
- `.claude/hooks/guard-normative.sh` asks the human to confirm edits to normative artifacts.
- `.claude/hooks/report-changes.sh` reports normative changes when the agent stops, and sends the agent back once if accepted material changed without a decision-log entry.

Agents MUST NOT disable or weaken these hooks, and MUST NOT route around them (for example, by editing protected files through shell commands). A confirmation prompt is not approval by itself; it confirms a change that procedure 3.2 already justified.

## 4. Decision boundaries

Agents MAY independently decompose approved tasks, implement and refactor code, write tests and step definitions, choose internal abstractions, and draft specs, ADRs, and scenarios.

Agents MUST obtain approval before:

- Changing any normative artifact (§3.1), including product-significant expected behavior.
- Violating or replacing an accepted ADR, or materially changing system boundaries.
- Adding major infrastructure or operational dependencies, or changing security/privacy posture.
- Introducing breaking contract changes (`docs/contracts/README.md`) or weakening accepted invariants.
- Running destructive operations against important data, exposing secrets, or deploying to production.

Record material architecture choices in ADRs, not line-by-line implementation details.

### Accepted Gherkin scenarios are protected

When an accepted scenario fails, investigate the implementation, environment, step definitions, and specification **before** proposing any change to the scenario. Do not edit, delete, skip, quarantine, weaken, or retag it to make CI green.

If evidence suggests the scenario itself is wrong:
1. Report the failing scenario and the evidence.
2. Explain the proposed behavior change and its impact on PRD, specs, and contracts.
3. Follow §3.2. Do not modify the scenario before approval.

## 5. Workflow for significant behavior

1. **Understand.** Read the relevant PRD requirements, ADRs, contracts, specs, features, glossary, and code. Identify uncertainty and risk.
2. **Specify.** Write or update a spec in `specs/` (`/spec`). Use Infra-style definitions, rules, algorithms, invariants, and failures.
3. **Illustrate.** Draft `@draft` scenarios in `features/` **before implementing**. Cover success, failure, and boundary cases.
4. **Review.** Run the `spec-reviewer` subagent for an independent read. Fix or surface its findings.
5. **Approve.** The human accepts specs and scenarios (`/accept`). Material ambiguities and product-significant outcomes are decided by the human.
6. **Plan.** Assess impact on ADRs, contracts, security, data consistency, and infrastructure. Propose ADRs (`/adr`) for material decisions.
7. **Implement.** Write code, step definitions, and `implements:` / `verifies:` annotations.
8. **Verify.** Run the Gherkin runner, other tests, static checks, and `tools/trace.sh check`.
9. **Map and report.** Update descriptive docs (`/map`) and report (`/change-report`).

Use proportional rigor: a cosmetic change does not need a spec, ADR, and feature file.

## 6. Verification discipline

- Existing regression tests do not automatically cover new behavior.
- Assertions and implementation written by the same agent can share the same mistaken assumption. Passing them is not independent validation; expected values come from accepted specs and scenarios.
- Gherkin examples do not establish all properties. Add property-based, integration, concurrency, security, or contract tests where appropriate, annotated with `verifies:`.
- A `.feature` file alone is not executable verification. A runner and step definitions must exist and satisfy `tests/README.md`.
- MUST NOT weaken assertions, silence failures, skip tests, or alter accepted specifications just to get a passing status.
- Report separately: **passed, failed, not run, unverified**. Never claim success for checks that were not executed.

## 7. Project map and reconstruction

The human must be able to see at any time what the system does, where, and why. `/map` rebuilds the map described in `docs/map/README.md`.

- `docs/map/traceability.md` is generated by `tools/trace.sh matrix`. Never edit it by hand.
- `overview.md` and `docs/map/flows/` are written from evidence. Label every claim **[fact]** (with evidence: path, config, test, trace), **[inference]**, **[hypothesis]**, or **[unknown]**.
- Never invent historical motivation. Rationale without evidence is a hypothesis.
- Report deviations between code and accepted intent. Do not silently fix either side.

## 8. Final change report

For each meaningful change, report (`/change-report`):

- The behavior implemented, and the IDs (PRD, SPEC rules, scenarios) it satisfies.
- Normative artifacts changed, each with its approval and decision-log entry. Draft and descriptive artifacts created, changed, or deleted.
- Significant files and modules changed.
- Architectural and contract impact; ADRs proposed.
- Checks: passed, failed, not run, with commands and evidence.
- Remaining unverified properties and risks.
- Decisions awaiting human approval.

**Core principle:** maximize autonomy over implementation while preserving human control of intent, consequential decisions, and independently checkable outcomes.
