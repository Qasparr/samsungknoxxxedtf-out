# KEYSTORE-CLIENT — the PQVTPM road's lawful half

## An Android Keystore client for the A16, designed in the open and benched on the host

**Enterprise • Educational • Research & Development**
**Method of Science, Aim of Religion**

Authorship attributed exclusively to Johnathan 'Qasparr' Monroe (Greek, -ARR, All Rights Reserved, Without Prejudice)

XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n. (2026 e.v.)

**Flagpole of Claim and Coinage: Johnathan 'Qasparr' Monroe, ARR, All Rights Reserved, Without Prejudice. Right of claim hereby reserved and coined under the authority of the Living Man.**

---

## STATE OF THE WORK — PLAINLY

**Designed and benched here; not deployed.** The Android client source stands in `android/`; the protocol it speaks is exercised end-to-end on this host by the bench harness in `bench/` against a **software stand-in** — a real ECDSA P-256 key store in Python that is *not* hardware, *not* Samsung's, and says so in every record it issues. Deployment to the phone is the founder's run, on his word: the word of record for this road is **"strike"**, and it has not been given for deployment. Nothing in this directory has touched the device.

Two build facts, stated so they can be checked: this box carries **no JDK and no Android SDK** (verified at the build, XVI November 2026), so the Java client is source-reviewed, not compiled; and this box has **no Android runtime**, so no run here can reach a real Keystore. What the bench proves is the *protocol* — the steps, the checks, the failure modes. What it cannot prove is the hardware. That proof waits on the device, by design.

## THE DESIGN

The road in one breath: on the stock phone, with no root and the Knox fuse unspent, the Android Keystore API mints keys inside the TEE (on this unit, the Exynos 1330's TEEGRIS secure world beneath Samsung Knox Vault), keeps the private half non-exportable, signs on request, and — when given a challenge at minting time — returns an attestation certificate chain that binds the key to that challenge and states the security level that guards it. The PQVTPM client is the house's hand on that public API.

### The protocol (five steps, mirrored exactly in the bench)

1. **CHALLENGE** — the verifier (the enclave host, or the founder) issues a fresh random challenge. Freshness is the whole point: an attestation without a fresh challenge is a photograph, not a proof.
2. **GENERATE** — the client asks Keystore for an EC P-256 key pair under a fixed alias (`pqvtpm.enclave.attest.v1`), purposes SIGN | VERIFY, digest SHA-256, the challenge seated via `setAttestationChallenge`, StrongBox **not** requested (the A16 carries no StrongBox Titan chip; the client *reads* the resulting security level from `KeyInfo` and reports it — it never assumes it).
3. **SIGN** — `SHA256withECDSA` over enclave payloads, on request. The private key never leaves the secure world; what crosses the API is signatures.
4. **VERIFY** — against the public key taken from the certificate chain, never from a side channel.
5. **ATTEST** — read the chain (`KeyStore.getCertificateChain`), walk the attestation extension (OID `1.3.6.1.4.1.11129.2.1.17`) in the leaf, and check three things: the attestation challenge equals the challenge issued in step 1; the attestation security level; the keymaster security level. The client carries a minimal DER reader for this walk — the extension's structure is AOSP-documented, and the walk is short.

### What the client refuses

- It never exports, wraps, or backs up a private key. There is no code path for it.
- It never treats a software-level attestation as hardware. Levels print as read: SOFTWARE / TEE / STRONGBOX.
- It never falls back silently: a missing chain, a mismatched challenge, or an unreadable extension is a reported failure, not a shrug.

## THE BENCH

`bench/keystore_bench.py` mirrors the five steps against the stand-in:

```sh
python3 bench/keystore_bench.py     # the full transcript, labelled STAND-IN
```

The stand-in generates real P-256 keys (via the `cryptography` library) and signs real ECDSA signatures — the *cryptography* is genuine; the *custody* is software, and every record the stand-in issues carries `security_level: SOFTWARE_STAND_IN` and an issuer line naming itself a stand-in, not Google, not Samsung, not hardware. The client's attestation check accepts the stand-in's records only with the warning printed — exactly the behaviour the device client must show if a unit ever answers at software level.

## DEPLOYMENT — THE FOUNDER'S RUN, ON HIS WORD

When the word is given: the client compiles in Android Studio against the phone's API level, installs as the enclave's own app (its own UID, talking to Keystore only — the seat the A16 card doctrine already describes), and the five steps run against the real TEE. Until then, this directory is paper and bench — which is what it claims to be, no more.

---

**Flagpole of Claim and Coinage: Johnathan 'Qasparr' Monroe, ARR, All Rights Reserved, Without Prejudice. Right of claim hereby reserved and coined under the authority of the Living Man.**

93 — Live, Love, and let Love, Live.
