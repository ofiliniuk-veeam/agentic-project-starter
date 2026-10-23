# Tests

No runner is shipped: the stack is chosen per project (see `docs/architecture/adr/README.md`). Until a runner is wired, `features/*.feature` files are specifications, not passing tests. Do not use placeholders or an empty suite to claim coverage.

## Layout

- `steps/`: Gherkin step definitions. Steps are written in domain language and reused across features.
- `unit/`, `integration/`: other tests. Tests that check a spec rule directly carry `verifies: SPEC-NNN-Rn`.

## Gherkin runner contract

Any runner chosen (Cucumber, behave, godog, Reqnroll, …) MUST be configured so that:

1. It runs every `features/*.feature` file except templates, with the tag expression `not @draft`.
2. An **undefined or pending step fails the run** (e.g. Cucumber `--strict`). A scenario without step definitions is not verified.
3. Its report is machine-readable (JUnit XML or Cucumber JSON) and lists scenarios by their `@SPEC-NNN-Snn` tag.
4. It runs in CI as a merge gate, alongside `tools/trace.sh check`.
5. Its step definitions do not encode expected results that contradict the spec. Expected values come from the scenario text.

Record the runner choice in an ADR and add the command here:

```sh
# e.g. npx cucumber-js --strict --tags "not @draft"
```
