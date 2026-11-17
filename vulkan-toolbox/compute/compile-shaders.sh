#!/usr/bin/env bash
# ============================================================================
# COMPILE-SHADERS — GLSL in, SPIR-V out, validated before it is believed
# ----------------------------------------------------------------------------
# "Do what thou wilt shall be the whole of the Law."
#   A shader that has not been compiled is a poem about a program.
#   This script compiles the toolbox's two compute shaders and runs
#   the SPIR-V validator over the result, because the house does not
#   ship poems in the program's seat.
#
# Authorship attributed exclusively to Johnathan "Qasparr" Monroe
# (Greek, -ARR, All Rights Reserved, Without Prejudice).
# XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
# (2026 e.v.). Method of Science, Aim of Religion. 93.
#
# MECHANISM — the compiler search, in printed order:
#   1. $GLSLC — the operator's explicit seat;
#   2. glslc on PATH;
#   3. the NDK's bundled shader-tools (glslc ships INSIDE the NDK —
#      shader-tools/linux-x86_64/glslc — in every NDK seat the
#      toolbox knows: $ANDROID_NDK_HOME, $VK_TOOLBOX_NDK, the fetched
#      ../vendor/ndk seat, the house PQPE seat);
#   4. glslangValidator on PATH, or $GLSLANGVALIDATOR.
#   The seat that answers is printed. If none answers, the script
#   exits 3 with the gate named — COMPILER-GATED — and compiles
#   nothing. A silent skip would be a lie by omission; an exit code
#   and a named gate are the truth in machine-readable form.
#   spirv-val, when found beside the compiler, validates both
#   products; its absence is reported, not hidden.
#
# Output: ../build/parallel_sum.spv and ../build/fft_butterfly.spv,
# the exact file names the dispatch programs take as their defaults.
# ============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TOOLBOX="$(cd "$HERE/.." && pwd)"
BUILD="$TOOLBOX/build"
mkdir -p "$BUILD"

find_in_ndk_seats() {
    # $1 = tool path suffix inside an NDK root; echoes the first hit.
    local suffix="$1" candidate
    for candidate in \
        "${ANDROID_NDK_HOME:-}" \
        "${VK_TOOLBOX_NDK:-}" \
        "$TOOLBOX/vendor/ndk/android-ndk-r30" \
        "$HOME/workspace/pqpe-ndk/ndk/android-ndk-r30" \
        ; do
        if [ -n "$candidate" ] && [ -x "$candidate/$suffix" ]; then
            echo "$candidate/$suffix"
            return 0
        fi
    done
    return 1
}

COMPILER=""
KIND=""
if [ -n "${GLSLC:-}" ] && [ -x "${GLSLC:-}" ]; then
    COMPILER="$GLSLC"; KIND="glslc"
elif command -v glslc >/dev/null 2>&1; then
    COMPILER="$(command -v glslc)"; KIND="glslc"
elif found="$(find_in_ndk_seats "shader-tools/linux-x86_64/glslc")"; then
    COMPILER="$found"; KIND="glslc (NDK shader-tools)"
elif [ -n "${GLSLANGVALIDATOR:-}" ] && [ -x "${GLSLANGVALIDATOR:-}" ]; then
    COMPILER="$GLSLANGVALIDATOR"; KIND="glslangValidator"
elif command -v glslangValidator >/dev/null 2>&1; then
    COMPILER="$(command -v glslangValidator)"; KIND="glslangValidator"
fi

if [ -z "$COMPILER" ]; then
    echo "COMPILER-GATED: no GLSL->SPIR-V compiler found in any seat." >&2
    echo "  The shaders stand as sources. To compile them, provide one of:" >&2
    echo "    - an Android NDK (its shader-tools carry glslc) — see" >&2
    echo "      ../setup/fetch-toolchain.sh for the fetch road;" >&2
    echo "    - glslc or glslangValidator on PATH, or \$GLSLC set." >&2
    exit 3
fi
echo "Shader compiler: $COMPILER ($KIND)"

# --- compile -----------------------------------------------------------
# glslc and glslangValidator spell this differently; both are driven
# explicitly so the record shows which tongue was spoken.
compile_one() {
    local src="$1" out="$2"
    if [ "$KIND" = "glslangValidator" ]; then
        "$COMPILER" -V "$src" -o "$out"
    else
        "$COMPILER" -O -o "$out" "$src"
    fi
    echo "Compiled: $src -> $out"
}

compile_one "$HERE/parallel_sum.comp"  "$BUILD/parallel_sum.spv"
compile_one "$HERE/fft_butterfly.comp" "$BUILD/fft_butterfly.spv"

# --- validate ----------------------------------------------------------
VALIDATOR=""
if [ -x "$(dirname "$COMPILER")/spirv-val" ]; then
    VALIDATOR="$(dirname "$COMPILER")/spirv-val"
elif command -v spirv-val >/dev/null 2>&1; then
    VALIDATOR="$(command -v spirv-val)"
fi
if [ -n "$VALIDATOR" ]; then
    "$VALIDATOR" "$BUILD/parallel_sum.spv"
    "$VALIDATOR" "$BUILD/fft_butterfly.spv"
    echo "Validated: both SPIR-V modules pass spirv-val ($VALIDATOR)"
else
    echo "NOTE: spirv-val not found; compilation stands, validation unrun."
fi

# ============================================================================
# 93 — Live, Love, and let Love, Live.
# ============================================================================
