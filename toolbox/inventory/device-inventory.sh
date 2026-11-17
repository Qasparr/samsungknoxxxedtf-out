#!/bin/sh
# =====================================================================
# DEVICE-INVENTORY — the A16 dossier strike, Termux side
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
# A read-only enumeration of the unit, run in Termux on the phone:
# identity properties, SoC, kernel, build, thermal zones, CPU
# governors, sensors (as far as the shell may see), memory, storage,
# battery — written as one dated dossier. The identity section is
# emitted in getprop's own '[key]: [value]' shape so the toolbox's
# parser (parse_dossier.py) reads a dossier exactly as it reads a
# raw dump.
#
# Every probe is defensive: a probe the shell has no permission for
# records UNAVAILABLE and the strike continues. A dossier with
# honest gaps outranks a strike that dies on its first refusal.
#
# DOCTRINE
# --------
# Read-only, end to end. Nothing here writes to the device, changes
# a setting, or sends a byte anywhere: the dossier is printed to
# stdout, and to a file only when the founder passes --save. The
# desk does not run this against the founder's phone; it is struck
# by his hand, on his unit, for his records.
#
# Usage:  sh device-inventory.sh [--save [FILE]]
#   default        dossier to stdout only
#   --save         also write ~/device-dossier-<date>.txt
#   --save FILE    also write FILE
#
# 93 — Live, Love, and let Love, Live.
# =====================================================================

set -u

SAVE=""
case "${1:-}" in
    --save) SAVE="${2:-$HOME/device-dossier-$(date +%Y%m%d-%H%M%S).txt}" ;;
    "")     ;;
    *) echo "usage: sh device-inventory.sh [--save [FILE]]" >&2; exit 64 ;;
esac

# probe LABEL COMMAND... — run, and on any failure record the gap.
probe() {
    label=$1; shift
    echo "-- $label"
    if out=$("$@" 2>/dev/null) && [ -n "$out" ]; then
        echo "$out"
    else
        echo "UNAVAILABLE"
    fi
}

# prop KEY — one getprop in dossier shape, or ABSENT.
prop() {
    v=$(getprop "$1" 2>/dev/null || echo "")
    if [ -n "$v" ]; then echo "[$1]: [$v]"; else echo "[$1]: [ABSENT]"; fi
}

strike() {
    echo "=================================================================="
    echo "DEVICE DOSSIER — struck $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "struck by: device-inventory.sh (toolbox/inventory), Termux side"
    echo "=================================================================="

    echo "== IDENTITY (getprop shape — the parser reads this section) =="
    for k in ro.product.model ro.product.device ro.product.brand \
             ro.product.manufacturer ro.board.platform ro.hardware \
             ro.soc.manufacturer ro.soc.model ro.build.fingerprint \
             ro.build.id ro.build.version.release \
             ro.build.version.security_patch ro.bootloader \
             ro.build.display.id ro.config.knox; do
        prop "$k"
    done

    echo "== SOC / CPU =="
    probe "uname" uname -a
    probe "/proc/cpuinfo (head)" sh -c 'head -30 /proc/cpuinfo'
    probe "cpu count" sh -c 'ls /sys/devices/system/cpu/ | grep -c "^cpu[0-9]"'

    echo "== THERMAL ZONES (type = millidegree-C as the kernel reports) =="
    found=0
    for z in /sys/class/thermal/thermal_zone*; do
        [ -d "$z" ] || continue
        found=1
        t=$(cat "$z/type" 2>/dev/null || echo "?")
        v=$(cat "$z/temp" 2>/dev/null || echo "UNAVAILABLE")
        echo "  $t = $v"
    done
    [ "$found" -eq 1 ] || echo "  UNAVAILABLE (no readable thermal zones)"

    echo "== CPU GOVERNORS (per policy) =="
    found=0
    for p in /sys/devices/system/cpu/cpufreq/policy*; do
        [ -d "$p" ] || continue
        found=1
        echo "  $p:"
        echo "    governor:  $(cat "$p/scaling_governor" 2>/dev/null || echo UNAVAILABLE)"
        echo "    available: $(cat "$p/scaling_available_governors" 2>/dev/null || echo UNAVAILABLE)"
        echo "    max freq:  $(cat "$p/cpuinfo_max_freq" 2>/dev/null || echo UNAVAILABLE)"
    done
    [ "$found" -eq 1 ] || echo "  UNAVAILABLE (no readable cpufreq policies)"

    echo "== SENSORS (as far as the shell may see) =="
    probe "dumpsys sensorservice (head)" sh -c 'dumpsys sensorservice 2>/dev/null | head -60'

    echo "== MEMORY =="
    probe "/proc/meminfo (head)" sh -c 'head -6 /proc/meminfo'

    echo "== STORAGE =="
    probe "df" df -h /data /storage/emulated/0 /sdcard

    echo "== BATTERY =="
    for f in capacity status temp; do
        v=$(cat "/sys/class/power_supply/battery/$f" 2>/dev/null || echo UNAVAILABLE)
        echo "  $f = $v"
    done

    echo "== VARIANT VERDICT (fallback subset — the reference logic"
    echo "   is variant_guard.py; run it on this dossier for the full"
    echo "   ruling with evidence) =="
    MODEL=$(getprop ro.product.model 2>/dev/null || echo "")
    DEVICE=$(getprop ro.product.device 2>/dev/null || echo "")
    case "$MODEL" in
        SM-A166B*|SM-A166U*|SM-S166V*) echo "  EXYNOS (by model $MODEL)" ;;
        SM-A166P*)                     echo "  MEDIATEK (by model $MODEL)" ;;
        SM-A165*)                      echo "  NOT_A16_5G (the 4G family)" ;;
        *)
            case "$DEVICE" in
                a16x)  echo "  EXYNOS (by codename a16x)" ;;
                a16xm) echo "  MEDIATEK (by codename a16xm)" ;;
                *)     echo "  UNKNOWN — stop and look" ;;
            esac ;;
    esac
    echo "=================================================================="
    echo "END OF DOSSIER"
}

if [ -n "$SAVE" ]; then
    strike | tee "$SAVE"
    echo "dossier saved: $SAVE" >&2
else
    strike
fi

# 93 — Live, Love, and let Love, Live.
