# Glossary

The single vocabulary of the project domain. Specs, Gherkin steps, contracts, and code identifiers SHOULD use these terms verbatim. Data types follow [Infra](https://infra.spec.whatwg.org/) (see `docs/standards/specification-style.md` §3).

Each entry has a heading, which Markdown turns into a linkable anchor (`docs/glossary.md#term`):

```markdown
### Reservation

A **reservation** is a struct with the following items: **id** (string), **seats** (ordered set of seat numbers), **state** (enumeration `"held"`, `"confirmed"`, `"released"`).

Defined by: SPEC-NNN. Not to be confused with: *hold*.
```

Changes to existing terms change the meaning of every spec that uses them, so they follow `AGENTS.md` §3. New terms may be added freely and reported.

## Terms

_None yet._
