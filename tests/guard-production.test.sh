#!/usr/bin/env bash
# Tests for scripts/guard-production.sh (the production lock).
#
# Builds throwaway repositories in a temporary folder: one without dev, one with
# dev, and clones with dev only in the cloud. Then feeds the guard hook inputs and
# checks the exit code (0 = allowed, 2 = blocked), including commands that touch
# a repository other than the conversation folder.
#
# Usage: bash tests/guard-production.test.sh [path/to/guard-production.sh]
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
GUARD="${1:-$HERE/../scripts/guard-production.sh}"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
export CLAUDE_PLUGIN_DATA="$T/plugin-data"
mkdir -p "$CLAUDE_PLUGIN_DATA"
export GIT_CONFIG_GLOBAL=/dev/null
mkdir -p "$T/remote.git" "$T/remote2.git" "$T/nodev" "$T/withdev"
git init -q --bare "$T/remote.git"
git init -q --bare "$T/remote2.git"
for d in nodev withdev; do
  (cd "$T/$d" && git init -q -b main && git config user.email t@t && git config user.name t && echo a > a && git add a && git commit -qm first)
done
(cd "$T/withdev" && git remote add origin "$T/remote.git" && git push -q origin main && git switch -q -c dev && git push -q -u origin dev && git switch -q main)
(cd "$T/nodev" && git remote add origin "$T/remote2.git" && git push -q origin main)
git -C "$T/remote.git" symbolic-ref HEAD refs/heads/main
rm -rf "$T/clone"; git clone -q "$T/remote.git" "$T/clone"
(cd "$T/clone" && git config user.email t@t && git config user.name t)

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\n'/\\n}"; s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

PASS=0; FAILED=0
run() { # cwd-repo command expected-exit
  local cwd json rc ok label
  cwd="$(cygpath -m "$T/$1" 2>/dev/null || echo "$T/$1")"
  json=$(printf '{"tool_name":"Bash","tool_input":{"command":"%s"},"cwd":"%s"}' "$(json_escape "$2")" "$cwd")
  printf '%s' "$json" | bash "$GUARD" >/dev/null 2>&1; rc=$?
  if [ "$rc" = "$3" ]; then ok=ok; PASS=$((PASS + 1)); else ok=FAIL; FAILED=$((FAILED + 1)); fi
  label="${2//$'\n'/ ⏎ }"; label="${label//$T/<T>}"; label="${label//$(cygpath -w "$T" 2>/dev/null || echo "$T")/<T>}"
  printf '%-4s %-8s %-62.62s exit=%s (want %s)\n' "$ok" "$1" "$label" "$rc" "$3"
}
P=push; M=main
W="$T/withdev"; N="$T/nodev"
WW="$(cygpath -w "$W" 2>/dev/null || echo "$W")"

echo "-- same folder (as before)"
run nodev   "git commit -m x"                         0
run nodev   "git $P origin $M"                        0
run nodev   "gh pr create --base $M --head feat"      0
run withdev "git commit -m x"                         2
run withdev "git $P origin $M"                        2
run withdev "gh pr create --base $M --head feat"      2
run withdev "gh pr create --base $M --head dev"       0
run withdev "git switch -c feat && git commit -m x"   0
run clone   "git commit -m x"                         2

echo "-- another folder"
run nodev   "git -C \"$W\" commit -m x"               2
run withdev "git -C \"$N\" commit -m x"               0
run withdev "cd \"$N\" && git commit -m x"            0
run nodev   "cd \"$W\" && git commit -m x"            2
run nodev   "cd .. && git -C withdev commit -m x"     2
run nodev   "R=\"$W\"; git -C \"\$R\" commit -m x"    2
run withdev "R=\"$N\"; git -C \"\$R\" commit -m x"    0
run withdev "git -C \"\$NOT_SET_ANYWHERE\" commit -m x" 0
run nodev   "Set-Location \"$WW\"; git commit -m x"   2
run nodev   "git -C \"$WW\" $P origin $M"             2
run nodev   "git -C \"$W\" switch -c feat && git -C \"$W\" commit -m x" 0
rm -rf "$T/sp ace"; git clone -q "$T/remote.git" "$T/sp ace"
run nodev   "cd \"$T/sp ace\" && git commit -m x"     2
run nodev   "cd '$T/sp ace'; git -C . commit -m x"    2

echo "-- text that is not a command"
run withdev "git switch -c feat && git commit -m \"a; git merge dev && git $P origin $M\"" 0
run withdev "cat > f.sh <<'EOF'
git $P origin $M
EOF"                                                  0
run withdev "bash <<'EOF'
git $P origin $M
EOF"                                                  2
run withdev "# git commit -m x"                       0
run withdev "echo ok # git commit -m x"               0

echo "== $PASS passed, $FAILED failed"
[ "$FAILED" -eq 0 ]
