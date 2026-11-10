#!/usr/bin/env python3
"""Install optional personal workflow instructions without changing team repos."""

import argparse
from datetime import datetime, timezone
from pathlib import Path
import re
import shutil

START = "<!-- aes:personal-herdr begin -->"
END = "<!-- aes:personal-herdr end -->"
ROOT = Path(__file__).resolve().parent.parent


def render(original, policy):
    """Replace the managed block and the superseded personal coordination section."""
    if original.count(START) != original.count(END) or original.count(START) > 1:
        raise ValueError("invalid personal Herdr markers; no files changed")
    if START in original:
        start = original.index(START)
        end = original.index(END)
        if end < start:
            raise ValueError("reversed personal Herdr markers; no files changed")
        original = original[:start] + original[end + len(END):]
    original = re.sub(
        r"(?m)^## Herdr research coordination\n.*?(?=^## |\Z)",
        "", original, flags=re.S,
    )
    return original.rstrip() + "\n\n" + START + "\n" + policy.rstrip() + "\n" + END + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--home", type=Path, default=Path.home())
    parser.add_argument("--check", action="store_true", help="check without writing")
    args = parser.parse_args()
    policy = (ROOT / "skills/engineering-preferences/references/personal-herdr-defaults.md").read_text()
    targets = [args.home / ".codex/AGENTS.md", args.home / ".claude/CLAUDE.md"]
    pending = []
    # Check both targets before changing either one.
    for target in targets:
        if target.is_symlink() or target.parent.is_symlink():
            raise ValueError(f"refusing symlinked instruction path: {target}")
        original = target.read_text() if target.exists() else ""
        updated = render(original, policy)
        if updated != original:
            pending.append((target, updated))
    if args.check:
        for target, _ in pending:
            print(f"needs update: {target}")
        return bool(pending)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    for target, updated in pending:
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists():
            backup = target.with_name(target.name + ".before-herdr-" + stamp)
            shutil.copy2(target, backup)
            backup.chmod(0o600)
            print(f"backup: {backup}")
        target.write_text(updated)
        target.chmod(0o600)
        print(f"updated: {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
