#!/usr/bin/env bash
# ============================================================================
# RUN-TESTS — the Vulkan toolbox's bench, on this host
# ----------------------------------------------------------------------------
# "Do what thou wilt shall be the whole of the Law."
#   What can be proven here is proven here; what cannot is named
#   gated, in the open, with the gate's name on it. A test suite that
#   silently skips is a witness that silently leaves the stand.
#
# Authorship attributed exclusively to Johnathan "Qasparr" Monroe
# (Greek, -ARR, All Rights Reserved, Without Prejudice).
# XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
# (2026 e.v.). Method of Science, Aim of Religion. 93.
#
# THE BENCH — six tests:
#   T1  caps_probe.c compiles for aarch64 Android (NDK clang).
#   T2  dispatch_parallel_sum.c compiles for aarch64 Android.
#   T3  dispatch_fft.c compiles for aarch64 Android.
#   T4  both compute shaders compile to SPIR-V and validate
#       (SKIP, named COMPILER-GATED, only if no compiler seat exists).
#   T5  fetch-toolchain.sh --dry-run exits 0 and prints the maker's
#       URL — the road is readable without being driven.
#   T6  house law in the fetch script: no 64-hex hash is hardcoded
#       (a hash remembered is a hash that can rot), and every code
#       file in the toolbox carries the authorship line.
#   PASS / FAIL / SKIP are counted and printed. Exit is nonzero iff
#   FAIL > 0. Compilation products land in ../build (git-ignored).
# ============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TOOLBOX="$(cd "$HERE/.." && pwd)"
BUILD="$TOOLBOX/build"
mkdir -p "$BUILD"

PASS=0; FAIL=0; SKIP=0
report() { # $1 = id, $2 = PASS|FAIL|SKIP, $3 = note
    case "$2" in
        PASS) PASS=$((PASS+1)) ;;
        FAIL) FAIL=$((FAIL+1)) ;;
        SKIP) SKIP=$((SKIP+1)) ;;
    esac
    printf '%s  %-4s  %s\n' "$1" "$2" "$3"
}

# Find the same NDK seat build.sh searches (order kept in step).
NDK=""
for candidate in \
    "${ANDROID_NDK_HOME:-}" \
    "${VK_TOOLBOX_NDK:-}" \
    "$TOOLBOX/vendor/ndk/android-ndk-r30" \
    "$HOME/workspace/pqpe-ndk/ndk/android-ndk-r30" \
    ; do
    if [ -n "$candidate" ] && [ -d "$candidate/toolchains/llvm/prebuilt/linux-x86_64" ]; then
        NDK="$candidate"; break
    fi
done
API="${VK_API:-31}"
CC=""
[ -n "$NDK" ] && CC="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${API}-clang"

compile_test() { # $1 = id, $2 = source, $3 = extra libs
    local id="$1" src="$2" libs="${3:-}"
    if [ -z "$CC" ] || [ ! -x "$CC" ]; then
        report "$id" SKIP "NDK-GATED: no NDK clang seat found"
        return
    fi
    if "$CC" -O2 -Wall -Wextra -std=c11 -fsyntax-only "$src" 2>"$BUILD/$id.log" \
       && "$CC" -O2 -std=c11 "$src" $libs -o "$BUILD/$id.bin" 2>>"$BUILD/$id.log"; then
        report "$id" PASS "$src compiles and links for aarch64 Android API $API"
    else
        report "$id" FAIL "$src — see $BUILD/$id.log"
    fi
}

compile_test T1 "$TOOLBOX/caps-probe/caps_probe.c" "-lvulkan"
compile_test T2 "$TOOLBOX/compute/dispatch_parallel_sum.c" "-lvulkan"
compile_test T3 "$TOOLBOX/compute/dispatch_fft.c" "-lvulkan -lm"

# T4 — shaders.
if bash "$TOOLBOX/compute/compile-shaders.sh" >"$BUILD/T4.log" 2>&1; then
    if [ -s "$BUILD/parallel_sum.spv" ] && [ -s "$BUILD/fft_butterfly.spv" ]; then
        report T4 PASS "both shaders compiled to SPIR-V (see T4.log for the validator's word)"
    else
        report T4 FAIL "compile script exited 0 but a .spv is missing"
    fi
else
    rc=$?
    if [ "$rc" -eq 3 ]; then
        report T4 SKIP "COMPILER-GATED: no glslc/glslangValidator seat (see T4.log)"
    else
        report T4 FAIL "shader compilation failed — see $BUILD/T4.log"
    fi
fi

# T5 — the fetch road reads clean in dry-run.
if bash "$TOOLBOX/setup/fetch-toolchain.sh" --dry-run >"$BUILD/T5.log" 2>&1 \
   && grep -q "dl.google.com/android/repository" "$BUILD/T5.log"; then
    report T5 PASS "fetch-toolchain.sh --dry-run prints Google's URL and moves nothing"
else
    report T5 FAIL "fetch dry-run misbehaved — see $BUILD/T5.log"
fi

# T6 — house law: no hardcoded hash; the authorship line everywhere.
t6=1
if grep -Eq '\b[0-9a-f]{64}\b' "$TOOLBOX/setup/fetch-toolchain.sh"; then
    echo "  T6 detail: a 64-hex string stands in fetch-toolchain.sh" >&2
    t6=0
fi
while IFS= read -r f; do
    if ! grep -q "Authorship attributed exclusively" "$f"; then
        echo "  T6 detail: authorship line missing in $f" >&2
        t6=0
    fi
done <<EOF
$TOOLBOX/caps-probe/caps_probe.c
$TOOLBOX/caps-probe/build.sh
$TOOLBOX/compute/dispatch_parallel_sum.c
$TOOLBOX/compute/dispatch_fft.c
$TOOLBOX/compute/parallel_sum.comp
$TOOLBOX/compute/fft_butterfly.comp
$TOOLBOX/compute/compile-shaders.sh
$TOOLBOX/setup/fetch-toolchain.sh
EOF
if [ "$t6" -eq 1 ]; then
    report T6 PASS "no hardcoded hash in the fetch script; authorship line in every code file"
else
    report T6 FAIL "house law breached — see details above"
fi

echo "----------------------------------------------------------------"
echo "VULKAN TOOLBOX BENCH: PASS=$PASS FAIL=$FAIL SKIP=$SKIP"
[ "$FAIL" -eq 0 ]

# ============================================================================
# 93 — Live, Love, and let Love, Live.
# ============================================================================
