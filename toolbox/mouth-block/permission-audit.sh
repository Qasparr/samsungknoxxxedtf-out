#!/bin/sh
# =====================================================================
# PERMISSION-AUDIT — read the mouth's current state, change nothing
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
# For every package in the manifest (all tiers, never-tier included
# — reading the protected stack's presence is how you prove it
# still stands), record over ADB: present or absent, enabled or
# disabled for user 0, the runtime permissions currently GRANTED,
# and the appops state. Output is one dated audit file: the
# before-picture against which any mouth-block is later judged.
#
# DOCTRINE
# --------
# Read-only without exception: pm list, dumpsys, cmd appops get —
# no command in this script can change a state. Run it BEFORE the
# block (the baseline), AFTER the block (the proof), and whenever
# the phone starts talking again (the diagnosis). The desk never
# runs it; the founder strikes it from his own host.
#
# Usage:  sh permission-audit.sh [--out FILE]
#
# 93 — Live, Love, and let Love, Live.
# =====================================================================

set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MANIFEST="$HERE/packages.tsv"
OUT="$HERE/permission-audit-$(date +%Y%m%d-%H%M%S).txt"
case "${1:-}" in
    --out) OUT="${2:?--out needs a file}" ;;
    "")    ;;
    *) echo "usage: sh permission-audit.sh [--out FILE]" >&2; exit 64 ;;
esac

command -v adb >/dev/null 2>&1 || { echo "adb not found on this host." >&2; exit 69; }
[ "$(adb get-state 2>/dev/null)" = "device" ] || {
    echo "no device answers adb (state: $(adb get-state 2>/dev/null || echo none))." >&2
    exit 69
}
[ -f "$MANIFEST" ] || { echo "manifest not found: $MANIFEST" >&2; exit 66; }

{
    echo "=================================================================="
    echo "PERMISSION AUDIT — struck $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "read-only: nothing in the striking changed any state."
    echo "=================================================================="
    awk -F '\t' '$1 !~ /^#/ && NF >= 4 {print $1"\t"$2"\t"$3}' "$MANIFEST" |
    while IFS="$(printf '\t')" read -r pkg tier action; do
        echo "------------------------------------------------------------------"
        echo "PACKAGE: $pkg   (manifest tier: $tier / $action)"
        if adb shell pm list packages "$pkg" 2>/dev/null | grep -q "package:$pkg"; then
            echo "  present: yes"
        else
            echo "  present: NO (absent on this unit — the manifest is"
            echo "           amended from this evidence, never from habit)"
            continue
        fi
        if adb shell pm list packages -d "$pkg" 2>/dev/null | grep -q "package:$pkg"; then
            echo "  state: DISABLED for user 0"
        else
            echo "  state: enabled"
        fi
        echo "  granted runtime permissions:"
        adb shell dumpsys package "$pkg" 2>/dev/null |
            sed -n '/granted permissions:/,/^$/p' | head -30 |
            sed 's/^/    /' || echo "    UNAVAILABLE"
        echo "  appops:"
        adb shell cmd appops get "$pkg" 2>/dev/null | head -20 |
            sed 's/^/    /' || echo "    UNAVAILABLE"
    done
    echo "=================================================================="
    echo "END OF AUDIT — pair with AUDIT-CHECKLIST.md for the Settings"
    echo "passes (background data, battery) that no shell may strike."
} > "$OUT"

echo "audit written: $OUT"

# 93 — Live, Love, and let Love, Live.
