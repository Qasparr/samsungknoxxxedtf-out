#!/usr/bin/env python3
# =====================================================================
# KEYSTORE BENCH — the PQVTPM protocol, exercised on the host
# against a software stand-in
#
# "Do what thou wilt shall be the whole of the Law."
#
# XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
# (2026 e.v.)
# 93
#
# Authorship attributed exclusively to Johnathan 'Qasparr' Monroe
# (Greek, -ARR, All Rights Reserved, Without Prejudice).
# Scientific Illuminism: Method of Science, Aim of Religion.
#
# Flagpole of Claim and Coinage: Johnathan 'Qasparr' Monroe, ARR,
# All Rights Reserved, Without Prejudice. Right of claim hereby
# reserved and coined under the authority of the Living Man.
# =====================================================================
#
# MECHANISM
# ---------
# This harness mirrors the device client's five steps exactly —
# CHALLENGE, GENERATE, SIGN, VERIFY, ATTEST — with the Android
# Keystore replaced by SoftwareKeystoreStandIn: a dict of P-256 key
# pairs held in ordinary process memory, minted by the
# `cryptography` library, plus a stand-in issuer key that "attests"
# by signing a JSON record binding alias, public key, challenge,
# and security level.
#
# DOCTRINE — READ THIS BEFORE TRUSTING ANY OUTPUT
# ------------------------------------------------
# The cryptography is genuine: real keys, real ECDSA-SHA256
# signatures, real verification. The CUSTODY is software. The
# stand-in is not hardware, not Samsung's TEE, not Google's
# attestation root, and it says so in every record it issues
# (issuer line + security_level "SOFTWARE_STAND_IN"). The bench
# proves the PROTOCOL — the steps, the checks, the failure modes.
# It proves nothing about any device. The client below enforces
# the house rule in code: an attestation that does not answer at a
# hardware level is accepted only as a labelled stand-in result,
# never as hardware proof — the same refusal the device client
# owes a software-level answer.
#
# Usage:  python3 keystore_bench.py     (prints the transcript)
#         import it for the tests — every step is a function.
#
# 93 — Live, Love, and let Love, Live.
# =====================================================================

from __future__ import annotations

import hashlib
import json
import os

from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec, utils

ALIAS = "pqvtpm.enclave.attest.v1"   # the same alias as the device client
STANDIN_ISSUER = ("PQVTPM BENCH STAND-IN — not Google, not Samsung, "
                  "not hardware")


def _pub_pem(public_key) -> str:
    return public_key.public_bytes(
        serialization.Encoding.PEM,
        serialization.PublicFormat.SubjectPublicKeyInfo).decode()


def _record_bytes(record: dict) -> bytes:
    """MECHANISM: the attestation record is signed in canonical
    form — sorted keys, tight separators — so the bytes the issuer
    signed are the bytes the verifier re-derives, exactly."""
    return json.dumps(record, sort_keys=True,
                      separators=(",", ":")).encode()


class SoftwareKeystoreStandIn:
    """A software key store that plays the Keystore's part in the
    protocol — and never pretends to be more. Private keys live in
    this process's memory; on the device they would live in the
    TEE and never leave it. That difference is the whole reason
    this class is named STAND-IN in every sentence it touches."""

    def __init__(self):
        self._keys = {}          # alias -> (private_key, record, record_sig)
        self._issuer_key = ec.generate_private_key(ec.SECP256R1())

    # STEP 2 (device side) — GENERATE + issue the attestation record
    def generate_key(self, alias: str, challenge: bytes) -> dict:
        priv = ec.generate_private_key(ec.SECP256R1())
        record = {
            "alias": alias,
            "public_key_pem": _pub_pem(priv.public_key()),
            "attestation_challenge_hex": challenge.hex(),
            "attestation_security_level": "SOFTWARE_STAND_IN",
            "keymaster_security_level": "SOFTWARE_STAND_IN",
            "issuer": STANDIN_ISSUER,
        }
        sig = self._issuer_key.sign(
            _record_bytes(record), ec.ECDSA(hashes.SHA256()))
        self._keys[alias] = (priv, record, sig)
        return record

    # STEP 3 (device side) — SIGN
    def sign(self, alias: str, data: bytes) -> bytes:
        priv, _, _ = self._keys[alias]
        return priv.sign(data, ec.ECDSA(hashes.SHA256()))

    # STEP 5 (device side) — hand over the "chain": record + its sig
    def attestation(self, alias: str):
        _, record, sig = self._keys[alias]
        return _record_bytes(record), sig

    def issuer_public_key(self):
        return self._issuer_key.public_key()


class PqvtpmBenchClient:
    """The verifier-side client — the mirror of the Java client's
    checks, run against the stand-in. It trusts nothing it has not
    verified: the public key comes from the attestation record (as,
    on device, it comes from the certificate chain), the record's
    issuer signature is checked, and the challenge must match the
    one this client issued."""

    def __init__(self, store: SoftwareKeystoreStandIn):
        self.store = store
        self._records = {}

    # STEP 1 — CHALLENGE
    @staticmethod
    def issue_challenge() -> bytes:
        return os.urandom(32)

    # STEP 2 — GENERATE (ask the store to mint, keep the record)
    def generate(self, alias: str, challenge: bytes) -> dict:
        record = self.store.generate_key(alias, challenge)
        self._records[alias] = record
        return record

    # STEP 3 — SIGN (the store signs; the key never crosses)
    def sign(self, alias: str, data: bytes) -> bytes:
        return self.store.sign(alias, data)

    # STEP 4 — VERIFY, public key from the record and nowhere else
    def verify(self, alias: str, data: bytes, signature: bytes) -> bool:
        record = self._records[alias]
        pub = serialization.load_pem_public_key(
            record["public_key_pem"].encode())
        try:
            pub.verify(signature, data, ec.ECDSA(hashes.SHA256()))
            return True
        except InvalidSignature:
            return False

    # STEP 5 — ATTEST: check the record's issuer signature, the
    # challenge binding, and report the level AS READ.
    def attest(self, alias: str, expected_challenge: bytes) -> dict:
        record_bytes, record_sig = self.store.attestation(alias)
        # The issuer signature must verify over the canonical bytes.
        try:
            self.store.issuer_public_key().verify(
                record_sig, record_bytes, ec.ECDSA(hashes.SHA256()))
        except InvalidSignature:
            raise ValueError("attestation REFUSED: issuer signature "
                             "does not verify")
        record = json.loads(record_bytes)
        if record["attestation_challenge_hex"] != expected_challenge.hex():
            raise ValueError("attestation REFUSED: challenge mismatch — "
                             "the record answers a different question "
                             "than the one asked")
        level = record["attestation_security_level"]
        return {
            "alias": record["alias"],
            "attestation_security_level": level,
            "keymaster_security_level": record["keymaster_security_level"],
            "issuer": record["issuer"],
            "hardware_backed": level in ("TEE", "STRONGBOX"),
            "warning": (None if level in ("TEE", "STRONGBOX") else
                        "NOT HARDWARE: this attestation answers at "
                        "software level. On the bench that is the "
                        "stand-in being honest; on a device it "
                        "would be a refusal."),
        }


def run_demo() -> int:
    """The full transcript, printed. Every line the stand-in
    touches is labelled; the protocol's checks all run for real."""
    print("=" * 68)
    print("PQVTPM KEYSTORE BENCH — the protocol against a SOFTWARE STAND-IN")
    print("custody here is software; on the device it is the TEE.")
    print("=" * 68)
    store = SoftwareKeystoreStandIn()
    client = PqvtpmBenchClient(store)

    challenge = client.issue_challenge()
    print(f"1. CHALLENGE  {challenge.hex()[:32]}… (fresh, 32 bytes)")
    record = client.generate(ALIAS, challenge)
    print(f"2. GENERATE   alias {ALIAS}")
    print(f"              issuer: {record['issuer']}")
    print(f"              level:  {record['attestation_security_level']}")
    payload = b"enclave genesis: the bench speaks the protocol"
    sig = client.sign(ALIAS, payload)
    digest = hashlib.sha256(sig).hexdigest()[:16]
    print(f"3. SIGN       {len(sig)} bytes (sha256 {digest}…)")
    ok = client.verify(ALIAS, payload, sig)
    print(f"4. VERIFY     {'PASS' if ok else 'FAIL'}")
    report = client.attest(ALIAS, challenge)
    print(f"5. ATTEST     challenge bound; level as read: "
          f"{report['attestation_security_level']}")
    if report["warning"]:
        print(f"              ! {report['warning']}")
    print("=" * 68)
    print("transcript complete — protocol proven, hardware not claimed.")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(run_demo())

# 93 — Live, Love, and let Love, Live.
