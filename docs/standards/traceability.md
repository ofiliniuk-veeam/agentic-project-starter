# Identifiers, Statuses, and Traceability

Status: Accepted

The project map is **computed**, not written from memory. Every requirement, rule, scenario, and decision carries a stable ID, and every link between them is written in a form `tools/trace.sh` can find. The chain is:

```
PRD-NNN  →  SPEC-NNN-Rn  →  @SPEC-NNN-Snn (Gherkin)  →  step definitions / tests  →  code
   ↑              ↑                                         verifies:               implements:
 ADR-NNNN and docs/contracts/ constrain any link in the chain
```

## 1. Identifiers

| ID | Defined in | Format |
| --- | --- | --- |
| `PRD-NNN` | a row of the requirements table in `docs/product/PRD.md` | 3 digits |
| `ADR-NNNN` | `docs/architecture/adr/NNNN-slug.md`, heading `# ADR-NNNN: Title` | 4 digits |
| `SPEC-NNN` | `specs/NNN-slug.md`, heading `# SPEC-NNN: Title` | 3 digits, equal to the file prefix |
| `SPEC-NNN-Rn` | a normative bullet `- **SPEC-NNN-Rn:** …` in that spec | rule number, 1-based |
| `SPEC-NNN-Snn` | a Gherkin tag `@SPEC-NNN-Snn` on exactly one scenario | scenario number, 2+ digits |

- IDs are **never reused or renumbered**, even after deprecation or deletion.
- Number `000`/`0000` is reserved for templates, which tools ignore.
- `tools/trace.sh next prd|spec|adr` prints the next free ID.
- Any ID-shaped token in project files must refer to a defined ID; `tools/trace.sh check` reports dangling references. This does not apply to `docs/standards/`, `docs/DECISION-LOG.md`, `AGENTS.md`, `CLAUDE.md`, `.claude/`, `.github/`, `tools/`, and templates.

## 2. Statuses

| Artifact | Statuses | Where |
| --- | --- | --- |
| PRD requirement | `Draft`, `Accepted`, `Deprecated` | Status column of the table |
| ADR | `Proposed`, `Accepted`, `Rejected`, `Deprecated`, `Superseded by ADR-NNNN` | `Status:` line |
| Spec | `Draft`, `Accepted`, `Deprecated` | `Status:` line |
| Spec rule | inherits the spec's status; may be marked `[draft]` (proposed addition to an accepted spec) or `[deprecated]` | marker on the rule line |
| Scenario | accepted, unless `@draft` is on its feature, rule, or scenario | tags |

Accepted artifacts record `Approved-by:` and `Approved-on:`, and every transition is logged in `docs/DECISION-LOG.md`.

## 3. Links

| Link | How it is written |
| --- | --- |
| Rule → requirement | `Related PRD:` in the spec header (applies to all rules) and/or `(PRD-NNN)` on the rule line |
| Scenario → rule | `@SPEC-NNN-Rn` tag on the `Rule:` block (inherited) or on the scenario |
| Test → rule (non-Gherkin) | a comment containing `verifies: SPEC-NNN-Rn` in a test file |
| Code → rule | a comment containing `implements: SPEC-NNN-Rn` near the implementing code |
| Anything → ADR / contract | mention `ADR-NNNN` or link the contract file |

One annotation line may list several rule IDs: `// implements: SPEC-004-R1, SPEC-004-R2`. Annotations use the host language's comment syntax, so the scheme works for any stack.

## 4. Coverage rules

`tools/trace.sh check` enforces these rules. CI runs the same command.

**Errors** (check fails):
- A duplicate ID, an unknown referenced ID, an invalid status, or a header that does not match its file name.
- An **accepted rule** with no accepted scenario and no `verifies:` test. To acknowledge a known gap, put `[waiver: reason]` on the rule line; the gap is then reported as a warning.
- An **accepted scenario** without exactly one scenario ID, without a rule tag, or illustrating a rule that is not accepted.
- `docs/map/traceability.md` differs from what `tools/trace.sh matrix` would generate.

**Warnings**:
- An accepted rule with no `implements:` annotation.
- An accepted rule with no requirement, or relying on a requirement that is not accepted.
- An accepted requirement no spec refers to.
- An annotation pointing to a rule that is not accepted.

## 5. What tracing does not prove

- Tracing proves that links **exist**, not that the linked tests are meaningful or pass.
- Whether every step of an accepted scenario has a step definition is checked by the Gherkin runner. It must fail on undefined steps (see `tests/README.md`).
