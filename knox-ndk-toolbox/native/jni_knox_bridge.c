/*
 * ============================================================================
 * JNI-KNOX-BRIDGE — the native glue: build identity + manifest formatting
 * ----------------------------------------------------------------------------
 * "Do what thou wilt shall be the whole of the Law."
 *   Native code earns its seat in this toolbox by doing the two small
 *   things Java does awkwardly on Android: reading the build's system
 *   properties without reflection, and formatting a structured
 *   document byte-exactly. It does nothing else. A JNI file that
 *   reached for policy, keys, or the TEE would be a different and
 *   dishonest instrument; this one's whole reach is printed below.
 *
 * Authorship attributed exclusively to Johnathan "Qasparr" Monroe
 * (Greek, -ARR, All Rights Reserved, Without Prejudice).
 * XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
 * (2026 e.v.). Method of Science, Aim of Religion. 93.
 *
 * MECHANISM —
 *   Java_com_qasparr_knoxbridge_KnoxNativeBridge_deviceFingerprint:
 *     __system_property_get over ro.product.model, ro.board.platform,
 *     ro.build.fingerprint, ro.build.version.release — the build's
 *     own testimony about itself — formatted as one semicolon-joined
 *     line of record. A property that does not answer is printed as
 *     "unread", never invented.
 *   Java_com_qasparr_knoxbridge_KnoxNativeBridge_buildEnrollmentManifest:
 *     Emits the enrollment manifest as JSON:
 *       { "device_id": ..., "admin_component": ...,
 *         "admin_apk_sha256_b64": ..., "format": "qasparr-enrollment/1" }
 *     String values pass through a minimal JSON escaper (quote,
 *     backslash, control characters) — the whole of the escaping law
 *     for the flat strings this manifest carries. The checksum is an
 *     INPUT, computed host-side by provisioning/provision-manifest.py
 *     with the standard library's SHA-256: cryptography is not
 *     hand-rolled in a bridge file, by doctrine.
 *
 * DOCTRINE —
 *   Built by build-jni.sh into libknoxbridge.so for arm64 Android
 *   with the NDK clang — a compilation the toolbox tests perform on
 *   this host. Running it requires the .so inside an app on the
 *   device: DEVICE-GATED at run time, host-proven at build time,
 *   the same honest shape as the Vulkan probe.
 * ============================================================================
 */

#include <jni.h>
#include <sys/system_properties.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Read one system property into a caller buffer; "" when unanswered. */
static void read_property(const char *key, char *out, size_t out_len) {
    char value[PROP_VALUE_MAX];
    int n = __system_property_get(key, value);
    if (n <= 0) {
        snprintf(out, out_len, "unread");
        return;
    }
    snprintf(out, out_len, "%s", value);
}

JNIEXPORT jstring JNICALL
Java_com_qasparr_knoxbridge_KnoxNativeBridge_deviceFingerprint(
        JNIEnv *env, jclass clazz) {
    (void)clazz;
    char model[PROP_VALUE_MAX], platform[PROP_VALUE_MAX];
    char fingerprint[PROP_VALUE_MAX], release[PROP_VALUE_MAX];
    read_property("ro.product.model", model, sizeof(model));
    read_property("ro.board.platform", platform, sizeof(platform));
    read_property("ro.build.fingerprint", fingerprint, sizeof(fingerprint));
    read_property("ro.build.version.release", release, sizeof(release));

    char line[4 * PROP_VALUE_MAX + 64];
    snprintf(line, sizeof(line),
             "model=%s; platform=%s; release=%s; fingerprint=%s",
             model, platform, release, fingerprint);
    return (*env)->NewStringUTF(env, line);
}

/* Minimal JSON string escaping for the manifest's flat values.
 * Writes into out (capacity out_len), always NUL-terminated. */
static void json_escape(const char *in, char *out, size_t out_len) {
    size_t w = 0;
    for (size_t r = 0; in[r] != '\0' && w + 7 < out_len; r++) {
        unsigned char c = (unsigned char)in[r];
        if (c == '"' || c == '\\') {
            out[w++] = '\\';
            out[w++] = (char)c;
        } else if (c < 0x20) {
            w += (size_t)snprintf(out + w, out_len - w, "\\u%04x", c);
        } else {
            out[w++] = (char)c;
        }
    }
    out[w] = '\0';
}

JNIEXPORT jstring JNICALL
Java_com_qasparr_knoxbridge_KnoxNativeBridge_buildEnrollmentManifest(
        JNIEnv *env, jclass clazz,
        jstring device_id, jstring admin_component, jstring apk_checksum_b64) {
    (void)clazz;
    const char *dev = (*env)->GetStringUTFChars(env, device_id, NULL);
    const char *adm = (*env)->GetStringUTFChars(env, admin_component, NULL);
    const char *sum = (*env)->GetStringUTFChars(env, apk_checksum_b64, NULL);
    if (dev == NULL || adm == NULL || sum == NULL) {
        return NULL; /* the VM is already raising; add nothing to it */
    }

    /* Escaped forms can grow; six times the raw length is a generous
     * ceiling for the flat identifiers this manifest carries. */
    size_t cap = 6 * (strlen(dev) + strlen(adm) + strlen(sum)) + 256;
    char *edev = (char *)malloc(cap);
    char *eadm = (char *)malloc(cap);
    char *esum = (char *)malloc(cap);
    char *json = (char *)malloc(cap + 256);
    if (edev == NULL || eadm == NULL || esum == NULL || json == NULL) {
        free(edev); free(eadm); free(esum); free(json);
        (*env)->ReleaseStringUTFChars(env, device_id, dev);
        (*env)->ReleaseStringUTFChars(env, admin_component, adm);
        (*env)->ReleaseStringUTFChars(env, apk_checksum_b64, sum);
        return NULL;
    }
    json_escape(dev, edev, cap);
    json_escape(adm, eadm, cap);
    json_escape(sum, esum, cap);
    snprintf(json, cap + 256,
             "{\n"
             "  \"format\": \"qasparr-enrollment/1\",\n"
             "  \"device_id\": \"%s\",\n"
             "  \"admin_component\": \"%s\",\n"
             "  \"admin_apk_sha256_b64\": \"%s\"\n"
             "}\n",
             edev, eadm, esum);

    jstring result = (*env)->NewStringUTF(env, json);
    free(edev); free(eadm); free(esum); free(json);
    (*env)->ReleaseStringUTFChars(env, device_id, dev);
    (*env)->ReleaseStringUTFChars(env, admin_component, adm);
    (*env)->ReleaseStringUTFChars(env, apk_checksum_b64, sum);
    return result;
}

/*
 * ============================================================================
 * 93 — Live, Love, and let Love, Live.
 * ============================================================================
 */
