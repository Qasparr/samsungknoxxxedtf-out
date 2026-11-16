#!/usr/bin/env bash
# ============================================================================
# BUILD-ISO — the Enclave deployment-ISO repack pipeline
# ----------------------------------------------------------------------------
# "Do what thou wilt shall be the whole of the Law."
#   The birth medium is not downloaded twice and trusted twice; it is
#   fetched once from its maker, weighed once against its maker's own
#   hash, and thereafter handled only by instruments that print what
#   they did. This script is such an instrument.
#
# Authorship attributed exclusively to Johnathan "Qasparr" Monroe
# (Greek, -ARR, All Rights Reserved, Without Prejudice).
# XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
# (2026 e.v.). Method of Science, Aim of Religion. 93.
#
# MECHANISM — what this script does, in order, and why:
#   0. GATES. Every tool the pipeline needs is named and required up
#      front (xorriso, wimlib-imagex, sha256sum, and the POSIX
#      furniture). A missing tool halts the build before a single
#      byte moves: fail-closed is the house posture, because a
#      pipeline that improvises around a missing instrument produces
#      media nobody can swear to.
#   1. THE WEIGHING. The input ISO's SHA-256 is computed and compared,
#      character for character, against the hash the OPERATOR supplies
#      from Microsoft's own download page at run time (--expected-sha256
#      or $EXPECTED_SHA256). No hash is hardcoded anywhere in this
#      file, by law: a hash remembered is a hash that can rot, and the
#      Bootstrap spec (WIN11-PRO-WS-BOOTSTRAP.md §I.3) forbids taking
#      one from memory or from the spec itself. Mismatch = halt.
#   2. THE SPACE AUDIT. The build needs room for the extracted tree,
#      the split WIM parts, and the output image — roughly three
#      times the input's size, plus a margin. On the A16 (the
#      Card-Keeper of Amendment IX) this audit is the capacity
#      coordinate made executable: if the phone cannot hold the
#      build, the script says so before it starts, not after.
#   3. EXTRACTION. xorriso's osirrox extracts the source tree whole.
#      Nothing is mounted (Termux has no loop mounts to give), and
#      nothing in the source is modified — the tree is a copy.
#   4. BOOT INVENTORY. The source's own El Torito report is captured
#      and printed into the build log, and the tree is searched for
#      the boot images the source itself carries (etfsboot.com for
#      the BIOS entry where present, efisys.bin / efisys_noprompt.bin
#      for the UEFI entry). The repack reuses THE SOURCE'S OWN boot
#      images — boot files are never fabricated, borrowed, or
#      substituted. An ARM64 image is UEFI-only and will show no
#      etfsboot.com; the pipeline adapts to what the source carries
#      and dies if it finds no UEFI boot image at all.
#   5. WIM SERVICE, MEDIA-SIDE. install.wim is verified with
#      wimlib-imagex (a corrupt WIM halts the build). The deployment
#      engine is NOT written into the WIM. DOCTRINE: the engine rides
#      ON THE MEDIA, in the open, where it can be read, diffed, and
#      re-struck without servicing an image — media-side is the
#      simpler and the auditable choice, and it is the choice of
#      record for this kit. If install.wim exceeds the FAT32 file
#      limit's neighbourhood, it is SPLIT with wimlib into .swm
#      parts (the card's BOOT and SHELF partitions include FAT32
#      targets; a 4 GiB single file would be refused there), and the
#      unsplit original is removed from the tree.
#   6. INJECTION. The house autounattend.xml is seated at the media
#      root, where Windows Setup looks for it first; the engine
#      (deploy.cmd, capture.cmd) is seated under \EnclaveEngine; and
#      a BUILD-MANIFEST.txt is written into the root recording the
#      input's name and hash, so the finished medium carries its own
#      provenance in its own tree.
#   7. REPACK. xorriso (mkisofs emulation) writes the output with the
#      source's volume label, ISO9660 level 3 (multi-extent, so no
#      file is truncated by the old 4 GiB extent law), Joliet, and
#      UDF — the bridge Windows media itself uses — and an El Torito
#      catalog rebuilt on the source's own boot images.
#   8. VERIFY, OR IT DID NOT HAPPEN. The output's own El Torito
#      report must name the UEFI boot image; the output's file
#      listing must show autounattend.xml and the engine; and the
#      output's SHA-256 is written beside it as <output>.sha256.
#      Any failed check halts with the output marked UNVERIFIED.
#
# DOCTRINE: this script assembles and services installation media.
# It captures nothing and deploys nothing; capture and deployment
# belong to the engine (engine/capture.cmd, engine/deploy.cmd) on
# the iron's own day. The ISO it consumes is downloaded by the
# operator — on the A16, BY THE PHONE, directly from Microsoft
# (Amendment IX, A9.4) — never fetched by this script, so that the
# supply chain has exactly one hop and it is the maker's.
#
# USAGE:
#   EXPECTED_SHA256=<hash-from-microsoft> ./build-iso.sh \
#       --input  /path/to/official-win11-arm64.iso \
#       --output /path/to/win11-pro-ws-arm64-enclave.iso
#   Options: --expected-sha256 HEX   (or $EXPECTED_SHA256)
#            --kit-dir DIR           (default: this script's folder)
#            --work-root DIR         (default: the output's folder)
#            --split-threshold-mib N (default: 3900; 0 = never split)
#            --keep-work             (keep the extracted tree; audit)
# ============================================================================

set -euo pipefail

# --- small instruments -------------------------------------------------------
# die: the fail-closed exit. Every gate in this script ends here when
# its condition is not met; nothing limps past a failed gate.
die() { printf 'BUILD-ISO: HALT — %s\n' "$*" >&2; exit 1; }
# note: a step banner, so the build log reads as the ceremony it is.
note() { printf '\n== %s ==\n' "$*"; }
# need: require one command by name, or halt before any byte moves.
need() { command -v "$1" >/dev/null 2>&1 || die "required tool not found: $1 (see PHONE-RUNBOOK.md)"; }

# --- arguments ---------------------------------------------------------------
INPUT="" OUTPUT="" EXPECTED="${EXPECTED_SHA256:-}"
KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_ROOT="" SPLIT_THRESHOLD_MIB=3900 KEEP_WORK=0
while [ $# -gt 0 ]; do
  case "$1" in
    --input)              INPUT="${2:-}"; shift 2 ;;
    --output)             OUTPUT="${2:-}"; shift 2 ;;
    --expected-sha256)    EXPECTED="${2:-}"; shift 2 ;;
    --kit-dir)            KIT_DIR="${2:-}"; shift 2 ;;
    --work-root)          WORK_ROOT="${2:-}"; shift 2 ;;
    --split-threshold-mib) SPLIT_THRESHOLD_MIB="${2:-}"; shift 2 ;;
    --keep-work)          KEEP_WORK=1; shift ;;
    -h|--help)            sed -n '2,86p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *)                    die "unknown argument: $1" ;;
  esac
done
[ -n "$INPUT" ]  || die "--input is required"
[ -n "$OUTPUT" ] || die "--output is required"
[ -f "$INPUT" ]  || die "input ISO not found: $INPUT"
[ "$INPUT" != "$OUTPUT" ] || die "input and output must differ (the source is never overwritten)"

AUTOUNATTEND="$KIT_DIR/autounattend.xml"
ENGINE_DIR="$KIT_DIR/engine"
[ -f "$AUTOUNATTEND" ]        || die "autounattend.xml not found in kit dir: $KIT_DIR"
[ -f "$ENGINE_DIR/deploy.cmd" ]  || die "engine/deploy.cmd not found in kit dir: $KIT_DIR"
[ -f "$ENGINE_DIR/capture.cmd" ] || die "engine/capture.cmd not found in kit dir: $KIT_DIR"

note "0 · GATES — every instrument named before any byte moves"
for tool in xorriso wimlib-imagex sha256sum find stat awk sed grep sort cp rm mkdir df date; do
  need "$tool"
done
printf 'tools: xorriso %s · wimlib-imagex present · sha256sum present\n' \
  "$(xorriso --version 2>/dev/null | awk 'NR==1{print $NF}')"

note "1 · THE WEIGHING — the input against the maker's own hash"
# The expected hash comes from the operator, read off Microsoft's page
# at run time. Normalise case and whitespace, then demand the shape of
# a SHA-256 before any comparison is trusted.
EXPECTED="$(printf '%s' "$EXPECTED" | tr -d '[:space:]' | tr 'A-F' 'a-f')"
printf '%s' "$EXPECTED" | grep -Eq '^[0-9a-f]{64}$' \
  || die "no valid expected SHA-256 supplied (--expected-sha256 or \$EXPECTED_SHA256); read it from Microsoft's download page at run time — never from memory"
ACTUAL="$(sha256sum "$INPUT" | awk '{print $1}')"
printf 'input   : %s\nsha256  : %s\nexpected: %s\n' "$INPUT" "$ACTUAL" "$EXPECTED"
[ "$ACTUAL" = "$EXPECTED" ] || die "HASH MISMATCH — the input is not the maker's image. Halted; nothing extracted."
printf 'verdict : MATCH — the input is weighed and stands.\n'

note "2 · THE SPACE AUDIT — the capacity coordinate, made executable"
IN_BYTES="$(stat -c %s "$INPUT")"
OUT_DIR="$(cd "$(dirname "$OUTPUT")" && pwd)"
# Room for: extracted tree (~1x), split parts (~1x), output (~1x),
# plus a 1 GiB margin for the repack's own breathing.
NEED_KB=$(( IN_BYTES * 3 / 1024 + 1048576 ))
AVAIL_KB="$(df -Pk "$OUT_DIR" | awk 'NR==2{print $4}')"
printf 'input size: %s bytes · required free: %s KiB · available: %s KiB\n' \
  "$IN_BYTES" "$NEED_KB" "$AVAIL_KB"
[ "$AVAIL_KB" -ge "$NEED_KB" ] \
  || die "insufficient free space at $OUT_DIR — the build does not start what it cannot finish"

# The work tree lives beside the output unless the operator rules
# otherwise; it is removed on exit unless --keep-work was given.
WORK_DIR="$(mktemp -d "${WORK_ROOT:-$OUT_DIR}/.enclave-iso-build.XXXXXX")"
cleanup() {
  if [ "$KEEP_WORK" -eq 1 ]; then
    printf 'work tree kept for audit: %s\n' "$WORK_DIR"
  else
    rm -rf "$WORK_DIR"
  fi
}
trap cleanup EXIT
TREE="$WORK_DIR/tree"
mkdir -p "$TREE"

note "3 · EXTRACTION — the source tree, copied whole, never mounted"
xorriso -osirrox on -indev "$INPUT" -extract / "$TREE" >/dev/null 2>&1 \
  || die "xorriso extraction failed — the input may not be a readable ISO image"

note "4 · BOOT INVENTORY — the source's own boot images, and no others"
# The source's El Torito report is evidence: print it into the log so
# the repack's catalog can be compared against the maker's own.
BOOT_REPORT="$(xorriso -indev "$INPUT" -report_el_torito as_mkisofs 2>/dev/null || true)"
printf '%s\n' "$BOOT_REPORT" | sed 's/^/  source boot: /'
# Locate the boot images inside the extracted tree, case-insensitively
# (media name-cases vary; the law does not).
rel_of() { printf '%s' "${1#"$TREE"/}"; }
EFI_BIN=""
if printf '%s' "$BOOT_REPORT" | grep -qi 'efisys_noprompt'; then
  EFI_BIN="$(find "$TREE" -iname 'efisys_noprompt.bin' | sort | head -n 1 || true)"
fi
if [ -z "$EFI_BIN" ]; then
  EFI_BIN="$(find "$TREE" -iname 'efisys.bin' | sort | head -n 1 || true)"
fi
[ -n "$EFI_BIN" ] || die "no UEFI boot image (efisys*.bin) found in the source tree — this pipeline builds UEFI media only"
BIOS_BIN="$(find "$TREE" -iname 'etfsboot.com' | sort | head -n 1 || true)"
EFI_REL="$(rel_of "$EFI_BIN")"
printf 'UEFI boot image: %s\n' "$EFI_REL"
if [ -n "$BIOS_BIN" ]; then
  printf 'BIOS boot image: %s (carried as the catalog’s first entry, as the maker laid it)\n' "$(rel_of "$BIOS_BIN")"
else
  printf 'BIOS boot image: none — UEFI-only media (the ARM64 shape), catalog carries the UEFI entry alone\n'
fi
# The volume label is the maker's; the repack keeps it, so the house
# medium answers to the same name as the image it was weighed as.
LABEL="$(xorriso -indev "$INPUT" -pvd_info 2>/dev/null | sed -n 's/^Volume Id[[:space:]]*:[[:space:]]*//p' | head -n 1 | sed 's/[[:space:]]*$//')"
[ -n "$LABEL" ] || LABEL="ENCLAVE_WIN11"
printf 'volume label   : %s\n' "$LABEL"

note "5 · WIM SERVICE — media-side engine; the WIM verified, then split if FAT32 demands"
WIM="$(find "$TREE" -ipath '*/sources/install.wim' | sort | head -n 1 || true)"
[ -n "$WIM" ] || die "no sources/install.wim in the tree — this is not Windows installation media"
wimlib-imagex info "$WIM" >/dev/null 2>&1 \
  || die "wimlib cannot read install.wim — the image fails verification. Halted."
WIM_BYTES="$(stat -c %s "$WIM")"
printf 'install.wim verified by wimlib: %s bytes\n' "$WIM_BYTES"
if [ "$SPLIT_THRESHOLD_MIB" -gt 0 ] && [ "$WIM_BYTES" -gt $(( SPLIT_THRESHOLD_MIB * 1048576 )) ]; then
  SWM_BASE="${WIM%.wim}.swm"
  printf 'install.wim exceeds %s MiB — splitting to %s (parts of %s MiB) for FAT32 media targets\n' \
    "$SPLIT_THRESHOLD_MIB" "$SWM_BASE" "$SPLIT_THRESHOLD_MIB"
  # --check writes integrity tables into every part, so a part that
  # rots on a card is detected at apply time, not discovered by it.
  wimlib-imagex split "$WIM" "$SWM_BASE" "$SPLIT_THRESHOLD_MIB" --check \
    || die "wimlib split failed"
  rm -f "$WIM"
  find "$(dirname "$WIM")" -maxdepth 1 -iname 'install*.swm' | sort | sed 's/^/  part: /'
else
  printf 'no split required (threshold %s MiB)\n' "$SPLIT_THRESHOLD_MIB"
fi

note "6 · INJECTION — the answer file at the root, the engine in the open"
cp "$AUTOUNATTEND" "$TREE/autounattend.xml"
mkdir -p "$TREE/EnclaveEngine"
cp "$ENGINE_DIR/deploy.cmd" "$ENGINE_DIR/capture.cmd" "$TREE/EnclaveEngine/"
# The medium carries its own provenance: what it was built from, and
# the hash that input was weighed at, inside its own tree.
{
  printf 'ENCLAVE DEPLOYMENT MEDIA — BUILD MANIFEST\n'
  printf 'built (UTC)   : %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'input file    : %s\n' "$(basename "$INPUT")"
  printf 'input sha256  : %s (operator-verified against the maker)\n' "$ACTUAL"
  printf 'answer file   : autounattend.xml (house, Bootstrap §II)\n'
  printf 'engine        : EnclaveEngine/deploy.cmd · EnclaveEngine/capture.cmd (media-side, not in WIM)\n'
  printf 'authorship    : Johnathan Qasparr Monroe, ARR, All Rights Reserved, Without Prejudice\n'
} > "$TREE/BUILD-MANIFEST.txt"
printf 'seated: /autounattend.xml · /EnclaveEngine/deploy.cmd · /EnclaveEngine/capture.cmd · /BUILD-MANIFEST.txt\n'

note "7 · REPACK — the maker's label, the maker's boot images, a new body"
# Boot arguments are assembled from what the source actually carries:
# both entries when the BIOS image exists (the maker's own layout),
# the UEFI entry alone when it does not (the ARM64 shape).
BOOT_ARGS=()
if [ -n "$BIOS_BIN" ]; then
  BOOT_ARGS+=( -b "$(rel_of "$BIOS_BIN")" -c boot/boot.cat
               -no-emul-boot -boot-load-size 8
               -eltorito-alt-boot -e "$EFI_REL" -no-emul-boot )
else
  BOOT_ARGS+=( -eltorito-boot "$EFI_REL" -eltorito-catalog boot/boot.cat
               -no-emul-boot )
fi
# -iso-level 3: multi-extent files, so nothing is truncated by the
# classic 4 GiB extent law. -udf -joliet: the bridge the maker's own
# media uses, so Windows reads long names from the layer it expects.
xorriso -as mkisofs \
  -iso-level 3 -full-iso9660-filenames -joliet -udf \
  -volid "$LABEL" -appid "ENCLAVE_DEPLOYMENT" \
  "${BOOT_ARGS[@]}" \
  -o "$OUTPUT" "$TREE" \
  || die "xorriso repack failed"

note "8 · VERIFY — or it did not happen"
OUT_REPORT="$(xorriso -indev "$OUTPUT" -report_el_torito as_mkisofs 2>/dev/null || true)"
printf '%s\n' "$OUT_REPORT" | grep -qi 'efisys' \
  || die "output carries no UEFI El Torito entry naming efisys — output marked UNVERIFIED: $OUTPUT"
xorriso -indev "$OUTPUT" -find / -type f 2>/dev/null > "$OUTPUT.manifest.txt" \
  || die "cannot list the output tree — output marked UNVERIFIED: $OUTPUT"
grep -qi 'autounattend.xml' "$OUTPUT.manifest.txt" \
  || die "autounattend.xml missing from the output — UNVERIFIED"
grep -qi 'EnclaveEngine/deploy.cmd' "$OUTPUT.manifest.txt" \
  || die "deployment engine missing from the output — UNVERIFIED"
grep -qi 'EnclaveEngine/capture.cmd' "$OUTPUT.manifest.txt" \
  || die "capture engine missing from the output — UNVERIFIED"
( cd "$OUT_DIR" && sha256sum "$(basename "$OUTPUT")" > "$(basename "$OUTPUT").sha256" )
printf 'output  : %s\nsha256  : %s\nmanifest: %s.manifest.txt\n' \
  "$OUTPUT" "$(awk '{print $1}' "$OUTPUT.sha256")" "$OUTPUT"
printf '\nBUILD COMPLETE — media weighed, serviced, seated, repacked, verified.\n'
printf '93 — Live, Love, and let Love, Live.\n'

# ============================================================================
# Inputs:  an official Windows 11 ARM64 ISO + the maker's SHA-256,
#          supplied by the operator at run time; this kit's answer
#          file and engine, from the kit directory.
# Processes: gate, weigh, audit space, extract, inventory boot,
#          verify/split the WIM, inject, repack, verify.
# Outputs: the deployment ISO; its .sha256; its .manifest.txt.
# Tolerances: the input hash must match EXACTLY (zero tolerance);
#          free space must meet the audit or the build does not
#          start; a missing tool, an unreadable WIM, or a failed
#          output check halts the build — nothing ships UNVERIFIED
#          under a verified name.
# ============================================================================
