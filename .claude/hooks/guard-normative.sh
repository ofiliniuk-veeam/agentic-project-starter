#!/usr/bin/env bash
# PreToolUse hook: asks the human to confirm any change to a normative artifact
# (policy: AGENTS.md §3). It never denies; it turns the change into an explicit decision.
# Agents MUST NOT disable, weaken, or route around this hook.
#
# No `set -e`: an internal failure must not turn into a silent allow, so errors fall
# through to the conservative branches below.
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

input=$(cat)
root=${CLAUDE_PROJECT_DIR:-$PWD}

ask() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' \
    "$(json_escape "Normative change: $1 Approve only if you intend this change (AGENTS.md §3).")"
  exit 0
}

if ! command -v jq >/dev/null 2>&1; then
  printf '%s' "$input" | grep -qE "$PROTECTED_RE" && ask "jq is not installed, so the hook cannot tell which file is touched; a protected path is mentioned."
  exit 0
fi

tool=$(jq -r '.tool_name // ""' <<<"$input")

if [ "$tool" = Bash ]; then
  cmd=$(jq -r '.tool_input.command // ""' <<<"$input")
  if grep -qE 'git[[:space:]]+(reset[[:space:]]+--hard|clean|stash|checkout[[:space:]]+(--[[:space:]]+)?\.|restore[[:space:]]+\.)' <<<"$cmd"; then
    ask "this git command can discard uncommitted changes, including to specs and scenarios."
  fi
  # Drop harmless redirections before looking for writes.
  scrubbed=$(sed -E 's/[0-9]*>&[0-9]+//g; s#[0-9]*>{1,2}[[:space:]]*/dev/null##g' <<<"$cmd")
  writes='>|(^|[^[:alnum:]_-])(tee|rm|mv|cp|truncate|dd|ln|chmod|install|patch|touch|unlink|rsync)([^[:alnum:]_-]|$)|sed[^|;&]*[[:space:]]-[[:alpha:]]*i|perl[^|;&]*[[:space:]]-[[:alpha:]]*i|git[[:space:]]+(rm|mv|checkout|restore|apply|am)([^[:alnum:]_-]|$)'
  if grep -qE "$PROTECTED_RE" <<<"$cmd" && grep -qE "$writes" <<<"$scrubbed"; then
    ask "this shell command may modify a protected path. Prefer the Edit/Write tools for these files."
  fi
  exit 0
fi

case "$tool" in Edit|Write|MultiEdit|NotebookEdit) ;; *) exit 0 ;; esac

path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // ""' <<<"$input")
new=$(jq -r '[.tool_input.content, .tool_input.new_string, .tool_input.new_source, (.tool_input.edits // [] | .[].new_string)] | map(select(. != null)) | join("\n")' <<<"$input")
old=$(jq -r '[.tool_input.old_string, (.tool_input.edits // [] | .[].old_string)] | map(select(. != null)) | join("\n")' <<<"$input")

case "$path" in
  "$root"/*) rel=${path#"$root"/} ;;
  /*) exit 0 ;;
  *) rel=$path ;;
esac
file="$root/$rel"
exists=false; [ -f "$file" ] && exists=true

# An Edit whose replacement keeps the old text intact only inserts.
pure_insert() { [ "$tool" = Edit ] && [ -n "$old" ] && [[ "$new" == *"$old"* ]]; }

case "$rel" in
  */0*-template.*)
    ask "$rel is a template every new artifact is copied from." ;;
  AGENTS.md | CLAUDE.md | .claude/* | docs/standards/* | tools/* | .github/*)
    ask "$rel is part of the agent rules, guardrails, or verification tooling." ;;
  docs/product/*)
    ask "$rel holds product requirements." ;;
  docs/contracts/*)
    ask "$rel is a contract other parties rely on." ;;
  docs/glossary.md)
    $exists && ! pure_insert && ask "$rel: changing or removing an existing term changes the meaning of every spec using it." ;;
  docs/DECISION-LOG.md)
    $exists && ! pure_insert && ask "$rel is append-only; this change rewrites existing content." ;;
  specs/*.md | docs/architecture/adr/*.md | features/*.feature)
    if $exists && ! is_draft_content "$rel" <"$file"; then
      ask "$rel contains accepted material."
    fi
    if [ "$tool" = Write ] || [ "$tool" = NotebookEdit ]; then
      is_draft_content "$rel" <<<"$new" || ask "this write makes $rel accepted (status or scenarios without @draft)."
    else
      case "$rel" in
        features/*) [ "$(grep -o '@draft' <<<"$old" | wc -l)" -gt "$(grep -o '@draft' <<<"$new" | wc -l)" ] \
                      && ask "this edit removes @draft from $rel, which accepts scenarios." ;;
        *) grep -qE '^Status:[[:space:]]*(Accepted|Rejected|Deprecated|Superseded)' <<<"$new" \
             && ask "this edit changes the status of $rel." ;;
      esac
    fi ;;
esac
exit 0
