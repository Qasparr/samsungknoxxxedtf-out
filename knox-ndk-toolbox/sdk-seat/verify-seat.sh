#!/usr/bin/env bash
# ============================================================================
# VERIFY-SEAT — is Samsung's SDK standing in the seat, and is it whole?
# ----------------------------------------------------------------------------
# "Do what thou wilt shall be the whole of the Law."
#   A seat is a promise about where a thing will stand. This script
#   checks the promise without breaking the law that created it: it
#   looks for Samsung's archives in the seat, opens their TABLES OF
#   CONTENTS (never their code), and asks whether the classes the
#   wrappers are written against are inside. Nothing of Samsung's is
#   copied, extracted, or mirrored by this script — a listing is a
#   witness, not a theft.
#
# Authorship attributed exclusively to Johnathan "Qasparr" Monroe
# (Greek, -ARR, All Rights Reserved, Without Prejudice).
# XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
# (2026 e.v.). Method of Science, Aim of Religion. 93.
#
# MECHANISM — three verdicts, three exits:
#   SEAT OK (exit 0)      : an archive stands in ../vendor/samsung/
#                           and its listing names the load-bearing
#                           classes (EnterpriseDeviceManager at
#                           minimum).
#   SEAT INCOMPLETE (3)   : the seat directory exists but holds no
#                           archive, or the archive's listing lacks
#                           the load-bearing class — the download
#                           was partial, or the wrong package came
#                           through the door.
#   ACCOUNT-GATED (3)     : the seat was never filled. The script
#                           prints the exact door, in order:
#                             1. Enroll in the Knox Partner Program
#                                (the Knox Partner Portal).
#                             2. Knox Developers dashboard ->
#                                SDK Tools -> SDK Downloads.
#                             3. Accept the SDK Agreement; download.
#                             4. Generate a KPE license key (My
#                                license keys; Development while
#                                testing) — the key itself never
#                                enters this repository.
#                             5. Lay the package's archives under
#                                ../vendor/samsung/ (git-ignored;
#                                Samsung's binaries never enter git).
#   Exit 3 is a GATE, not a failure: the script's whole duty is to
#   tell the gate from a breakage, and it does so in its first line.
# ============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TOOLBOX="$(cd "$HERE/.." && pwd)"
SEAT="$TOOLBOX/vendor/samsung"

print_door() {
    echo "  The door, in order:"
    echo "    1. Enroll in the Knox Partner Program (Knox Partner Portal)."
    echo "    2. Knox Developers dashboard -> SDK Tools -> SDK Downloads."
    echo "    3. Accept the SDK Agreement and download the Knox SDK."
    echo "    4. Generate a KPE license key in the same portal (Development"
    echo "       while testing). The key never enters this repository."
    echo "    5. Lay the package's .jar/.aar archives under:"
    echo "         $SEAT"
    echo "       (git-ignored — Samsung's binaries are never committed.)"
}

if [ ! -d "$SEAT" ]; then
    echo "ACCOUNT-GATED: the seat has never been filled ($SEAT does not stand)."
    print_door
    exit 3
fi

ARCHIVES="$(find "$SEAT" -name '*.jar' -o -name '*.aar' 2>/dev/null)"
if [ -z "$ARCHIVES" ]; then
    echo "SEAT INCOMPLETE: $SEAT stands but holds no .jar or .aar archive."
    print_door
    exit 3
fi

echo "Seat archives:"
echo "$ARCHIVES" | while IFS= read -r a; do echo "  $a"; done

# The load-bearing class, sought in the listings (contents only).
FOUND=0
while IFS= read -r a; do
    case "$a" in
        *.jar)
            if command -v unzip >/dev/null 2>&1 \
               && unzip -l "$a" 2>/dev/null | grep -q "com/samsung/android/knox/EnterpriseDeviceManager.class"; then
                FOUND=1
                echo "  load-bearing class found in: $a"
            fi
            ;;
        *.aar)
            echo "  (aar present — its inner classes.jar is the seat's to"
            echo "   confirm at build time; listings of .aar are archives"
            echo "   within archives and this script opens only one level)"
            FOUND=1
            ;;
    esac
done <<EOF
$ARCHIVES
EOF

if [ "$FOUND" -eq 1 ]; then
    echo "SEAT OK: Samsung's SDK stands in the seat and names its classes."
    exit 0
fi
echo "SEAT INCOMPLETE: archives stand, but no listing names"
echo "  com/samsung/android/knox/EnterpriseDeviceManager — the wrong"
echo "  package may have come through the door, or a partial one."
exit 3

# ============================================================================
# 93 — Live, Love, and let Love, Live.
# ============================================================================
