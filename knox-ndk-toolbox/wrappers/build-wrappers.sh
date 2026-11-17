#!/usr/bin/env bash
# ============================================================================
# BUILD-WRAPPERS — compile what can be compiled; name what cannot
# ----------------------------------------------------------------------------
# "Do what thou wilt shall be the whole of the Law."
#   The wrappers stand in two rooms. The platform room — Android's
#   own APIs — compiles anywhere an android.jar stands, and this
#   script compiles it, here, as proof. The Knox room compiles only
#   against Samsung's JAR in the seat; without the seat, this script
#   prints GATED and the gate's name, and compiles nothing in that
#   room. A build that stubbed Samsung's classes to make the red
#   light turn green would be manufacturing evidence.
#
# Authorship attributed exclusively to Johnathan "Qasparr" Monroe
# (Greek, -ARR, All Rights Reserved, Without Prejudice).
# XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
# (2026 e.v.). Method of Science, Aim of Religion. 93.
#
# MECHANISM —
#   0. GATES, all searched in printed order and reported:
#        javac   : $JAVA_HOME/bin, the house seat
#                  (/home/hatch/android-build/jdk-17), PATH.
#        android.jar : $ANDROID_JAR, $ANDROID_HOME/platforms,
#                  $ANDROID_SDK_ROOT/platforms, the house seat
#                  (/home/hatch/android-build/sdk/platforms).
#        Knox JAR: the seat — ../../vendor/samsung/**.jar, or
#                  $KNOX_SDK_JAR named by the operator.
#      Missing javac or android.jar = halt (the platform room is
#      this host's proven ground; its absence is a real failure).
#      Missing Knox JAR = the Knox room reports ACCOUNT-GATED and
#      the script still exits 0 if the platform room compiled: a
#      gate is a fact, not a failure.
#   1. PLATFORM ROOM. PlatformPolicyReader, KeyAttestationReader,
#      KnoxNativeBridge compile against android.jar into
#      ../../build/classes-platform. Both rooms compile with
#      -encoding UTF-8, and the flag is load-bearing: the house
#      headers are UTF-8 (em-dashes and all), while javac's default
#      encoding follows the host locale — on a POSIX-locale host
#      that is US-ASCII, and the first bench run died on exactly
#      that (81 unmappable-character errors). The sources declare
#      their encoding; the build repeats the declaration.
#   2. KNOX ROOM (seat permitting). KnoxPolicyReader,
#      KnoxLicenseActivator, KnoxAttestationReader compile against
#      android.jar + the seat JAR into ../../build/classes-knox.
#      If the seated JAR's shapes differ from the documented ones
#      the wrappers were written against, javac's errors print
#      whole — that printout is the seat doing its teaching.
# ============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TOOLBOX="$(cd "$HERE/.." && pwd)"
SRC="$HERE/java/com/qasparr/knoxbridge"
BUILD="$TOOLBOX/build"
mkdir -p "$BUILD/classes-platform" "$BUILD/classes-knox"

# --- 0. Gates. ----------------------------------------------------------
JAVAC=""
for candidate in \
    "${JAVA_HOME:-}/bin/javac" \
    "/home/hatch/android-build/jdk-17/bin/javac" \
    "$(command -v javac 2>/dev/null || true)" \
    ; do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then JAVAC="$candidate"; break; fi
done
if [ -z "$JAVAC" ]; then
    echo "BUILD HALT: no javac found (searched JAVA_HOME, the house JDK seat, PATH)." >&2
    exit 2
fi
echo "javac: $JAVAC"

ANDROID_JAR=""
jar_candidates() {
    [ -n "${ANDROID_JAR:-}" ] && echo "$ANDROID_JAR"
    for root in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "/home/hatch/android-build/sdk"; do
        [ -n "$root" ] || continue
        for jar in "$root"/platforms/*/android.jar; do
            [ -f "$jar" ] && echo "$jar"
        done
    done
}
while IFS= read -r jar; do
    if [ -f "$jar" ]; then ANDROID_JAR="$jar"; break; fi
done <<EOF
$(jar_candidates)
EOF
if [ -z "$ANDROID_JAR" ]; then
    echo "BUILD HALT: no android.jar found in any platform seat." >&2
    exit 2
fi
echo "android.jar: $ANDROID_JAR"

KNOX_JAR=""
if [ -n "${KNOX_SDK_JAR:-}" ] && [ -f "${KNOX_SDK_JAR:-}" ]; then
    KNOX_JAR="$KNOX_SDK_JAR"
else
    found="$(find "$TOOLBOX/vendor/samsung" -name '*.jar' -o -name '*.aar' 2>/dev/null | head -1 || true)"
    [ -n "$found" ] && KNOX_JAR="$found"
fi

# --- 1. The platform room. ------------------------------------------------
echo "--- platform room ---"
"$JAVAC" -encoding UTF-8 -cp "$ANDROID_JAR" -d "$BUILD/classes-platform" \
    "$SRC/PlatformPolicyReader.java" \
    "$SRC/KeyAttestationReader.java" \
    "$SRC/KnoxNativeBridge.java"
echo "Compiled: PlatformPolicyReader, KeyAttestationReader, KnoxNativeBridge"

# --- 2. The Knox room. ------------------------------------------------------
echo "--- knox room ---"
if [ -z "$KNOX_JAR" ]; then
    echo "ACCOUNT-GATED: no Knox SDK JAR in the seat."
    echo "  The Knox wrappers (KnoxPolicyReader, KnoxLicenseActivator,"
    echo "  KnoxAttestationReader) stand as sources. The seat is filled"
    echo "  only through the founder's Knox Partner Program door — see"
    echo "  ../../sdk-seat/README.md. Nothing was stubbed to force this"
    echo "  room green; a gate reported is a gate respected."
    exit 0
fi
echo "Knox JAR: $KNOX_JAR"
"$JAVAC" -encoding UTF-8 -cp "$ANDROID_JAR:$KNOX_JAR" -d "$BUILD/classes-knox" \
    "$SRC/KnoxPolicyReader.java" \
    "$SRC/KnoxLicenseActivator.java" \
    "$SRC/KnoxAttestationReader.java"
echo "Compiled: the Knox room stands against the seated SDK."

# ============================================================================
# 93 — Live, Love, and let Love, Live.
# ============================================================================
