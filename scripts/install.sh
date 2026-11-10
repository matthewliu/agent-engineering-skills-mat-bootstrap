#!/usr/bin/env bash
# Install agent-engineering-skills for the current user, or into a repo.
# Idempotent. Only creates, updates, or deletes entries this script manages.

unset CDPATH
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
MARKER=".managed-by-agent-engineering-skills"
SLUG_RE='^[a-z0-9]+(-[a-z0-9]+)*$'

DRY_RUN=0
UNINSTALL=0
UNINSTALL_FAILED=0
INSTALL_FAILED=0
PROJECT=""
BOUNDARY=""
STAGING=""
OLD_ASIDE=""
DEST_PATH=""

usage() {
  cat <<'EOF'
Usage: install.sh [--dry-run] [--uninstall] [--project <path>]

With no flags, install every skill in this repo for the current user:
  symlink  ~/.claude/skills/<slug>     (Claude Code)
  symlink  ~/.agents/skills/<slug>     (Codex and local Cursor)
  copy     ~/.cursor/skills/<slug>     (Cursor cloud-agent sync)

--project <path> installs copies into that repo instead of the home
directory:
  <path>/.cursor/skills/<slug>
  <path>/.agents/skills/<slug>
  <path>/.claude/skills/<slug>

The path is required, must not be empty, and must not start with "-".
Copies are real files. A re-run replaces managed copies, so local edits
inside those copies are overwritten.

Managed copies contain .managed-by-agent-engineering-skills, and that
file names the slug. Symlinks are managed only when they point at
skills/<slug> in this clone. A manifest lists those slugs. Invalid
manifest lines are refused. This script does not delete other files.
Interrupted copies are removed only when the directory name starts with
.aes-staging. or .aes-old. A user backup such as product-spec.old.bak
is left alone.

A symlinked skills root is refused. Install and uninstall report that
root, skip it, continue with the others, then exit nonzero.

--uninstall removes managed entries listed in the manifest. It does not
sweep every directory that happens to contain a marker.
--dry-run prints the same actions and changes nothing.

Claude Code: the script prints an @ import line for the rule file.
Codex and Cursor still get the full text to paste. Nothing is edited.
EOF
}

cleanup() {
  if [[ -n "$OLD_ASIDE" && -n "$DEST_PATH" && ! -e "$DEST_PATH" && -e "$OLD_ASIDE" ]]; then
    mv "$OLD_ASIDE" "$DEST_PATH" 2>/dev/null || true
  fi
  if [[ -n "$STAGING" && -d "$STAGING" ]]; then
    rm -rf -- "$STAGING"
  fi
}
trap cleanup EXIT

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --uninstall)
      UNINSTALL=1
      shift
      ;;
    --project)
      if [[ $# -lt 2 ]]; then
        echo "error: --project requires a path" >&2
        exit 2
      fi
      PROJECT="$2"
      shift 2
      if [[ -z "$PROJECT" ]]; then
        echo "error: --project path is empty" >&2
        exit 2
      fi
      case "$PROJECT" in
        -*)
          echo "error: --project path must not start with -" >&2
          exit 2
          ;;
      esac
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

say() {
  printf '%s\n' "$*"
}

valid_slug() {
  [[ "$1" =~ $SLUG_RE ]]
}

path_is_inside() {
  local boundary="$1"
  local path="$2"
  case "$path" in
    "$boundary"|"$boundary"/*) return 0 ;;
  esac
  return 1
}

phys_dir() {
  local dir="$1"
  local phys
  phys="$(cd "$dir" && pwd -P)" || return 1
  printf '%s\n' "$phys"
}

skill_slugs=()
collect_skills() {
  local dir base
  skill_slugs=()
  for dir in "$ROOT/skills"/*; do
    [[ -d "$dir" ]] || continue
    [[ -f "$dir/SKILL.md" ]] || continue
    base="$(basename "$dir")"
    if ! valid_slug "$base"; then
      echo "error: skill folder is not a kebab-case slug: $base" >&2
      exit 1
    fi
    skill_slugs+=("$base")
  done
  if [[ ${#skill_slugs[@]} -eq 0 ]]; then
    echo "error: no skills found under $ROOT/skills" >&2
    exit 1
  fi
}

slug_in_library() {
  local needle="$1"
  local slug
  if [[ ${#skill_slugs[@]} -eq 0 ]]; then
    return 1
  fi
  for slug in "${skill_slugs[@]}"; do
    if [[ "$slug" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

require_regular_manifest() {
  local file="$1"
  if [[ -L "$file" ]]; then
    echo "error: refusing symlinked manifest: $file" >&2
    exit 1
  fi
  if [[ ! -f "$file" ]]; then
    echo "error: manifest is not a regular file: $file" >&2
    exit 1
  fi
}

validate_manifest_lines() {
  local file="$1"
  local line
  local bad=0
  if [[ ! -e "$file" && ! -L "$file" ]]; then
    return 0
  fi
  require_regular_manifest "$file"
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    if ! valid_slug "$line"; then
      echo "error: refusing invalid manifest entry in $file: $line" >&2
      bad=1
    fi
  done <"$file"
  if [[ "$bad" -ne 0 ]]; then
    exit 1
  fi
}

marker_names_slug() {
  local file="$1"
  local slug="$2"
  [[ -f "$file" && ! -L "$file" ]] || return 1
  grep -qx "agent-engineering-skills" "$file" || return 1
  grep -qx "slug: $slug" "$file" || return 1
}

link_points_at_library() {
  local link="$1"
  local slug="$2"
  local target stored
  stored="$(readlink "$link")" || return 1
  case "$stored" in
    /*) target="$stored" ;;
    *) target="$(dirname "$link")/$stored" ;;
  esac
  if [[ -d "$target" ]]; then
    target="$(phys_dir "$target")" || return 1
  fi
  [[ "$target" == "$ROOT/skills/$slug" ]]
}

child_is_contained() {
  local parent="$1"
  local slug="$2"
  local path parent_phys dir_phys
  valid_slug "$slug" || return 1
  [[ -d "$parent" && ! -L "$parent" ]] || return 1
  parent_phys="$(phys_dir "$parent")" || return 1
  path_is_inside "$BOUNDARY" "$parent_phys" || return 1
  path="$parent/$slug"
  if [[ -e "$path" || -L "$path" ]]; then
    dir_phys="$(phys_dir "$(dirname "$path")")" || return 1
  else
    dir_phys="$parent_phys"
  fi
  [[ "$dir_phys" == "$parent_phys" ]]
}

remove_contained() {
  local parent="$1"
  local slug="$2"
  local path
  if ! child_is_contained "$parent" "$slug"; then
    echo "error: refusing to touch $parent/$slug" >&2
    exit 1
  fi
  path="$parent/$slug"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    say "would remove $path"
    return 0
  fi
  rm -rf -- "$path"
  say "removed $path"
}

ensure_skills_root() {
  local dir="$1"
  local host anchor anchor_phys phys
  host="$(dirname "$dir")"
  if [[ -n "$PROJECT" ]]; then
    if [[ -L "$host" ]]; then
      echo "error: refusing symlinked path: $host" >&2
      exit 1
    fi
    if [[ -L "$dir" ]]; then
      echo "error: refusing symlinked path: $dir" >&2
      exit 1
    fi
  fi
  anchor="$dir"
  if [[ ! -d "$anchor" ]]; then
    anchor="$(dirname "$dir")"
  fi
  if [[ ! -d "$anchor" ]]; then
    anchor="$(dirname "$anchor")"
  fi
  anchor_phys="$(phys_dir "$anchor")" || exit 1
  if ! path_is_inside "$BOUNDARY" "$anchor_phys"; then
    echo "error: $dir is outside the install boundary ($anchor_phys)" >&2
    exit 1
  fi
  if [[ -d "$dir" ]]; then
    phys="$(phys_dir "$dir")" || exit 1
    if ! path_is_inside "$BOUNDARY" "$phys"; then
      echo "error: $dir resolves outside the install boundary ($phys)" >&2
      exit 1
    fi
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    say "would create directory $dir"
    return 0
  fi
  mkdir -p "$dir"
  phys="$(phys_dir "$dir")" || exit 1
  if ! path_is_inside "$BOUNDARY" "$phys"; then
    echo "error: created $dir outside the install boundary ($phys)" >&2
    exit 1
  fi
}

prune_leftovers() {
  local parent="$1"
  local d
  [[ -d "$parent" && ! -L "$parent" ]] || return 0
  for d in "$parent"/.aes-staging.* "$parent"/.aes-old.*; do
    [[ -e "$d" || -L "$d" ]] || continue
    [[ -L "$d" ]] && continue
    [[ -d "$d" && -f "$d/$MARKER" ]] || continue
    grep -qx "agent-engineering-skills" "$d/$MARKER" || continue
    if [[ "$DRY_RUN" -eq 1 ]]; then
      say "would remove leftover $d"
    else
      rm -rf -- "$d"
      say "removed leftover $d"
    fi
  done
}

copy_skill() {
  local parent="$1"
  local src="$2"
  local dest="$3"
  local slug="$4"
  local tmp old links
  links="$(find "$src" -type l)"
  if [[ -n "$links" ]]; then
    echo "error: source skill contains symlinks: $src" >&2
    return 2
  fi
  tmp="$(mktemp -d "$parent/.aes-staging.XXXXXX")" || return 2
  STAGING="$tmp"
  if ! cp -R "$src/." "$tmp/"; then
    echo "error: copy failed: $src" >&2
    rm -rf -- "$tmp"
    STAGING=""
    return 2
  fi
  if ! printf 'agent-engineering-skills\nslug: %s\n' "$slug" >"$tmp/$MARKER"; then
    echo "error: could not write marker for $slug" >&2
    rm -rf -- "$tmp"
    STAGING=""
    return 2
  fi
  if ! chmod -R u+w "$tmp"; then
    echo "error: could not make the staged copy writable: $src" >&2
    rm -rf -- "$tmp"
    STAGING=""
    return 2
  fi
  old=""
  if [[ -e "$dest" || -L "$dest" ]]; then
    old="$(mktemp -d "$parent/.aes-old.XXXXXX")" || return 2
    if ! rmdir "$old"; then
      rm -rf -- "$tmp"
      STAGING=""
      return 2
    fi
    OLD_ASIDE="$old"
    DEST_PATH="$dest"
    if ! mv "$dest" "$old"; then
      echo "error: could not move the existing copy aside: $dest" >&2
      rm -rf -- "$tmp"
      STAGING=""
      OLD_ASIDE=""
      return 2
    fi
  fi
  if ! mv "$tmp" "$dest"; then
    echo "error: could not move the staged copy into place: $dest" >&2
    STAGING=""
    if [[ -n "$old" && ! -e "$dest" ]]; then
      mv "$old" "$dest" || echo "error: failed to restore $dest" >&2
    fi
    OLD_ASIDE=""
    rm -rf -- "$tmp"
    return 2
  fi
  STAGING=""
  OLD_ASIDE=""
  DEST_PATH=""
  if [[ -n "$old" ]]; then
    rm -rf -- "$old"
  fi
  return 0
}

install_entry() {
  local parent="$1"
  local mode="$2"
  local slug="$3"
  local src="$4"
  local dest reason owned
  dest="$parent/$slug"
  owned=0
  reason=""

  if [[ ! -e "$dest" && ! -L "$dest" ]]; then
    owned=1
  elif [[ -L "$dest" ]]; then
    if link_points_at_library "$dest" "$slug"; then
      owned=1
    else
      reason="unmanaged symlink"
    fi
  elif [[ -d "$dest" && ! -L "$dest" ]] && marker_names_slug "$dest/$MARKER" "$slug"; then
    owned=1
  else
    reason="unmanaged path"
  fi

  if [[ "$owned" -eq 0 ]]; then
    say "skip $dest ($reason)"
    return 1
  fi

  if [[ "$mode" == "link" ]]; then
    if [[ -e "$dest" && ! -L "$dest" ]]; then
      remove_contained "$parent" "$slug" || return 2
    fi
    if [[ "$DRY_RUN" -eq 1 ]]; then
      say "would symlink $dest -> $src"
    else
      if ! ln -sfn "$src" "$dest"; then
        echo "error: could not symlink $dest" >&2
        return 2
      fi
      say "symlinked $dest -> $src"
    fi
  else
    if [[ -L "$dest" ]]; then
      remove_contained "$parent" "$slug" || return 2
    fi
    if [[ "$DRY_RUN" -eq 1 ]]; then
      say "would copy $src -> $dest"
    else
      copy_skill "$parent" "$src" "$dest" "$slug" || return 2
      say "copied $src -> $dest"
    fi
  fi
  return 0
}

prune_stale() {
  local parent="$1"
  local old="$2"
  local slug path
  while IFS= read -r slug || [[ -n "$slug" ]]; do
    [[ -z "$slug" ]] && continue
    if slug_in_library "$slug"; then
      continue
    fi
    path="$parent/$slug"
    if [[ -L "$path" ]]; then
      if link_points_at_library "$path" "$slug"; then
        remove_contained "$parent" "$slug"
      else
        say "leaving unmanaged symlink: $path"
      fi
    elif [[ -d "$path" && ! -L "$path" ]] && marker_names_slug "$path/$MARKER" "$slug"; then
      remove_contained "$parent" "$slug"
    elif [[ -e "$path" || -L "$path" ]]; then
      say "leaving unmanaged stale entry: $path"
    fi
  done <<< "$old"
}

write_manifest() {
  local parent="$1"
  local body="$2"
  local file tmp
  file="$parent/$MARKER"
  if [[ -L "$file" ]]; then
    echo "error: refusing symlinked manifest: $file" >&2
    exit 1
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    say "would write $file"
    if [[ -n "$body" ]]; then
      printf '%s' "$body" | sed 's/^/  /'
    fi
    return 0
  fi
  if [[ -z "$body" ]]; then
    rm -f -- "$file"
    return 0
  fi
  tmp="$(mktemp "$parent/.aes-manifest.XXXXXX")"
  if ! printf '%s' "$body" >"$tmp"; then
    rm -f -- "$tmp"
    echo "error: could not write manifest: $file" >&2
    exit 1
  fi
  if ! mv "$tmp" "$file"; then
    rm -f -- "$tmp"
    echo "error: could not replace manifest: $file" >&2
    exit 1
  fi
}

process_root() {
  local parent="$1"
  local mode="$2"
  local manifest old slug src current rc
  if [[ -L "$parent" ]]; then
    echo "error: refusing symlinked skills directory: $parent" >&2
    return 1
  fi
  manifest="$parent/$MARKER"
  ensure_skills_root "$parent"
  if [[ "$DRY_RUN" -eq 0 || -d "$parent" ]]; then
    if [[ -e "$manifest" || -L "$manifest" ]]; then
      validate_manifest_lines "$manifest"
    fi
  fi
  old=""
  if [[ -f "$manifest" && ! -L "$manifest" ]]; then
    old="$(cat "$manifest")"
  fi
  if [[ "$DRY_RUN" -eq 0 ]]; then
    prune_leftovers "$parent"
  fi
  current=""
  for slug in "${skill_slugs[@]}"; do
    src="$ROOT/skills/$slug"
    set +e
    install_entry "$parent" "$mode" "$slug" "$src"
    rc=$?
    set -e
    if [[ "$rc" -eq 0 ]]; then
      current="${current}${slug}"$'\n'
    elif [[ "$rc" -eq 1 ]]; then
      :
    else
      exit "$rc"
    fi
  done
  prune_stale "$parent" "$old"
  write_manifest "$parent" "$current"
}

uninstall_root() {
  local parent="$1"
  local manifest slug path
  manifest="$parent/$MARKER"
  if [[ ! -d "$parent" && ! -L "$parent" ]]; then
    say "nothing to uninstall in $parent"
    return 0
  fi
  if [[ -L "$parent" ]]; then
    echo "error: refusing symlinked skills directory: $parent" >&2
    return 1
  fi
  ensure_skills_root "$parent"
  if [[ ! -e "$manifest" && ! -L "$manifest" ]]; then
    return 0
  fi
  validate_manifest_lines "$manifest"
  while IFS= read -r slug || [[ -n "$slug" ]]; do
    [[ -z "$slug" ]] && continue
    path="$parent/$slug"
    if [[ -L "$path" ]]; then
      if link_points_at_library "$path" "$slug"; then
        remove_contained "$parent" "$slug"
      else
        say "leaving unmanaged symlink: $path"
      fi
    elif [[ -d "$path" && ! -L "$path" ]] && marker_names_slug "$path/$MARKER" "$slug"; then
      remove_contained "$parent" "$slug"
    elif [[ -e "$path" || -L "$path" ]]; then
      say "leaving unmanaged path: $path"
    fi
  done <"$manifest"
  if [[ -L "$manifest" ]]; then
    echo "error: refusing symlinked manifest: $manifest" >&2
    exit 1
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    say "would remove $manifest"
  else
    rm -f -- "$manifest"
    say "removed $manifest"
  fi
}

rule_body() {
  awk '
    NR == 1 {
      if ($0 != "---") {
        print "engineering-preferences SKILL.md is missing frontmatter" > "/dev/stderr"
        exit 2
      }
      next
    }
    !closed && $0 == "---" { closed = 1; next }
    closed && !ate_blank && $0 == "" { ate_blank = 1; next }
    closed { ate_blank = 1; print }
  ' "$ROOT/skills/engineering-preferences/SKILL.md"
}

refresh_rule() {
  local dest body tmp
  dest="$ROOT/rules/engineering-preferences.md"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    say "would refresh $dest from skills/engineering-preferences/SKILL.md when the text differs"
    return 0
  fi
  if ! body="$(rule_body)"; then
    echo "warning: could not render engineering preferences; leaving the rule file unchanged" >&2
    return 0
  fi
  if [[ ! -d "$ROOT/rules" ]]; then
    if ! mkdir -p "$ROOT/rules"; then
      echo "warning: clone is read-only; not updating $dest" >&2
      return 0
    fi
  fi
  if [[ ! -w "$ROOT/rules" ]]; then
    echo "warning: clone is read-only; not updating $dest" >&2
    return 0
  fi
  tmp="$(mktemp "$ROOT/rules/.rule.XXXXXX")" || {
    echo "warning: clone is read-only; not updating $dest" >&2
    return 0
  }
  if ! printf '%s\n' "$body" >"$tmp"; then
    rm -f -- "$tmp"
    echo "warning: could not write a temporary rule file; leaving $dest unchanged" >&2
    return 0
  fi
  if [[ -f "$dest" ]] && cmp -s "$dest" "$tmp"; then
    rm -f -- "$tmp"
    return 0
  fi
  if ! mv "$tmp" "$dest"; then
    rm -f -- "$tmp"
    echo "warning: could not replace $dest; leaving it unchanged" >&2
    return 0
  fi
  say "refreshed $dest"
}

print_rule_block() {
  local claude_file codex_file cursor_note import_line
  import_line="@${ROOT}/rules/engineering-preferences.md"
  if [[ -n "$PROJECT" ]]; then
    claude_file="$PROJECT/CLAUDE.md"
    codex_file="$PROJECT/AGENTS.md"
    cursor_note="Cursor project rules for $PROJECT"
  else
    claude_file="${HOME}/.claude/CLAUDE.md"
    codex_file="${HOME}/.codex/AGENTS.md"
    cursor_note="Cursor User Rules"
  fi
  if [[ "$UNINSTALL" -eq 1 ]]; then
    cat <<EOF

The installer does not edit instruction files. If you added engineering
preferences earlier, remove that import or pasted block yourself from:
  $claude_file
  $codex_file
  $cursor_note
EOF
    return 0
  fi
  cat <<EOF

Add this line to $claude_file:

$import_line

Claude Code imports that file. Do not paste a second copy there.

Paste the text below into $codex_file and into $cursor_note.
Cursor does not load the rule file automatically. User rules are pasted by hand.
The installer does not edit any of these files.

skills/engineering-preferences/SKILL.md is canonical. rules/engineering-preferences.md is that file with the frontmatter removed.

--- begin engineering-preferences ---
EOF
  rule_body
  printf '%s\n' "--- end engineering-preferences ---"
}

run_user_roots() {
  local path mode
  while IFS= read -r path; do
    mode="${path##*|}"
    path="${path%%|*}"
    if [[ "$UNINSTALL" -eq 1 ]]; then
      uninstall_root "$path" || UNINSTALL_FAILED=1
    else
      process_root "$path" "$mode" || INSTALL_FAILED=1
    fi
  done <<EOF
${HOME}/.claude/skills|link
${HOME}/.agents/skills|link
${HOME}/.cursor/skills|copy
EOF
}

run_project_roots() {
  local path
  for path in "$PROJECT/.cursor/skills" "$PROJECT/.agents/skills" "$PROJECT/.claude/skills"; do
    if [[ "$UNINSTALL" -eq 1 ]]; then
      uninstall_root "$path" || UNINSTALL_FAILED=1
    else
      process_root "$path" "copy" || INSTALL_FAILED=1
    fi
  done
}

if [[ -n "$PROJECT" ]]; then
  if [[ ! -d "$PROJECT" ]]; then
    echo "error: project path is not a directory: $PROJECT" >&2
    exit 2
  fi
  PROJECT="$(cd "$PROJECT" && pwd -P)"
  BOUNDARY="$PROJECT"
else
  if [[ -z "${HOME:-}" || ! -d "$HOME" ]]; then
    echo "error: HOME is not set to a directory" >&2
    exit 2
  fi
  HOME="$(cd "$HOME" && pwd -P)"
  BOUNDARY="$HOME"
fi

if [[ "$UNINSTALL" -eq 1 ]]; then
  if [[ -n "$PROJECT" ]]; then
    run_project_roots
  else
    run_user_roots
  fi
  print_rule_block
  if [[ "$UNINSTALL_FAILED" -ne 0 ]]; then
    exit 1
  fi
  exit 0
fi

collect_skills
refresh_rule
if [[ -n "$PROJECT" ]]; then
  run_project_roots
else
  run_user_roots
fi
print_rule_block
if [[ "$INSTALL_FAILED" -ne 0 ]]; then
  exit 1
fi
