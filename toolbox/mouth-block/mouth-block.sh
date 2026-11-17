#!/bin/sh
# =====================================================================
# MOUTH-BLOCK — the vendor-layer isolation, as a reversible kit
#
# "Do what thou wilt shall be the whole of the Law."
#
# XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
# (2026 e.v.) — the order of the same day: isolate and block the
# consumer Samsung layer — "block the mouth, not the Vault."
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
# Reads packages.tsv (the manifest beside this script) and drives
# ADB: for every disable-user row in scope it emits the pair
#     pm disable-user --user 0 <package>     (the block)
#     pm enable <package>                    (its undo)
# --dry-run (the DEFAULT) only prints the pairs. --apply runs the
# disables for packages actually present on the unit and writes a
# dated state log of what was truly applied. --undo reads the state
# log and enables exactly what the log records — nothing else.
#
# disable-user is the reversible seat by design: the package stays
# on the device, its data stays, and pm enable restores it whole.
# Nothing here uninstalls, clears, or roots anything.
#
# DOCTRINE — THE NEVER-TOUCH LIST, PRINTED BEFORE ANYTHING RUNS
# --------------------------------------------------------------
# KeyMint / Keystore (keystore2), Gatekeeper, Weaver, the TEE stack
# (TEEGRIS), the Knox platform, radio/baseband, storage and display
# HALs: these are the Vault's house and the phone's body. This kit
# refuses them by name — if the manifest ever names a never-tier
# package in a disable row, the script ABORTS before touching adb.
# The founder's doctrine stands: rooting to murder privileged
# daemons spends the Knox fuse and devalues attestation; this kit
# exists precisely so that road is never needed for silence.
#
# THE DESK NEVER RUNS THIS. The phone's settings are the founder's
# own; the kit is struck by his hand, from his host, on his word.
#
# Usage:
#   sh mouth-block.sh [--dry-run] [--include-review]
#   sh mouth-block.sh --apply [--include-review]
#   sh mouth-block.sh --undo [STATE-LOG]
#
# 93 — Live, Love, and let Love, Live.
# =====================================================================

set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MANIFEST="$HERE/packages.tsv"
MODE="dry-run"
INCLUDE_REVIEW=0
STATE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)        MODE="dry-run" ;;
        --apply)          MODE="apply" ;;
        --undo)           MODE="undo"; STATE="${2:-}"; [ $# -ge 2 ] && shift ;;
        --include-review) INCLUDE_REVIEW=1 ;;
        *) echo "unknown argument: $1" >&2; exit 64 ;;
    esac
    shift
done

[ -f "$MANIFEST" ] || { echo "manifest not found: $MANIFEST" >&2; exit 66; }

echo "=================================================================="
echo "MOUTH-BLOCK — block the mouth, not the Vault."
echo "NEVER TOUCH: KeyMint · keystore2 · Gatekeeper · Weaver ·"
echo "  TEEGRIS / the TEE stack · the Knox platform · radio/baseband ·"
echo "  storage and display HALs. This kit refuses them by name."
echo "=================================================================="

# --- Self-guard: a disable row naming a never-tier package aborts. -
# MECHANISM: collect the never set and the disable set from the one
# manifest; if they intersect, the manifest itself is corrupt and
# the only safe act is refusal.
NEVER_SET=$(awk -F '\t' '$2=="never" {print $1}' "$MANIFEST")
DISABLE_SET=$(awk -F '\t' '$3=="disable-user" {print $1}' "$MANIFEST")
for p in $DISABLE_SET; do
    for n in $NEVER_SET; do
        if [ "$p" = "$n" ]; then
            echo "ABORT: manifest names never-touch package '$p' in a disable row." >&2
            echo "The manifest is corrupt; nothing was run." >&2
            exit 65
        fi
    done
done

# --- rows_in_scope: the disable rows this run may touch. -----------
rows_in_scope() {
    awk -F '\t' -v review="$INCLUDE_REVIEW" '
        $3=="disable-user" && ($2=="default" || (review=="1" && $2=="review")) {print $1}
    ' "$MANIFEST"
}

if [ "$MODE" = "undo" ]; then
    # Undo enables EXACTLY what a state log records — no log, no undo.
    if [ -z "$STATE" ]; then
        STATE=$(ls -t "$HERE"/mouth-block-state-*.log 2>/dev/null | head -1 || echo "")
    fi
    [ -n "$STATE" ] && [ -f "$STATE" ] || {
        echo "no state log found — nothing to undo from. Undo is" >&2
        echo "driven by the record of what was applied, never by guess." >&2
        exit 66
    }
    echo "undo from state log: $STATE"
    command -v adb >/dev/null 2>&1 || { echo "adb not found." >&2; exit 69; }
    [ "$(adb get-state 2>/dev/null)" = "device" ] || {
        echo "no device answers adb; nothing enabled." >&2; exit 69; }
    while IFS= read -r pkg; do
        [ -n "$pkg" ] || continue
        echo "  enable: adb shell pm enable $pkg"
        adb shell pm enable "$pkg" 2>/dev/null || \
            echo "  -> adb refused this one; recorded, undo continues"
    done <<EOF
$(grep '^applied ' "$STATE" | awk '{print $2}')
EOF
    echo "undo complete (each line above was enabled, or adb said why not)."
    exit 0
fi

# --- dry-run / apply share the pair generation. ---------------------
echo "mode: $MODE   include-review: $INCLUDE_REVIEW"
echo "------------------------------------------------------------------"
if [ "$MODE" = "apply" ]; then
    command -v adb >/dev/null 2>&1 || { echo "adb not found." >&2; exit 69; }
    [ "$(adb get-state 2>/dev/null)" = "device" ] || {
        echo "no device answers adb; nothing applied." >&2; exit 69; }
    STATE="$HERE/mouth-block-state-$(date +%Y%m%d-%H%M%S).log"
    echo "# mouth-block state log — $(date '+%Y-%m-%d %H:%M:%S %Z')" > "$STATE"
fi

rows_in_scope | while IFS= read -r pkg; do
    [ -n "$pkg" ] || continue
    echo "BLOCK  adb shell pm disable-user --user 0 $pkg"
    echo "UNDO   adb shell pm enable $pkg"
    if [ "$MODE" = "apply" ]; then
        if adb shell pm list packages "$pkg" 2>/dev/null | grep -q "package:$pkg"; then
            if adb shell pm disable-user --user 0 "$pkg" >/dev/null 2>&1; then
                echo "applied $pkg" >> "$STATE"
                echo "  -> applied"
            else
                echo "  -> FAILED (adb refused; recorded, strike continues)"
                echo "failed $pkg" >> "$STATE"
            fi
        else
            echo "  -> absent on this unit; skipped and logged"
            echo "absent $pkg" >> "$STATE"
        fi
    fi
done

if [ "$MODE" = "apply" ]; then
    echo "------------------------------------------------------------------"
    echo "state log: $STATE"
    echo "undo with: sh mouth-block.sh --undo $STATE"
else
    echo "------------------------------------------------------------------"
    echo "dry run only — nothing was sent to any device."
    echo "apply with: sh mouth-block.sh --apply"
fi

# 93 — Live, Love, and let Love, Live.
