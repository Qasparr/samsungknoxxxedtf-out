#!/bin/sh
# =====================================================================
# VARIANT-GUARD — the on-device door (Termux / ADB shell wrapper)
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
# Reads the unit's own identifiers with getprop (ro.product.model,
# ro.product.device) and rules EXYNOS vs MEDIATEK for the Galaxy
# A16 5G family. If python3 and the reference logic
# (variant_guard.py, same directory) are at hand, this wrapper hands
# the full getprop dump to the reference and reports its ruling —
# one logic, one truth. Without python3 it falls back to the model /
# codename subset embedded below, and SAYS it is the fallback.
#
# DOCTRINE
# --------
# Read-only. This script changes nothing on the device; it reads
# two properties and renders a verdict. Run it BEFORE anything is
# flashed, every time: the MediaTek variant's recovery tree flashed
# on an Exynos unit kills the phone. The variants are marked apart.
#
# Usage:  sh variant-guard.sh
# Exit:   the reference logic's codes when python3 serves
#         (0 EXYNOS · 2 MEDIATEK · 3 UNKNOWN · 4 CONFLICT ·
#          5 NOT_A16_5G); the fallback uses the same codes for the
#         rulings it can reach.
#
# 93 — Live, Love, and let Love, Live.
# =====================================================================

set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

MODEL=$(getprop ro.product.model 2>/dev/null || echo "")
DEVICE=$(getprop ro.product.device 2>/dev/null || echo "")

echo "variant-guard: model='${MODEL}' device='${DEVICE}'"

# --- The full road: hand the whole dump to the reference logic. ----
if command -v python3 >/dev/null 2>&1 && [ -f "$HERE/variant_guard.py" ]; then
    getprop 2>/dev/null | python3 "$HERE/variant_guard.py" --getprop -
    exit $?
fi

# --- The fallback: model / codename subset, embedded. --------------
echo "variant-guard: python3 or variant_guard.py not at hand;"
echo "variant-guard: ruling on the FALLBACK subset (model/codename only)."
case "$MODEL" in
    SM-A166B*|SM-A166U*|SM-S166V*)
        echo "RULING: EXYNOS (fallback, by model)"; exit 0 ;;
    SM-A166P*)
        echo "RULING: MEDIATEK (fallback, by model)"; exit 2 ;;
    SM-A165*)
        echo "RULING: NOT_A16_5G (fallback — the 4G A16 family)"; exit 5 ;;
esac
# Exact-token codename match — 'a16xm' must never read as 'a16x'.
case "$DEVICE" in
    a16x)  echo "RULING: EXYNOS (fallback, by codename)"; exit 0 ;;
    a16xm) echo "RULING: MEDIATEK (fallback, by codename)"; exit 2 ;;
esac
echo "RULING: UNKNOWN (fallback) — stop and look; UNKNOWN never means proceed."
exit 3

# 93 — Live, Love, and let Love, Live.
