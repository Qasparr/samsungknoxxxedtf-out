/*
 * ============================================================================
 * KNOX-ATTESTATION-READER — Samsung's testimony, requested as published
 * ----------------------------------------------------------------------------
 * "Do what thou wilt shall be the whole of the Law."
 *   Knox attestation is the device, through its TrustZone, signing
 *   measurements of its own boot — bootloader, kernel, the works —
 *   under a key derived from the hardware Device Root Key, against
 *   a nonce the verifier chose, so the testimony is fresh and the
 *   signature's chain ends at Samsung. This reader makes that
 *   request through Samsung's documented classes and reports what
 *   was asked and what answered. It does not grade the blob: the
 *   verdict belongs to Samsung's Attestation Server (or the
 *   founder's on-prem verifier), exactly as with the platform path.
 *
 * Authorship attributed exclusively to Johnathan "Qasparr" Monroe
 * (Greek, -ARR, All Rights Reserved, Without Prejudice).
 * XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
 * (2026 e.v.). Method of Science, Aim of Religion. 93.
 *
 * MECHANISM — two roads, because Samsung keeps two:
 *   THE LEGACY ROAD (Knox <= 3.3; the class is deprecated since Knox
 *   API level 33, and the deprecation is Samsung's, printed here as
 *   Samsung printed it): com.samsung.android.knox.integrity.
 *   AttestationPolicy, constructed with the Context;
 *   startAttestation(nonce) where the nonce is a 32-byte value as a
 *   HEX string (64 hex characters — any other shape is refused by
 *   the service with ERROR_INVALID_NONCE); the caller must hold
 *   com.samsung.android.knox.permission.KNOX_REMOTE_ATTESTATION;
 *   the blob returns by the broadcast action
 *   com.samsung.android.knox.intent.action.KNOX_ATTESTATION_RESULT.
 *   startLegacyAttestation() validates the nonce's shape before
 *   asking, because a malformed nonce deserves a local refusal with
 *   a reason, not a round trip to a silent service.
 *
 *   THE ENHANCED ROAD (Knox 3.4+, API level 29+; the road a current
 *   device walks): EnterpriseKnoxManager.getInstance(context)
 *   .getEnhancedAttestationPolicy(), then either
 *   startAttestation(auk, nonce, callback) — Samsung Attestation
 *   Server, where auk is the Attestation Unique Key issued per
 *   vendor through the Knox Developer Portal — or
 *   startAttestation(nonce, callback) for on-prem verdicts; the
 *   caller must hold com.samsung.android.knox.permission
 *   .KNOX_ENHANCED_ATTESTATION. The REST twin of this road stands
 *   at https://attest.samsungknox.com/v3 (nonces, then verdicts),
 *   authorised by the same vendor key.
 *
 * DOCTRINE — why the enhanced road is invoked REFLECTIVELY here:
 *   The enhanced entry points and their signatures are documented;
 *   the callback type's exact seat (a nested interface of
 *   EnhancedAttestationPolicy, per the API reference's own code
 *   fragments) is the one shape this host cannot confirm without
 *   Samsung's JAR, and this toolbox does not guess at a type it will
 *   then claim to have compiled. So the enhanced request is made by
 *   reflection over the documented method names, with a callback
 *   supplied by the caller as an Object: when the seat is laid, the
 *   reflection resolves against the real classes or fails loudly
 *   with the missing name printed. The legacy road, whose every
 *   shape is pinned by Samsung's published tutorial code, is called
 *   directly. SEAT-GATED throughout: no JAR, no compile, no run —
 *   the gate is the Knox Partner Program, named in the README.
 * ============================================================================
 */

package com.qasparr.knoxbridge;

import android.content.Context;

import com.samsung.android.knox.integrity.AttestationPolicy;

import java.lang.reflect.Method;

public final class KnoxAttestationReader {

    /** The broadcast action Samsung's legacy service answers on. */
    public static final String RESULT_ACTION =
            "com.samsung.android.knox.intent.action.KNOX_ATTESTATION_RESULT";

    private KnoxAttestationReader() {
    }

    /** A nonce is 32 bytes as hex: exactly 64 hex characters. */
    private static boolean isNonceShaped(String nonce) {
        if (nonce == null || nonce.length() != 64) {
            return false;
        }
        for (int i = 0; i < nonce.length(); i++) {
            char c = nonce.charAt(i);
            boolean hex = (c >= '0' && c <= '9')
                    || (c >= 'a' && c <= 'f')
                    || (c >= 'A' && c <= 'F');
            if (!hex) {
                return false;
            }
        }
        return true;
    }

    /**
     * The legacy road, called directly: every shape in it is pinned
     * by Samsung's published tutorial code.
     *
     * @param nonceHex 32 bytes as a 64-character hex string, fetched
     *                 from the verifier's nonce service.
     * @return a line of record; the blob itself arrives by broadcast
     *         on RESULT_ACTION and is not claimed here.
     */
    public static String startLegacyAttestation(Context context, String nonceHex) {
        if (!isNonceShaped(nonceHex)) {
            return "attestation(legacy) : NOT STARTED — the nonce is not "
                    + "32 bytes as hex (64 hex characters); the service "
                    + "would refuse it as ERROR_INVALID_NONCE";
        }
        try {
            AttestationPolicy policy = new AttestationPolicy(context);
            policy.startAttestation(nonceHex);
            return "attestation(legacy) : STARTED — the blob returns by "
                    + "broadcast on " + RESULT_ACTION + " (verdict is the "
                    + "attestation server's, not this reader's)";
        } catch (SecurityException e) {
            return "attestation(legacy) : REFUSED (SecurityException — "
                    + "KNOX_REMOTE_ATTESTATION or license seat missing)";
        } catch (Exception e) {
            return "attestation(legacy) : REFUSED ("
                    + e.getClass().getSimpleName() + ")";
        }
    }

    /**
     * The enhanced road, invoked reflectively for the reason stated
     * in this file's doctrine: the entry points are documented, the
     * callback's exact seat is confirmed only by the seated JAR.
     *
     * @param auk      the Attestation Unique Key from the founder's
     *                 Knox Developer Portal (used, never stored here)
     * @param nonce    the verifier's nonce for this request
     * @param callback the caller's callback object, of the type the
     *                 seated SDK's EnhancedAttestationPolicy expects
     * @return a line of record naming what resolved and what did not.
     */
    public static String startEnhancedAttestation(
            Context context, String auk, String nonce, Object callback) {
        try {
            Class<?> ekmClass = Class.forName(
                    "com.samsung.android.knox.EnterpriseKnoxManager");
            Method getInstance = ekmClass.getMethod("getInstance", Context.class);
            Object ekm = getInstance.invoke(null, context);
            if (ekm == null) {
                return "attestation(enhanced) : NOT STARTED — "
                        + "EnterpriseKnoxManager does not stand here";
            }
            Method getPolicy = ekmClass.getMethod("getEnhancedAttestationPolicy");
            Object policy = getPolicy.invoke(ekm);
            if (policy == null) {
                return "attestation(enhanced) : NOT STARTED — no "
                        + "EnhancedAttestationPolicy on this device/build";
            }
            // The documented server road: (auk, nonce, callback).
            for (Method m : policy.getClass().getMethods()) {
                if (m.getName().equals("startAttestation")
                        && m.getParameterTypes().length == 3) {
                    m.invoke(policy, auk, nonce, callback);
                    return "attestation(enhanced) : STARTED via the "
                            + "documented 3-argument road (Samsung "
                            + "Attestation Server; verdict is the "
                            + "server's, not this reader's)";
                }
            }
            return "attestation(enhanced) : NOT STARTED — the seated SDK "
                    + "shows no 3-argument startAttestation; the gate is "
                    + "named, the shape is reported, nothing was forced";
        } catch (Exception e) {
            return "attestation(enhanced) : REFUSED ("
                    + e.getClass().getSimpleName()
                    + " — seat, KNOX_ENHANCED_ATTESTATION, or license)";
        }
    }
}

/*
 * ============================================================================
 * 93 — Live, Love, and let Love, Live.
 * ============================================================================
 */
