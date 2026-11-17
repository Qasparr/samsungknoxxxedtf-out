#!/usr/bin/env python3
# =====================================================================
# TESTS — variant_guard: the A16 variant ruler, pinned.
#
# XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
# (2026 e.v.) · 93
# Authorship attributed exclusively to Johnathan 'Qasparr' Monroe
# (Greek, -ARR, All Rights Reserved, Without Prejudice).
#
# MECHANISM: every case feeds classify()/the parsers fabricated
# signals — including the toolbox's labelled SAMPLE getprop dumps —
# and pins the ruling, the exit code, and the two traps that matter:
# the a16xm prefix trap, and CONFLICT over coin-flips.
# =====================================================================

import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "..", "variant-guard"))
import variant_guard as vg  # noqa: E402

SAMPLES = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "..", "inventory", "samples")


class TestModels(unittest.TestCase):
    def test_exynos_models(self):
        for m in ("SM-A166B", "SM-A166U", "SM-A166U1", "SM-S166V"):
            v = vg.classify({"model": m})
            self.assertEqual(v.ruling, "EXYNOS", m)
            self.assertEqual(v.exit_code, 0, m)

    def test_mediatek_model(self):
        v = vg.classify({"model": "SM-A166P"})
        self.assertEqual(v.ruling, "MEDIATEK")
        self.assertEqual(v.exit_code, 2)

    def test_dual_sim_suffix_normalised(self):
        self.assertEqual(vg.classify({"model": "SM-A166P/DS"}).ruling,
                         "MEDIATEK")
        self.assertEqual(vg.classify({"model": "sm-a166u"}).ruling,
                         "EXYNOS")

    def test_unrecorded_model_is_silent_not_wrong(self):
        # SM-A166E's silicon is not in the recorded tables: alone,
        # it must rule UNKNOWN, never a guess.
        v = vg.classify({"model": "SM-A166E"})
        self.assertEqual(v.ruling, "UNKNOWN")
        self.assertEqual(v.exit_code, 3)

    def test_4g_family_ruled_out_of_scope(self):
        v = vg.classify({"model": "SM-A165F"})
        self.assertEqual(v.ruling, "NOT_A16_5G")
        self.assertEqual(v.exit_code, 5)


class TestCodenamesAndThePrefixTrap(unittest.TestCase):
    def test_a16x_is_exynos(self):
        self.assertEqual(vg.classify({"device": "a16x"}).ruling, "EXYNOS")

    def test_a16xm_is_mediatek_not_exynos(self):
        # THE PREFIX TRAP: 'a16xm' begins with 'a16x'. Exact-token
        # matching or the guard is worse than no guard.
        self.assertEqual(vg.classify({"device": "a16xm"}).ruling,
                         "MEDIATEK")

    def test_fingerprint_device_a16xm(self):
        fp = ("samsung/a16xmxx/a16xm:14/SAMPLE/A166PSAMPLE:"
              "user/release-keys")
        self.assertEqual(vg.classify({"fingerprint": fp}).ruling,
                         "MEDIATEK")

    def test_fingerprint_device_a16x(self):
        fp = ("samsung/a16xsq/a16x:14/SAMPLE/A166USAMPLE:"
              "user/release-keys")
        self.assertEqual(vg.classify({"fingerprint": fp}).ruling,
                         "EXYNOS")

    def test_malformed_fingerprint_is_no_signal(self):
        self.assertEqual(vg.parse_fingerprint("not-a-fingerprint"), {})
        self.assertEqual(
            vg.classify({"fingerprint": "not-a-fingerprint"}).ruling,
            "UNKNOWN")


class TestBoardsSocAndConflict(unittest.TestCase):
    def test_board_s5e8535_alone_is_provisional_exynos(self):
        v = vg.classify({"board": "s5e8535"})
        self.assertEqual(v.ruling, "EXYNOS")
        self.assertTrue(any("provisional" in w for w in v.warnings))

    def test_soc_strings(self):
        self.assertEqual(vg.classify({"soc": "Exynos 1330"}).ruling,
                         "EXYNOS")
        self.assertEqual(vg.classify({"soc": "Dimensity 6300"}).ruling,
                         "MEDIATEK")

    def test_conflict_model_vs_codename(self):
        # An Exynos model wearing a MediaTek codename: the unit's
        # identifiers argue. CONFLICT — stop — never an average.
        v = vg.classify({"model": "SM-A166U", "device": "a16xm"})
        self.assertEqual(v.ruling, "CONFLICT")
        self.assertEqual(v.exit_code, 4)

    def test_empty_signals_unknown(self):
        v = vg.classify({})
        self.assertEqual(v.ruling, "UNKNOWN")

    def test_standing_warning_rides_a_ruling(self):
        v = vg.classify({"model": "SM-A166U"})
        self.assertTrue(any("STANDING WARNING" in w
                            for w in v.warnings))


class TestSampleDumps(unittest.TestCase):
    def _classify_sample(self, name):
        with open(os.path.join(SAMPLES, name), encoding="utf-8") as f:
            text = f.read()
        props = vg.parse_getprop(text)
        return vg.classify(vg.signals_from_props(props)), props

    def test_exynos_sample(self):
        v, props = self._classify_sample("sample-getprop-exynos-a166u.txt")
        self.assertEqual(props["ro.product.model"], "SM-A166U")
        self.assertEqual(v.ruling, "EXYNOS")

    def test_mediatek_sample(self):
        v, props = self._classify_sample(
            "sample-getprop-mediatek-a166p.txt")
        self.assertEqual(props["ro.product.device"], "a16xm")
        self.assertEqual(v.ruling, "MEDIATEK")

    def test_parse_getprop_ignores_other_shapes(self):
        props = vg.parse_getprop("noise line\n[ro.x]: [1]\n[broken\n")
        self.assertEqual(props, {"ro.x": "1"})


if __name__ == "__main__":
    unittest.main()

# 93 — Live, Love, and let Love, Live.
