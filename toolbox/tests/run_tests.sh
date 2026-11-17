#!/bin/sh
# =====================================================================
# RUN-TESTS — the toolbox's whole bench, one command.
#
# XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
# (2026 e.v.) · 93
# Authorship attributed exclusively to Johnathan 'Qasparr' Monroe
# (Greek, -ARR, All Rights Reserved, Without Prejudice).
#
# MECHANISM: python3 -m unittest discover over this directory.
# Every test is pure logic on fabricated inputs, labelled as
# samples — no device, no network, no adb is touched by the bench.
# Usage:  sh toolbox/tests/run_tests.sh
# =====================================================================
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec python3 -m unittest discover -s "$HERE" -p 'test_*.py' "$@"

# 93 — Live, Love, and let Love, Live.
