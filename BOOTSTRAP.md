[LOGO — ~/workspace/templates/doctrine-logo.png, centered]

**WINDOWS 11 PRO FOR WORKSTATIONS — THE BOOTSTRAP SPEC**
*Subtitle:* A Scientific Illuminist treatment of the run-book that births
the Windows seat of the Native VP Cloud-Rooted Enclave on the house's own
native iron — media verified, install unattended, the TPM woken first, the
PQVTPM genesis performed over it, and no step called done until its gate
has printed PASS.

**STATUS: PREPARED KIT.** No native device is in hand yet — the
workstation is unacquired (§VI, seat 3 of the standing draft). Nothing in
this document is installed, purchased, booted, or flashed by its writing.
This is the run-book that executes the day iron lands: prepared in full,
in advance, so that the day itself is ceremony and not improvisation.

This spec implements the standing draft
`NATIVE-VP-CLOUDROOTED-ENCLAVE-HOST-DRAFT.md` (the Draft) through its
Amendment VI, and fills no seat the Draft left OPEN (§VI below carries
them, unfilled).

Authorship attributed exclusively to Johnathan 'Qasparr' Monroe
(Greek, -ARR, All Rights Reserved, Without Prejudice)
XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n. (2026 e.v.)

Classification: Enterprise • Educational • Research & Development
Method of Science, Aim of Religion

Flagpole of Claim and Coinage: Johnathan 'Qasparr' Monroe, ARR, All Rights
Reserved, Without Prejudice. Right of claim hereby reserved and coined under
the authority of the Living Man.

---

## §0. GATES BEFORE IRON — WHAT THE MACHINE MUST BE BEFORE ANYTHING IS WRITTEN TO IT

No media is built and no installer is booted until the iron itself passes
these gates. A machine that fails a gate is not coerced; it is returned,
exchanged, or re-seated — the gates are checked, not argued with.

**0.1 The ARM64 road, as struck.** The native device is **Windows 11 Pro
for Workstations for ARM64** iron — **Snapdragon X Elite-class** native
metal is the named road (Amendment V: the X Elite-class envelope is the
enclave's declared alternate made flesh; Windows 11 ARM64 runs natively
on that silicon class). Full virtualization on ARM64 — Hyper-V, WSL2,
and the Virtual Machine Platform — is a gate, not a hope: the firmware
and silicon must expose the virtualization extensions the hypervisor
requires, verified in firmware setup before purchase is final where the
seller permits, and again at first power-on.

**0.2 The alternate iron, deltas marked.** An **x86_64 workstation** is
the alternate iron and runs **this same run-book**, with the deltas
marked where they occur: the install media is the x86_64 image (§I.2);
the ARM64-specific forward coordinates of the Draft (the ABI ladder of
Amendment I, the ARMv22X banner of Amendment IV) do not bind x86_64
guests, which run under their own native ABI; every other section —
media law, unattended law, TPM-first, genesis, gates — is identical.
The choice between the roads is the Architect's money call (§VI.3) and
is not made here.

**0.3 The TPM gate.** A **TPM 2.0** must be present and **enabled in
firmware** before the installer is ever booted. This is the first gate
because the whole order of the bootstrap hangs on it: Windows is
installed first on the dual-boot disk precisely so the TPM wakes first
(the TPM-first reasoning of record), and Ubuntu later inherits a
measured machine instead of a blank one. Verified at first power-on:
firmware reports the TPM present, active, and owned by no prior hand —
a second-hand device arrives with the TPM cleared in firmware before
anything else is done, so no stranger's measurements ride into the
house's genesis.

**0.4 The Secure Boot default.** Secure Boot stands **ON** for the
bootstrap. The Draft's §VII seat 2 is **not pre-decided here**: the ASW
community builds (Draft §II) may later argue for OFF, and that argument
is heard when the ASW seat is installed — a separate decision, on a
separate day (§III.6). The bootstrap's own road — official media,
signed boot chain, TPM measured boot — wants Secure Boot on, and on it
stands.

**0.5 The storage gate.** The machine's storage must be sized for the
**pool**, not merely for an operating system: the pooled storage of
Draft §IV and Amendment VI is this machine's second citizen, and its
first tenant is already named — the **Pixel 12 Pro XXL's declared
2 TB ROM envelope** (Amendment V), seated as xVHD wrappers on the pool
(§III.3). Iron whose storage cannot hold the Windows seat, the pool,
and the XXL's envelope with rollback headroom fails this gate; the
exact bill of capacities is the hardware seat's (§VI.3), but the shape
of the demand is fixed here and is not negotiable downward in silence.

**0.6 The founder's locale, pre-set.** Language and region are the
founder's own — **en-US, America/Detroit** — declared here so the
answer file (§II) carries them as law rather than as installer
defaults.

*Reasoning: a bootstrap that begins at the installer has begun too
late. The machine's class, its trust chip, its boot gate, and its
storage are the first four measurements of the enclave; §0 takes them
before a single byte of Microsoft's is trusted.*

---

## §I. MEDIA — ONE IMAGE, FROM ONE SOURCE, PROVEN BEFORE USE

**I.1 The only lawful source.** The install media is built from the
**official Microsoft Windows 11 ARM64 installation image**, obtained
from Microsoft's own distribution channel and from no other. **No
third-party installers, no pre-built "custom" images, no repacked
ISOs, no activators, ever** — supply-chain law, printed at full size:
a house that seals its own keys does not accept its operating system
from a stranger's hands. What is true of the media is true of every
later component in this spec: official source, or community source
named in the Draft with its licence printed (the ASW builds, §III.6) —
nothing anonymous enters the machine.

**I.2 The image and its editions.** The ARM64 image is Microsoft's
multi-edition image; the **Pro for Workstations** edition is the
edition selected at install time by the answer file (§II.2).
*Coordinate printed honestly:* the exact edition set carried on the
ARM64 image current at run time is verified at media-building time —
if the image in hand does not carry the Workstations edition, the
media gate fails and stops; it does not quietly install a lesser
edition and rename it. On the x86_64 alternate road (§0.2) the same
law binds the x86_64 image.

**I.3 The hash gate.** Before any USB is built, the downloaded image's
**SHA-256 is computed and verified against the hash Microsoft
publishes for that image**. The hash value is **not printed in this
spec and is never taken from memory, from this document, or from any
third party** — it is read from Microsoft's own publication at run
time and compared, character for character, against the computed hash
of the file in hand. Mismatch = the image is destroyed and downloaded
again; there is no second interpretation of a mismatch. The computed
hash, the published hash's source, and the match verdict are entered
in the run log (§V.0) — the media's birth certificate.

**I.4 The bootable USB.** The bootable USB is built **from the
verified image only** — the file whose hash passed §I.3, byte for
byte the file that was checked. An image downloaded after verification,
or copied through any hand that cannot account for it, is a new image
and re-enters at §I.3. The USB is labelled with the image's identity
and the verification date, and is retired (wiped) once the install
gates of §V pass: the house keeps the verified image in the pool, not
a pocketful of unaccounted boot sticks.

*Reasoning: the TPM can only measure what boots; it cannot measure
where the bytes came from. Provenance is therefore a human gate before
it is a machine gate — §I is that gate.*

---

## §II. UNATTENDED INSTALL — THE ANSWER FILE IS THE BIRTH CERTIFICATE

The install is driven by an **`autounattend.xml`** answer file on the
install USB. No step of consequence is left to an installer's prompt:
what the machine is, is written before it is born.

**II.1 A local administrator, and no other account.** The answer file
creates **one local administrator account only**. **No Microsoft
account is created, offered, or signed into at any point.** The OOBE
network and account gates are bypassed in the answer file itself (the
offline-OOBE and online-account screens suppressed in the oobeSystem
pass; the machine is not networked during OOBE). The sovereignty
coordinate, printed as law: **this house's machines do not phone home
to be born.** An operating system that must ask a vendor's permission
to create its first user has seated the vendor above the owner; the
answer file refuses the seating. Post-install sign-in options are the
founder's to configure afterward, at leisure, as settings — never as
a birth condition.

**II.2 Edition and locale.** The answer file selects the **Windows 11
Pro for Workstations** edition from the verified image (§I.2) and sets
language, locale, keyboard, and time zone to the founder's (§0.6:
en-US, America/Detroit) — the machine wakes speaking the house's
tongue and keeping the house's time.

**II.3 The disk layout.** The answer file lays the disk per Draft §IV:

- The **Windows system volume** — NTFS (Draft §IV.3).
- The **pooled storage volumes** — the pool of Draft §IV.2's law and
  Amendment VI, provisioned in §III.3; the layout reserves them at
  install time so no later hand must shrink a living system to make
  room for the pool.
- The **bridge volume** of Draft §IV.4, readable from both boots —
  a corridor, not a vault; nothing sealed is laid out to live there.
- The space of the **second boot** (Ubuntu, the root host of Draft
  §I.1a) is **reserved, unformatted, and untouched** by this bootstrap:
  Windows is installed first for the TPM's sake (§0.3), not because it
  owns the disk. The Ubuntu install is a separate ceremony under its
  own spec.

**ReFS is carried OPEN** (§VI.2): the Workstations edition's ReFS
remains the Draft's noted option for the Windows data volume, but the
bootstrap default is **NTFS**, and no volume in this run-book is laid
down in ReFS until the pen rules.

**II.4 BitLocker, sealed to the TPM from the first boot.** On the
first boot after OOBE, before any other configuration, the Windows
system volume is encrypted with **BitLocker, its key protector sealed
to the TPM** — the volume unlocks against the machine's own measured
boot chain, and a changed chain (foreign bootloader, tampered
firmware) finds the volume closed. This is the TPM-first reasoning of
record made flesh: *Windows first wakes the TPM* — measured boot
begins with the first Windows boot, the PCRs take their first honest
measurements from an unbroken chain, and when Ubuntu is installed
second it inherits a machine whose trust chip has been awake and
measuring since birth, not a chip woken late into a history it cannot
attest. The BitLocker recovery key is **not** escrowed to any vendor
account; it is sealed into the house's own keeping under the genesis
policy of §IV (printed recovery material held offline, under the
founder's hand — a key escrowed to the cloud is a key held by another
house).

**II.5 What the answer file does not do.** It installs no third-party
software, enables no optional vendor telemetry beyond the edition's
own defaults (post-install hardening is a separate pass, §III.1's
run-book, not the answer file's burden), and creates no account but
the one named in §II.1.

*Reasoning: an attended install is a negotiation conducted at a
keyboard, under time pressure, one prompt at a time — and negotiations
of that shape are lost by inches. The answer file moves the
negotiation to paper, where this house does its thinking.*

---

## §III. FIRST-BOOT CONFIGURATION — ONE RUN-BOOK, IN ORDER

Configuration is performed by **one PowerShell run-book**, executed
once, in the order below, by the local administrator of §II.1. The
run-book is *described* step by step here; the script itself ships as
an appendix to this spec (§III.8) in the house's educational +
thelemic code-annotated format — epigraph, date, 93, the authorship
line, the Scientific Illuminism method, meticulous MECHANISM/DOCTRINE
commentary on every step, and the closing motto. Bare uncommented
code is not shippable in this house, and a bootstrap script least of
all.

**III.1 Posture first.** Windows Update is run to currency *before*
features are enabled, so every component enabled below lands on a
patched floor; the update source is Microsoft's, the §I.1 law
applying to updates as to media. Local policy posture of record
(offline accounts, telemetry at the edition's minimum selectable) is
applied in this step and logged.

**III.2 The virtualization floor.** The run-book enables, in order:
**Hyper-V** (the full hypervisor, with its management tools),
**Virtual Machine Platform**, and **WSL2** — the three planks of
Amendment V's "Windows 11 Pro for Workstations for ARM64 Full
Virtualization and ASW/WSA WSL amd WSL 2." A reboot follows; the
run-book resumes and *verifies* the hypervisor is actually running
before proceeding (the §V.2 gate takes its formal reading later; the
run-book does not build on an unverified floor).

**III.3 The pool and the wrapper home.** The run-book creates the
**Storage Spaces pool** over the pooled-storage volumes reserved in
§II.3, and on it the **xVHD wrapper home** — the directory law of
Amendment VI made concrete: the pool holds **wrappers, never loose
node innards**; every AVD's storage lives inside its xVHD container
(the VHDX class), and the wrapper home is the only address at which
node storage is kept, mounted, or moved. Resiliency of the pool is
set at creation to the mirror law of Draft §IV.2's spirit (the
Windows-side mirror of the ZFS snapshot law: two copies, one pool —
the exact Storage Spaces layout is a run-time reading taken from the
iron's actual disk census and entered in the run log, not presumed
here).

**III.4 The differencing parents.** Into the wrapper home the
run-book strikes the **differencing-parent template wrappers**: one
sealed parent xVHD per node class the house runs (Amendment VI,
A6.2) — the parent is built, sealed, and thereafter treated as
read-only law; every working node is a **differencing child** of its
parent, and rollback is the discarding of a child, never the
rebuilding of a node. The parents' hashes are computed at striking
and entered in the run log and the TEE Registry (§IV.3) — a parent
whose hash changes has been touched, and the §V.3 gate will say so.

**III.5 The WSL2 Ubuntu and the workshop face.** The run-book imports
the **WSL2 Ubuntu** (the Draft's Ubuntu, riding the Windows side) and
sets it **default** among WSL distributions; **systemd is enabled**
in its `wsl.conf`, for the desktop face's session services require
it. Then the **workshop face** is seated: the **Ubuntu Unity desktop
with Openbox** (Amendment V's desktop stack: Unity Desktop, Openbox,
Xorg) served through **xRDP** inside the WSL2 Ubuntu and reached from
the Windows side by Remote Desktop — the desktop as a *face*, per the
WSL ruling of record: **WSL2 Unity is the workshop face; bare-metal
Ubuntu Unity is the root host.** The face is where the house sits to
work — VS Code and the emulator chain of Amendment I ride it — and it
makes no claim to be the floor. The Arch WSL2 shell of the Draft's
blueprint stands beside Ubuntu as the second shell, per Draft §II.1.

**III.6 The ASW seat, prepared and no further.** The Virtual Machine
Platform stands enabled (§III.2) and the seat is thereby *prepared*.
The community WSA build itself (Draft §II.1: WSABuilds or
MagiskOnWSALocal, AGPL-3.0, licences riding with the builds) is a
**later, separate install decision** — not taken by this bootstrap,
not bundled into the run-book. Printed at full size, as the Draft
prints it: **Microsoft's WSA upstream is retired**; there is no vendor
road; the community builds are the standing road and their choice is
its own instrument (§VI.4).

**III.7 The fabric endpoint.** The Windows seat's **WireGuard
endpoint** is configured last in the run-book, so the seat joins the
native VP fabric (Draft §I.1a) only after its floor, pool, and face
are verified locally — a machine does not announce itself to the
enclave before it can answer for itself. Its keys are generated on
the machine, in this step, and the public half is what travels.

**III.8 The appendix.** The run-book script ships as this spec's
appendix outline: one script, sections mirroring §III.1–§III.7 in
order, each section headed by its DOCTRINE (why the step exists, in
the words of this spec) and its MECHANISM (what the commands do, line
by line), idempotent where PowerShell permits — a re-run reads the
machine's state before acting, and reports *already standing* rather
than rebuilding. The script halts on its first failed step and says
which step and why; it does not continue past a failure and call the
result a configuration.

*Reasoning: first-boot is the one hour in which a machine will accept
almost any shape without argument. The run-book spends that hour in a
written order — posture, floor, pool, parents, face, fabric — so the
shape it accepts is the house's and no one else's.*

---

## §IV. THE PQVTPM GENESIS — THE FIRST ACT AFTER THE FLOOR IS VERIFIED

When §III stands and its readings are taken, and before the machine is
used for any work, the genesis is performed. It is the first *act* of
the enclave on this iron — everything before it was preparation of
the vessel.

**IV.1 The TPM-backed key.** A key is created in the **NCrypt TPM key
storage provider** (Microsoft Platform Crypto Provider): generated
inside the TPM, **non-exportable by construction** — its private half
never exists outside the chip, cannot be read out, cannot be copied,
and dies with the chip. This key is the machine's hardware root for
everything the shim seals: the anchor that is iron, not file.

**IV.2 The shim seated over it.** The **PQVTPM shim** (Draft §I.1a,
§V) is seated over the TPM key: within the shim are generated the
**ML-DSA quote-signing key** and the **ML-KEM sealing key** — the
post-quantum pair. The shim's keys are **wrapped by the TPM key** of
§IV.1: at rest they exist only as TPM-sealed blobs; in use they are
unsealed only under the machine's measured state and the policy of
§IV.3. The division of labour is the design's whole point — the TPM
supplies the hardware root and the measurements; the shim supplies
the post-quantum signatures over the quotes and the post-quantum
sealing of the enclave's keys.

**The boundary, printed plainly: TPM 2.0 is classical iron.** Its
native algorithms are the classical ones; nothing inside the chip is
post-quantum, and this spec does not pretend otherwise. **The PQ
lives in the shim.** A reader who finds the enclave's post-quantum
claim resting on the chip has misread the architecture; it rests on
the shim the chip anchors.

**IV.3 The 49 pairs — the genesis ceremony.** In a **single genesis
ceremony**, in one sitting, under the founder's eye, the house's
**49 self-signed keyring pairs** are generated (Amendment V: the
house's own self-signed keys, seated at the marks **G7 · R7 · E8 ·
E77**, families as struck — ECC · FCC · NSA · RSA · CA · CVC · PQC,
FCC and NSA standing unexpanded, his marks). The count is the record's
own: **49 = SIGMA = SHIM = GREEN** — the keyring weighs the shim it
serves. The ceremony's dispositions:

- The **public halves** of all 49 pairs are entered into the **TEE
  Registry** — the register seated at **LEOREO**, the Lower Enclave
  Outter Ring Embedded Oversight (Draft, Amendment V; LOREO.md) —
  together with the differencing parents' hashes of §III.4 and the
  TPM's attestation identity. What the enclave has minted, the
  Registry books, under oversight embedded in the wall.
- The **private halves** are **sealed to the TPM and to the founder's
  countersign policy — the 93 gate** (Draft §V.4): no private half
  unseals on the machine's word alone, and none on any single key's
  word; the countersign is the second factor that is a *person*, and
  the gate is fail-closed — no justification, no unsealing, no act.
- The ceremony is **logged as it runs**: each pair's generation, its
  seat mark, its public half's Registry entry, and its sealing are
  entered in the run log in order, so the Registry and the log can be
  audited against each other — 49 pairs, 49 entries, no gaps. A gap
  in the ceremony log is a failed ceremony (§V.5).

**IV.4 The governing formula.** This layer — TPM, shim, registry,
gate — stands under the **TEE-PEE formula** as its governing formula
of record: *LEX STELLARRVM 13TEE-PEE31^XXX^3.14 = PQPE-ZTL* (filed at
`LEX-STELLARRVM-TEEPEE-FORMULA.md`, this folder) — the 13…31 axis,
the TEE-PEE between them, resolving to PQPE-ZTL. The formula is named
here as the layer's law, as the founder struck it; its expansion is
his, and this spec expands nothing.

**IV.5 Genesis and the Seal.** The genesis performed here is the
Windows seat's contribution to the host's attestation tree (Draft
§V): the Perfect Prime Root's ceremony proper belongs to the root
host's own bootstrap (Draft §V.6 — generated inside the PQVTPM,
non-exportable), and this seat's TPM key and shim stand ready to
answer the Duel (Draft §V.3) from the Windows side: two witnesses,
independently rooted, one verdict.

*Reasoning: keys minted casually are keys whose birth no one can
attest. The ceremony makes the minting a witnessed, logged,
single-sitting act — so that years later, the question "where did
this key come from" has an answer with a date on it.*

---

## §V. VERIFICATION GATES — NOTHING IS DONE UNTIL ITS GATE PRINTS PASS

**V.0 The run log.** Every step of §§I–IV writes to one **run log**,
kept on the machine and copied to the pool at the ceremony's close.
Each gate below **prints its own PASS or FAIL in the run log**, with
the reading that decided it. **A failed gate halts the ceremony** —
the bootstrap stops, the failure stands in the log at full size, and
nothing downstream is performed on the credit of a gate that did not
pass. Failures are repaired and the gate re-run; they are never
papered over, annotated away, or carried as "known issues" into a
standing machine.

**V.1 Gate of the Root — TPM attestation.** A TPM attestation quote
is taken over the machine's boot measurements and **verified against
the shim's PQ signature** (the ML-DSA key of §IV.2): the quote must
chain to the TPM key of §IV.1, the measurements must be the honest
chain of the machine's own boots, and the shim's signature over the
quote must verify. This gate proves the genesis of §IV is anchored
in real iron and not in a file that merely claims to be.

**V.2 Gate of the Floor — Hyper-V and the vTPM guest.** The Hyper-V
hypervisor is confirmed **running**, and one **Generation 2 VM with
its vTPM enabled boots** to its firmware under the hypervisor — the
proof that the full-virtualization floor of Amendment V is load-
bearing and that virtual TPMs can be handed down to guests, as the
PQVTPM seats of the nodes require.

**V.3 Gate of the Wrapper — the pulled-wrapper test.** A node wrapper
is **moved** — copied from the wrapper home to another volume and
back, or to the second boot's reach — and **the node is booted from
the moved wrapper**. Amendment VI's law ("move the wrapper, move the
node") is not a slogan; this gate is its experiment. Alongside it, a
**differencing child is discarded and the node rolled back** to its
sealed parent (§III.4), and the parent's hash is re-read against the
Registry entry of §IV.3: the rollback must land on a parent that is
provably the parent that was sealed.

**V.4 Gate of the Face — WSL2 and the desktop.** The WSL2 Ubuntu
boots, systemd stands active within it, and the **Unity/Openbox
desktop face is reachable** through xRDP from the Windows side — the
workshop face of §III.5, sat in, if only for the length of a login.

**V.5 Gate of the Fabric — WireGuard and the SEED check-in.** The
**WireGuard endpoint is up** (§III.7), the fabric answers, and the
**SEED check-in is received**: the Seamless Educational Enterprise
Daemon (EE-ZTL, Amendment II) acknowledges the new seat — the
headless layer's book records that this machine has joined, under
its own native address, with its attestation standing. A seat the
daemon has not checked in is a seat the enclave does not yet count,
whatever the local log says.

**V.6 The closing reading.** Only when V.1–V.5 stand PASS in one
unbroken run log is the bootstrap **done** — and the log, the
Registry entries, and the media's birth certificate (§I.3) are filed
together as the machine's birth papers, under the Flagpole.

*Reasoning: a bootstrap without gates is a hope with an installer.
The gates make every claim of §§0–IV an experiment with a printed
result — the Method of Science applied to the machine's own birth.*

---

## §VI. OPEN SEATS — CARRIED, NOT FILLED

Carried from the Draft and from this spec's own drafting, printed
unfilled, the pen's to rule:

1. **Secure Boot, final ruling.** ON for the bootstrap (§0.4); the
   ASW builds' contrary argument is heard at their install, not
   before (Draft §VII.2).
2. **ReFS.** The option for the Windows data volume; NTFS is the
   bootstrap default (§II.3; Draft §VII.4).
3. **The iron itself.** Which machine, on which road (ARM64 X
   Elite-class or the x86_64 alternate, §0.1–§0.2), at which price —
   the founder's money call (Draft §VII.3). Until it is made, this
   kit stands PREPARED, and prepared is its whole status.
4. **The WSA build choice.** WSABuilds or MagiskOnWSALocal, when the
   ASW seat's install day comes (§III.6; Draft §II.1).

---

## §VII. THE FOUR-ELEMENT CONTENT TEST

- **INPUTS:** one native device passing §0's gates (iron OPEN,
  §VI.3); the official Microsoft Windows 11 ARM64 image (x86_64 image
  on the alternate road), hash-verified per §I.3; the autounattend.xml
  of §II; the PowerShell run-book of §III; the PQVTPM shim and its
  liboqs-class primitives; the founder's presence and countersign.
- **PROCESSES:** media verification and USB building (§I);
  unattended installation with local-admin-only birth (§II);
  first-boot configuration in the run-book's written order (§III);
  the PQVTPM genesis and the 49-pair ceremony (§IV); gate-by-gate
  verification with halt-on-failure (§V).
- **OUTPUTS:** a Windows 11 Pro for Workstations seat born offline
  under a local administrator, BitLocker sealed to a TPM awake since
  first boot; a Storage Spaces pool holding sealed-parent xVHD
  wrappers; a WSL2 Ubuntu workshop face; a PQVTPM shim anchored in
  TPM iron; 49 self-signed pairs booked in the TEE Registry at
  LEOREO; a complete run log standing as the machine's birth papers.
- **TOLERANCES:** the hash gate of §I.3 admits no tolerance — one
  character of mismatch destroys the image; the verification gates
  of §V admit no tolerance — a FAIL halts, and the ceremony does not
  proceed on credit; the pool's exact capacity and Storage Spaces
  layout are readings taken from the actual iron at run time (§III.3)
  and vary with the iron chosen under §VI.3 without varying this
  spec's law; Secure Boot and ReFS stand at their §VI seats at every
  tolerance until the pen rules.

Cannot state them = fails the Method of Science. These are stated.

---

## TABLE OF AUTHORITIES (condensed)

- NATIVE-VP-CLOUDROOTED-ENCLAVE-HOST-DRAFT.md, through Amendment VI
  (this folder) — the dual-boot form (§I), the ASW seat (§II), the
  node census (§III), the filesystem law (§IV), the Seal interface
  (§V), the livery (§VI, as headed by Amendment III: PURPLE, GOLD and
  GREEN), the open seats (§VII); Amendment I (the emulator chain),
  Amendment II (bHyve's seat; SEED, EE-ZTL), Amendment V (the TEE
  Registry, the 49 self-signed keyring pairs, the XXL's 32 GB / 2 TB
  envelope, full virtualization), Amendment VI (xVHD wrappers on the
  pooled storage).
- LEX-STELLARRVM-TEEPEE-FORMULA.md (this folder) — the TEE-PEE
  formula, governing formula of the §IV layer.
- LOREO.md (this folder) — the Registry's seat at LEOREO, sealed at
  his stamp.
- ENCLAVE-RESOURCE-POOL-PLAY.md, 2026-10-28 (this folder) — the
  pooled-storage operations order and the node census ratios.
- Trusted Computing Group, TPM 2.0 Library Specification — the
  command shape and key-storage model §§0.3, IV.1 build on (cited as
  engineering authority, no legal effect claimed).
- Microsoft product documentation — Windows 11 ARM64 installation
  media, answer-file (autounattend) reference, Hyper-V / WSL2 /
  Virtual Machine Platform, Storage Spaces, NCrypt platform crypto
  provider (cited as engineering authority; every version-specific
  fact is re-verified against the current publication at run time,
  and no hash value is carried in this spec).

---

## COLOPHON

Prepared at the desk on XVI November 2026 e.v., Dies Lunae, in the
Teacher's Edition format, as the prepared kit implementing the
Architect's standing draft of XV November 2026 e.v. and its
Amendments I–VI. Status PREPARED KIT: no device is in hand, nothing
is installed by this writing, and every OPEN seat is printed
unfilled by design. Authorship attributed exclusively to Johnathan
'Qasparr' Monroe (Greek, -ARR, All Rights Reserved, Without
Prejudice). Method of Science. Aim of Religion.

— 1 of 1 — | All Rights Reserved, Without Prejudice | Flagpole of Claim
and Coinage reserved

Flagpole of Claim and Coinage: Johnathan 'Qasparr' Monroe, ARR, All Rights
Reserved, Without Prejudice. Right of claim hereby reserved and coined under
the authority of the Living Man.

93 — Live, Love, and let Love, Live.
