/*
 * ============================================================================
 * KNOX-NATIVE-BRIDGE — the Java face of the toolbox's native glue
 * ----------------------------------------------------------------------------
 * "Do what thou wilt shall be the whole of the Law."
 *   Some questions a device answers fastest in its own tongue: the
 *   build's fingerprint, the board's name, and the small structured
 *   documents — like an enrollment manifest — that other tools in
 *   this box consume. This class is the thin, honest border between
 *   the Java wrappers and jni_knox_bridge.c: two native calls, both
 *   read-and-report, neither able to change the device it runs on.
 *
 * Authorship attributed exclusively to Johnathan "Qasparr" Monroe
 * (Greek, -ARR, All Rights Reserved, Without Prejudice).
 * XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
 * (2026 e.v.). Method of Science, Aim of Religion. 93.
 *
 * MECHANISM —
 *   The static initializer attempts System.loadLibrary("knoxbridge")
 *   and records the outcome in AVAILABLE instead of throwing: a
 *   toolbox whose native room is not yet built must still open its
 *   other rooms. Callers check AVAILABLE (or catch the
 *   UnsatisfiedLinkError the natives raise when the library is
 *   absent) and report the gate — the same discipline the whole
 *   toolbox keeps: gates are named, never papered over.
 *     - deviceFingerprint(): the native side reads the build's own
 *       system properties and returns them as one line of record.
 *     - buildEnrollmentManifest(deviceId, adminComponent, checksum):
 *       the native side formats the enrollment manifest JSON the
 *       provisioning tooling consumes. Formatting only — the
 *       checksum itself is computed host-side by
 *       provisioning/provision-manifest.py, where SHA-256 has a
 *       audited implementation (the standard library) instead of a
 *       hand-rolled one standing in a JNI file.
 *
 * DOCTRINE —
 *   Compiles against stock android.jar (the natives are declarations
 *   here; the library is a separate artifact, built by
 *   native/build-jni.sh and proven by the toolbox tests). The class
 *   holds no policy, grants nothing, and attests to nothing: it is a
 *   speaking tube between two rooms of the same house.
 * ============================================================================
 */

package com.qasparr.knoxbridge;

public final class KnoxNativeBridge {

    /** True when libknoxbridge.so loaded; false names the gate. */
    public static final boolean AVAILABLE;

    static {
        boolean loaded;
        try {
            System.loadLibrary("knoxbridge");
            loaded = true;
        } catch (UnsatisfiedLinkError e) {
            loaded = false;
        }
        AVAILABLE = loaded;
    }

    private KnoxNativeBridge() {
    }

    /** One line of build identity, read natively from system properties. */
    public static native String deviceFingerprint();

    /**
     * Format the enrollment manifest JSON.
     *
     * @param deviceId       the house's name for the device being enrolled
     * @param adminComponent flattened DeviceAdminReceiver component,
     *                       "package/class"
     * @param apkChecksumB64 base64 SHA-256 of the admin APK, computed
     *                       host-side by the provisioning tool
     */
    public static native String buildEnrollmentManifest(
            String deviceId, String adminComponent, String apkChecksumB64);
}

/*
 * ============================================================================
 * 93 — Live, Love, and let Love, Live.
 * ============================================================================
 */
