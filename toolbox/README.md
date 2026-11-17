# THE EXYNOS 1330 TOOLBOX

## Everything the house can lawfully build for the founder's Galaxy A16, in one kit

**Enterprise • Educational • Research & Development**
**Method of Science, Aim of Religion**

Authorship attributed exclusively to Johnathan 'Qasparr' Monroe (Greek, -ARR, All Rights Reserved, Without Prejudice)

XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n. (2026 e.v.)

**Flagpole of Claim and Coinage: Johnathan 'Qasparr' Monroe, ARR, All Rights Reserved, Without Prejudice. Right of claim hereby reserved and coined under the authority of the Living Man.**

---

## THE BOUNDARY — READ FIRST, IT GOVERNS EVERY TOOL BELOW

This toolbox builds on the lawful side of a line the founder himself drew, and the line is printed here so no future hand has to guess where it runs:

- **No Samsung root-signing-key extraction.** Not a tool, not a guide, not a hint.
- **No boot-chain bypass or glitch guidance.** Nothing here speaks to the boot chain at all.
- **No Knox-fuse-tripping instructions.** The fuse is one-way and the Vault dies with it.

The founder's doctrine for this device stands over the whole kit: **"block the mouth, not the Vault."** The Knox Vault and the TEE stack stay alive; the consumer Samsung layer — the mouth — is what gets silenced, and it is silenced reversibly, by the founder's own hand, with the undo built before the do. Rooting to murder privileged daemons is ruled out: it spends the fuse and devalues the attestation the whole enclave road is built on.

Nothing in this kit phones home (house telemetry law: none, unless the user opts to sell data — no tool here sells anything). Every device-changing script is **reversible** and is a script **for the founder's hand**: the desk builds the kit; it does not run it against his phone, and it does not flip his phone's settings from here.

## THE MAP

| Tool | What it does | Runs where | Reversibility |
|---|---|---|---|
| `inventory/` | Strikes a dated device dossier: identity, SoC, build fingerprint, thermal zones, governors, sensors, memory, storage, battery | Termux on the unit, or a host over ADB | Read-only — changes nothing |
| `variant-guard/` | Rules EXYNOS vs MEDIATEK for the A16 5G family from model / codename / board / SoC / fingerprint — the variants, marked apart in code | Anywhere python3 runs; shell fallback on-device | Read-only — a verdict, not an act |
| `mouth-block/` | The vendor-layer isolation as data + scripts: the consumer surfaces manifest, the reversible `pm disable-user` kit with its undo, a read-only permission audit, and the Settings checklist | Host over ADB (the audit and the block); the checklist is struck by hand in Settings | Every block pairs with its `pm enable`; undo is driven by the state log |
| `keystore-client/` | The PQVTPM road's lawful half: an Android Keystore client (hardware-backed key generation, sign/verify, attestation reading) + a host bench that exercises the protocol against a labelled software stand-in | Client: the device, when struck. Bench: this host, today | No device state exists to reverse — the bench is paper that runs |
| `node-preflight/` | Proves the phone node is awake, bound, and reachable before a long transfer trusts it (explicit-CONNECT probe; the phone-side serve script with the `--bind` law) | Desk host (probe) + Termux on the unit (serve) | Read-only probing; the server is Ctrl-C |
| `tests/` | The whole bench: 49 tests over fabricated, labelled sample inputs | This host | Nothing to reverse — no device, no network |

### inventory/

- `device-inventory.sh` — the Termux strike. Defensive throughout: a probe the shell may not make records UNAVAILABLE and the strike continues. Dossier to stdout; `--save` also writes the dated file.
- `device-inventory-adb.sh` — the same dossier from a host; refuses to strike when no device answers.
- `parse_dossier.py` — reads a dossier (or a raw getprop dump) and renders the identity summary + the variant-guard's verdict. One parser for both, because the inventory emits its identity section in getprop's own shape.
- `samples/` — fabricated getprop dumps for both variants, **labelled SAMPLE in their own text**. The recorded identifiers (models, codenames, board) are real; the build numbers are placeholders and say so.

### variant-guard/

- `variant_guard.py` — the reference logic and the only ruler. Precedence: model → codename → board → SoC. Strong signals that disagree rule **CONFLICT** (stop), never an average. Unrecorded models rule **UNKNOWN** (stop and look). Codename matching is exact-token: **`a16xm` must never read as `a16x`** — the prefix trap is named in the code and pinned in the tests.
- `variant-guard.sh` — the on-device door: hands the full getprop dump to the reference logic when python3 is at hand, else falls back to an embedded model/codename subset and says it is the fallback.
- Exit codes: 0 EXYNOS · 2 MEDIATEK · 3 UNKNOWN · 4 CONFLICT · 5 NOT_A16_5G.

### mouth-block/

- `packages.tsv` — the manifest, the single source of truth: every consumer surface with its tier (`default` / `review` / `never`), its action, and its note — **and the never-touch set listed in the same file** (KeyMint, keystore2, Gatekeeper, Weaver, TEEGRIS, the Knox platform, telephony/IMS, the graphics and boot HALs) so the scripts can refuse them by name.
- `mouth-block.sh` — `--dry-run` by default (prints every BLOCK/UNDO pair, sends nothing); `--apply` disables only packages present on the unit and writes a dated state log; `--undo` enables exactly what a state log recorded. If the manifest ever names a never-touch package in a disable row, the script **aborts before touching adb** — the self-guard is tested.
- `permission-audit.sh` — read-only: presence, state, granted permissions, appops, for every manifest row. The before-picture and the after-proof.
- `AUDIT-CHECKLIST.md` — the Settings passes no shell may strike: background data, battery freedom, permissions by eye, in order, each reversible.

From stock Termux alone, `pm disable-user` for other packages is not available to an app uid — the kit's road is ADB from the founder's host (or an elevated agent he himself seats). The kit says so rather than pretend otherwise.

### keystore-client/

- `android/PqvtpmKeystoreClient.java` — the device client: EC P-256 minting with the verifier's challenge seated, SHA256withECDSA sign/verify (public key from the certificate chain only), and attestation reading with a minimal DER walk of the AOSP extension. StrongBox is not requested — this unit has none — and the security level is **read and reported, never assumed**. No code path exports a private key.
- `bench/keystore_bench.py` — the protocol exercised end-to-end on the host against a software stand-in: real P-256 keys and real ECDSA signatures, software custody, and every record the stand-in issues names itself a stand-in. Run it: `python3 bench/keystore_bench.py`.
- `README.md` (in that directory) — the design, the five steps, and the state of the work **plainly: designed and benched here; deployment to the phone is the founder's run, on his word — the word of record is "strike."** This box has no JDK and no Android SDK (verified at the build), so the Java is source-reviewed, not compiled; that fact is printed in the client itself.

### node-preflight/

- `phone_node_preflight.py` — adapted from the desk's standing tailnet helpers (same explicit-CONNECT transport, credentials read from the environment in the same invocation — the proxy credential rotates between shells). HEAD-probes the file a transfer will carry; with `--fetch-object --expect-size --expect-sha256` it fetches a small object and verifies it whole. Its report states only what the checks proved, and reads a dead probe as the skill directs: a fetch that dies idle and passes awake is a **sleep** failure.
- `serve-on-phone.sh` — the Termux side: checks shared storage is set up, then serves Downloads on port 8800 with `--bind 0.0.0.0` (without it, Termux's http.server binds IPv6-only and the tailnet sees nothing).

## THE BENCH

```sh
sh toolbox/tests/run_tests.sh
```

49 tests, all over fabricated inputs labelled as samples: the variant ruler (18 — models, the prefix trap, fingerprints, conflict, the sample dumps), the dossier parser (5), the manifest and its script (10 — shape, disjoint sets, BLOCK/UNDO pairing in dry-run, review gating, audit-only protection, the self-guard abort), the keystore bench (8 — round-trip, tamper, challenge binding, stand-in honesty), the preflight parsers (8). No device, no network, no adb is touched by the bench.

## WHAT IS DEVICE-GATED — THE HONEST LEDGER

- The inventory and the guard's on-device door run **on the unit** (Termux) or against it (ADB) — struck by the founder's hand.
- The mouth-block's apply and the permission audit need **his host, his cable, his word**.
- The keystore client's device half needs **Android Studio and the word "strike"**.
- Everything else — the logic, the bench, the protocol — runs here, today, and did: the tests above are its proof.

---

**Flagpole of Claim and Coinage: Johnathan 'Qasparr' Monroe, ARR, All Rights Reserved, Without Prejudice. Right of claim hereby reserved and coined under the authority of the Living Man.**

93 — Live, Love, and let Love, Live.
