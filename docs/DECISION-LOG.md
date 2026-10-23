# Decision Log

Append-only history of every change to a normative artifact: PRD requirements, ADR statuses, specs, accepted Gherkin scenarios, contracts, glossary terms, standards, and agent rules. Git shows *what* changed. This log records *that a human approved it and why*.

Rules:
- Add new entries at the **bottom**. Never edit or delete existing entries; correct a mistake with a new entry.
- One entry per approved change. Write it in the same commit as the change.
- Reference IDs (`PRD-NNN`, `ADR-NNNN`, `SPEC-NNN-Rn`, `SPEC-NNN-Snn`) and files.

Entry format:

```markdown
## YYYY-MM-DD — short title

- **Changed:** IDs and files, with old → new status where applicable.
- **Why:** reason and evidence (failing scenario, user feedback, incident, …).
- **Impact:** affected specs, scenarios, contracts, code.
- **Approved by:** name, and where (conversation, PR #, issue).
```

## Entries
