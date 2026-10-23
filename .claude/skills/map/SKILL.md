---
name: map
description: Rebuild the project map — traceability matrix, C4 architecture overview, and runtime flow diagrams — from specs, ADRs, and the actual code, with evidence labels. Use when asked how the system works, before large changes, or after significant implementation.
argument-hint: "[optional focus: a flow, component, or SPEC-NNN]"
---

Rebuild the project map (`docs/map/README.md`). Focus, if given: $ARGUMENTS

1. **Traceability.** Run `tools/trace.sh matrix` and then `tools/trace.sh check`. Read `docs/map/traceability.md` and keep its findings for the report.
2. **Survey the code.**
   - Find entry points, deployable units, modules, dependencies, persistence, external calls, and configuration.
   - Use `implements:` annotations to connect components to rules.
   - For a large codebase, delegate the read-only survey to an Explore subagent and keep only conclusions with evidence paths.
3. **Update `docs/architecture/overview.md`.**
   - C4 context, container, and component levels as Mermaid diagrams and tables.
   - Data and state, cross-cutting concerns.
   - **Deviations from intent:** code that contradicts accepted specs, ADRs, or contracts; code with no traceable rule; accepted rules with no implementation.
   
   Label every claim [fact] (with `path:line` or config evidence), [inference], [hypothesis], or [unknown]. Update `Last verified against code` with today's date and the commit.
4. **Update flows.** One file per key runtime process in `docs/map/flows/NNN-slug.md` (from the template), each step linked to a rule and code location. Add flows for new processes; mark flows whose code disappeared as [unknown] and report them rather than deleting silently.
5. **Do not touch normative artifacts.** If the map reveals that a spec, ADR, or scenario is wrong or missing, report it as a proposal.
6. **Report:**
   - what changed in the map;
   - trace errors and warnings;
   - deviations from intent;
   - unknowns worth investigating.
