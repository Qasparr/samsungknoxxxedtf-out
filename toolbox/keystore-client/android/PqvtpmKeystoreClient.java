// =====================================================================
// PQVTPM KEYSTORE CLIENT — the enclave's hand on the Android
// Keystore API (device source; compiles against the Android SDK)
//
// "Do what thou wilt shall be the whole of the Law."
//
// XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
// (2026 e.v.)
// 93
//
// Authorship attributed exclusively to Johnathan 'Qasparr' Monroe
// (Greek, -ARR, All Rights Reserved, Without Prejudice).
// Scientific Illuminism: Method of Science, Aim of Religion.
//
// Flagpole of Claim and Coinage: Johnathan 'Qasparr' Monroe, ARR,
// All Rights Reserved, Without Prejudice. Right of claim hereby
// reserved and coined under the authority of the Living Man.
// =====================================================================
//
// MECHANISM
// ---------
// Five steps, mirroring bench/keystore_bench.py exactly, so the
// protocol benched on the host is the protocol run on the unit:
//
//   1. CHALLENGE  the verifier issues fresh random bytes.
//   2. GENERATE   KeyPairGenerator over the "AndroidKeyStore"
//                 provider: EC secp256r1, PURPOSE_SIGN | VERIFY,
//                 SHA-256 digest, the challenge seated with
//                 setAttestationChallenge(). StrongBox is NOT
//                 requested — the Galaxy A16 carries no StrongBox
//                 chip; the security level is READ from KeyInfo
//                 after minting and reported, never assumed.
//   3. SIGN       Signature "SHA256withECDSA" under the alias.
//                 The private key is non-exportable by the API's
//                 own construction; no code path here exports,
//                 wraps, or backs one up. There is deliberately
//                 no such path to audit.
//   4. VERIFY     against the public key from the certificate
//                 chain — the chain is the only public-key source.
//   5. ATTEST     KeyStore.getCertificateChain(alias); the leaf's
//                 attestation extension (OID
//                 1.3.6.1.4.1.11129.2.1.17) is walked by the small
//                 DER reader below to lift the attestation
//                 challenge and both security levels, and the
//                 challenge is compared byte-for-byte with the
//                 one issued in step 1.
//
// DOCTRINE
// --------
// Stock phone, no root, the Knox fuse unspent: this client is the
// lawful half of the PQVTPM road. It asks the TEE for keys the
// public way, through the public API, and it believes nothing the
// API does not prove — a software-level answer is reported as
// software, a missing chain as a failure, a mismatched challenge
// as a refusal. Fail-closed, like everything the house seals.
//
// BUILD STATE, PLAINLY: this file is source-reviewed, not compiled
// — the bench box carries no JDK and no Android SDK (XVI November
// 2026). It compiles in Android Studio against the unit's API
// level when deployment is struck, on the founder's word.
//
// 93 — Live, Love, and let Love, Live.
// =====================================================================

package house.enclave.pqvtpm;

import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyInfo;
import android.security.keystore.KeyProperties;

import java.io.ByteArrayInputStream;
import java.security.KeyFactory;
import java.security.KeyPairGenerator;
import java.security.KeyStore;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.Signature;
import java.security.cert.Certificate;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.security.spec.ECGenParameterSpec;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public final class PqvtpmKeystoreClient {

    /** The one alias this client mints under. Versioned in the
     *  name: a future key ceremony mints v2 beside v1, never over
     *  it — the registry keeps its history. */
    public static final String ALIAS = "pqvtpm.enclave.attest.v1";

    private static final String PROVIDER = "AndroidKeyStore";

    /** AOSP's attestation extension OID, as published in the
     *  Android keystore attestation documentation. */
    private static final String ATTESTATION_OID = "1.3.6.1.4.1.11129.2.1.17";

    // ---------------------------------------------------------------
    // STEP 2 — GENERATE
    // ---------------------------------------------------------------

    /** Mint the attested key pair under ALIAS, bound to the
     *  verifier's fresh challenge.
     *
     *  MECHANISM: KeyGenParameterSpec carries the purposes, the
     *  curve, the digest, and the attestation challenge. The
     *  challenge is what turns the returned certificate chain from
     *  a photograph into a proof: the TEE signs the challenge into
     *  the leaf at minting time.
     *
     *  @param attestationChallenge fresh bytes from the verifier
     *  @return the KeyInfo security facts, as read — not assumed
     */
    public KeyFacts generateAttestedKey(byte[] attestationChallenge)
            throws Exception {
        KeyPairGenerator gen =
                KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, PROVIDER);
        KeyGenParameterSpec spec = new KeyGenParameterSpec.Builder(
                ALIAS,
                KeyProperties.PURPOSE_SIGN | KeyProperties.PURPOSE_VERIFY)
                .setAlgorithmParameterSpec(new ECGenParameterSpec("secp256r1"))
                .setDigests(KeyProperties.DIGEST_SHA256)
                .setAttestationChallenge(attestationChallenge)
                // DOCTRINE: no setIsStrongBoxBacked(true) — this
                // unit has no StrongBox to back with, and asking
                // would either fail or lie by omission. The level
                // is read below and reported as found.
                .build();
        gen.initialize(spec);
        gen.generateKeyPair();
        return readKeyFacts();
    }

    /** Read the security facts of the key under ALIAS.
     *  MECHANISM: KeyFactory/KeyInfo is the API's own testimony
     *  about where the private key lives. isInsideSecureHardware
     *  (and, API 31+, getSecurityLevel) are reported verbatim. */
    public KeyFacts readKeyFacts() throws Exception {
        KeyStore ks = loadKeyStore();
        PrivateKey key = (PrivateKey) ks.getKey(ALIAS, null);
        if (key == null) {
            throw new IllegalStateException("no key under alias " + ALIAS);
        }
        KeyFactory factory = KeyFactory.getInstance(key.getAlgorithm(), PROVIDER);
        KeyInfo info = factory.getKeySpec(key, KeyInfo.class);
        int level = -1;
        try {
            level = info.getSecurityLevel(); // API 31+
        } catch (Throwable ignored) {
            // Older API: isInsideSecureHardware carries the fact.
        }
        return new KeyFacts(info.isInsideSecureHardware(), level);
    }

    // ---------------------------------------------------------------
    // STEPS 3–4 — SIGN / VERIFY
    // ---------------------------------------------------------------

    /** Sign data under ALIAS. The private half never leaves the
     *  secure world; what crosses the API is the signature. */
    public byte[] sign(byte[] data) throws Exception {
        KeyStore ks = loadKeyStore();
        PrivateKey key = (PrivateKey) ks.getKey(ALIAS, null);
        if (key == null) {
            throw new IllegalStateException("no key under alias " + ALIAS);
        }
        Signature sig = Signature.getInstance("SHA256withECDSA");
        sig.initSign(key);
        sig.update(data);
        return sig.sign();
    }

    /** Verify against the public key taken from the certificate
     *  chain — the chain is the only public-key source this
     *  client trusts, so what ATTEST proves is what VERIFY uses. */
    public boolean verify(byte[] data, byte[] signatureBytes) throws Exception {
        Certificate[] chain = loadKeyStore().getCertificateChain(ALIAS);
        if (chain == null || chain.length == 0) {
            throw new IllegalStateException("no certificate chain for " + ALIAS);
        }
        PublicKey pub = chain[0].getPublicKey();
        Signature sig = Signature.getInstance("SHA256withECDSA");
        sig.initVerify(pub);
        sig.update(data);
        return sig.verify(signatureBytes);
    }

    // ---------------------------------------------------------------
    // STEP 5 — ATTEST
    // ---------------------------------------------------------------

    /** Read and check the attestation of the key under ALIAS.
     *
     *  MECHANISM: parse the leaf certificate's attestation
     *  extension; compare its challenge with the expected one
     *  byte-for-byte; report both security levels as ENUMERATED
     *  values read (0 = Software, 1 = TEE, 2 = StrongBox).
     *  DOCTRINE: a mismatch is a refusal, thrown — never a boolean
     *  a caller can forget to check.
     */
    public AttestationReport attest(byte[] expectedChallenge) throws Exception {
        Certificate[] chain = loadKeyStore().getCertificateChain(ALIAS);
        if (chain == null || chain.length == 0) {
            throw new IllegalStateException("attestation failed: no chain for " + ALIAS);
        }
        X509Certificate leaf = (X509Certificate) chain[0];
        byte[] ext = leaf.getExtensionValue(ATTESTATION_OID);
        if (ext == null) {
            throw new IllegalStateException(
                    "attestation failed: leaf carries no attestation extension");
        }
        KeyDescription kd = KeyDescription.parse(ext);
        if (!Arrays.equals(kd.attestationChallenge, expectedChallenge)) {
            throw new IllegalStateException(
                    "attestation REFUSED: challenge mismatch — the chain "
                    + "answers a different question than the one asked");
        }
        List<String> chainSubjects = new ArrayList<>();
        CertificateFactory cf = CertificateFactory.getInstance("X.509");
        for (Certificate c : chain) {
            X509Certificate xc = (X509Certificate) cf.generateCertificate(
                    new ByteArrayInputStream(c.getEncoded()));
            chainSubjects.add(xc.getSubjectX500Principal().getName());
        }
        return new AttestationReport(
                kd.attestationSecurityLevel,
                kd.keymasterSecurityLevel,
                chain.length,
                chainSubjects);
    }

    // ---------------------------------------------------------------
    // Facts, as read
    // ---------------------------------------------------------------

    public static final class KeyFacts {
        public final boolean insideSecureHardware;
        /** KeyInfo security level on API 31+ (1 = TEE, 2 =
         *  StrongBox, 0 = Software); -1 where the API is older. */
        public final int securityLevel;

        KeyFacts(boolean insideSecureHardware, int securityLevel) {
            this.insideSecureHardware = insideSecureHardware;
            this.securityLevel = securityLevel;
        }
    }

    public static final class AttestationReport {
        public final int attestationSecurityLevel;
        public final int keymasterSecurityLevel;
        public final int chainLength;
        public final List<String> chainSubjects;

        AttestationReport(int a, int k, int len, List<String> subjects) {
            this.attestationSecurityLevel = a;
            this.keymasterSecurityLevel = k;
            this.chainLength = len;
            this.chainSubjects = subjects;
        }

        /** Level names as AOSP enumerates them. */
        public static String levelName(int level) {
            switch (level) {
                case 0: return "SOFTWARE";
                case 1: return "TEE";
                case 2: return "STRONGBOX";
                default: return "UNKNOWN(" + level + ")";
            }
        }
    }

    // ---------------------------------------------------------------
    // The minimal DER reader — just enough ASN.1 to walk the
    // attestation extension, and no more.
    //
    // MECHANISM: X509Certificate.getExtensionValue returns the
    // extension as a DER OCTET STRING wrapping the value. Inside,
    // AOSP's KeyDescription is a SEQUENCE:
    //   [0] attestationVersion      INTEGER
    //   [1] attestationSecurityLevel ENUMERATED
    //   [2] keymasterVersion        INTEGER
    //   [3] keymasterSecurityLevel  ENUMERATED
    //   [4] attestationChallenge    OCTET STRING
    //   [5] uniqueId                OCTET STRING
    //   [6] softwareEnforced        SEQUENCE
    //   [7] teeEnforced             SEQUENCE
    // The reader walks TLVs (short- and long-form lengths) and
    // lifts fields 1, 3, 4. Anything malformed throws — a reader
    // that guesses is a reader that lies.
    // ---------------------------------------------------------------

    static final class KeyDescription {
        int attestationSecurityLevel;
        int keymasterSecurityLevel;
        byte[] attestationChallenge;

        static KeyDescription parse(byte[] extensionValue) throws Exception {
            DerReader outer = new DerReader(extensionValue);
            byte[] inner = outer.readOctetString();
            DerReader seq = new DerReader(inner);
            List<DerReader.Tlv> fields = seq.readSequenceChildren();
            if (fields.size() < 5) {
                throw new IllegalStateException(
                        "attestation extension too short: " + fields.size());
            }
            KeyDescription kd = new KeyDescription();
            kd.attestationSecurityLevel = fields.get(1).asInt();
            kd.keymasterSecurityLevel = fields.get(3).asInt();
            kd.attestationChallenge = fields.get(4).value;
            return kd;
        }
    }

    static final class DerReader {
        static final class Tlv {
            final int tag;
            final byte[] value;

            Tlv(int tag, byte[] value) {
                this.tag = tag;
                this.value = value;
            }

            int asInt() {
                int v = 0;
                for (byte b : value) {
                    v = (v << 8) | (b & 0xFF);
                }
                return v;
            }
        }

        private final byte[] buf;
        private int pos;

        DerReader(byte[] buf) {
            this.buf = buf;
            this.pos = 0;
        }

        private int readByte() throws Exception {
            if (pos >= buf.length) {
                throw new IllegalStateException("DER overrun");
            }
            return buf[pos++] & 0xFF;
        }

        private int readLength() throws Exception {
            int first = readByte();
            if ((first & 0x80) == 0) {
                return first;
            }
            int n = first & 0x7F;
            if (n == 0 || n > 3) {
                throw new IllegalStateException("DER length form unsupported: " + n);
            }
            int len = 0;
            for (int i = 0; i < n; i++) {
                len = (len << 8) | readByte();
            }
            return len;
        }

        Tlv readTlv() throws Exception {
            int tag = readByte();
            if ((tag & 0x1F) == 0x1F) {
                // Multi-byte tag — not present in this extension's
                // documented shape; refuse rather than improvise.
                throw new IllegalStateException("DER multi-byte tag unsupported");
            }
            int len = readLength();
            if (pos + len > buf.length) {
                throw new IllegalStateException("DER value overrun");
            }
            byte[] value = Arrays.copyOfRange(buf, pos, pos + len);
            pos += len;
            return new Tlv(tag, value);
        }

        byte[] readOctetString() throws Exception {
            Tlv tlv = readTlv();
            if (tlv.tag != 0x04) {
                throw new IllegalStateException("expected OCTET STRING, tag=" + tlv.tag);
            }
            return tlv.value;
        }

        List<Tlv> readSequenceChildren() throws Exception {
            Tlv seq = readTlv();
            if (seq.tag != 0x30) {
                throw new IllegalStateException("expected SEQUENCE, tag=" + seq.tag);
            }
            DerReader inner = new DerReader(seq.value);
            List<Tlv> children = new ArrayList<>();
            while (inner.pos < inner.buf.length) {
                children.add(inner.readTlv());
            }
            return children;
        }
    }

    private static KeyStore loadKeyStore() throws Exception {
        KeyStore ks = KeyStore.getInstance(PROVIDER);
        ks.load(null);
        return ks;
    }
}

// 93 — Live, Love, and let Love, Live.
