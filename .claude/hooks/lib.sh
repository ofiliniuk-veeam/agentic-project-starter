# Shared helpers for the guardrail hooks. Sourced, not executed.
# The protection policy itself is AGENTS.md §3; keep these patterns in sync with it.

# Paths whose changes always need approval when touched through a shell command.
PROTECTED_RE='docs/(product|contracts|standards|architecture/adr)/|docs/(glossary|DECISION-LOG)\.md|specs/|features/|AGENTS\.md|CLAUDE\.md|\.claude/|tools/|\.github/'

# Paths reported to the human by the Stop hook.
NORMATIVE_PATHS=(docs/product docs/contracts docs/standards docs/architecture/adr docs/glossary.md
                 docs/DECISION-LOG.md specs features AGENTS.md CLAUDE.md .claude tools .github)

json_escape() {
  local s=$1
  s=${s//\\/\\\\}; s=${s//\"/\\\"}; s=${s//$'\n'/\\n}; s=${s//$'\t'/\\t}; s=${s//$'\r'/}
  printf '%s' "$s"
}

# Reads a .feature file on stdin; succeeds if any scenario is not covered by @draft.
has_accepted_scenarios() {
  awk '
    { line = $0; sub(/^[ \t]+/, "", line) }
    line ~ /^@/ { t = " " line; sub(/[ \t]#.*$/, "", t); pending = pending t; next }
    line ~ /^Feature:/ { f = pending; pending = ""; r = ""; next }
    line ~ /^Rule:/ { r = pending; pending = ""; next }
    line ~ /^(Background|Examples|Scenarios):/ { pending = ""; next }
    line ~ /^(Scenario|Scenario Outline|Scenario Template|Example):/ {
      if ((f " " r " " pending " ") !~ /[ \t]@draft[ \t]/) found = 1
      pending = ""
    }
    END { exit !found }'
}

# Reads a spec or ADR on stdin; prints the value of its first "Status:" line.
status_of() { sed -n 's/^Status:[[:space:]]*//p' | head -n 1; }

# Reads content on stdin; succeeds if, as file PATH, it holds only draft material
# (Draft spec, Proposed ADR, feature with no accepted scenario, or a template).
is_draft_content() {
  local path=$1 st
  case "$path" in
    */0*-template.*) cat >/dev/null; return 0 ;;
    specs/*.md) st=$(status_of); [ -z "$st" ] || [ "$st" = Draft ] ;;
    docs/architecture/adr/README.md) cat >/dev/null; return 0 ;;
    docs/architecture/adr/*.md) st=$(status_of); [ -z "$st" ] || [ "$st" = Proposed ] ;;
    features/*.feature) ! has_accepted_scenarios ;;
    *) cat >/dev/null; return 1 ;;
  esac
}
