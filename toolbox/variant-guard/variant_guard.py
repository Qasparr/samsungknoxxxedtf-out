#!/usr/bin/env python3
# =====================================================================
# VARIANT-GUARD — the A16 family variant ruler (reference logic)
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
# The Galaxy A16 5G ships on two different silicons under one name:
#
#   * Samsung Exynos 1330  — models SM-A166B / SM-A166U / SM-A166U1 /
#     SM-S166V; device codename "a16x"; board/hardware "s5e8535".
#     (The founder's unit is of this line: SM-A166U / SM-S166V.)
#   * MediaTek Dimensity 6300 — model SM-A166P; device codename
#     "a16xm".
#
# (Identifiers as recorded from Samsung firmware listings and the
# Device Info hardware census, November 2026; the tables below are
# data, and data can be amended by evidence — the logic cannot.)
#
# This module rules EXYNOS or MEDIATEK (or refuses to rule) from any
# subset of five signals: model, device codename, board, SoC string,
# build fingerprint. Signals are weighed in a fixed precedence —
# model, then codename, then board, then SoC string — and two strong
# signals that disagree produce CONFLICT, never a coin flip.
#
# DOCTRINE
# --------
# This guard exists because a MediaTek-variant recovery tree
# (the circulating "a16xm" TWRP tree) flashed onto an Exynos A16
# kills the phone, and the reverse is no kinder. The variants are
# marked apart here, in code, so the marking does not depend on
# anyone's memory at the moment of a flash. The guard is fail-closed:
# an unrecognised model (SM-A166E, say, whose silicon the desk has
# not verified) rules UNKNOWN, and UNKNOWN means stop and look, not
# proceed and hope.
#
# The prefix trap is named and tested: "a16xm" begins with "a16x".
# Codename matching is therefore EXACT-TOKEN, never substring. A
# ruler that cannot tell a16x from a16xm is worse than no ruler.
#
# Exit codes (CLI): 0 EXYNOS · 2 MEDIATEK · 3 UNKNOWN · 4 CONFLICT ·
# 5 NOT-A16-5G (a different family entirely, e.g. the 4G A16).
#
# 93 — Live, Love, and let Love, Live.
# =====================================================================

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass, field

# ---------------------------------------------------------------------
# THE TABLES — recorded identifiers, November 2026.
# Sources: Samsung firmware listings (SM-A166U / SM-A166U1: chipset
# Exynos 1330, codename a16x); Device Info hardware census (Exynos
# models SM-A166B, SM-A166U, SM-S166V, board/hardware s5e8535;
# MediaTek model SM-A166P, codename a16xm, Dimensity 6300).
# ---------------------------------------------------------------------

EXYNOS_MODELS = {"SM-A166B", "SM-A166U", "SM-A166U1", "SM-S166V"}
MEDIATEK_MODELS = {"SM-A166P"}

# The 4G A16 (SM-A165F, MediaTek Helio G99) is a different device
# family that shares the shelf name. It is ruled out of scope, not
# into either 5G silicon.
OTHER_FAMILY_PREFIXES = ("SM-A165",)

EXYNOS_CODENAMES = {"a16x"}
MEDIATEK_CODENAMES = {"a16xm"}

EXYNOS_BOARDS = {"s5e8535"}
# No MediaTek board string is asserted: the desk has not recorded one
# from a source it can cite, so the board signal simply stays silent
# on that side. A silent signal is honest; an invented one is not.

STANDING_WARNING = (
    "STANDING WARNING: the A16 5G name covers two silicons. A "
    "recovery, kernel, or firmware built for the MediaTek variant "
    "(codename a16xm — e.g. the circulating a16xm TWRP tree) flashed "
    "onto an Exynos unit (codename a16x) kills the phone, and the "
    "reverse is no kinder. Rule the variant BEFORE anything is "
    "flashed, every time."
)


# ---------------------------------------------------------------------
# Signal extraction
# ---------------------------------------------------------------------

def normalise_model(raw: str) -> str:
    """MECHANISM: model strings arrive as 'SM-A166U', 'SM-A166P/DS',
    'sm-a166u', with stray spaces. Normalise to the bare upper-case
    model: strip, upper-case, drop the '/DS' dual-SIM suffix and any
    other '/...' tail, drop internal spaces."""
    m = raw.strip().upper().replace(" ", "")
    m = m.split("/")[0]
    return m


def parse_fingerprint(fingerprint: str) -> dict:
    """MECHANISM: a build fingerprint has the shape
    brand/product/device:release/build-id/incremental:type/tags.
    The device codename is the third field of the first segment.
    Returns {'product': ..., 'device': ...} or {} if the string does
    not carry the shape — a malformed fingerprint is no signal, not
    a wrong one."""
    head = fingerprint.strip().split(":", 1)[0]
    parts = head.split("/")
    if len(parts) != 3:
        return {}
    return {"product": parts[1], "device": parts[2]}


def parse_getprop(text: str) -> dict:
    """MECHANISM: getprop output lines read '[key]: [value]'. Parse
    them into a plain dict; lines of any other shape are ignored.
    Pure function — the dossier parser and the tests both feed it
    fabricated sample text, labelled as samples."""
    props = {}
    for line in text.splitlines():
        m = re.match(r"\[([^\]]+)\]:\s*\[(.*)\]\s*$", line.strip())
        if m:
            props[m.group(1)] = m.group(2)
    return props


def signals_from_props(props: dict) -> dict:
    """MECHANISM: lift the guard's five signals out of a getprop
    dict. Missing properties yield missing signals — absence is
    recorded as absence, never filled in."""
    sig = {}
    if props.get("ro.product.model"):
        sig["model"] = props["ro.product.model"]
    if props.get("ro.product.device"):
        sig["device"] = props["ro.product.device"]
    # Board evidence can ride in either of two properties.
    board = props.get("ro.board.platform") or props.get("ro.hardware")
    if board:
        sig["board"] = board
    soc = props.get("ro.soc.model") or props.get("ro.chipname")
    if soc:
        sig["soc"] = soc
    if props.get("ro.build.fingerprint"):
        sig["fingerprint"] = props["ro.build.fingerprint"]
    return sig


# ---------------------------------------------------------------------
# The ruling
# ---------------------------------------------------------------------

@dataclass
class Verdict:
    ruling: str                       # EXYNOS | MEDIATEK | UNKNOWN |
                                      # CONFLICT | NOT_A16_5G
    evidence: list = field(default_factory=list)   # (signal, value, side)
    warnings: list = field(default_factory=list)

    @property
    def exit_code(self) -> int:
        return {"EXYNOS": 0, "MEDIATEK": 2, "UNKNOWN": 3,
                "CONFLICT": 4, "NOT_A16_5G": 5}[self.ruling]


def _side_of_model(model: str):
    if model in EXYNOS_MODELS:
        return "EXYNOS"
    if model in MEDIATEK_MODELS:
        return "MEDIATEK"
    return None


def classify(signals: dict) -> Verdict:
    """MECHANISM: weigh the signals in precedence order — model,
    codename, board, SoC — collecting each signal's side. The first
    (strongest) side becomes the ruling UNLESS a later strong signal
    (model or codename) disagrees, which is a CONFLICT: a unit whose
    own identifiers argue is a unit to stop on, not to average.
    DOCTRINE: fail-closed. No side at all rules UNKNOWN."""
    v = Verdict(ruling="UNKNOWN")
    strong = {}   # sides attested by model/codename (the strong pair)

    model = signals.get("model")
    if model:
        m = normalise_model(model)
        if any(m.startswith(p) for p in OTHER_FAMILY_PREFIXES):
            v.ruling = "NOT_A16_5G"
            v.evidence.append(("model", model, "OTHER_FAMILY"))
            v.warnings.append(
                "This is the 4G A16 family (SM-A165...), not a 5G "
                "A16 at all. Neither 5G variant's files belong on it.")
            return v
        side = _side_of_model(m)
        if side:
            strong["model"] = side
            v.evidence.append(("model", model, side))
        else:
            v.warnings.append(
                f"Model {m} is not in the recorded tables; the model "
                "signal stays silent rather than guess.")

    device = signals.get("device")
    if not device and signals.get("fingerprint"):
        device = parse_fingerprint(signals["fingerprint"]).get("device")
        if device:
            v.evidence.append(("fingerprint-device", device, "parsed"))
    if device:
        # EXACT-TOKEN matching. 'a16xm' must never read as 'a16x'.
        if device in EXYNOS_CODENAMES:
            strong["device"] = "EXYNOS"
            v.evidence.append(("device", device, "EXYNOS"))
        elif device in MEDIATEK_CODENAMES:
            strong["device"] = "MEDIATEK"
            v.evidence.append(("device", device, "MEDIATEK"))

    board = signals.get("board")
    weak_side = None
    if board:
        if board.strip().lower() in EXYNOS_BOARDS:
            weak_side = "EXYNOS"
            v.evidence.append(("board", board, "EXYNOS"))

    soc = signals.get("soc")
    if soc:
        s = soc.lower()
        if "exynos" in s:
            weak_side = weak_side or "EXYNOS"
            v.evidence.append(("soc", soc, "EXYNOS"))
        elif "dimensity" in s or "mediatek" in s:
            weak_side = weak_side or "MEDIATEK"
            v.evidence.append(("soc", soc, "MEDIATEK"))

    sides = set(strong.values())
    if len(sides) > 1:
        v.ruling = "CONFLICT"
        v.warnings.append(
            "CONFLICT: the strong signals disagree "
            f"({strong}). This unit's identifiers argue with each "
            "other — a mislabel, a franken-build, or a board swap. "
            "STOP. Rule nothing from this unit until the argument "
            "is explained.")
        v.warnings.append(STANDING_WARNING)
        return v
    if sides:
        v.ruling = sides.pop()
    elif weak_side:
        v.ruling = weak_side
        v.warnings.append(
            "Ruled on weak signals only (board/SoC); no model or "
            "codename attested. Treat as provisional.")
    else:
        v.ruling = "UNKNOWN"
        v.warnings.append(
            "No signal matched the recorded tables. UNKNOWN means "
            "stop and look — it never means proceed.")

    if v.ruling in ("EXYNOS", "MEDIATEK"):
        v.warnings.append(STANDING_WARNING)
    return v


# ---------------------------------------------------------------------
# CLI — the door the shell wrapper and the founder both use.
# ---------------------------------------------------------------------

def main(argv=None) -> int:
    ap = argparse.ArgumentParser(
        description="Rule EXYNOS vs MEDIATEK for a Galaxy A16 5G.")
    ap.add_argument("--model")
    ap.add_argument("--device")
    ap.add_argument("--board")
    ap.add_argument("--soc")
    ap.add_argument("--fingerprint")
    ap.add_argument("--getprop", metavar="FILE",
                    help="a getprop dump file ('-' for stdin)")
    args = ap.parse_args(argv)

    signals = {}
    if args.getprop:
        if args.getprop == "-":
            text = sys.stdin.read()
        else:
            with open(args.getprop, encoding="utf-8") as f:
                text = f.read()
        signals.update(signals_from_props(parse_getprop(text)))
    for key in ("model", "device", "board", "soc", "fingerprint"):
        val = getattr(args, key)
        if val:
            signals[key] = val

    verdict = classify(signals)
    print(f"RULING: {verdict.ruling}")
    for sig, val, side in verdict.evidence:
        print(f"  evidence: {sig} = {val!r} -> {side}")
    for w in verdict.warnings:
        print(f"  ! {w}")
    return verdict.exit_code


if __name__ == "__main__":
    sys.exit(main())

# 93 — Live, Love, and let Love, Live.
