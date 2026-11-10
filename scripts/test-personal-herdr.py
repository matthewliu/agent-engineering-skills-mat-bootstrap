#!/usr/bin/env python3
"""Check personal instruction installation using dummy home folders."""

from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).with_name("install-personal-herdr.py")


class PersonalHerdrTest(unittest.TestCase):
    def run_install(self, home, *args):
        return subprocess.run(
            ["python3", str(SCRIPT), "--home", str(home), *args],
            capture_output=True, text=True, check=False,
        )

    def test_preserves_text_and_replaces_old_rule_once(self):
        with tempfile.TemporaryDirectory() as folder:
            home = Path(folder)
            target = home / ".codex/AGENTS.md"
            target.parent.mkdir()
            original = "Keep prefix.\n\n## Herdr research coordination\nOld rule.\n\n## Code\nKeep suffix.\n"
            target.write_text(original)
            self.assertEqual(self.run_install(home, "--check").returncode, 1)
            self.assertEqual(target.read_text(), original)
            self.assertEqual(self.run_install(home).returncode, 0)
            result = target.read_text()
            self.assertIn("Keep prefix.", result)
            self.assertIn("## Code\nKeep suffix.", result)
            self.assertNotIn("Old rule.", result)
            self.assertTrue((home / ".claude/CLAUDE.md").is_file())
            backup = list(target.parent.glob("AGENTS.md.before-herdr-*"))
            self.assertEqual(len(backup), 1)
            self.assertEqual(backup[0].read_text(), original)
            self.assertEqual(self.run_install(home).returncode, 0)
            self.assertEqual(self.run_install(home, "--check").returncode, 0)
            self.assertEqual(target.read_text(), result)
            self.assertEqual(len(list(target.parent.glob("AGENTS.md.before-herdr-*"))), 1)

    def test_bad_second_target_changes_neither_target(self):
        with tempfile.TemporaryDirectory() as folder:
            home = Path(folder)
            first = home / ".codex/AGENTS.md"
            second = home / ".claude/CLAUDE.md"
            first.parent.mkdir()
            second.parent.mkdir()
            first.write_text("Original first file.\n")
            second.write_text("<!-- aes:personal-herdr begin -->\n")
            self.assertNotEqual(self.run_install(home).returncode, 0)
            self.assertEqual(first.read_text(), "Original first file.\n")

    def test_refuses_symlinked_instruction(self):
        with tempfile.TemporaryDirectory() as folder:
            home = Path(folder)
            original = home / "shared.md"
            original.write_text("Shared instructions.\n")
            (home / ".codex").mkdir()
            (home / ".codex/AGENTS.md").symlink_to(original)
            self.assertNotEqual(self.run_install(home).returncode, 0)
            self.assertEqual(original.read_text(), "Shared instructions.\n")


if __name__ == "__main__":
    unittest.main()
