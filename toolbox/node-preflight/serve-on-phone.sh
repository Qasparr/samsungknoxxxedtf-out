#!/bin/sh
# =====================================================================
# SERVE-ON-PHONE — start the phone's file server the way the
# tailnet can actually reach it (Termux side)
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
# Serves ~/storage/downloads on port 8800 with Python's http.server
# bound to 0.0.0.0. Two phone-side facts govern, learned the hard
# way (2026-11-10) and printed here so they are never relearned:
#   * http.server on Termux binds IPv6-only by default — without
#     --bind 0.0.0.0 the tailnet cannot reach it at all.
#   * Termux shared storage needs termux-setup-storage run once;
#     without it ~/storage/downloads does not exist and a chained
#     cd fails in silence. This script checks and says so.
#
# DOCTRINE
# --------
# The server serves the founder's own files to the founder's own
# desk over his own tailnet — nothing else, no one else. Keep the
# unit awake and charging for the whole serve: a sleeping phone is
# a closed door, and the preflight (phone_node_preflight.py) is
# struck from the desk before any long pull trusts the node.
#
# Usage:  sh serve-on-phone.sh
# Stop:   Ctrl-C in the Termux session.
#
# 93 — Live, Love, and let Love, Live.
# =====================================================================

set -u

if [ ! -d "$HOME/storage/downloads" ]; then
    echo "shared storage is not set up: ~/storage/downloads is absent."
    echo "run once:  termux-setup-storage"
    echo "then strike this script again."
    exit 69
fi

cd "$HOME/storage/downloads" || {
    echo "cannot enter ~/storage/downloads" >&2; exit 69; }

echo "serving $PWD on port 8800 (bind 0.0.0.0) — keep the unit"
echo "awake and charging; Ctrl-C stops the serve."
echo "tailnet addresses as this unit sees them:"
ip -o addr show 2>/dev/null | awk '{print "  " $2 " " $4}' || true
command -v tailscale >/dev/null 2>&1 && tailscale ip 2>/dev/null | sed 's/^/  tailscale: /' || true

exec python3 -m http.server 8800 --bind 0.0.0.0

# 93 — Live, Love, and let Love, Live.
