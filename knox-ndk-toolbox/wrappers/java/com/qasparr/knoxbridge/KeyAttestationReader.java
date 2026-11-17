/*
 * ============================================================================
 * KEY-ATTESTATION-READER — the platform's own attestation readout path
 * ----------------------------------------------------------------------------
 * "Do what thou wilt shall be the whole of the Law."
 *   Attestation is a device testifying about itself, under a key it
 *   cannot extract, in a chain that ends at a root the verifier
 *   already trusts. This reader performs the on-device half of that
 *   testimony exactly as the platform documents it: mint a key in
 *   the Android Keystore with a server-supplied challenge folded in,
 *   take the certificate chain the Keystore returns, and report what
 *   the chain carries — above all whether the attestation extension
 *   (OID 1.3.6.1.4.1.11129.2.1.17) is present in the leaf.
 *
 * Authorship attributed exclusively to Johnathan "Qasparr" Monroe
 * (Greek, -ARR, All Rights Reserved, Without Prejudice).
 * XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
 * (2026 e.v.). Method of Science, Aim of Religion. 93.
 *
 * MECHANISM —
 *   attest(Context-free, challenge) :
 *     1. A fresh EC (secp256r1) key pair is generated inside the
 *        Android Keystore under a fixed alias, with
 *        KeyGenParameterSpec.setAttestationChallenge(challenge) —
 *        the challenge is the verifier's nonce; a chain minted
 *        without one testifies about nothing in particular and is
 *        worth about that much.
 *     2. The certificate chain is read back from the Keystore. Its
 *        length, and each certificate's subject and issuer, are
 *        reported. The leaf's attestation extension is checked for
 *        presence and its byte length reported.
 *     3. The minted key is DELETED. This reader borrows the
 *        Keystore's testimony; it does not leave keys behind it —
 *        a reader that accumulates keys is a tenant, not a witness.
 *
 * DOCTRINE — the honest limits of an on-device readout:
 *   Presence of the extension is reported; its ASN.1 interior —
 *   the security level, the verified-boot state, the challenge
 *   echo — is NOT parsed here. Full parsing and verdict belong to
 *   the verifying server, which holds the root and the policy; an
 *   on-device printout that declared "VERDICT: TRUSTED" about
 *   itself would be the device grading its own homework. Knox's
 *   enhanced attestation (the SAK-rooted Samsung path) stands
 *   beside this platform path in KnoxAttestationReader; the two are
 *   different testimonies and this file does not conflate them.
 *   Compiles against stock android.jar (proven by the toolbox
 *   tests); runs only on a device — the host's android.jar is a
 *   book of stubs and throws if its methods are called here.
 * ============================================================================
 */

package com.qasparr.knoxbridge;

import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;

import java.security.KeyPairGenerator;
import java.security.KeyStore;
import java.security.cert.Certificate;
import java.security.cert.X509Certificate;
import java.security.spec.ECGenParameterSpec;

public final class KeyAttestationReader {

    /** The one alias this reader ever uses; deleted after each read. */
    private static final String ALIAS = "qasparr.attestation.readout";

    /** Google's attestation extension OID, as documented for key attestation. */
    private static final String ATTESTATION_OID = "1.3.6.1.4.1.11129.2.1.17";

    private KeyAttestationReader() {
    }

    /**
     * Mint, read, report, delete.
     *
     * @param challenge the verifier's nonce bytes; must be non-empty,
     *                  because an unchallenged attestation is a
     *                  statement about no particular moment.
     * @return a plain-text readout of the returned chain.
     */
    public static String attest(byte[] challenge) throws Exception {
        if (challenge == null || challenge.length == 0) {
            throw new IllegalArgumentException(
                    "attestation requires a challenge; an unchallenged "
                            + "testimony is worth nothing");
        }

        KeyStore keyStore = KeyStore.getInstance("AndroidKeyStore");
        keyStore.load(null);

        try {
            KeyPairGenerator generator = KeyPairGenerator.getInstance(
                    KeyProperties.KEY_ALGORITHM_EC, "AndroidKeyStore");
            generator.initialize(new KeyGenParameterSpec.Builder(
                    ALIAS, KeyProperties.PURPOSE_SIGN)
                    .setAlgorithmParameterSpec(new ECGenParameterSpec("secp256r1"))
                    .setDigests(KeyProperties.DIGEST_SHA256)
                    .setAttestationChallenge(challenge)
                    .build());
            generator.generateKeyPair();

            Certificate[] chain = keyStore.getCertificateChain(ALIAS);
            if (chain == null || chain.length == 0) {
                return "== key attestation readout ==\n"
                        + "chain : EMPTY — this device returned no attestation chain\n";
            }

            StringBuilder out = new StringBuilder();
            out.append("== key attestation readout ==\n");
            out.append("chain length : ").append(chain.length).append('\n');
            for (int i = 0; i < chain.length; i++) {
                if (chain[i] instanceof X509Certificate) {
                    X509Certificate cert = (X509Certificate) chain[i];
                    out.append("cert ").append(i)
                       .append(" subject : ")
                       .append(cert.getSubjectX500Principal().getName())
                       .append('\n');
                    out.append("cert ").append(i)
                       .append(" issuer  : ")
                       .append(cert.getIssuerX500Principal().getName())
                       .append('\n');
                }
            }
            X509Certificate leaf = (X509Certificate) chain[0];
            byte[] extension = leaf.getExtensionValue(ATTESTATION_OID);
            out.append("attestation extension (").append(ATTESTATION_OID)
               .append(") : ");
            if (extension == null) {
                out.append("ABSENT — the leaf carries no attestation record\n");
            } else {
                out.append("present, ").append(extension.length)
                   .append(" bytes (interior parsed server-side, by doctrine)\n");
            }
            return out.toString();
        } finally {
            // The witness leaves no keys behind.
            if (keyStore.containsAlias(ALIAS)) {
                keyStore.deleteEntry(ALIAS);
            }
        }
    }
}

/*
 * ============================================================================
 * 93 — Live, Love, and let Love, Live.
 * ============================================================================
 */
