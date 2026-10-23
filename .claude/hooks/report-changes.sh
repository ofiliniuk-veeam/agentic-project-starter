#!/usr/bin/env bash
# Stop hook: tells the human which normative artifacts changed (committed or not) since
# the previous report. If accepted material changed without a decision-log entry, it
# sends the agent back once to add the entry or explain why none is needed.
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

input=$(cat)
cd "${CLAUDE_PROJECT_DIR:-$PWD}" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

state="$(git rev-parse --git-dir)/claude-normative-report"
head=$(git rev-parse -q --verify HEAD 2>/dev/null || echo none)
last_head=$head last_sig=
[ -f "$state" ] && read -r last_head last_sig <"$state"

committed=
if [ "$last_head" != "$head" ] && [ "$last_head" != none ] && [ "$head" != none ]; then
  committed=$(git diff --name-only "$last_head" "$head" -- "${NORMATIVE_PATHS[@]}" 2>/dev/null)
fi
working=$(git status --porcelain --untracked-files=all -- "${NORMATIVE_PATHS[@]}" | cut -c4- | sed 's/.* -> //')
sig=$( { [ "$head" = none ] || git diff HEAD -- "${NORMATIVE_PATHS[@]}"
         git ls-files -o --exclude-standard -- "${NORMATIVE_PATHS[@]}" | while IFS= read -r f; do echo "$f"; cat "$f"; done
       } 2>/dev/null | cksum | cut -d' ' -f1)
[ -n "$working" ] || sig=clean

printf '%s %s\n' "$head" "$sig" >"$state"
[ -z "$committed" ] && [ "$sig" = "$last_sig" ] && exit 0
[ -z "$committed" ] && [ -z "$working" ] && exit 0

# Does a change to FILE need a decision-log entry? Not if every version involved is draft.
needs_log() {
  local f=$1 rev
  [ "$f" = docs/DECISION-LOG.md ] && return 1
  for rev in "$last_head" "$head"; do
    [ "$rev" = none ] && continue
    git cat-file -e "$rev:$f" 2>/dev/null || continue
    git show "$rev:$f" | is_draft_content "$f" || return 0
  done
  [ -f "$f" ] && ! is_draft_content "$f" <"$f" && return 0
  return 1
}

msg="Normative artifacts changed:"
[ -n "$committed" ] && msg+=$'\n'"Committed since last report:"$'\n'"$(sed 's/^/  /' <<<"$committed")"
[ -n "$working" ] && msg+=$'\n'"Uncommitted:"$'\n'"$(sed 's/^/  /' <<<"$working")"

unlogged=
logged=false
while IFS= read -r f; do
  [ -n "$f" ] || continue
  [ "$f" = docs/DECISION-LOG.md ] && logged=true
  needs_log "$f" && unlogged+="  $f"$'\n'
done <<<"$(printf '%s\n%s\n' "$committed" "$working" | sort -u)"

if [ -n "$unlogged" ] && ! $logged && ! grep -qE '"stop_hook_active"[[:space:]]*:[[:space:]]*true' <<<"$input"; then
  reason="Accepted normative artifacts changed but docs/DECISION-LOG.md has no new entry:"$'\n'"$unlogged"
  reason+="Add a decision-log entry for each approved change (AGENTS.md §3), or tell the human explicitly why none is needed."
  printf '{"decision":"block","reason":"%s","systemMessage":"%s"}\n' "$(json_escape "$reason")" "$(json_escape "$msg")"
  exit 0
fi
printf '{"systemMessage":"%s"}\n' "$(json_escape "$msg")"
