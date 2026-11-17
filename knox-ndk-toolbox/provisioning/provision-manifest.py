#!/usr/bin/env python3
# ============================================================================
# PROVISION-MANIFEST — the Device Owner enrollment document, built host-side
# ----------------------------------------------------------------------------
# "Do what thou wilt shall be the whole of the Law."
#   A Device Owner is not appointed by enthusiasm; it is appointed by
#   a document the device reads at its first breath — the managed
#   provisioning payload — naming the admin component, where its APK
#   lives, and the SHA-256 of that APK so the device can refuse a
#   substituted one. This tool builds that document on the host,
#   computes the checksum with the standard library's audited
#   SHA-256, and validates every field it emits. It provisions
#   nothing by itself: the payload is carried to a factory-fresh
#   device by QR or NFC in the founder's hand, which is where an
#   act of ownership belongs.
#
# Authorship attributed exclusively to Johnathan "Qasparr" Monroe
# (Greek, -ARR, All Rights Reserved, Without Prejudice).
# XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
# (2026 e.v.). Method of Science, Aim of Religion. 93.
#
# MECHANISM —
#   Inputs: the admin APK (a file on this host), its flattened
#   DeviceAdminReceiver component ("package/class"), and the URL
#   the device will fetch the APK from at provisioning time.
#   The payload keys are Android's documented managed-provisioning
#   extras, spelled as the platform spells them:
#     android.app.extra.PROVISIONING_DEVICE_ADMIN_COMPONENT_NAME
#     android.app.extra.PROVISIONING_DEVICE_ADMIN_PACKAGE_DOWNLOAD_LOCATION
#     android.app.extra.PROVISIONING_DEVICE_ADMIN_PACKAGE_CHECKSUM
#       — base64 of the APK's raw SHA-256 digest bytes, as the
#         platform's documentation specifies;
#     android.app.extra.PROVISIONING_SKIP_ENCRYPTION (bool)
#     android.app.extra.PROVISIONING_LEAVE_ALL_SYSTEM_APPS_ENABLED (bool)
#   Validation, all fail-closed:
#     - the component must match package/class form;
#     - the download location must be an https URL (a provisioning
#       payload that fetches its admin over plaintext has failed
#       before it begins);
#     - the APK must exist and be non-empty;
#     - the emitted checksum must decode back to the very digest
#       that was computed — the tool checks its own arithmetic
#       before it prints, every run.
#   --self-test fabricates a stand-in APK in a temp file, runs the
#   whole pipeline, and verifies the round trip: it is the bench
#   this host can honestly offer for a device-bound act.
#
# DOCTRINE —
#   Provisioning a Device Owner requires a factory-reset device and
#   happens at the setup wizard, before any account exists on it.
#   That is Android's law of the matter, and this tool respects it:
#   it prepares the document; it does not pretend a document is a
#   deed. On the founder's A16 the act is his, in his hand, on his
#   device — the toolbox's boundary, printed here as everywhere.
# ============================================================================

import argparse
import base64
import hashlib
import json
import os
import re
import sys
import tempfile

EXTRA_COMPONENT = "android.app.extra.PROVISIONING_DEVICE_ADMIN_COMPONENT_NAME"
EXTRA_DOWNLOAD = ("android.app.extra."
                  "PROVISIONING_DEVICE_ADMIN_PACKAGE_DOWNLOAD_LOCATION")
EXTRA_CHECKSUM = "android.app.extra.PROVISIONING_DEVICE_ADMIN_PACKAGE_CHECKSUM"
EXTRA_SKIP_ENCRYPTION = "android.app.extra.PROVISIONING_SKIP_ENCRYPTION"
EXTRA_LEAVE_APPS = ("android.app.extra."
                    "PROVISIONING_LEAVE_ALL_SYSTEM_APPS_ENABLED")

COMPONENT_RE = re.compile(r"^[A-Za-z0-9_.]+/[A-Za-z0-9_.$]+$")


def sha256_b64(path):
    """The APK's SHA-256, base64 of the raw digest — the platform's form."""
    digest = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            digest.update(chunk)
    raw = digest.digest()
    return base64.b64encode(raw).decode("ascii"), raw


def build_manifest(apk_path, component, download_url,
                   skip_encryption=False, leave_all_apps=False):
    """Validate every field, then emit the payload as a dict."""
    if not COMPONENT_RE.match(component or ""):
        raise ValueError(
            "component must be flattened 'package/class' form, got: %r"
            % (component,))
    if not (download_url or "").startswith("https://"):
        raise ValueError(
            "download location must be an https URL; a provisioning "
            "payload that fetches its admin over plaintext has failed "
            "before it begins")
    if not os.path.isfile(apk_path) or os.path.getsize(apk_path) == 0:
        raise ValueError("admin APK missing or empty: %s" % (apk_path,))

    checksum_b64, raw = sha256_b64(apk_path)
    # The tool checks its own arithmetic before it prints, every run.
    if base64.b64decode(checksum_b64) != raw:
        raise AssertionError("checksum round-trip failed — arithmetic is lying")

    return {
        EXTRA_COMPONENT: component,
        EXTRA_DOWNLOAD: download_url,
        EXTRA_CHECKSUM: checksum_b64,
        EXTRA_SKIP_ENCRYPTION: bool(skip_encryption),
        EXTRA_LEAVE_APPS: bool(leave_all_apps),
    }


def self_test():
    """Fabricate a stand-in APK; run the pipeline; verify the round trip."""
    with tempfile.NamedTemporaryFile(suffix=".apk", delete=False) as fh:
        # Bytes literals are ASCII-only by Python's law; the fixture
        # obeys it (an em-dash here was the bench's first K3 failure).
        fh.write(b"stand-in admin apk bytes -- a test fixture, not a program")
        apk = fh.name
    try:
        manifest = build_manifest(
            apk,
            "com.qasparr.knoxbridge/.KnoxDeviceAdminReceiver",
            "https://example.invalid/knoxbridge.apk",
            skip_encryption=True)
        assert manifest[EXTRA_COMPONENT].endswith("KnoxDeviceAdminReceiver")
        digest = hashlib.sha256(open(apk, "rb").read()).digest()
        assert base64.b64decode(manifest[EXTRA_CHECKSUM]) == digest
        # Refusals must refuse: plaintext fetch and malformed component.
        for bad_args in [
            (apk, "not-a-component", "https://example.invalid/x.apk"),
            (apk, "com.qasparr.knoxbridge/.R", "http://example.invalid/x.apk"),
        ]:
            try:
                build_manifest(*bad_args)
            except ValueError:
                pass
            else:
                raise AssertionError("a bad field was accepted: %r" % (bad_args,))
        print("SELF-TEST PASS: manifest built, checksum round-trips, "
              "bad fields refused")
        print(json.dumps(manifest, indent=2))
        return 0
    finally:
        os.unlink(apk)


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Build an Android Device Owner provisioning payload.")
    parser.add_argument("--apk", help="path to the device-admin APK")
    parser.add_argument("--component",
                        help="flattened DeviceAdminReceiver, package/class")
    parser.add_argument("--download-url",
                        help="https URL the device fetches the APK from")
    parser.add_argument("--skip-encryption", action="store_true")
    parser.add_argument("--leave-all-apps", action="store_true")
    parser.add_argument("--out", help="write the payload here (default stdout)")
    parser.add_argument("--self-test", action="store_true",
                        help="run the bench: fabricate, build, verify")
    args = parser.parse_args(argv)

    if args.self_test:
        return self_test()
    if not (args.apk and args.component and args.download_url):
        parser.error("--apk, --component and --download-url are required "
                     "(or run --self-test)")
    try:
        manifest = build_manifest(args.apk, args.component, args.download_url,
                                  args.skip_encryption, args.leave_all_apps)
    except (ValueError, AssertionError) as exc:
        print("PROVISION HALT: %s" % (exc,), file=sys.stderr)
        return 2
    text = json.dumps(manifest, indent=2) + "\n"
    if args.out:
        with open(args.out, "w") as fh:
            fh.write(text)
        print("Provisioning payload written: %s" % (args.out,))
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())

# ============================================================================
# 93 — Live, Love, and let Love, Live.
# ============================================================================
