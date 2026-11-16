# DEPLOYMENT KIT — FORTHCOMING

This directory is reserved for the Windows 11 Pro for Workstations ARM64 deployment ISO build kit. It lands by follow-up commit when the kit is complete:

- **build-iso.sh** — the repack pipeline: verify the official ARM64 ISO's hash, extract, seat the autounattend and the deployment engine, service the WIM with wimlib, repack a bootable UEFI ISO with xorriso, hash and verify. Fail-closed at every gate. Runs in Termux on the Galaxy A16 (the card-keeper) and in a Linux shell alike.
- **autounattend.xml** — the bootstrap's answer file: ARM64, Pro for Workstations, local administrator only, no Microsoft account, BitLocker sealed to the TPM.
- **engine/** — the deployment engine (deploy.cmd, capture.cmd) for the WinPE side: apply a backup image to bare iron, or capture the living seat into a new epoch. Both ask before they act.
- **PHONE-RUNBOOK.md** — the founder's paste-ready Termux steps: packages, storage checks, downloading the ARM64 ISO on the phone itself, running the build, and serving the finished ISO for network boot.

Flagpole of Claim and Coinage: Johnathan 'Qasparr' Monroe, ARR, All Rights Reserved, Without Prejudice.

93 — Live, Love, and let Love, Live.
