#!/usr/bin/env python3
# =====================================================================
# TESTS — parse_dossier: identity extraction + the guard's verdict,
# over the labelled SAMPLE dumps and fabricated dossier text.
#
# XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
# (2026 e.v.) · 93
# Authorship attributed exclusively to Johnathan 'Qasparr' Monroe
# (Greek, -ARR, All Rights Reserved, Without Prejudice).
# =====================================================================

import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "inventory"))
import parse_dossier  # noqa: E402

SAMPLES = os.path.join(HERE, "..", "inventory", "samples")


def _sample(name):
    with open(os.path.join(SAMPLES, name), encoding="utf-8") as f:
        return f.read()


class TestParseDossier(unittest.TestCase):
    def test_exynos_sample_identity_and_verdict(self):
        r = parse_dossier.parse_dossier(
            _sample("sample-getprop-exynos-a166u.txt"))
        self.assertEqual(r["identity"]["ro.product.model"], "SM-A166U")
        self.assertEqual(r["identity"]["ro.product.device"], "a16x")
        self.assertEqual(r["identity"]["ro.soc.model"], "Exynos 1330")
        self.assertEqual(r["verdict"].ruling, "EXYNOS")

    def test_mediatek_sample_identity_and_verdict(self):
        r = parse_dossier.parse_dossier(
            _sample("sample-getprop-mediatek-a166p.txt"))
        self.assertEqual(r["identity"]["ro.product.model"], "SM-A166P")
        self.assertEqual(r["identity"]["ro.soc.model"],
                         "Dimensity 6300")
        self.assertEqual(r["verdict"].ruling, "MEDIATEK")

    def test_dossier_sections_do_not_confuse_the_parser(self):
        # A finished dossier wraps the identity block in section
        # heads and other readings; only getprop-shaped lines count.
        text = ("DEVICE DOSSIER — sample\n"
                "== THERMAL ZONES ==\n  cpu = 42000\n"
                "[ro.product.model]: [SM-S166V]\n"
                "[ro.product.device]: [a16x]\n"
                "END OF DOSSIER\n")
        r = parse_dossier.parse_dossier(text)
        self.assertEqual(r["identity"]["ro.product.model"], "SM-S166V")
        self.assertEqual(r["verdict"].ruling, "EXYNOS")

    def test_absent_fields_stay_absent(self):
        r = parse_dossier.parse_dossier("[ro.product.model]: [SM-A166U]\n")
        self.assertNotIn("ro.soc.model", r["identity"])
        self.assertEqual(r["verdict"].ruling, "EXYNOS")

    def test_empty_text_rules_unknown(self):
        r = parse_dossier.parse_dossier("")
        self.assertEqual(r["identity"], {})
        self.assertEqual(r["verdict"].ruling, "UNKNOWN")


if __name__ == "__main__":
    unittest.main()

# 93 — Live, Love, and let Love, Live.
