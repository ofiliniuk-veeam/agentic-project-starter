# Architecture Decision Records

Each consequential technical decision is one file, `NNNN-slug.md`, created from [`0000-template.md`](0000-template.md). Status rules: [`docs/standards/traceability.md`](../../standards/traceability.md) §2.

Agents write ADRs as `Proposed`. Only the human owner accepts them. Record the decision **before** implementing it when practicable. Local, reversible implementation choices do not need ADRs.

## Index

| ADR | Title | Status |
| --- | --- | --- |

## Decisions every project needs early

These are not pre-made. Propose each as an ADR when the project starts:

- Language, runtime, and package management.
- Gherkin runner and step-definition layout (must satisfy the runner contract in `tests/README.md`).
- Test levels and tools (unit, integration, contract, property-based).
- CI platform and which checks gate merges.
- Contract formats (OpenAPI, AsyncAPI, JSON Schema, protobuf, …).
- Deployment target and environments.
