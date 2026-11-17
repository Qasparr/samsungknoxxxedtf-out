#!/usr/bin/env python3
# =====================================================================
# TESTS — the mouth-block manifest and its script: the pairs are
# whole, the never-touch set is untouchable, the self-guard aborts.
#
# XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
# (2026 e.v.) · 93
# Authorship attributed exclusively to Johnathan 'Qasparr' Monroe
# (Greek, -ARR, All Rights Reserved, Without Prejudice).
#
# MECHANISM: the manifest is parsed as data; the script is then
# run in --dry-run (which touches no device and needs no adb) and
# its printed BLOCK/UNDO pairs are paired off mechanically. A
# corrupted copy of the kit, staged in a temp dir, proves the
# self-guard aborts before adb is ever consulted.
# =====================================================================

import csv
import os
import shutil
import subprocess
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
MOUTH = os.path.join(HERE, "..", "mouth-block")
MANIFEST = os.path.join(MOUTH, "packages.tsv")
SCRIPT = os.path.join(MOUTH, "mouth-block.sh")


def _rows():
    rows = []
    with open(MANIFEST, encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if not line or line.startswith("#"):
                continue
            rows.append(next(csv.reader([line], delimiter="\t")))
    return rows


def _dry_run(*extra, script=SCRIPT):
    return subprocess.run(["sh", script, "--dry-run", *extra],
                          capture_output=True, text=True, timeout=30)


class TestManifestShape(unittest.TestCase):
    def test_every_row_has_four_columns(self):
        for row in _rows():
            self.assertEqual(len(row), 4, row)

    def test_tiers_and_actions_are_from_the_named_sets(self):
        for pkg, tier, action, _note in _rows():
            self.assertIn(tier, ("default", "review", "never"), pkg)
            self.assertIn(action,
                          ("disable-user", "audit-only", "never"), pkg)

    def test_never_rows_never_carry_a_disable_action(self):
        for pkg, tier, action, _note in _rows():
            if tier == "never":
                self.assertEqual(action, "never", pkg)

    def test_disable_and_never_sets_are_disjoint(self):
        rows = _rows()
        disable = {r[0] for r in rows if r[2] == "disable-user"}
        never = {r[0] for r in rows if r[1] == "never"}
        self.assertEqual(disable & never, set())


class TestDryRunPairs(unittest.TestCase):
    def test_every_default_disable_has_its_undo_pair(self):
        out = _dry_run()
        self.assertEqual(out.returncode, 0, out.stderr)
        for pkg, tier, action, _ in _rows():
            if action == "disable-user" and tier == "default":
                self.assertIn(f"pm disable-user --user 0 {pkg}",
                              out.stdout, pkg)
                self.assertIn(f"pm enable {pkg}", out.stdout, pkg)

    def test_block_and_undo_counts_match(self):
        out = _dry_run()
        blocks = [ln for ln in out.stdout.splitlines()
                  if ln.startswith("BLOCK")]
        undos = [ln for ln in out.stdout.splitlines()
                 if ln.startswith("UNDO")]
        self.assertGreater(len(blocks), 0)
        self.assertEqual(len(blocks), len(undos))

    def test_review_rows_held_back_by_default(self):
        out = _dry_run()
        self.assertNotIn("com.samsung.android.scloud", out.stdout)
        out2 = _dry_run("--include-review")
        self.assertIn("pm disable-user --user 0 "
                      "com.samsung.android.scloud", out2.stdout)

    def test_audit_only_rows_never_become_blocks(self):
        # Samsung Pass is audit-only even with --include-review:
        # a credential store is never a block target in this kit.
        out = _dry_run("--include-review")
        self.assertNotIn("pm disable-user --user 0 "
                         "com.samsung.android.samsungpass", out.stdout)

    def test_never_touch_names_appear_in_no_block_line(self):
        out = _dry_run("--include-review")
        for ln in out.stdout.splitlines():
            if ln.startswith("BLOCK"):
                self.assertNotIn("keymint", ln)
                self.assertNotIn("gatekeeper", ln)
                self.assertNotIn("weaver", ln)
                self.assertNotIn("teegris", ln)


class TestSelfGuard(unittest.TestCase):
    def test_corrupted_manifest_aborts(self):
        with tempfile.TemporaryDirectory() as td:
            script = os.path.join(td, "mouth-block.sh")
            manifest = os.path.join(td, "packages.tsv")
            shutil.copy(SCRIPT, script)
            shutil.copy(MANIFEST, manifest)
            with open(manifest, "a", encoding="utf-8") as f:
                f.write("keystore2\tdefault\tdisable-user\tcorrupt row\n")
            out = _dry_run(script=script)
            self.assertEqual(out.returncode, 65, out.stdout)
            self.assertIn("ABORT", out.stderr)


if __name__ == "__main__":
    unittest.main()

# 93 — Live, Love, and let Love, Live.
