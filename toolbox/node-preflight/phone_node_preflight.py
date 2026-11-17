#!/usr/bin/env python3
# =====================================================================
# PHONE-NODE PREFLIGHT — prove the phone node is awake, bound, and
# reachable BEFORE a long transfer trusts it
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
# Adapted from the desk's standing helpers (enclave-desktop/
# tailnet_fetch.py and tailnet_head.py) — same transport, one
# instrument: an explicit HTTP CONNECT through the tunnel proxy
# (credentials read from HTTPS_PROXY at run time, in this same
# invocation — the proxy credential rotates between shells, so a
# config written by an older shell 407s), then inside the tunnel a
# HEAD probe of the file the transfer will carry, and optionally a
# full fetch of a small object whose size and SHA-256 are compared
# against the expected values.
#
# Why explicit CONNECT and not a plain proxy-GET: the plain form
# returns empty/garbled answers even from a healthy node — a
# known-closed port and a live port present IDENTICALLY under it,
# so it can diagnose nothing. The CONNECT form is the probe that
# tells the truth. (House law, learned 2026-11-10.)
#
# DOCTRINE — the preflight law (the house skill of the same name)
# ---------------------------------------------------------------
# * A fetch that dies idle and passes awake is a SLEEP failure,
#   not a tunnel ceiling and not a broken file. This script cannot
#   wake the phone; it reports which state it found, and the
#   founder keeps the unit awake (charger in) for the transfer.
# * No long transfer starts on a node that has not passed an
#   AWAKE fetch. This script is that fetch, made repeatable.
# * Report only what the checks proved: reachable / server-up /
#   content-length / hash — each stated, none inflated.
# * Nothing here phones home: the only bytes move between this
#   host and the founder's own phone, over his own tailnet.
#
# Usage:
#   python3 phone_node_preflight.py <phone-ip> <port> <path>
#       [--fetch-object <path> --expect-size N --expect-sha256 HEX]
# Exit: 0 all checks passed · 1 a check failed · 2 usage/transport
#
# 93 — Live, Love, and let Love, Live.
# =====================================================================

from __future__ import annotations

import argparse
import base64
import hashlib
import os
import socket
import sys
import time
from urllib.parse import urlparse

PROXY_PORT = 3130   # the tunnel proxy's port, as the house helpers use it


# ---------------------------------------------------------------------
# Pure builders and parsers — the tests feed these fabricated bytes,
# labelled as samples. No sockets live in this section.
# ---------------------------------------------------------------------

def proxy_auth_b64(proxy_url: str) -> str:
    """MECHANISM: the CONNECT credentials ride in a
    Proxy-Authorization header, Basic-encoded from the proxy URL's
    userinfo — read from the environment at run time, never stored."""
    p = urlparse(proxy_url)
    return base64.b64encode(f"{p.username}:{p.password}".encode()).decode()


def build_connect_request(host: str, port: int, auth_b64: str) -> bytes:
    return (f"CONNECT {host}:{port} HTTP/1.1\r\n"
            f"Host: {host}:{port}\r\n"
            f"Proxy-Authorization: Basic {auth_b64}\r\n\r\n").encode()


def build_request(method: str, path: str, host: str, port: int) -> bytes:
    return (f"{method} {path} HTTP/1.1\r\n"
            f"Host: {host}:{port}\r\n"
            f"Connection: close\r\n\r\n").encode()


def parse_status_line(head: bytes) -> int:
    """MECHANISM: the first line of an HTTP response head is
    'HTTP/1.x NNN ...'. Return NNN as an int; a head that does not
    carry the shape raises — a garbled answer is a finding, not a
    number to guess at."""
    first = head.split(b"\r\n", 1)[0].decode(errors="replace")
    parts = first.split(" ")
    if len(parts) < 2 or not parts[0].startswith("HTTP/"):
        raise ValueError(f"unrecognised response head: {first!r}")
    return int(parts[1])


def parse_headers(head: bytes) -> dict:
    """MECHANISM: 'Name: value' lines after the status line, keys
    lower-cased. Duplicate names keep the first value — the probes
    read Server and Content-Length, which a simple server sends
    once."""
    headers = {}
    for line in head.split(b"\r\n")[1:]:
        if b":" not in line:
            continue
        name, _, value = line.partition(b":")
        key = name.decode(errors="replace").strip().lower()
        if key and key not in headers:
            headers[key] = value.decode(errors="replace").strip()
    return headers


def split_head_body(buf: bytes):
    head, _, body = buf.partition(b"\r\n\r\n")
    return head, body


# ---------------------------------------------------------------------
# The transport — the house helpers' CONNECT pattern, kept whole.
# ---------------------------------------------------------------------

class Tunnel:
    def __init__(self, proxy_url: str, host: str, port: int, timeout=30):
        p = urlparse(proxy_url)
        self._sock = socket.create_connection((p.hostname, PROXY_PORT),
                                              timeout=timeout)
        auth = proxy_auth_b64(proxy_url)
        self._sock.sendall(build_connect_request(host, port, auth))
        resp = b""
        while b"\r\n\r\n" not in resp:
            chunk = self._sock.recv(4096)
            if not chunk:
                raise RuntimeError("CONNECT closed early — the node "
                                   "did not answer the tunnel")
            resp += chunk
        status = resp.split(b"\r\n")[0].decode(errors="replace")
        if "200" not in status:
            raise RuntimeError(f"CONNECT refused: {status}")

    def request(self, method: str, path: str, host: str, port: int,
                read_body: bool):
        self._sock.sendall(build_request(method, path, host, port))
        self._sock.settimeout(60)
        buf = b""
        while b"\r\n\r\n" not in buf:
            chunk = self._sock.recv(65536)
            if not chunk:
                raise RuntimeError("closed before headers — the "
                                   "server did not answer")
            buf += chunk
        head, body = split_head_body(buf)
        if read_body:
            chunks = [body]
            while True:
                try:
                    chunk = self._sock.recv(65536)
                except socket.timeout:
                    break
                if not chunk:
                    break
                chunks.append(chunk)
            body = b"".join(chunks)
        return head, body

    def close(self):
        try:
            self._sock.close()
        except Exception:
            pass


# ---------------------------------------------------------------------
# The preflight itself — checks stated, verdicts no larger.
# ---------------------------------------------------------------------

def run_preflight(ip: str, port: int, path: str,
                  fetch_object: str = None,
                  expect_size: int = None,
                  expect_sha256: str = None) -> int:
    proxy = os.environ.get("HTTPS_PROXY")
    if not proxy:
        print("FAIL  HTTPS_PROXY is not set — the tunnel proxy is "
              "this road's only door, and its credential must come "
              "from this invocation's environment.")
        return 2

    print(f"preflight: {ip}:{port}{path}")
    started = time.monotonic()
    try:
        tunnel = Tunnel(proxy, ip, port)
    except Exception as e:
        print(f"FAIL  CONNECT: {e}")
        print("      reading: the node is unreachable or asleep. A "
              "probe that dies idle and passes awake is a SLEEP "
              "failure — wake the unit, charger in, and strike again.")
        return 1
    print("PASS  CONNECT — the tunnel opened and the node answered")

    try:
        head, _ = tunnel.request("HEAD", path, ip, port, read_body=False)
        status = parse_status_line(head)
        headers = parse_headers(head)
    except Exception as e:
        print(f"FAIL  HEAD: {e}")
        tunnel.close()
        return 1
    if status != 200:
        print(f"FAIL  HEAD {path}: HTTP {status}")
        tunnel.close()
        return 1
    print(f"PASS  HEAD {path}: HTTP 200")
    server = headers.get("server", "unknown")
    print(f"      server: {server}")
    if "content-length" in headers:
        print(f"      content-length: {headers['content-length']}")
    else:
        print("      content-length: not stated by the server")

    if fetch_object:
        try:
            _, body = tunnel.request("GET", fetch_object, ip, port,
                                     read_body=True)
        except Exception as e:
            print(f"FAIL  GET {fetch_object}: {e}")
            tunnel.close()
            return 1
        size = len(body)
        digest = hashlib.sha256(body).hexdigest()
        ok = True
        if expect_size is not None and size != expect_size:
            print(f"FAIL  size: got {size}, expected {expect_size}")
            ok = False
        if expect_sha256 is not None and digest != expect_sha256.lower():
            print(f"FAIL  sha256: got {digest}, expected {expect_sha256}")
            ok = False
        if ok:
            print(f"PASS  GET {fetch_object}: {size} bytes, "
                  f"sha256 {digest[:16]}… verified")
        else:
            tunnel.close()
            return 1

    tunnel.close()
    elapsed = time.monotonic() - started
    print(f"preflight complete in {elapsed:.1f}s — the node passed "
          "awake, as far as these checks reach. A long transfer "
          "still wants the unit awake and charging for its whole run.")
    return 0


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(
        description="Preflight a phone-served node over the tailnet.")
    ap.add_argument("ip")
    ap.add_argument("port", type=int)
    ap.add_argument("path")
    ap.add_argument("--fetch-object")
    ap.add_argument("--expect-size", type=int)
    ap.add_argument("--expect-sha256")
    args = ap.parse_args(argv)
    return run_preflight(args.ip, args.port, args.path,
                         args.fetch_object, args.expect_size,
                         args.expect_sha256)


if __name__ == "__main__":
    sys.exit(main())

# 93 — Live, Love, and let Love, Live.
