#!/usr/bin/env python3
# =====================================================================
# TESTS — keystore_bench: the PQVTPM protocol against the software
# stand-in. The cryptography is real; the custody is software, and
# the tests pin that honesty as firmly as the signatures.
#
# XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
# (2026 e.v.) · 93
# Authorship attributed exclusively to Johnathan 'Qasparr' Monroe
# (Greek, -ARR, All Rights Reserved, Without Prejudice).
# =====================================================================

import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "..", "keystore-client", "bench"))
import keystore_bench as kb  # noqa: E402


class TestProtocol(unittest.TestCase):
    def setUp(self):
        self.store = kb.SoftwareKeystoreStandIn()
        self.client = kb.PqvtpmBenchClient(self.store)
        self.challenge = self.client.issue_challenge()
        self.client.generate(kb.ALIAS, self.challenge)

    def test_sign_verify_round_trip(self):
        msg = b"enclave payload"
        sig = self.client.sign(kb.ALIAS, msg)
        self.assertTrue(self.client.verify(kb.ALIAS, msg, sig))

    def test_tampered_message_fails_verify(self):
        sig = self.client.sign(kb.ALIAS, b"enclave payload")
        self.assertFalse(self.client.verify(kb.ALIAS, b"enclave payloaX",
                                            sig))

    def test_wrong_alias_record_fails_verify(self):
        other = "pqvtpm.enclave.attest.other"
        self.client.generate(other, self.client.issue_challenge())
        sig = self.client.sign(kb.ALIAS, b"payload")
        self.assertFalse(self.client.verify(other, b"payload", sig))

    def test_attest_happy_path_reports_standin_level(self):
        report = self.client.attest(kb.ALIAS, self.challenge)
        self.assertEqual(report["attestation_security_level"],
                         "SOFTWARE_STAND_IN")
        self.assertFalse(report["hardware_backed"])
        self.assertIsNotNone(report["warning"])

    def test_attest_challenge_mismatch_refused(self):
        with self.assertRaises(ValueError):
            self.client.attest(kb.ALIAS, b"\x00" * 32)

    def test_attest_tampered_record_refused(self):
        # White-box: rewrite the stored record after issuance. The
        # issuer signature no longer covers the bytes — refusal.
        priv, record, sig = self.store._keys[kb.ALIAS]
        forged = dict(record)
        forged["attestation_challenge_hex"] = (b"\x01" * 32).hex()
        self.store._keys[kb.ALIAS] = (priv, forged, sig)
        with self.assertRaises(ValueError):
            self.client.attest(kb.ALIAS, self.challenge)


class TestStandinHonesty(unittest.TestCase):
    def test_record_names_itself_a_standin(self):
        store = kb.SoftwareKeystoreStandIn()
        record = store.generate_key("a", b"\x02" * 32)
        self.assertIn("STAND-IN", record["issuer"])
        self.assertEqual(record["attestation_security_level"],
                         "SOFTWARE_STAND_IN")
        self.assertEqual(record["keymaster_security_level"],
                         "SOFTWARE_STAND_IN")

    def test_challenges_are_fresh(self):
        c1 = kb.PqvtpmBenchClient.issue_challenge()
        c2 = kb.PqvtpmBenchClient.issue_challenge()
        self.assertEqual(len(c1), 32)
        self.assertNotEqual(c1, c2)


if __name__ == "__main__":
    unittest.main()

# 93 — Live, Love, and let Love, Live.
