# Specification Style

Status: Accepted

Feature specifications in this project are written in the language of the [Infra Standard](https://infra.spec.whatwg.org/). Its terminology, data types, and algorithm conventions apply **by reference**. This document summarizes the parts used most often and lists every project deviation (§8). It is a project convention and makes no claim of WHATWG conformance.

Identifier, status, and annotation formats are defined in [traceability.md](traceability.md).

## 1. Conformance keywords

The key words **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **NOT RECOMMENDED**, **MAY**, and **OPTIONAL** are to be interpreted as described in BCP 14 ([RFC 2119](https://www.rfc-editor.org/rfc/rfc2119), [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174)) when, and only when, they appear in all capitals.

- Normative text appears only in the **Normative requirements**, **Algorithms**, and **Invariants** sections of a spec, and in algorithms anywhere.
- Everything else is informative. Informative asides start with `Note:`; examples start with `Example:`.
- **SHOULD** permits deviation only with a recorded rationale (in the spec, an ADR, or the decision log).
- A requirement that cannot be observed or checked is not a requirement. Do not write "The system MUST work correctly."

## 2. Definitions and terms

- Every domain term is defined exactly once. Project-wide terms belong in [`docs/glossary.md`](../glossary.md). Terms local to one feature belong in that spec's **Definitions** section.
- A defining instance is written in bold: "A **reservation** is a struct with …".
- Other places refer to a term with a Markdown link to its definition, at least at first use in each section.
- Infra terms (list, ordered map, string, struct, …) are never redefined. Use them with their Infra meaning.
- Gherkin steps, code identifiers, and contract field names SHOULD use glossary terms verbatim, so the project map can be read in one vocabulary.

## 3. Data model

Model inputs, outputs, and state with Infra types. Contracts in `docs/contracts/` map them to concrete formats.

| Infra concept | Use for | Typical contract mapping (JSON Schema) |
| --- | --- | --- |
| [null](https://infra.spec.whatwg.org/#nulls) | Explicit absence | `null` |
| [boolean](https://infra.spec.whatwg.org/#booleans) | Two-valued state | `boolean` |
| [numbers](https://infra.spec.whatwg.org/#numbers) (e.g. 64-bit signed integer) | Counts, amounts; always state range and unit | `integer` with `minimum`/`maximum` |
| [string](https://infra.spec.whatwg.org/#strings), scalar value string, ASCII string | Text; state length limits and normalization | `string` with `maxLength`/`pattern` |
| [byte sequence](https://infra.spec.whatwg.org/#byte-sequences) | Opaque binary data | `string` with `contentEncoding` |
| [moment](https://infra.spec.whatwg.org/#moment), [duration](https://infra.spec.whatwg.org/#duration) | Points in time, time spans | `string` with `format: date-time` / `duration` |
| [list](https://infra.spec.whatwg.org/#list), [stack](https://infra.spec.whatwg.org/#stack), [queue](https://infra.spec.whatwg.org/#queue) | Ordered collections | `array` |
| [ordered set](https://infra.spec.whatwg.org/#ordered-set) | Ordered, no duplicates | `array` with `uniqueItems` |
| [ordered map](https://infra.spec.whatwg.org/#ordered-map) | Keyed collections; iteration order is insertion order | `object` or array of entries |
| [struct](https://infra.spec.whatwg.org/#struct), [tuple](https://infra.spec.whatwg.org/#tuple) | Records with named items | `object` with `required` |
| *enumeration* (project, §8) | Closed set of string values | `enum` |

Write a struct like this:

> A **reservation** is a [struct](https://infra.spec.whatwg.org/#struct) with the following [items](https://infra.spec.whatwg.org/#struct-item):
> - **id**, a string of 1–64 ASCII alphanumerics.
> - **seats**, an ordered set of seat numbers (integers in the range 1–500).
> - **state**, an enumeration: `"held"`, `"confirmed"`, or `"released"`.

## 4. Algorithms

Use ordered algorithms for any nontrivial behavior, following [Infra §3 Algorithms](https://infra.spec.whatwg.org/#algorithms).

- **Declaration.** "To **confirm a reservation**, given a reservation *reservation* and a moment *now*, run these steps:". If there is a result, state it: "… returns a reservation or failure."
- **Steps.** Use numbered lists, nested for substeps. Each step does one thing.
- **Variables.** Write variables in italics. "Let *x* be …" introduces a variable. "Set *x* to …" changes it.
- **Control flow.** Use the Infra phrasing: "If …, then …", "Otherwise, …", "For each *item* of *list*: …", "While …: …", "Continue", "Break", "Return *x*", "Return failure".
- **Assertions.** "Assert: …" states something that holds by construction. A false assertion is a bug in the spec, not a runtime error. Validate inputs with "If …, then return failure" instead.
- **Equivalence.** Implementations MAY use any algorithm that produces the same observable result ([Infra §3.1](https://infra.spec.whatwg.org/#algorithm-conformance)). The algorithm defines behavior, not structure.
- **Concurrency.** Use "in parallel" for steps that run independently of the caller. Mark sections that no other algorithm may observe halfway with "Atomically:" (§8). State ordering, retry, timeout, and idempotency requirements explicitly whenever they matter.

## 5. Spec structure

Copy [`specs/000-template.md`](../../specs/000-template.md). Sections:

1. **Header**: ID, status, approval, related PRD requirements, ADRs, contracts.
2. **Goal and scope.**
3. **Definitions**: local terms, data types per §3.
4. **Normative requirements**: one rule per bullet, formatted `- **SPEC-NNN-Rn:** …`. Each rule states one checkable obligation with one primary keyword.
5. **Algorithms / state transitions**, where behavior is nontrivial.
6. **Invariants**: security, integrity, atomicity, ordering, idempotency.
7. **Failure and boundary behavior**: every failure is observable and named.
8. **Observability**: what a client or user can determine.
9. **Verification**: links to the feature file, plus non-Gherkin verification (property, concurrency, contract tests).
10. **Out of scope and open questions.**

## 6. Gherkin conventions

Gherkin is the primary format for **examples** of required behavior. The rules in the spec stay authoritative.

- **One feature file per spec.** `features/NNN-slug.feature` mirrors `specs/NNN-slug.md`.
- **One `Rule:` block per spec rule.** Title it `SPEC-NNN-Rn — short statement` and tag it `@SPEC-NNN-Rn`. Scenarios inherit the tag. A scenario that illustrates several rules carries the extra rule tags itself.
- **Scenario IDs.** Each scenario has exactly one ID tag `@SPEC-NNN-Snn`, unique and never reused.
- **Domain language.**
  - Given = initial observable state; When = one action or event; Then = observable outcome.
  - No method names, database tables, or UI selectors unless they are part of the externally visible contract.
- **Coverage.** Include success, rejection, boundary, and failure examples as risk warrants. Use `Scenario Outline` with `Examples` for data variation.
- **`@draft`** marks proposed, unaccepted scenarios on a feature, rule, or scenario. Runners MUST exclude them with the tag expression `not @draft`. Removing `@draft` is the act of acceptance and requires approval.
- **No silent edits.** Accepted scenarios, including steps, examples, and tags, change only through the procedure in `AGENTS.md` §3.

## 7. Example (informative)

Spec excerpt:

```markdown
- **SPEC-004-R2:** Confirming a held [reservation] MUST be idempotent: confirming an already
  confirmed reservation returns it unchanged. (PRD-007)

To **confirm a reservation**, given a reservation *reservation* and a moment *now*, run these steps:
1. If *reservation*'s state is `"confirmed"`, then return *reservation*.
2. If *reservation*'s state is `"released"`, then return failure with reason `"reservation-released"`.
3. Assert: *reservation*'s state is `"held"`.
4. If *now* is after *reservation*'s hold expiry, then return failure with reason `"hold-expired"`.
5. Atomically:
   1. Set *reservation*'s state to `"confirmed"`.
   2. Append a confirmation record for *reservation* to the audit log.
6. Return *reservation*.
```

Matching feature file excerpt:

```gherkin
Feature: Reservations

  @SPEC-004-R2
  Rule: SPEC-004-R2 — confirming is idempotent

    @SPEC-004-S03
    Scenario: Confirming an already confirmed reservation changes nothing
      Given a confirmed reservation "R-1" for seats 10 and 11
      When the customer confirms reservation "R-1"
      Then reservation "R-1" is confirmed for seats 10 and 11
      And the audit log contains exactly one confirmation for "R-1"
```

## 8. Deviations from Infra

| Deviation | Reason |
| --- | --- |
| Markdown links instead of Bikeshed autolinks (`[=term=]`) | No spec toolchain required; renders on any Git host. |
| Rule IDs `SPEC-NNN-Rn` on normative bullets | Traceability to scenarios, tests, and code. |
| **Enumeration**: a closed set of string values, written `"value"` | Infra has no enumeration type. |
| "Return failure with reason `"code"`" | Failures must be observable and testable; the reason codes match the contract. |
| "Atomically:" | Makes atomicity explicit: no other algorithm observes intermediate state. |
