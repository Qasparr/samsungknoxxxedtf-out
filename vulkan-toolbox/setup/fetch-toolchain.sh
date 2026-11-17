#!/usr/bin/env bash
# ============================================================================
# FETCH-TOOLCHAIN — the road by which an NDK reaches this host
# ----------------------------------------------------------------------------
# "Do what thou wilt shall be the whole of the Law."
#   The Java machinery on this host has no real TCP: sdkmanager
#   cannot download here, and pretending otherwise wastes a night.
#   So the toolchain travels the road that works — curl, by hand,
#   from the maker's own server — and it is weighed against the
#   maker's own hash before it is trusted. This script is that road,
#   with the gates printed on its face.
#
# Authorship attributed exclusively to Johnathan "Qasparr" Monroe
# (Greek, -ARR, All Rights Reserved, Without Prejudice).
# XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
# (2026 e.v.). Method of Science, Aim of Religion. 93.
#
# MECHANISM — what this script does, in order:
#   0. DEFAULT IS DRY-RUN. With no --fetch, the script prints the
#      whole plan — the archive, the URL, the size of the promise,
#      the layout — and moves nothing. Reading the road is free;
#      driving it is a decision.
#   1. GATES. curl, unzip, sha256sum are required up front; a missing
#      tool halts before a byte moves (the house posture, fail-closed).
#   2. THE ARCHIVE. The Android NDK, revision r30 — the revision this
#      house already runs at the PQPE seat — from Google's own
#      repository: https://dl.google.com/android/repository/
#      android-ndk-r30-linux.zip. No mirrors, no third-party hosts:
#      a toolchain from anywhere else is a toolchain from an
#      stranger. (The revision is a variable, NDK_REV, so the day
#      the house moves, the script moves by one edited line and a
#      new hash — not by archaeology.)
#   3. THE WEIGHING. The operator supplies the expected SHA-256 at
#      run time (--expected-sha256), taken from Google's own NDK
#      downloads page in the same sitting. NO HASH IS HARDCODED IN
#      THIS FILE, by the same law the deployment kit keeps: a hash
#      remembered is a hash that can rot. Mismatch = the archive is
#      deleted and the script halts; a weighed-and-failed archive is
#      never laid out "to look at later".
#   4. THE LAYOUT. The verified archive is unpacked under
#      ../vendor/ndk/ — inside the toolbox, nothing system-wide —
#      yielding ../vendor/ndk/android-ndk-r30, the seat build.sh and
#      compile-shaders.sh already search. The bundled shader-tools
#      (glslc, spirv-val) arrive inside the NDK itself; no separate
#      shader compiler fetch is needed, and the script says so.
#   5. WHAT THIS SCRIPT DOES NOT DO. It does not fetch glslang from
#      Khronos (unnecessary — see 4), does not touch the system, does
#      not run sdkmanager, and does not fetch on a dry run. The
#      download is several hundred megabytes of the operator's
#      bandwidth, spent only on the operator's word: --fetch.
#
# Usage:
#   fetch-toolchain.sh [--dry-run]
#   fetch-toolchain.sh --fetch --expected-sha256 <64 hex, from Google>
# ============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TOOLBOX="$(cd "$HERE/.." && pwd)"
NDK_REV="${NDK_REV:-r30}"
ARCHIVE="android-ndk-${NDK_REV}-linux.zip"
URL="https://dl.google.com/android/repository/${ARCHIVE}"
VENDOR="$TOOLBOX/vendor"
DOWNLOADS="$VENDOR/downloads"
SEAT="$VENDOR/ndk"

FETCH=0
EXPECTED=""
while [ $# -gt 0 ]; do
    case "$1" in
        --fetch)            FETCH=1; shift ;;
        --dry-run)          FETCH=0; shift ;;
        --expected-sha256)  EXPECTED="${2:-}"; shift 2 ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
done

echo "FETCH-TOOLCHAIN — the NDK road"
echo "  archive : $ARCHIVE"
echo "  url     : $URL"
echo "  layout  : $SEAT/android-ndk-${NDK_REV}"
echo "  carries : the NDK clang seats and shader-tools (glslc, spirv-val)"
echo "  note    : sdkmanager cannot download on this host (the JVM has"
echo "            no real TCP); this curl road is the house's proven one."

if [ "$FETCH" -eq 0 ]; then
    echo "DRY-RUN: nothing fetched, nothing laid out."
    echo "  To drive the road: $0 --fetch --expected-sha256 <hash from"
    echo "  Google's NDK downloads page, taken in the same sitting>"
    exit 0
fi

# --- 1. Gates. ----------------------------------------------------------
for tool in curl unzip sha256sum; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "FETCH HALT: required tool missing: $tool" >&2
        exit 2
    fi
done
if [ -z "$EXPECTED" ]; then
    echo "FETCH HALT: --fetch requires --expected-sha256." >&2
    echo "  Take the hash from Google's NDK downloads page now, in this" >&2
    echo "  sitting. No hash is hardcoded here, by law: a hash remembered" >&2
    echo "  is a hash that can rot." >&2
    exit 2
fi

# --- 2+3. Fetch, then weigh. ---------------------------------------------
mkdir -p "$DOWNLOADS" "$SEAT"
echo "Fetching $URL ..."
curl -fL --progress-bar -o "$DOWNLOADS/$ARCHIVE" "$URL"

ACTUAL="$(sha256sum "$DOWNLOADS/$ARCHIVE" | awk '{print $1}')"
if [ "$ACTUAL" != "$EXPECTED" ]; then
    echo "FETCH HALT: SHA-256 mismatch." >&2
    echo "  expected: $EXPECTED" >&2
    echo "  actual  : $ACTUAL" >&2
    echo "  The archive is deleted; a failed weighing is never laid out." >&2
    rm -f "$DOWNLOADS/$ARCHIVE"
    exit 4
fi
echo "Weighed: SHA-256 matches the maker's hash."

# --- 4. Layout, inside the toolbox only. ----------------------------------
unzip -q -o "$DOWNLOADS/$ARCHIVE" -d "$SEAT"
echo "Laid out: $SEAT/android-ndk-${NDK_REV}"
echo "  build.sh and compile-shaders.sh search this seat automatically."

# ============================================================================
# 93 — Live, Love, and let Love, Live.
# ============================================================================
