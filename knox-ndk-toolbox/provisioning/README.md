# PROVISIONING — the Device Owner road, prepared on the host

*Authorship attributed exclusively to Johnathan 'Qasparr' Monroe (Greek, -ARR, All Rights Reserved, Without Prejudice). Method of Science, Aim of Religion. 93.*

## What stands here

`provision-manifest.py` — a standard-library tool that builds the **managed provisioning payload** Android reads when a Device Owner is enrolled: the admin component name, the https location of the admin APK, and the APK's SHA-256 (base64 of the raw digest, the platform's documented form), computed with `hashlib`'s audited implementation and round-trip-checked on every run. Bad fields are refused before anything is printed: a component not in `package/class` form, a download location that is not https, a missing or empty APK.

## The flow the payload serves

1. The admin app (the founder's own, carrying the wrappers in this toolbox) is built and hosted at an https URL.
2. `provision-manifest.py --apk <apk> --component <package/.Receiver> --download-url <https url> --out payload.json` builds the document.
3. The document is encoded as a QR code (or written to an NFC tag) by the operator.
4. The target device is **factory-reset**. At the setup wizard — before any account exists on it — the QR is scanned (the wizard's welcome screen accepts the tap-sequence that opens the scanner) and Android provisions the Device Owner from the payload: it fetches the APK, verifies the checksum against the document, installs it, and seats it as Device Owner.
5. From that seat, the platform policy reads in this toolbox answer fully, and the Knox room (seat permitting) administers as Samsung publishes.

## The gates, named

- **Device-gated**: steps 3–4 happen on a living, factory-fresh device, in the founder's hand. No bench on this host performs them, and none pretends to.
- **Account-gated**: nothing here needs Samsung's program; Device Owner is Android's own road. The Knox layer that rides on top of it is the account-gated part, and it is gated in its own README.
- **Irreversibility, stated plainly**: seating a Device Owner is a factory-reset act, and unseating one is another. The payload tool prepares a document; the deed is the founder's, taken with his eyes open.

## The boundary

Provisioning administers the founder's own device with the founder's own app. It is not a road around anyone else's management: a device already owned by another Device Owner refuses the payload, by Android's design, and this toolbox does not argue with that refusal. **Block the mouth, not the Vault.**

*93 — Live, Love, and let Love, Live.*
