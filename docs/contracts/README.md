# Contracts

Externally relied-upon interfaces: API schemas, event formats, protocols, persisted data formats, error codes, and their invariants. Contracts are **normative**: every change follows `AGENTS.md` §3.

- Prefer machine-readable formats (OpenAPI, AsyncAPI, JSON Schema, protobuf). Map Infra types as in `docs/standards/specification-style.md` §3.
- Each contract names its version and links the specs (`SPEC-NNN`) and ADRs that define its semantics. Failure reason codes in specs must match the contract's error codes.
- Contract tests annotate `verifies: SPEC-NNN-Rn` where they check a spec rule.

## Compatibility

A change is **breaking** if a previously valid client or stored datum can be rejected or misinterpreted. This includes:
- removing or renaming a field, endpoint, event, or enum value;
- making something optional required;
- narrowing an accepted range;
- changing a default or the meaning of a value;
- changing error codes;
- changing ordering or idempotency guarantees.

Breaking changes require explicit approval, a version bump, and a migration note in the decision log. Additive changes still require approval because contracts are normative.

## Index

| Contract | Format | Version | Specs |
| --- | --- | --- | --- |
