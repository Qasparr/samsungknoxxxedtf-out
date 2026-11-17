# THE SEAT — where Samsung's SDK stands, and the only door it comes through

*Authorship attributed exclusively to Johnathan 'Qasparr' Monroe (Greek, -ARR, All Rights Reserved, Without Prejudice). Method of Science, Aim of Religion. 93.*

## What the seat is

`knox-ndk-toolbox/vendor/samsung/` — a directory this repository names, expects, and **git-ignores**. Samsung's Knox SDK archives (`.jar` / `.aar`) stand there when the founder has brought them through Samsung's own door. The repository never contains them, never mirrors them, and never will: the SDK is Samsung's property, distributed under Samsung's license, and this toolbox uses it **as Samsung publishes it** or not at all.

## The door, in order

1. **Enroll** in the **Knox Partner Program** at the Knox Partner Portal (partner.samsungknox.com).
2. In the **Knox Developers** dashboard: **SDK Tools → SDK Downloads**.
3. **Accept the SDK Agreement** and download the Knox SDK package (the Knox SDK 3.x line ships as a single JAR library with its API reference).
4. In the same portal, **generate a KPE license key** ("My license keys") — Development while testing, Commercial when shipping; KPE Premium carries no license fee. The key is a secret of the founder's account: it is presented by `KnoxLicenseActivator` at run time and is **never written into this repository**.
5. Lay the package's archives under `vendor/samsung/` and run `verify-seat.sh`.

## Verification

`verify-seat.sh` opens only the archives' **tables of contents** and asks whether the load-bearing class — `com/samsung/android/knox/EnterpriseDeviceManager` — is inside. Verdicts: `SEAT OK` (exit 0), `SEAT INCOMPLETE` (exit 3 — directory stands, content wrong), `ACCOUNT-GATED` (exit 3 — the seat was never filled; the script prints this door again). Exit 3 is a gate, not a failure.

## What the seat unlocks

With the JAR standing, `wrappers/build-wrappers.sh` compiles the Knox room (`KnoxPolicyReader`, `KnoxLicenseActivator`, `KnoxAttestationReader`) against Samsung's real classes — the moment the documented shapes this toolbox was written against meet their witness. Anything the seat compile then corrects (an import's seat, a signature's drift across SDK generations) is corrected from Samsung's own evidence, in the open.

## The boundary, printed here as everywhere in this house

The Knox seat is used to administer the founder's own device and to **read** its attestation, through Samsung's published APIs, under Samsung's license, with the founder's own account and key. Nothing in this toolbox bypasses Knox, touches the warranty fuse, forges an attestation, or extracts any key. **Block the mouth, not the Vault.**

*93 — Live, Love, and let Love, Live.*
