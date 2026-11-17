# KNOX NDK TOOLBOX — Samsung's enterprise seat, used as Samsung publishes it

*For the founder's Galaxy A16 (Exynos 1330, SM-A166U / SM-S166V family) — his device, his account, his hand.*
*Authorship attributed exclusively to Johnathan 'Qasparr' Monroe (Greek, -ARR, All Rights Reserved, Without Prejudice). Enterprise • Educational • Research & Development. Method of Science, Aim of Religion. 93.*

## What this toolbox is

The lawful elevation shelf for the founder's own device, in Samsung's own shapes. Where the platform toolbox reads what Android publishes, this one prepares the founder to use the **Knox SDK** — Samsung's enterprise kit — exactly as Samsung distributes it: policy reads through `EnterpriseDeviceManager`, the attestation readout through Samsung's attestation policies, license activation through the founder's own KPE key, and the host-side tooling a Device Owner provisioning flow needs. Half of it compiles and runs its bench on this host today; the Samsung half stands as source behind a gate that is printed, named, and never circumvented.

## Contents

| Seat | What it is | State on this host |
|---|---|---|
| `wrappers/java/…/PlatformPolicyReader.java` | Platform policy reads: Device/Profile Owner state, build identity, Knox version (reflective `SystemProperties` read, labeled as such) | **Compiles** against stock `android.jar` |
| `wrappers/java/…/KeyAttestationReader.java` | Platform key attestation: an AndroidKeyStore EC key with a verifier challenge; the certificate chain read out, presence + length of the attestation extension reported, verdict left to the verifier | **Compiles** against stock `android.jar` |
| `wrappers/java/…/KnoxNativeBridge.java` + `native/jni_knox_bridge.c` | JNI glue: device fingerprint and a JSON enrollment manifest (model, platform, build fingerprint, release) struck from the system property store | **Compiles and links** — `libknoxbridge.so` for aarch64 |
| `wrappers/java/…/KnoxPolicyReader.java` | Knox policy reads: `EnterpriseDeviceManager.getInstance()`, `getApiLevel()`, `DeviceInventory.isDeviceSecure()`, refusals reported as facts | **ACCOUNT-GATED** — needs Samsung's JAR in the seat |
| `wrappers/java/…/KnoxLicenseActivator.java` | The gate's own door: `EnterpriseLicenseManager…activateLicense(key)`; the key is an input, never stored, never printed (length only) | **ACCOUNT-GATED** |
| `wrappers/java/…/KnoxAttestationReader.java` | Samsung's attestation: the legacy `AttestationPolicy` road called directly (every shape pinned by Samsung's tutorial code); the enhanced road (`EnterpriseKnoxManager.getEnhancedAttestationPolicy()`) invoked reflectively, because the callback's exact seat is confirmed only by the seated JAR — the reason is printed in the file, at full size | **ACCOUNT-GATED** |
| `provisioning/provision-manifest.py` | Builds the Device Owner provisioning payload (component, https APK location, SHA-256 checksum in the platform's form); validates every field; `--self-test` benches the round trip | **Runs here** — stdlib only |
| `sdk-seat/` | The named seat for Samsung's archives + `verify-seat.sh`, which reads archive listings only and answers OK / INCOMPLETE / ACCOUNT-GATED | Gate verified working |
| `tests/run-tests.sh` | The bench: K1–K6 (see below) | **6/6 green on this host** (run record below) |

## The gate, printed plainly

**The Knox SDK is Samsung's, distributed through the Knox Partner Program under Samsung's license.** It is not on this host, not in this repository, and not mirrored anywhere by this house. Everything in the Knox room is **GATED ON THE FOUNDER'S OWN SAMSUNG ACCOUNT**, through exactly this door:

1. Enroll in the **Knox Partner Program** (Knox Partner Portal).
2. **Knox Developers → SDK Tools → SDK Downloads**; accept the SDK Agreement; download.
3. Generate a **KPE license key** in the same portal (Development while testing; KPE Premium is free).
4. Lay the archives under `knox-ndk-toolbox/vendor/samsung/` (git-ignored) and run `sdk-seat/verify-seat.sh`.

No step of that door is circumvented, automated around, or substituted with an unofficial copy. A gate reported is a gate respected.

## The boundary

The standing line holds inside this toolbox, in the same terms as the Exynos toolbox's README: **no Knox bypass, no fuse games, no attestation forgery, no key extraction.** The Knox seat is used as Samsung publishes it — to administer the founder's own device and to **read** its attestation, whose verdict belongs to Samsung's Attestation Server or the founder's verifier, never to a wrapper's say-so. The consumer mouth is blocked by policy; the Vault is not touched. **Block the mouth, not the Vault.**

Two refusals this toolbox builds in, by design:

- **No hand-rolled cryptography.** Checksums and digests come from the standard library's audited SHA-256; the native manifest takes its checksum as an input computed host-side. A toolbox that invented its own hash would be manufacturing the testimony it exists to read.
- **No stubbed Samsung classes.** The Knox room does not compile until Samsung's real JAR stands in the seat. A green build bought with forged classes would be a lie with a compiler's stamp on it.

## Build & test

```sh
wrappers/build-wrappers.sh     # platform room always; Knox room when seated
native/build-jni.sh            # libknoxbridge.so (aarch64, NDK)
provisioning/provision-manifest.py --self-test
sdk-seat/verify-seat.sh        # exit 3 = gate, named — not a failure
tests/run-tests.sh             # the whole bench
```

Bench record on this host (2026-11-16): **K1** platform wrappers compile against `android.jar` (SDK platform 34, JDK 17) · **K2** `libknoxbridge.so` struck for aarch64 with the house NDK r30 · **K3** provisioning manifest round-trips, bad fields refused · **K4** the seat verifier answers ACCOUNT-GATED with exit 3 on the unfilled seat — the gate working as designed · **K5** the Knox room's state is named in print by the build · **K6** house form (authorship line + closing motto) in every code file.

## What remains gated, at full size

- **ACCOUNT-GATED (the founder's Samsung door):** compiling or running the Knox room; license activation; Samsung attestation (legacy and enhanced); the Attestation Unique Key the enhanced server road requires.
- **DEVICE-GATED (a living A16, the founder's hand):** every wrapper's run-time behaviour; a real attestation round trip and its server verdict; Device Owner provisioning itself (factory-reset act, setup wizard, QR/NFC in hand).
- **NAMED UNCERTAINTIES, kept open rather than smoothed:** the `EnterpriseLicenseManager` import seat across SDK generations (one line to correct when the seated JAR answers — see the file's doctrine block); the enhanced attestation callback's exact type seat (the reason that road is reflective); Knox API levels move — `AttestationPolicy` is deprecated since API 33 in favour of the enhanced road, and this toolbox walks the road the seated device speaks.

*93 — Live, Love, and let Love, Live.*
