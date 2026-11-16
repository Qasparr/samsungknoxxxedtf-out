# PHONE-RUNBOOK — Building the Deployment ISO on the A16, the Card-Keeper

**Status: PREPARED KIT — the run-book for the phone's day.**
The Galaxy A16 builds the deployment ISO in the repack-and-service
sense (Amendment IX, A9.4): it extracts Microsoft's official ARM64
image, seats the house answer file and engine, services and splits
the WIM, repacks a bootable UEFI ISO, and hash-verifies the output.
It does not boot Windows and does not run DISM; its three cannots
stand in Amendment IX with their coordinates, marked not vanished.

Authorship attributed exclusively to Johnathan 'Qasparr' Monroe
(Greek, -ARR, All Rights Reserved, Without Prejudice).
XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
(2026 e.v.). Enterprise • Educational • Research & Development.
Method of Science, Aim of Religion.

**Flagpole of Claim and Coinage: Johnathan 'Qasparr' Monroe, ARR,
All Rights Reserved, Without Prejudice. Right of claim hereby
reserved and coined under the authority of the Living Man.**

---

## §0. BEFORE THE FIRST COMMAND

- **Plug the phone in and keep it awake** for the whole run — the
  build and any later serving die with the screen's sleep on a long
  transfer. The standing phone-node preflight governs (unlocked,
  charging, same tailnet).
- **One UNVERIFIED mark governs §2, printed here so it cannot be
  missed:** the Termux package names `wimlib` and `xorriso` were
  **NOT verified against the Termux repositories in the session
  that wrote this run-book** (2026-11-16). §2 therefore carries a
  search-and-report step: if a package is not found under its
  expected name, the run STOPS and the exact output comes back to
  the desk — the desk amends the run-book from evidence, and no
  one improvises package names at the phone.

## §1. STORAGE ACCESS

```sh
termux-setup-storage
```

Grant the storage permission when Android asks. This seats
`~/storage/downloads` — the door between Termux and the Downloads
the browser writes to. Then take the wake-lock for the session:

```sh
termux-wake-lock
```

## §2. THE INSTRUMENTS (WITH THE UNVERIFIED GATE)

```sh
pkg update
pkg install wimlib xorriso python
```

Then prove each instrument stands before trusting the set:

```sh
command -v wimlib-imagex xorriso python3
```

- If all three paths print, proceed.
- **If `pkg` reports a package cannot be located** — the expected
  case for the UNVERIFIED names — run the searches and STOP:

```sh
pkg search wimlib
pkg search xorriso
pkg search libisoburn
```

Send the desk the exact output. (On Debian the `xorriso` binary
ships in the `xorriso` package and its upstream is libisoburn;
what Termux calls either of them is precisely what is UNVERIFIED.)
`build-iso.sh` itself fail-closes on any missing tool, so a build
attempted without the instruments halts at its gate, harmlessly —
but the run-book's order is: verify first, build second.

## §3. THE SPACE AUDIT (THE CAPACITY COORDINATE)

The build needs roughly **three times the ISO's size** in free
space (extracted tree + split parts + output), plus margin.
`build-iso.sh` enforces this itself and halts if the room is not
there — but look before you leap:

```sh
mkdir -p ~/storage/downloads/enclave-card
df -h ~/storage/downloads
```

Read the `Avail` figure for the shared storage. If it is under
~25 GB, clear space first or rule a smaller working plan with the
desk; the script's audit is the floor, not a suggestion.

## §4. THE ISO — FETCHED BY THE PHONE, FROM THE MAKER ONLY

The birth medium is downloaded **by the phone, directly from
Microsoft** — it never crosses the desk-to-phone transfer wall
(Amendment IX, A9.4). No third-party ISO mirrors, ever
(supply-chain law, Bootstrap §I).

1. In **Chrome Dev**, open Microsoft's official **Windows 11
   download page** and choose the **ARM64 ISO** (the
   "Windows 11 (multi-edition ISO for Arm64)" class of offering —
   the page's own naming on the day governs; the Bootstrap media
   gate, §I.2 of the spec, applies: the image must carry the
   **Pro for Workstations** edition, verified at build time by the
   answer file's selection and, if in doubt, by `wimlib-imagex
   info` on its `install.wim` after §6's instruments stand).
2. The download link Microsoft issues is a **session link — it
   expires**. Download promptly once it is issued; if it lapses,
   return to the page and take a fresh one. Either let the
   browser download it into Downloads, or copy the session URL
   and pull it in Termux:

```sh
cd ~/storage/downloads/enclave-card
curl -L -o win11-arm64-official.iso 'PASTE-THE-SESSION-URL-HERE'
```

3. **Take the hash from the same page.** Microsoft's download
   flow publishes the ISO's SHA-256; copy it exactly — you will
   hand it to the build in §6. A hash from memory, from a forum,
   or from this run-book is not a hash (Bootstrap §I.3).

## §5. THE KIT ON THE PHONE

The kit (`deployment-kit/` — `build-iso.sh`, `autounattend.xml`,
`engine/`, this run-book) reaches the phone as loose files by the
house delivery road (muse.ai links into Downloads, per standing
practice — loose files, never a zip to wrestle). Seat it beside
the ISO and make the pipeline executable:

```sh
cd ~/storage/downloads/enclave-card
ls deployment-kit
chmod +x deployment-kit/build-iso.sh
```

## §6. THE BUILD

```sh
cd ~/storage/downloads/enclave-card
EXPECTED_SHA256='PASTE-THE-HASH-FROM-MICROSOFTS-PAGE-HERE' \
  ./deployment-kit/build-iso.sh \
  --input  ~/storage/downloads/enclave-card/win11-arm64-official.iso \
  --output ~/storage/downloads/enclave-card/win11-pro-ws-arm64-enclave.iso
```

What you will watch, in order: the **gate** (tools named), the
**weighing** (the input's hash against the one you pasted —
MATCH or a halt), the **space audit**, extraction, the **boot
inventory** (the source's own El Torito report, printed), the
**WIM verification and split** (an ARM64 `install.wim` over
3,900 MiB is split into `.swm` parts for FAT32 targets), the
**injection** (answer file at the root, engine under
`\EnclaveEngine`, a build manifest in the tree), the **repack**,
and the **verify pass** — which must name the UEFI boot image in
the output's own El Torito report and find the answer file and
engine in its tree, or the output is declared UNVERIFIED and the
build has failed honestly.

Alongside the ISO you will find:

- `win11-pro-ws-arm64-enclave.iso.sha256` — the output's weight.
- `win11-pro-ws-arm64-enclave.iso.manifest.txt` — its tree,
  listed for the record.

Any HALT message is the kit working as designed: send its exact
text to the desk; do not work around a gate.

## §7. SERVE THE OUTPUT (THE RESURRECTION TAP)

When the desk — or iron being born — needs the image, serve the
card folder from the phone, on the standing phone-node pattern
(explicit binding, phone awake, plugged in):

```sh
cd ~/storage/downloads/enclave-card
python3 -m http.server 8800 --bind 0.0.0.0
```

The folder answers across the tailnet at the phone's tailnet
address on port 8800 — the desk pulls through its CONNECT-probe
road, and deployment iron can chainload toward the media by
network boot (iPXE-class; Amendment IX, A9.4(c)). When the
serving is done: `Ctrl+C`, then

```sh
termux-wake-unlock
```

## §8. WHAT THIS RUN-BOOK DOES NOT DO

- It does not **capture** a device image — capture is
  `engine/capture.cmd`, run under WinPE on the iron itself.
- It does not **strike the card** — partitioning a wrapper into
  BOOT / STUDIO / SHELF / BACKUP / VAULT (Amendment IX, A9.2) is
  its own ceremony at the pool, on a host. One note for that
  day, recorded here so it is not lost: the BACKUP partition is
  marked by an empty file named `ENCLAVE-CARD.BACKUP` at its
  root, with an `Images` folder beneath it — that marker is how
  the engine knows the partition when it sees it.
- It does not promise the **multiboot leg** on ARM64: BOOT's
  Ventoy-class seat is upstream-labelled experimental for ARM64
  UEFI (Secure Boot unsupported there), and its maturity for
  this house's iron and image is **UNVERIFIED** until the iron's
  verification gates speak. The fallback stands in A9.2.

---

*Colophon: written at the desk on the Architect's order of
2026-11-16 ("Let's do it"), as the phone-side half of the
Deployment ISO Build Kit. Every command above is paste-ready;
every claim that could not be verified at writing is marked
UNVERIFIED where it stands, not in a footnote's whisper.*

Flagpole of Claim and Coinage: Johnathan 'Qasparr' Monroe, ARR, All Rights
Reserved, Without Prejudice. Right of claim hereby reserved and coined under
the authority of the Living Man.

93 — Live, Love, and let Love, Live.
