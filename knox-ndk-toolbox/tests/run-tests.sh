#!/usr/bin/env bash
# ============================================================================
# KNOX TOOLBOX TESTS — what this host can honestly prove
# ----------------------------------------------------------------------------
# "Do what thou wilt shall be the whole of the Law."
#   The Knox bench proves three kinds of thing: the platform room
#   compiles (Android's own APIs, against the platform's own jar);
#   the native glue strikes for the device's architecture; and the
#   gates behave as gates — the seat verifier, asked about an
#   unfilled seat, must answer ACCOUNT-GATED with exit 3, and that
#   answer is a PASS here, because a gate that lies is worse than a
#   gate that stands. What no bench on this host can prove — the
#   Knox room against Samsung's real JAR, an attestation round trip,
#   a provisioning on a living device — is not faked; it is named in
#   the README as account-gated and device-gated, at full size.
#
# Authorship attributed exclusively to Johnathan "Qasparr" Monroe
# (Greek, -ARR, All Rights Reserved, Without Prejudice).
# XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
# (2026 e.v.). Method of Science, Aim of Religion. 93.
#
# MECHANISM —
#   K1 platform wrappers compile (javac + android.jar, real compile)
#   K2 the JNI glue strikes libknoxbridge.so for aarch64
#   K3 the provisioning manifest self-test (round trip + refusals)
#   K4 the seat gate: verify-seat.sh on the unfilled seat answers
#      ACCOUNT-GATED, exit 3 — counted PASS, gate working as designed
#   K5 build-wrappers.sh completes: platform room green, Knox room
#      gated in print (or compiled, if the seat has been filled)
#   K6 house form: every code file in the toolbox carries the
#      authorship line and the closing motto
#   Verdict lines print PASS/FAIL/GATED per test and a final count.
# ============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TOOLBOX="$(cd "$HERE/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0; GATED=0
verdict() {  # verdict <PASS|FAIL|GATED> <label> <note>
    echo "[$1] $2 — $3"
    case "$1" in
        PASS) PASS=$((PASS+1)) ;;
        FAIL) FAIL=$((FAIL+1)) ;;
        GATED) GATED=$((GATED+1)) ;;
    esac
}

# --- K1: the platform room compiles. --------------------------------------
if bash "$TOOLBOX/wrappers/build-wrappers.sh" >"$WORK/k1.log" 2>&1 \
   && [ -f "$TOOLBOX/build/classes-platform/com/qasparr/knoxbridge/PlatformPolicyReader.class" ]; then
    verdict PASS "K1 platform wrappers" "javac against android.jar"
else
    verdict FAIL "K1 platform wrappers" "see log:"; cat "$WORK/k1.log"
fi

# --- K2: the native glue strikes for aarch64. ------------------------------
if bash "$TOOLBOX/native/build-jni.sh" >"$WORK/k2.log" 2>&1 \
   && file "$TOOLBOX/build/libknoxbridge.so" 2>/dev/null | grep -q "aarch64"; then
    verdict PASS "K2 JNI glue" "libknoxbridge.so struck for aarch64"
else
    verdict FAIL "K2 JNI glue" "see log:"; cat "$WORK/k2.log"
fi

# --- K3: the provisioning manifest round-trips. ----------------------------
if python3 "$TOOLBOX/provisioning/provision-manifest.py" --self-test \
        >"$WORK/k3.log" 2>&1; then
    verdict PASS "K3 provisioning manifest" "checksum round trip + refusals"
else
    verdict FAIL "K3 provisioning manifest" "see log:"; cat "$WORK/k3.log"
fi

# --- K4: the seat gate answers as a gate. ----------------------------------
SEAT_OUT="$(bash "$TOOLBOX/sdk-seat/verify-seat.sh" 2>&1)"
SEAT_RC=$?
if [ "$SEAT_RC" -eq 0 ]; then
    verdict PASS "K4 seat verifier" "seat filled and whole — the gate stands open by right"
elif [ "$SEAT_RC" -eq 3 ] && echo "$SEAT_OUT" | grep -q "GATED\|INCOMPLETE"; then
    verdict PASS "K4 seat verifier" "gate answered as a gate (exit 3, named)"
else
    verdict FAIL "K4 seat verifier" "exit $SEAT_RC, first line: $(echo "$SEAT_OUT" | head -1)"
fi

# --- K5: build-wrappers reports the Knox room honestly. --------------------
if grep -q "ACCOUNT-GATED\|Compiled: the Knox room" "$WORK/k1.log"; then
    verdict PASS "K5 Knox room report" "gated in print, or compiled against the seat"
else
    verdict FAIL "K5 Knox room report" "the Knox room's state was not named"
fi

# --- K6: house form across the toolbox. ------------------------------------
MISSING=0
while IFS= read -r f; do
    if ! grep -q "Qasparr" "$f" || ! grep -q "Live, Love, and let Love, Live" "$f"; then
        echo "  house form missing in: $f"
        MISSING=$((MISSING+1))
    fi
done <<EOF
$(find "$TOOLBOX" -type f \( -name '*.java' -o -name '*.c' -o -name '*.py' -o -name '*.sh' \) ! -path '*/build/*' ! -path '*/vendor/*')
EOF
if [ "$MISSING" -eq 0 ]; then
    verdict PASS "K6 house form" "authorship line + closing motto in every code file"
else
    verdict FAIL "K6 house form" "$MISSING file(s) lack the house form"
fi

echo "----------------------------------------------------------------"
echo "KNOX TOOLBOX BENCH: PASS=$PASS FAIL=$FAIL GATED=$GATED"
echo "Device-gated remainder (named, not smoothed): the Knox room"
echo "against Samsung's real JAR; a live attestation round trip; a"
echo "Device Owner provisioning on the founder's A16. The gates are"
echo "the Knox Partner Program (account) and the device itself."
[ "$FAIL" -eq 0 ]

# ============================================================================
# 93 — Live, Love, and let Love, Live.
# ============================================================================
