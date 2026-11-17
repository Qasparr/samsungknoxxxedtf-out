#!/bin/sh
# =====================================================================
# DEVICE-INVENTORY — the A16 dossier strike, ADB (host) side
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
# The same dossier as device-inventory.sh, struck from a host over
# ADB: every probe is an `adb shell` read, the dossier is written
# host-side. The identity section keeps the '[key]: [value]' shape
# so parse_dossier.py reads it unchanged.
#
# DOCTRINE
# --------
# Read-only, end to end — `adb shell` is used here as a reading
# glass, never as a hand. The script refuses to strike when no
# device answers (a dossier of the wrong unit is worse than none),
# and it is run by the founder from his own host: the desk does not
# run it against his phone.
#
# Usage:  sh device-inventory-adb.sh [--out FILE]
#   default dossier: ./device-dossier-<date>.txt in the cwd
#
# 93 — Live, Love, and let Love, Live.
# =====================================================================

set -u

OUT="device-dossier-$(date +%Y%m%d-%H%M%S).txt"
case "${1:-}" in
    --out) OUT="${2:?--out needs a file}" ;;
    "")    ;;
    *) echo "usage: sh device-inventory-adb.sh [--out FILE]" >&2; exit 64 ;;
esac

command -v adb >/dev/null 2>&1 || { echo "adb not found on this host." >&2; exit 69; }
[ "$(adb get-state 2>/dev/null)" = "device" ] || {
    echo "no device answers adb (state: $(adb get-state 2>/dev/null || echo none))." >&2
    echo "connect the unit, unlock it, and strike again." >&2
    exit 69
}

SERIAL=$(adb get-serialno 2>/dev/null || echo unknown)
echo "striking dossier from device $SERIAL ..."

{
    echo "=================================================================="
    echo "DEVICE DOSSIER — struck $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "struck by: device-inventory-adb.sh (toolbox/inventory), host side"
    echo "device serial (as adb reports): $SERIAL"
    echo "=================================================================="

    echo "== IDENTITY (getprop shape — the parser reads this section) =="
    adb shell getprop 2>/dev/null | tr -d '\r' | grep -E \
      '^\[(ro\.product\.model|ro\.product\.device|ro\.product\.brand|ro\.product\.manufacturer|ro\.board\.platform|ro\.hardware|ro\.soc\.manufacturer|ro\.soc\.model|ro\.build\.fingerprint|ro\.build\.id|ro\.build\.version\.release|ro\.build\.version\.security_patch|ro\.bootloader|ro\.build\.display\.id|ro\.config\.knox)\]:' \
      || echo "  UNAVAILABLE (getprop refused)"

    echo "== SOC / CPU =="
    echo "-- uname";            adb shell uname -a 2>/dev/null || echo UNAVAILABLE
    echo "-- /proc/cpuinfo";    adb shell 'head -30 /proc/cpuinfo' 2>/dev/null || echo UNAVAILABLE

    echo "== THERMAL ZONES =="
    adb shell 'for z in /sys/class/thermal/thermal_zone*; do
                 echo "  $(cat $z/type 2>/dev/null) = $(cat $z/temp 2>/dev/null)"
               done' 2>/dev/null || echo "  UNAVAILABLE"

    echo "== CPU GOVERNORS =="
    adb shell 'for p in /sys/devices/system/cpu/cpufreq/policy*; do
                 echo "  $p governor: $(cat $p/scaling_governor 2>/dev/null)"
                 echo "  $p available: $(cat $p/scaling_available_governors 2>/dev/null)"
               done' 2>/dev/null || echo "  UNAVAILABLE"

    echo "== SENSORS =="
    adb shell 'dumpsys sensorservice | head -60' 2>/dev/null || echo UNAVAILABLE

    echo "== MEMORY =="
    adb shell 'head -6 /proc/meminfo' 2>/dev/null || echo UNAVAILABLE

    echo "== STORAGE =="
    adb shell 'df -h /data /storage/emulated/0' 2>/dev/null || echo UNAVAILABLE

    echo "== BATTERY =="
    adb shell 'dumpsys battery | head -20' 2>/dev/null || echo UNAVAILABLE

    echo "=================================================================="
    echo "END OF DOSSIER"
} > "$OUT"

echo "dossier written: $OUT"
echo "rule it with: python3 parse_dossier.py $OUT   (in this directory's parent kit)"

# 93 — Live, Love, and let Love, Live.
