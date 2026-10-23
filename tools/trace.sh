#!/usr/bin/env bash
# Traceability for the chain PRD requirement -> spec rule -> Gherkin scenario -> tests/code.
# ID, tag and annotation formats: docs/standards/traceability.md.
#
# Usage:
#   tools/trace.sh check            Validate traceability and matrix freshness; exit 1 on errors.
#   tools/trace.sh matrix [FILE]    Regenerate the matrix (default: docs/map/traceability.md).
#   tools/trace.sh next prd|spec|adr  Print the next free ID of that kind.
#
# Requires bash >= 3.2 and a POSIX awk. Runs from any directory.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
MATRIX_DEFAULT="docs/map/traceability.md"
ID_RE='PRD-[0-9]{3}|ADR-[0-9]{4}|SPEC-[0-9]{3}(-[RS][0-9]+)?'

usage() { sed -n '4,9p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }

# Project files: tracked plus untracked-but-not-ignored, minus templates (NNN-template.*).
project_files() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git ls-files -co --exclude-standard
  else
    find . -type f ! -path './.git/*' | sed 's|^\./||'
  fi | grep -Ev '(^|/)0+-template\.[^/]*$' | LC_ALL=C sort -u
}

prd=() specs=() features=() adrs=() docrefs=() code=()
classify_files() {
  local f base
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    base="${f##*/}"
    case "$f" in
      docs/product/PRD.md) prd+=("$f") ;;
      specs/*.md) [[ $base =~ ^[0-9]{3}- ]] && specs+=("$f") ;;
      features/*.feature) features+=("$f") ;;
      docs/architecture/adr/*.md) [[ $base =~ ^[0-9]{4}- ]] && adrs+=("$f") ;;
      # Generated output, history, and rule books mention IDs only as examples or past state.
      "$MATRIX_DEFAULT" | docs/DECISION-LOG.md | docs/standards/*) ;;
      docs/*) docrefs+=("$f") ;;
      specs/* | features/* | tools/* | .claude/* | .github/* | AGENTS.md | CLAUDE.md) ;;
      *) code+=("$f") ;;
    esac
  done < <(project_files)
}

# Emits tab-separated records; see the analysis program for the record kinds.
read -r -d '' EXTRACT_AWK <<'AWK' || true
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function ids(s, re,   out) {
  out = ""
  while (match(s, re)) { out = out (out == "" ? "" : ",") substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH) }
  return out
}
function prefix(path,   b) { b = path; sub(/.*\//, "", b); sub(/-.*/, "", b); return b }
BEGIN {
  OFS = "\t"
  PRD_RE = "PRD-[0-9][0-9][0-9]"; RULE_RE = "SPEC-[0-9][0-9][0-9]-R[0-9]+"; SCEN_RE = "SPEC-[0-9][0-9][0-9]-S[0-9]+"
}
FNR == 1 {
  if (prev != "") finish(prev)
  prev = FILENAME; id = ""; status = ""; specprds = ""; ftags = ""; rtags = ""; pending = ""
}
{ loc = FILENAME ":" FNR }

kind == "prd" && /^\|[ \t]*PRD-[0-9][0-9][0-9][ \t]*\|/ {
  split($0, c, "|"); print "PRD", trim(c[2]), trim(c[5]), loc
}

kind == "spec" && id == "" && /^# SPEC-[0-9][0-9][0-9]/ {
  id = substr($0, 3, 8); print "SPEC", id, loc
  if (substr(id, 6) != prefix(FILENAME)) print "ERR", "spec header " id " does not match file name " FILENAME
}
kind == "spec" && status == "" && /^Status:/ { status = trim(substr($0, 8)); print "SPECST", id, status, loc }
kind == "spec" && /^Related PRD:/ {
  specprds = ids($0, PRD_RE); n = split(specprds, p, ",")
  for (i = 1; i <= n; i++) print "SPECPRD", id, p[i], loc
}
kind == "spec" && /^[ \t]*[-*][ \t]+\*\*SPEC-[0-9][0-9][0-9]-R[0-9]+/ {
  match($0, RULE_RE); rid = substr($0, RSTART, RLENGTH)
  if (substr(rid, 1, 8) != id) print "ERR", "rule " rid " at " loc " is outside its spec " id
  strength = "-"
  if (match($0, /MUST NOT|MUST|SHOULD NOT|SHOULD|MAY/)) strength = substr($0, RSTART, RLENGTH)
  if (index($0, "[deprecated]")) state = "Deprecated"
  else if (status != "Accepted") state = (status == "" ? "Draft" : status)
  else if (index($0, "[draft]")) state = "Draft"
  else state = "Accepted"
  prds = ids($0, PRD_RE); if (specprds != "") prds = prds (prds == "" ? "" : ",") specprds
  print "RULE", rid, loc, state, strength, (index($0, "[waiver:") ? 1 : 0), prds
}

kind == "feature" {
  line = trim($0)
  if (line ~ /^@/) { t = " " line; sub(/[ \t]#.*$/, "", t); pending = pending t; next }
  if (line ~ /^Feature:/) { ftags = pending; pending = ""; rtags = ""; next }
  if (line ~ /^Rule:/) { rtags = pending; pending = ""; next }
  if (line ~ /^(Background|Examples|Scenarios):/) { pending = ""; next }
  if (line ~ /^(Scenario|Scenario Outline|Scenario Template|Example):/) {
    name = line; sub(/^[^:]*:[ \t]*/, "", name); gsub(/\t/, " ", name)
    all = ftags " " rtags " " pending " "
    own = ids(pending, SCEN_RE); nown = split(own, o, ",")
    print "SCEN", (nown ? o[1] : ""), (all ~ /[ \t]@draft[ \t]/ ? "draft" : "accepted"), loc, name, ids(all, RULE_RE), nown
    for (i = 2; i <= nown; i++) print "SCENEXTRA", o[i], loc
    pending = ""
  }
}

kind == "adr" && id == "" && /^# ADR-[0-9][0-9][0-9][0-9]/ {
  id = substr($0, 3, 8)
  if (substr(id, 5) != prefix(FILENAME)) print "ERR", "ADR header " id " does not match file name " FILENAME
}
kind == "adr" && status == "" && /^Status:/ { status = trim(substr($0, 8)); print "ADR", id, status, loc }

# grep -nH output: FILE:LINE:TEXT
kind == "annot" {
  f = $0; sub(/:.*/, "", f); rest = substr($0, length(f) + 2); ln = rest; sub(/:.*/, "", ln)
  text = substr(rest, length(ln) + 2); where = f ":" ln
  if (match(text, /implements:/)) { n = split(ids(substr(text, RSTART), RULE_RE), r, ","); for (i = 1; i <= n; i++) print "IMPL", r[i], where }
  if (match(text, /verifies:/)) { n = split(ids(substr(text, RSTART), RULE_RE), r, ","); for (i = 1; i <= n; i++) print "VERI", r[i], where }
}
# grep -noH output: FILE:LINE:ID
kind == "ref" { n = split($0, r, ":"); print "REF", r[n], r[1] ":" r[2] }

function finish(f) {
  if (kind == "spec" && id == "") print "ERR", "spec file " f " has no '# SPEC-NNN: Title' header"
  if (kind == "spec" && status == "") print "ERR", "spec file " f " has no 'Status:' line"
  if (kind == "adr" && (id == "" || status == "")) print "ERR", "ADR file " f " needs a '# ADR-NNNN: Title' header and a 'Status:' line"
}
END { if (prev != "") finish(prev) }
AWK

read -r -d '' ANALYZE_AWK <<'AWK' || true
function err(m) { E[++ne] = m }
function warn(m) { W[++nw] = m }
function add(arr, k, v) { arr[k] = (arr[k] == "" ? v : arr[k] ", " v) }
# Records a definition; returns 0 for a duplicate, whose data callers then ignore.
function def(what, id, loc) {
  if (id in DEF) { err("duplicate " what " ID " id " at " loc " (first defined at " DEF[id] ")"); return 0 }
  DEF[id] = loc; return 1
}
function cell(s) { gsub(/\|/, "\\|", s); return s == "" ? "—" : s }
function row(n, a, b, c, d, e, f, g, h,   s) {
  s = "| " cell(a) " | " cell(b)
  if (n > 2) s = s " | " cell(c); if (n > 3) s = s " | " cell(d); if (n > 4) s = s " | " cell(e)
  if (n > 5) s = s " | " cell(f); if (n > 6) s = s " | " cell(g); if (n > 7) s = s " | " cell(h)
  print s " |" > out
}
BEGIN { FS = "\t" }
$1 == "ERR"       { err($2) }
$1 == "PRD"       { if (!def("requirement", $2, $4)) next; P[++np] = $2; P_ST[$2] = $3; P_LOC[$2] = $4 }
$1 == "SPEC"      { def("spec", $2, $3) }
$1 == "SPECST"    { S_ST[$2] = $3; S_LOC[$2] = $4 }
$1 == "SPECPRD"   { add(P_SPECS, $3, $2) }
$1 == "RULE"      { if (!def("rule", $2, $3)) next; R[++nrule] = $2; R_LOC[$2] = $3; R_ST[$2] = $4; R_STR[$2] = $5; R_WAIV[$2] = $6; R_PRD[$2] = $7 }
$1 == "SCEN"      { if ($2 != "") def("scenario", $2, $4); ns++; C_ID[ns] = $2; C_ST[ns] = $3; C_LOC[ns] = $4; C_NAME[ns] = $5; C_RULES[ns] = $6; C_N[ns] = $7 }
$1 == "SCENEXTRA" { err("scenario at " $3 " has more than one scenario ID tag (" $2 ")") }
$1 == "IMPL"      { add(R_IMPL, $2, $3); IM[++nim] = $2; IM_LOC[nim] = $3 }
$1 == "VERI"      { add(R_VERI, $2, $3); IM[++nim] = $2; IM_LOC[nim] = $3 }
$1 == "ADR"       { if (!def("ADR", $2, $4)) next; A[++na] = $2; A_ST[$2] = $3; A_LOC[$2] = $4 }
$1 == "REF"       { RF[++nr] = $2; RF_LOC[nr] = $3 }

END {
  for (i = 1; i <= np; i++) if (P_ST[P[i]] !~ /^(Draft|Accepted|Deprecated)$/)
    err("requirement " P[i] " at " P_LOC[P[i]] " has invalid status '" P_ST[P[i]] "' (Draft|Accepted|Deprecated)")
  for (s in S_ST) if (S_ST[s] !~ /^(Draft|Accepted|Deprecated)$/)
    err("spec " s " at " S_LOC[s] " has invalid status '" S_ST[s] "' (Draft|Accepted|Deprecated)")
  for (i = 1; i <= na; i++) if (A_ST[A[i]] !~ /^(Proposed|Accepted|Rejected|Deprecated|Superseded by ADR-[0-9][0-9][0-9][0-9])$/)
    err("ADR " A[i] " at " A_LOC[A[i]] " has invalid status '" A_ST[A[i]] "'")

  for (i = 1; i <= nr; i++) {
    id = RF[i]; f = RF_LOC[i]; sub(/:[0-9]+$/, "", f)
    if (!(id in DEF)) err("unknown ID " id " referenced at " RF_LOC[i])
    else if (id ~ /^ADR-/ && index(A_LOC[id], f ":") != 1 && !((id, f) in SEEN)) { SEEN[id, f] = 1; add(A_REFS, id, f) }
  }

  for (i = 1; i <= ns; i++) {
    label = C_ID[i] != "" ? C_ID[i] : C_LOC[i]
    if (C_ID[i] != "" && !(substr(C_ID[i], 1, 8) in DEF)) err("scenario ID " C_ID[i] " at " C_LOC[i] " names a spec that does not exist")
    n = split(C_RULES[i], rs, ",")
    if (C_ST[i] == "accepted") {
      nacc++
      if (C_N[i] == 0) err("accepted scenario at " C_LOC[i] " has no scenario ID tag (@SPEC-NNN-Snn)")
      if (n == 0) err("accepted scenario " label " traces to no spec rule (@SPEC-NNN-Rn on its Rule or Scenario)")
      for (j = 1; j <= n; j++) {
        add(R_ACC, rs[j], label)
        if ((rs[j] in R_ST) && R_ST[rs[j]] != "Accepted")
          err("accepted scenario " label " illustrates rule " rs[j] " whose status is " R_ST[rs[j]])
      }
    } else {
      ndraft++
      for (j = 1; j <= n; j++) add(R_DRAFT, rs[j], label)
    }
  }

  for (i = 1; i <= nrule; i++) {
    r = R[i]
    n = split(R_PRD[r], ps, ",")
    for (j = 1; j <= n; j++) if (!((r, ps[j]) in RP)) { RP[r, ps[j]] = 1; add(P_RULES, ps[j], r) }
    if (R_ST[r] != "Accepted") continue
    nracc++
    if (R_ACC[r] == "" && R_VERI[r] == "") {
      if (R_WAIV[r]) warn("accepted rule " r " is verified by neither scenario nor test (waiver at " R_LOC[r] ")")
      else err("accepted rule " r " at " R_LOC[r] " has no accepted scenario and no 'verifies:' test")
    }
    if (R_IMPL[r] == "") warn("accepted rule " r " has no 'implements:' annotation in code")
    if (n == 0) warn("accepted rule " r " traces to no PRD requirement")
    for (j = 1; j <= n; j++) if ((ps[j] in P_ST) && P_ST[ps[j]] != "Accepted")
      warn("accepted rule " r " relies on requirement " ps[j] " whose status is " P_ST[ps[j]])
  }
  for (i = 1; i <= nim; i++) if ((IM[i] in R_ST) && R_ST[IM[i]] != "Accepted")
    warn("annotation at " IM_LOC[i] " points to rule " IM[i] " whose status is " R_ST[IM[i]])
  for (i = 1; i <= np; i++) {
    if (P_ST[P[i]] == "Accepted") npacc++
    if (P_ST[P[i]] == "Accepted" && P_SPECS[P[i]] == "" && P_RULES[P[i]] == "")
      warn("accepted requirement " P[i] " is not referenced by any spec")
  }
  for (i = 1; i <= na; i++) if (A_ST[A[i]] == "Accepted") naacc++

  for (i = 1; i <= ne; i++) print "ERROR: " E[i]
  for (i = 1; i <= nw; i++) print "WARN:  " W[i]

  if (out != "") {
    print "# Traceability matrix\n" > out
    print "> Generated by `tools/trace.sh matrix`. Do not edit by hand. ID formats: `docs/standards/traceability.md`.\n" > out
    print "## Summary\n\n| Item | Accepted | Total |\n| --- | --- | --- |" > out
    print "| PRD requirements | " npacc + 0 " | " np + 0 " |" > out
    print "| Spec rules | " nracc + 0 " | " nrule + 0 " |" > out
    print "| Gherkin scenarios | " nacc + 0 " | " nacc + ndraft " |" > out
    print "| ADRs | " naacc + 0 " | " na + 0 " |" > out
    print "| Findings | " ne + 0 " errors | " nw + 0 " warnings |\n" > out

    print "## Requirements → spec rules\n" > out
    if (np == 0) print "_None._" > out
    else { print "| Requirement | Status | Specs | Rules |\n| --- | --- | --- | --- |" > out
      for (i = 1; i <= np; i++) row(4, P[i], P_ST[P[i]], P_SPECS[P[i]], P_RULES[P[i]]) }

    print "\n## Spec rules → scenarios, tests, code\n" > out
    if (nrule == 0) print "_None._" > out
    else { print "| Rule | Status | Keyword | Requirements | Accepted scenarios | Draft scenarios | Tests (`verifies:`) | Code (`implements:`) |" > out
      print "| --- | --- | --- | --- | --- | --- | --- | --- |" > out
      for (i = 1; i <= nrule; i++) { r = R[i]; p = R_PRD[r]; gsub(/,/, ", ", p)
        row(8, r, R_ST[r] (R_WAIV[r] ? " (waiver)" : ""), R_STR[r], p, R_ACC[r], R_DRAFT[r], R_VERI[r], R_IMPL[r]) } }

    print "\n## Scenarios\n" > out
    if (ns == 0) print "_None._" > out
    else { print "| Scenario | Status | Location | Name | Rules |\n| --- | --- | --- | --- | --- |" > out
      for (i = 1; i <= ns; i++) { rr = C_RULES[i]; gsub(/,/, ", ", rr); row(5, C_ID[i], C_ST[i], C_LOC[i], C_NAME[i], rr) } }

    print "\n## Architecture decisions\n" > out
    if (na == 0) print "_None._" > out
    else { print "| ADR | Status | File | Referenced from |\n| --- | --- | --- | --- |" > out
      for (i = 1; i <= na; i++) { f = A_LOC[A[i]]; sub(/:[0-9]+$/, "", f); row(4, A[i], A_ST[A[i]], f, A_REFS[A[i]]) } }

    print "\n## Findings\n" > out
    if (ne + nw == 0) print "_None._" > out
    for (i = 1; i <= ne; i++) print "- **ERROR:** " E[i] > out
    for (i = 1; i <= nw; i++) print "- WARN: " W[i] > out
  }
  exit (ne > 0)
}
AWK

# Runs extraction over all inputs and prints records to stdout.
extract() {
  classify_files
  local refs=(${prd[@]+"${prd[@]}"} ${specs[@]+"${specs[@]}"} ${features[@]+"${features[@]}"}
              ${adrs[@]+"${adrs[@]}"} ${docrefs[@]+"${docrefs[@]}"} ${code[@]+"${code[@]}"})
  [ ${#prd[@]} -eq 0 ] || awk -v kind=prd "$EXTRACT_AWK" "${prd[@]}"
  [ ${#adrs[@]} -eq 0 ] || awk -v kind=adr "$EXTRACT_AWK" "${adrs[@]}"
  [ ${#specs[@]} -eq 0 ] || awk -v kind=spec "$EXTRACT_AWK" "${specs[@]}"
  [ ${#features[@]} -eq 0 ] || awk -v kind=feature "$EXTRACT_AWK" "${features[@]}"
  if [ ${#code[@]} -gt 0 ]; then
    { grep -nHIE '(implements|verifies):' -- "${code[@]}" || true; } | awk -v kind=annot "$EXTRACT_AWK"
  fi
  if [ ${#refs[@]} -gt 0 ]; then
    { grep -noHIE "$ID_RE" -- "${refs[@]}" || true; } | awk -v kind=ref "$EXTRACT_AWK"
  fi
}

# analyze OUT: prints findings; writes the matrix to OUT unless empty; returns 1 on errors.
analyze() { extract | awk -v out="$1" "$ANALYZE_AWK"; }

next_id() {
  local n
  case "${1:-}" in
    prd)  n=$(grep -oE '^\|[[:space:]]*PRD-[0-9]{3}' docs/product/PRD.md 2>/dev/null | grep -oE '[0-9]{3}' | sort -n | tail -1)
          printf 'PRD-%03d\n' $((10#${n:-0} + 1)) ;;
    spec) n=$(ls specs 2>/dev/null | grep -oE '^[0-9]{3}' | sort -n | tail -1)
          printf 'SPEC-%03d\n' $((10#${n:-0} + 1)) ;;
    adr)  n=$(ls docs/architecture/adr 2>/dev/null | grep -oE '^[0-9]{4}' | sort -n | tail -1)
          printf 'ADR-%04d\n' $((10#${n:-0} + 1)) ;;
    *) usage ;;
  esac
}

case "${1:-}" in
  check)
    status=0
    tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
    analyze "$tmp" || status=1
    if ! cmp -s "$tmp" "$MATRIX_DEFAULT"; then
      echo "ERROR: $MATRIX_DEFAULT is out of date; run tools/trace.sh matrix"
      status=1
    fi
    [ $status -eq 0 ] && echo "trace: OK"
    exit $status ;;
  matrix)
    out="${2:-$MATRIX_DEFAULT}"
    mkdir -p "$(dirname "$out")"
    analyze "$out" || true
    echo "trace: wrote $out" ;;
  next) next_id "${2:-}" ;;
  *) usage ;;
esac
