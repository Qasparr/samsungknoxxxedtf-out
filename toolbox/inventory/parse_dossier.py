#!/usr/bin/env python3
# =====================================================================
# PARSE-DOSSIER — read a device dossier (or a raw getprop dump) and
# render its identity summary + variant verdict.
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
# The inventory scripts emit their identity section in getprop's own
# shape — '[key]: [value]' lines — so ONE parser serves the raw dump
# and the finished dossier alike. parse_dossier() is a pure function
# over text: it extracts the identity fields, lifts the guard's
# signals, and asks variant_guard.classify() for the verdict. The
# guard is the only ruler; this parser never rules on its own.
#
# DOCTRINE
# --------
# A dossier is evidence, and evidence is read, not embellished:
# fields the text does not carry print as ABSENT, and the verdict is
# whatever the guard returns — including UNKNOWN, which means stop
# and look.
#
# Usage:  python3 parse_dossier.py <dossier-or-getprop-file>
#
# 93 — Live, Love, and let Love, Live.
# =====================================================================

from __future__ import annotations

import os
import sys

# The guard lives in the sibling directory; the toolbox is one kit,
# so the parser reaches across by path rather than by copy. A copied
# table is a table that can drift; a reached-for one cannot.
sys.path.insert(
    0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                    "..", "variant-guard"))

import variant_guard  # noqa: E402

IDENTITY_KEYS = (
    "ro.product.model",
    "ro.product.device",
    "ro.board.platform",
    "ro.hardware",
    "ro.soc.manufacturer",
    "ro.soc.model",
    "ro.build.fingerprint",
    "ro.build.id",
    "ro.build.version.release",
    "ro.build.version.security_patch",
    "ro.bootloader",
)


def parse_dossier(text: str) -> dict:
    """MECHANISM: parse getprop-shaped lines out of the text (any
    other lines — section heads, thermal readings — are passed over
    in silence), then return the identity fields present, the lifted
    signals, and the guard's verdict object."""
    props = variant_guard.parse_getprop(text)
    identity = {k: props[k] for k in IDENTITY_KEYS if k in props}
    signals = variant_guard.signals_from_props(props)
    verdict = variant_guard.classify(signals)
    return {"identity": identity, "signals": signals,
            "verdict": verdict}


def main(argv=None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    if len(argv) != 1:
        print("usage: parse_dossier.py <dossier-or-getprop-file>",
              file=sys.stderr)
        return 64
    with open(argv[0], encoding="utf-8") as f:
        text = f.read()
    result = parse_dossier(text)
    print("== IDENTITY ==")
    for key in IDENTITY_KEYS:
        print(f"  {key}: {result['identity'].get(key, 'ABSENT')}")
    verdict = result["verdict"]
    print(f"== VERDICT ==\n  RULING: {verdict.ruling}")
    for sig, val, side in verdict.evidence:
        print(f"  evidence: {sig} = {val!r} -> {side}")
    for w in verdict.warnings:
        print(f"  ! {w}")
    return verdict.exit_code


if __name__ == "__main__":
    sys.exit(main())

# 93 — Live, Love, and let Love, Live.
