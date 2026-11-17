#!/usr/bin/env bash
# ============================================================================
# BUILD — caps-probe, compiled for the A16's arm64 Android seat
# ----------------------------------------------------------------------------
# "Do what thou wilt shall be the whole of the Law."
#   The probe is compiled where the compilers live and run where the
#   GPU lives; this script is the bridge between those two places,
#   and it names every plank it stands on before it crosses.
#
# Authorship attributed exclusively to Johnathan "Qasparr" Monroe
# (Greek, -ARR, All Rights Reserved, Without Prejudice).
# XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
# (2026 e.v.). Method of Science, Aim of Religion. 93.
#
# MECHANISM — what this script does, in order:
#   0. GATES. The NDK is located by a search with a printed order:
#        1. $ANDROID_NDK_HOME, if the operator set it;
#        2. $VK_TOOLBOX_NDK, this toolbox's own override;
#        3. the toolbox's fetched seat, ../vendor/ndk/ (fetch-toolchain.sh
#           lays an NDK there);
#        4. the house's standing PQPE seat, ~/workspace/pqpe-ndk/ndk/,
#           where NDK r30 already lives on this host.
#      The seat that answers is printed. No seat = halt, fail-closed.
#   1. THE COMPILER. The per-API clang wrapper for the target API
#      (default 31 — Android 12's level, safely below the A16's own
#      Android 14/15 seat and safely above Vulkan's Android floor of
#      API 24, where libvulkan enters the NDK sysroot) is required to
#      exist inside the found NDK.
#   2. THE BUILD. caps_probe.c is compiled and linked against the
#      sysroot's libvulkan stub into ../build/caps_probe. The output
#      is an arm64 Android executable: it runs under `adb shell` on
#      the device. It does not run on this host, and this script does
#      not pretend otherwise — it prints the `file` verdict so the
#      record shows what was actually struck.
# ============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TOOLBOX="$(cd "$HERE/.." && pwd)"
API="${VK_API:-31}"

# --- 0. Gates: find the NDK, in the printed order. -------------------
NDK=""
for candidate in \
    "${ANDROID_NDK_HOME:-}" \
    "${VK_TOOLBOX_NDK:-}" \
    "$TOOLBOX/vendor/ndk/android-ndk-r30" \
    "$HOME/workspace/pqpe-ndk/ndk/android-ndk-r30" \
    ; do
    if [ -n "$candidate" ] && [ -d "$candidate/toolchains/llvm/prebuilt/linux-x86_64" ]; then
        NDK="$candidate"
        break
    fi
done
if [ -z "$NDK" ]; then
    echo "BUILD HALT: no Android NDK found in the searched seats." >&2
    echo "  Run ../setup/fetch-toolchain.sh --dry-run for the fetch road," >&2
    echo "  or set ANDROID_NDK_HOME / VK_TOOLBOX_NDK to an NDK seat." >&2
    exit 2
fi
echo "NDK seat: $NDK"

CC="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${API}-clang"
if [ ! -x "$CC" ]; then
    echo "BUILD HALT: compiler not found: $CC" >&2
    exit 2
fi
echo "Compiler: $CC (target API $API)"

# --- 2. The build. ----------------------------------------------------
mkdir -p "$TOOLBOX/build"
"$CC" -O2 -Wall -Wextra -std=c11 \
    "$HERE/caps_probe.c" -lvulkan \
    -o "$TOOLBOX/build/caps_probe"
echo "Struck: $TOOLBOX/build/caps_probe"
file "$TOOLBOX/build/caps_probe" || true
echo "Run it on the device:  adb push $TOOLBOX/build/caps_probe /data/local/tmp/"
echo "                       adb shell /data/local/tmp/caps_probe"

# ============================================================================
# 93 — Live, Love, and let Love, Live.
# ============================================================================
