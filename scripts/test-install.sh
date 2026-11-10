#!/usr/bin/env bash
# Install-matrix tests, including the five adversarial cases.
# Uses a temp HOME and a clone path that both contain spaces.

unset CDPATH
set -euo pipefail

SHELL_BIN="${BASH:-bash}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BASE="$(mktemp -d "${TMPDIR:-/tmp}/aes install.XXXXXX")"
MARKER=".managed-by-agent-engineering-skills"

cleanup() {
  chmod -R u+w "$BASE" 2>/dev/null || true
  rm -rf "$BASE"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'PASS: %s\n' "$1"
}

copy_clone() {
  local dest="$1"
  mkdir -p "$dest"
  cp -a "$ROOT/scripts" "$ROOT/skills" "$ROOT/rules" "$ROOT/README.md" "$ROOT/AGENTS.md" "$ROOT/.github" "$ROOT/.gitignore" "$dest/"
}

skill_count_of() {
  local clone="$1"
  local count=0
  local dir
  for dir in "$clone/skills"/*; do
    if [[ -f "$dir/SKILL.md" ]]; then
      count=$((count + 1))
    fi
  done
  printf '%s\n' "$count"
}

count_links() {
  local parent="$1"
  local count=0
  local path
  for path in "$parent"/*; do
    if [[ -L "$path" ]]; then
      count=$((count + 1))
    fi
  done
  printf '%s\n' "$count"
}

count_copies() {
  local parent="$1"
  local count=0
  local path
  for path in "$parent"/*; do
    if [[ -d "$path" && ! -L "$path" ]]; then
      count=$((count + 1))
    fi
  done
  printf '%s\n' "$count"
}

run_install() {
  local home="$1"
  local clone="$2"
  local log="$3"
  local err="$4"
  shift 4
  set +e
  HOME="$home" "$SHELL_BIN" "$clone/scripts/install.sh" "$@" >"$log" 2>"$err"
  run_rc=$?
  set -e
}

CLONE="$BASE/clone dir"
copy_clone "$CLONE"
CLONE_PHYS="$(cd "$CLONE" && pwd -P)"
EXPECTED="$(skill_count_of "$CLONE")"
if [[ "$EXPECTED" -lt 1 ]]; then
  fail "clone has no skills"
fi

HOME_A="$BASE/My Home"
mkdir -p "$HOME_A"
LOG="$BASE/log.txt"
ERR="$BASE/err.txt"

before="$(find "$HOME_A" -print | sort)"
run_install "$HOME_A" "$CLONE" "$LOG" "$ERR" --dry-run
if [[ "$run_rc" -ne 0 ]]; then
  fail "dry-run exited $run_rc"
fi
after="$(find "$HOME_A" -print | sort)"
if [[ "$before" != "$after" ]]; then
  fail "dry-run wrote files"
fi
pass "dry-run created nothing"

run_install "$HOME_A" "$CLONE" "$LOG" "$ERR"
if [[ "$run_rc" -ne 0 ]]; then
  cat "$ERR" >&2
  fail "real install exited $run_rc"
fi
if [[ "$(count_links "$HOME_A/.claude/skills")" -ne "$EXPECTED" ]]; then
  fail "claude link count"
fi
if [[ "$(count_links "$HOME_A/.agents/skills")" -ne "$EXPECTED" ]]; then
  fail "agents link count"
fi
if [[ "$(count_copies "$HOME_A/.cursor/skills")" -ne "$EXPECTED" ]]; then
  fail "cursor copy count"
fi
if [[ -n "$(find "$HOME_A/.cursor/skills" -type l -print)" ]]; then
  fail "cursor tree contains a symlink"
fi
slug=""
for slug in "$CLONE/skills"/*; do
  slug="$(basename "$slug")"
  [[ -f "$CLONE/skills/$slug/SKILL.md" ]] || continue
  target="$(readlink "$HOME_A/.claude/skills/$slug")"
  if [[ "$target" != "$CLONE_PHYS/skills/$slug" ]]; then
    fail "claude link for $slug points at $target"
  fi
  if [[ -e "$CLONE/skills/$slug/$MARKER" ]]; then
    fail "marker leaked into the library copy of $slug"
  fi
  if ! grep -qx "agent-engineering-skills" "$HOME_A/.cursor/skills/$slug/$MARKER"; then
    fail "cursor marker missing library name for $slug"
  fi
  if ! grep -qx "slug: $slug" "$HOME_A/.cursor/skills/$slug/$MARKER"; then
    fail "cursor marker missing slug for $slug"
  fi
  if ! grep -qx "$slug" "$HOME_A/.claude/skills/$MARKER"; then
    fail "manifest missing $slug"
  fi
done
if ! grep -q "@${CLONE_PHYS}/rules/engineering-preferences.md" "$LOG"; then
  fail "claude import line missing"
fi
pass "real install"

printf '%s\n' "===== FIND ====="
find "$HOME_A" -print | sort
printf '%s\n' "===== END FIND ====="

find "$HOME_A" -print | sort >"$BASE/tree1"
run_install "$HOME_A" "$CLONE" "$LOG" "$ERR"
if [[ "$run_rc" -ne 0 ]]; then
  fail "re-run exited $run_rc"
fi
find "$HOME_A" -print | sort >"$BASE/tree2"
if ! cmp -s "$BASE/tree1" "$BASE/tree2"; then
  fail "re-run changed the tree"
fi
pass "re-run left the tree unchanged"

MIG_CLONE="$BASE/review migration clone"
MIG_HOME="$BASE/review migration home"
copy_clone "$MIG_CLONE"
mkdir -p "$MIG_HOME"
mv "$MIG_CLONE/skills/herdr-code-review" "$MIG_CLONE/skills/cloud-agent-pr-review"
run_install "$MIG_HOME" "$MIG_CLONE" "$LOG" "$ERR"
if [[ "$run_rc" -ne 0 ]]; then
  fail "legacy review install exited $run_rc"
fi
for host in .claude .agents .cursor; do
  if [[ ! -f "$MIG_HOME/$host/skills/cloud-agent-pr-review/SKILL.md" ]]; then
    fail "legacy review skill missing for $host"
  fi
done
mv "$MIG_CLONE/skills/cloud-agent-pr-review" "$MIG_CLONE/skills/herdr-code-review"
run_install "$MIG_HOME" "$MIG_CLONE" "$LOG" "$ERR"
if [[ "$run_rc" -ne 0 ]]; then
  fail "review migration exited $run_rc"
fi
for host in .claude .agents .cursor; do
  old_review="$MIG_HOME/$host/skills/cloud-agent-pr-review"
  if [[ -e "$old_review" || -L "$old_review" ]]; then
    fail "retired managed review skill remained for $host"
  fi
  if [[ ! -f "$MIG_HOME/$host/skills/herdr-code-review/SKILL.md" ]]; then
    fail "replacement review skill missing for $host"
  fi
  if grep -qx cloud-agent-pr-review "$MIG_HOME/$host/skills/$MARKER"; then
    fail "retired review skill remained in manifest for $host"
  fi
done
pass "retired managed review skill migrated to Herdr review on all hosts"

rm "$HOME_A/.claude/skills/product-spec"
mkdir -p "$HOME_A/.claude/skills/product-spec"
printf 'user owned\n' >"$HOME_A/.claude/skills/product-spec/SKILL.md"
run_install "$HOME_A" "$CLONE" "$LOG" "$ERR"
if [[ "$run_rc" -ne 0 ]]; then
  fail "unmanaged re-run exited $run_rc"
fi
if ! grep -qx "user owned" "$HOME_A/.claude/skills/product-spec/SKILL.md"; then
  fail "unmanaged skill was replaced"
fi
if ! grep -q "unmanaged" "$LOG"; then
  fail "unmanaged skip was not reported"
fi
pass "unmanaged same-slug directory was left alone"

PROJ="$BASE/team repo"
mkdir -p "$PROJ"
home_before="$(find "$HOME_A" -print | sort)"
run_install "$HOME_A" "$CLONE" "$LOG" "$ERR" --project "$PROJ"
if [[ "$run_rc" -ne 0 ]]; then
  cat "$ERR" >&2
  fail "project install exited $run_rc"
fi
home_after="$(find "$HOME_A" -print | sort)"
if [[ "$home_before" != "$home_after" ]]; then
  fail "project install wrote to HOME"
fi
if [[ "$(count_copies "$PROJ/.cursor/skills")" -ne "$EXPECTED" ]]; then
  fail "project cursor copies"
fi
if [[ "$(count_copies "$PROJ/.agents/skills")" -ne "$EXPECTED" ]]; then
  fail "project agents copies"
fi
if [[ "$(count_copies "$PROJ/.claude/skills")" -ne "$EXPECTED" ]]; then
  fail "project claude copies"
fi
if [[ -n "$(find "$PROJ" -type l -print)" ]]; then
  fail "project install created a symlink"
fi
mkdir -p "$PROJ/.claude/skills/team-notes"
printf 'keep\n' >"$PROJ/.claude/skills/team-notes/SKILL.md"
run_install "$HOME_A" "$CLONE" "$LOG" "$ERR" --project "$PROJ" --uninstall
if [[ "$run_rc" -ne 0 ]]; then
  fail "project uninstall exited $run_rc"
fi
if [[ ! -f "$PROJ/.claude/skills/team-notes/SKILL.md" ]]; then
  fail "project uninstall removed an unmanaged skill"
fi
if [[ -e "$PROJ/.claude/skills/product-spec" ]]; then
  fail "project uninstall left a managed copy"
fi
pass "project install and uninstall"

OUTSIDE="$BASE/outside dir"
LINK_PROJ="$BASE/link proj"
mkdir -p "$OUTSIDE" "$LINK_PROJ/.cursor" "$LINK_PROJ/.agents" "$LINK_PROJ/.claude"
ln -s "$OUTSIDE" "$LINK_PROJ/.cursor/skills"
run_install "$HOME_A" "$CLONE" "$LOG" "$ERR" --project "$LINK_PROJ"
if [[ "$run_rc" -eq 0 ]]; then
  fail "symlinked project skills dir was accepted"
fi
if [[ -n "$(find "$OUTSIDE" -mindepth 1 -print)" ]]; then
  fail "symlinked skills dir received files"
fi
pass "symlinked project skills directory was refused"

FORK_HOME="$BASE/fork home"
mkdir -p "$FORK_HOME"
run_install "$FORK_HOME" "$CLONE" "$LOG" "$ERR"
if [[ "$run_rc" -ne 0 ]]; then
  fail "fork setup install exited $run_rc"
fi
cp -a "$FORK_HOME/.cursor/skills/product-spec" "$FORK_HOME/.cursor/skills/my-fork"
run_install "$FORK_HOME" "$CLONE" "$LOG" "$ERR" --uninstall
if [[ "$run_rc" -ne 0 ]]; then
  cat "$ERR" >&2
  fail "uninstall exited $run_rc"
fi
if [[ ! -d "$FORK_HOME/.cursor/skills/my-fork" ]]; then
  fail "renamed fork was deleted"
fi
if ! grep -qx "slug: product-spec" "$FORK_HOME/.cursor/skills/my-fork/$MARKER"; then
  fail "renamed fork lost its marker"
fi
if [[ -e "$FORK_HOME/.cursor/skills/product-spec" ]]; then
  fail "managed product-spec copy survived uninstall"
fi
pass "renamed fork survived uninstall"

EVIL_HOME="$BASE/evil home"
mkdir -p "$EVIL_HOME"
run_install "$EVIL_HOME" "$CLONE" "$LOG" "$ERR"
if [[ "$run_rc" -ne 0 ]]; then
  fail "evil setup install exited $run_rc"
fi
printf 'keep\n' >"$EVIL_HOME/sentinel"
ln -s "$EVIL_HOME/sentinel" "$EVIL_HOME/.claude/evil-link"
printf '%s\n' "../evil-link" >>"$EVIL_HOME/.claude/skills/$MARKER"
run_install "$EVIL_HOME" "$CLONE" "$LOG" "$ERR" --uninstall
if [[ "$run_rc" -eq 0 ]]; then
  fail "tampered manifest was accepted"
fi
if [[ ! -L "$EVIL_HOME/.claude/evil-link" ]]; then
  fail "outside symlink was removed"
fi
if ! grep -qx "keep" "$EVIL_HOME/sentinel"; then
  fail "sentinel file changed"
fi
if [[ ! -L "$EVIL_HOME/.claude/skills/product-spec" ]]; then
  fail "valid skill was deleted after a bad manifest line"
fi
pass "tampered manifest with ../ was refused"

COPY_CLONE="$BASE/copy clone"
copy_clone "$COPY_CLONE"
COPY_HOME="$BASE/copy home"
mkdir -p "$COPY_HOME"
run_install "$COPY_HOME" "$COPY_CLONE" "$LOG" "$ERR"
if [[ "$run_rc" -ne 0 ]]; then
  fail "copy setup install exited $run_rc"
fi
cp "$COPY_HOME/.cursor/skills/product-spec/SKILL.md" "$BASE/saved-skill.md"
chmod 000 "$COPY_CLONE/skills/product-spec/SKILL.md"
run_install "$COPY_HOME" "$COPY_CLONE" "$LOG" "$ERR"
if [[ "$run_rc" -eq 0 ]]; then
  fail "unreadable source still exited 0"
fi
if ! grep -q "copy failed" "$ERR"; then
  fail "copy failure was not reported"
fi
if grep -F "copied $COPY_CLONE/skills/product-spec" "$LOG"; then
  fail "failed copy was reported as copied"
fi
if ! cmp -s "$BASE/saved-skill.md" "$COPY_HOME/.cursor/skills/product-spec/SKILL.md"; then
  fail "old cursor copy was not kept"
fi
chmod u+r "$COPY_CLONE/skills/product-spec/SKILL.md" || true
pass "failed copy kept the old copy and exited nonzero"

EMPTY_HOME="$BASE/empty home"
mkdir -p "$EMPTY_HOME"
run_install "$EMPTY_HOME" "$CLONE" "$LOG" "$ERR" --project ""
if [[ "$run_rc" -ne 2 ]]; then
  fail "--project empty string exited $run_rc"
fi
if [[ -n "$(find "$EMPTY_HOME" -mindepth 1 -print)" ]]; then
  fail "--project empty string wrote into HOME"
fi
run_install "$EMPTY_HOME" "$CLONE" "$LOG" "$ERR" --project "-hidden"
if [[ "$run_rc" -ne 2 ]]; then
  fail "--project dash path exited $run_rc"
fi
pass "--project empty and dash paths exit 2"

RO_CLONE="$BASE/ro clone"
copy_clone "$RO_CLONE"
RO_HOME="$BASE/ro home"
mkdir -p "$RO_HOME"
chmod -R a-w "$RO_CLONE"
run_install "$RO_HOME" "$RO_CLONE" "$LOG" "$ERR"
chmod -R u+w "$RO_CLONE"
if [[ "$run_rc" -ne 0 ]]; then
  cat "$ERR" >&2
  fail "read-only clone exited $run_rc"
fi
if ! grep -q "read-only" "$ERR"; then
  fail "read-only clone did not warn"
fi
if [[ "$(count_links "$RO_HOME/.claude/skills")" -ne "$EXPECTED" ]]; then
  fail "read-only clone did not install links"
fi
if [[ ! -w "$RO_HOME/.cursor/skills/architecture-review/SKILL.md" ]]; then
  fail "installed file stayed read-only"
fi
if [[ ! -w "$RO_HOME/.cursor/skills/architecture-review/references" ]]; then
  fail "installed directory stayed read-only"
fi
run_install "$RO_HOME" "$RO_CLONE" "$LOG" "$ERR"
if [[ "$run_rc" -ne 0 ]]; then
  cat "$ERR" >&2
  fail "re-install of a read-only copy exited $run_rc"
fi
ro_left="$(find "$RO_HOME" \( -name '.aes-old.*' -o -name '.aes-staging.*' \) -print)"
if [[ -n "$ro_left" ]]; then
  fail "read-only re-install left staging dirs"
fi
run_install "$RO_HOME" "$RO_CLONE" "$LOG" "$ERR" --uninstall
if [[ "$run_rc" -ne 0 ]]; then
  cat "$ERR" >&2
  fail "uninstall of a read-only copy exited $run_rc"
fi
if [[ -e "$RO_HOME/.cursor/skills/architecture-review" ]]; then
  fail "uninstall left the read-only copy"
fi
pass "read-only clone warned, copies stayed writable, and uninstall succeeded"

BAK_HOME="$BASE/bak home"
mkdir -p "$BAK_HOME"
run_install "$BAK_HOME" "$CLONE" "$LOG" "$ERR"
if [[ "$run_rc" -ne 0 ]]; then
  fail "backup setup install exited $run_rc"
fi
cp -a "$BAK_HOME/.cursor/skills/product-spec" "$BAK_HOME/.cursor/skills/product-spec.old.bak"
run_install "$BAK_HOME" "$CLONE" "$LOG" "$ERR"
if [[ "$run_rc" -ne 0 ]]; then
  fail "install with a user backup exited $run_rc"
fi
if [[ ! -f "$BAK_HOME/.cursor/skills/product-spec.old.bak/SKILL.md" ]]; then
  fail "install deleted product-spec.old.bak"
fi
if ! grep -qx "agent-engineering-skills" "$BAK_HOME/.cursor/skills/product-spec.old.bak/$MARKER"; then
  fail "user backup lost its marker during install"
fi
run_install "$BAK_HOME" "$CLONE" "$LOG" "$ERR" --uninstall
if [[ "$run_rc" -ne 0 ]]; then
  fail "uninstall with a user backup exited $run_rc"
fi
if [[ ! -f "$BAK_HOME/.cursor/skills/product-spec.old.bak/SKILL.md" ]]; then
  fail "uninstall deleted product-spec.old.bak"
fi
if [[ -e "$BAK_HOME/.cursor/skills/product-spec" ]]; then
  fail "uninstall left the managed product-spec copy"
fi
pass "user backup product-spec.old.bak survived install and uninstall"

LINK_HOME="$BASE/link home"
mkdir -p "$LINK_HOME"
run_install "$LINK_HOME" "$CLONE" "$LOG" "$ERR"
if [[ "$run_rc" -ne 0 ]]; then
  fail "symlink setup install exited $run_rc"
fi
mv "$LINK_HOME/.claude/skills" "$LINK_HOME/.claude/skills-real"
ln -s "$LINK_HOME/.claude/skills-real" "$LINK_HOME/.claude/skills"
run_install "$LINK_HOME" "$CLONE" "$LOG" "$ERR" --uninstall
if [[ "$run_rc" -eq 0 ]]; then
  fail "symlinked skills root uninstall exited 0"
fi
if ! grep -q "refusing symlinked skills directory" "$ERR"; then
  fail "symlinked skills root was not reported"
fi
if [[ ! -e "$LINK_HOME/.claude/skills-real/product-spec" ]]; then
  fail "uninstall followed the symlinked skills root"
fi
if [[ -e "$LINK_HOME/.agents/skills/product-spec" ]]; then
  fail "uninstall stopped before the agents root"
fi
if [[ -e "$LINK_HOME/.cursor/skills/product-spec" ]]; then
  fail "uninstall stopped before the cursor root"
fi
pass "symlinked skills root was skipped and the other roots were removed"

SYM_HOME="$BASE/sym install home"
SYM_TARGET="$BASE/sym target"
mkdir -p "$SYM_HOME/.claude" "$SYM_TARGET"
ln -s "$SYM_TARGET" "$SYM_HOME/.claude/skills"
run_install "$SYM_HOME" "$CLONE" "$LOG" "$ERR" --dry-run
if [[ "$run_rc" -eq 0 ]]; then
  fail "dry-run accepted a symlinked skills root"
fi
if ! grep -q "refusing symlinked skills directory" "$ERR"; then
  fail "dry-run did not report the symlinked skills root"
fi
if [[ -n "$(find "$SYM_TARGET" -mindepth 1 -print)" ]]; then
  fail "dry-run followed the symlinked skills root"
fi
if [[ -e "$SYM_HOME/.agents/skills" || -e "$SYM_HOME/.cursor/skills" ]]; then
  fail "dry-run created the other skills roots"
fi
run_install "$SYM_HOME" "$CLONE" "$LOG" "$ERR"
if [[ "$run_rc" -eq 0 ]]; then
  fail "symlinked skills root install exited 0"
fi
if ! grep -q "refusing symlinked skills directory" "$ERR"; then
  fail "symlinked skills root install was not reported"
fi
if [[ -n "$(find "$SYM_TARGET" -mindepth 1 -print)" ]]; then
  fail "install followed the symlinked skills root"
fi
if [[ ! -L "$SYM_HOME/.claude/skills" ]]; then
  fail "install replaced the symlinked skills root"
fi
if [[ "$(count_links "$SYM_HOME/.agents/skills")" -ne "$EXPECTED" ]]; then
  fail "install stopped before the agents root"
fi
if [[ "$(count_copies "$SYM_HOME/.cursor/skills")" -ne "$EXPECTED" ]]; then
  fail "install stopped before the cursor root"
fi
pass "symlinked skills root was skipped at install and the other roots were written"

printf '%s\n' "test-install: ok"
