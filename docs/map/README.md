# Project Map

The map answers "what does the system do, where, and why" at any moment, without reading the code. It is rebuilt with `/map` (Claude Code), and its computed part with `tools/trace.sh matrix`.

| Part | What it shows | Produced by |
| --- | --- | --- |
| [`traceability.md`](traceability.md) | PRD requirement → spec rule → scenario → test → code, plus gaps | `tools/trace.sh matrix` (generated; CI checks it is current) |
| [`../architecture/overview.md`](../architecture/overview.md) | C4 context, containers, components, data, deviations | agent, from code and ADRs, with evidence labels |
| [`flows/`](flows/) | One file per key runtime process: sequence diagram + steps linked to rules | agent, from specs and code |
| [`../architecture/adr/README.md`](../architecture/adr/README.md) | Decisions and their status | agent proposes, human accepts |
| [`../glossary.md`](../glossary.md) | Domain vocabulary used everywhere | specs |

Reading order for a human: traceability summary → overview → flows of interest → specs and ADRs they link to.

Every descriptive claim is labeled **[fact]**, **[inference]**, **[hypothesis]**, or **[unknown]**, with evidence for facts.
