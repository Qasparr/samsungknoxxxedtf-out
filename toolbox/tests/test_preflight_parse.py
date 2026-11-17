#!/usr/bin/env python3
# =====================================================================
# TESTS — phone_node_preflight: the pure builders and parsers,
# fed fabricated response bytes, labelled here as samples. No
# socket is opened by any test in this file.
#
# XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
# (2026 e.v.) · 93
# Authorship attributed exclusively to Johnathan 'Qasparr' Monroe
# (Greek, -ARR, All Rights Reserved, Without Prejudice).
# =====================================================================

import base64
import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "..", "node-preflight"))
import phone_node_preflight as pf  # noqa: E402

# SAMPLE response head — fabricated for these tests, in the shape
# Python's http.server (the phone side's server) actually sends.
SAMPLE_HEAD = (b"HTTP/1.0 200 OK\r\n"
               b"Server: SimpleHTTP/0.6 Python/3.12.3\r\n"
               b"Content-Length: 106570907\r\n"
               b"Content-type: application/zip\r\n\r\n")


class TestBuilders(unittest.TestCase):
    def test_connect_request_shape(self):
        req = pf.build_connect_request("100.64.0.2", 8800, "QUJD")
        self.assertTrue(req.startswith(b"CONNECT 100.64.0.2:8800 "))
        self.assertIn(b"Proxy-Authorization: Basic QUJD\r\n", req)
        self.assertTrue(req.endswith(b"\r\n\r\n"))

    def test_proxy_auth_round_trip(self):
        auth = pf.proxy_auth_b64("http://user:pass@proxy.local:1234")
        self.assertEqual(base64.b64decode(auth), b"user:pass")

    def test_request_shape(self):
        req = pf.build_request("HEAD", "/file.zip", "100.64.0.2", 8800)
        self.assertTrue(req.startswith(b"HEAD /file.zip HTTP/1.1\r\n"))
        self.assertIn(b"Host: 100.64.0.2:8800\r\n", req)


class TestParsers(unittest.TestCase):
    def test_status_line(self):
        self.assertEqual(pf.parse_status_line(SAMPLE_HEAD), 200)

    def test_status_line_refuses_garbage(self):
        with self.assertRaises(ValueError):
            pf.parse_status_line(b"HTTP/0.9 garbled\r\n\r\n")

    def test_headers(self):
        h = pf.parse_headers(SAMPLE_HEAD)
        self.assertEqual(h["content-length"], "106570907")
        self.assertTrue(h["server"].startswith("SimpleHTTP"))

    def test_headers_keep_first_duplicate(self):
        head = b"HTTP/1.1 200 OK\r\nX-A: 1\r\nX-A: 2\r\n\r\n"
        self.assertEqual(pf.parse_headers(head)["x-a"], "1")

    def test_split_head_body(self):
        head, body = pf.split_head_body(SAMPLE_HEAD + b"PK\x03\x04")
        self.assertEqual(pf.parse_status_line(head), 200)
        self.assertEqual(body, b"PK\x03\x04")


if __name__ == "__main__":
    unittest.main()

# 93 — Live, Love, and let Love, Live.
