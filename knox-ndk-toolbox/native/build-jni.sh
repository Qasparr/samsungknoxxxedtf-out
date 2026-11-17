#!/usr/bin/env bash
# ============================================================================
# BUILD-JNI — libknoxbridge.so, struck for the A16's arm64 seat
# ----------------------------------------------------------------------------
# "Do what thou wilt shall be the whole of the Law."
#   The native glue is two small functions and a clear conscience.
#   This script compiles them with the NDK clang into the shared
#   library the Java bridge loads, and prints the `file` verdict so
#   the record shows the architecture that was actually struck.
#
# Authorship attributed exclusively to Johnathan "Qasparr" Monroe
# (Greek, -ARR, All Rights Reserved, Without Prejudice).
# XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
# (2026 e.v.). Method of Science, Aim of Religion. 93.
#
# MECHANISM —
#   The NDK search is the house's printed order (operator override,
#   the Knox toolbox's own vendor seat if ever filled, the Vulkan
#   toolbox's vendor seat, the standing PQPE seat). The JNI headers
#   ride inside the NDK sysroot; the library links against nothing
#   beyond the platform's own libc — __system_property_get lives
#   there on Android, and a bridge that needed more would say so.
#   Output: ../build/libknoxbridge.so, an arm64 Android shared
#   library. It runs inside an app on the device (DEVICE-GATED at
#   run time); its compilation is this host's proven ground.
# ============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TOOLBOX="$(cd "$HERE/.." && pwd)"
API="${VK_API:-31}"

NDK=""
for candidate in \
    "${ANDROID_NDK_HOME:-}" \
    "${VK_TOOLBOX_NDK:-}" \
    "$TOOLBOX/vendor/ndk/android-ndk-r30" \
    "$TOOLBOX/../vulkan-toolbox/vendor/ndk/android-ndk-r30" \
    "$HOME/workspace/pqpe-ndk/ndk/android-ndk-r30" \
    ; do
    if [ -n "$candidate" ] && [ -d "$candidate/toolchains/llvm/prebuilt/linux-x86_64" ]; then
        NDK="$candidate"; break
    fi
done
if [ -z "$NDK" ]; then
    echo "BUILD HALT: no Android NDK found in the searched seats." >&2
    exit 2
fi
echo "NDK seat: $NDK"

CC="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${API}-clang"
if [ ! -x "$CC" ]; then
    echo "BUILD HALT: compiler not found: $CC" >&2
    exit 2
fi

mkdir -p "$TOOLBOX/build"
"$CC" -O2 -Wall -Wextra -std=c11 -shared -fPIC \
    "$HERE/jni_knox_bridge.c" \
    -o "$TOOLBOX/build/libknoxbridge.so"
echo "Struck: $TOOLBOX/build/libknoxbridge.so"
file "$TOOLBOX/build/libknoxbridge.so" || true

# ============================================================================
# 93 — Live, Love, and let Love, Live.
# ============================================================================
