# VULKAN TOOLBOX — the Mali-G68's compute seat, opened with the NDK

*For the founder's Galaxy A16 (Exynos 1330, SM-A166U / SM-S166V family) — his device, his hand.*
*Authorship attributed exclusively to Johnathan 'Qasparr' Monroe (Greek, -ARR, All Rights Reserved, Without Prejudice). Enterprise • Educational • Research & Development. Method of Science, Aim of Religion. 93.*

## What this toolbox is

The Exynos 1330's GPU is an **ARM Mali-G68 MP2** — two shader cores of ARM's Valhall generation. On Android, that silicon is reachable for general compute through **Vulkan**, the cross-vendor API the Android NDK exposes natively (`libvulkan.so` has been a public NDK library since API 24). This toolbox is the house's hand on that seat: a probe that asks the device what its Vulkan actually is, two compute shaders that do real work the house's engines need, their host-side dispatch programs, and the fetch road that lays the toolchain down on a host where the usual downloader cannot run.

Nothing here needs root, a custom ROM, or Samsung's permission: Vulkan compute on the founder's own device, through the platform's public API, is ordinary Android development. The boundary that governs the rest of this repository — no root-key extraction, no boot-chain bypass, no fuse games — is untouched by anything in this toolbox, because nothing here asks for elevation at all.

## Contents

| Seat | What it is | State on this host |
|---|---|---|
| `caps-probe/caps_probe.c` | The dossier: instance version, per-device properties (vendor/device, API + driver versions, device type), subgroup size (via the Vulkan 1.1 properties chain), compute limits, memory heaps and types, queue families, device extensions — printed as a record. Exit 2 = no Vulkan on the device, 3 = no devices | **Compiles + links** for aarch64 Android (API 31) |
| `caps-probe/build.sh` | Strikes the probe with the NDK clang; prints the `file` verdict | Runs here |
| `compute/parallel_sum.comp` | Workgroup tree reduction: 256 lanes, shared-memory halving, the barrier outside the lane-conditional (a barrier inside divergent control flow is undefined behaviour — the shape is the lesson); per-workgroup partials out | **Compiled to SPIR-V + validated** |
| `compute/fft_butterfly.comp` | One radix-2 Cooley–Tukey stage: the host walks the stages, the shader does the butterfly arithmetic (direction −1 forward / +1 inverse by push constant; the host owes bit-reversal in and 1/n scaling out) | **Compiled to SPIR-V + validated** |
| `compute/dispatch_parallel_sum.c` | A complete host program: device pick, host-visible buffers, pipeline from a `.spv` file, dispatch, readback — and a verdict (the sum of a million ones must equal the count, exactly) | **Compiles + links**; run is device-gated |
| `compute/dispatch_fft.c` | The FFT host road as a **labeled skeleton**: full initialisation and the stage loop with its inter-stage barrier; the impulse→flat-spectrum check written; the named absences printed in its header (real-signal packing, subgroup shuffle, non-power-of-two sizes, timing) | **Compiles + links**; run is device-gated |
| `compute/compile-shaders.sh` | Finds a GLSL→SPIR-V compiler (operator's, PATH, the NDK's bundled shader-tools, glslangValidator), compiles both shaders, validates with `spirv-val` when present | Runs here |
| `setup/fetch-toolchain.sh` | The fetch road (below): dry-run by default; fetches Google's official NDK archive with curl, verifies the operator-supplied SHA-256, lays the NDK under this toolbox's `vendor/` | Dry-run verified; the download is the operator's step |
| `tests/run-tests.sh` | The bench: T1–T6 | **6/6 green on this host** (record below) |

## The verified facts, with their witnesses

- **The silicon.** Exynos 1330: Mali-G68 **MP2** (2 cores), 2× Cortex-A78 @ 2.4 GHz + 6× Cortex-A55 @ 2.0 GHz, 5 nm; the GPU is specified at ~949 MHz / ~121.5 GFLOPS. (NanoReview's Galaxy A16 5G / Exynos 1330 specifications, read 2026-11-16; multiple specification sources concur.) *Variant caution:* some regional A16 5G variants carry a MediaTek Dimensity 6300 instead — the founder's unit is the Exynos one, and the sibling Exynos toolbox's variant-guard exists because confusing the two is a real and documented hazard.
- **The Vulkan version — stated honestly.** Published sources **disagree**: NotebookCheck lists Vulkan **1.1** for the Mali-G68 line; some aggregator tables print 1.2; Mesa's PanVK driver reaches further on Valhall silicon, but Mesa is not Samsung's stock driver. **Doctrine:** the silicon is Vulkan-capable from 1.1 upward; the version a given A16 *exposes* is a property of Samsung's driver build, not of the spec sheet. That is precisely why `caps-probe` exists: its readout on the founder's device is the deciding witness, and until it runs, this README claims no version.
- **The toolchain.** Android NDK **r30** (Pkg.Revision 30.0.16248370) stands on this host already (the house PQPE seat) and **bundles glslc and the SPIRV-Tools suite** under `shader-tools/linux-x86_64/` — so the shaders in this toolbox were compiled and validated here, with Google's own compiler, not merely eyeballed. `libvulkan.so` stubs ship per-API in the NDK sysroot from API 24; this toolbox builds at API 31.
- **The fetch law.** On this host the JVM has no real TCP, so `sdkmanager` can never download (the house's recorded finding). `setup/fetch-toolchain.sh` therefore follows the standing pattern: **curl** fetches the official archive from `dl.google.com`, the SHA-256 is supplied by the operator from Google's NDK downloads page *in the same sitting* (no hash is hardcoded in the script — a hardcoded hash rots, and a rotted hash teaches operators to ignore mismatches), a mismatch deletes the archive and halts, and the layout lands under this toolbox's own `vendor/` — nothing system-wide.

## What the Mali seat means for the house

- **For the Enclave's future nodes:** a phone-class node with a real compute queue is a worker, not a terminal. The parallel-sum is the shape of every reduction the Enclave will ask of such a node (aggregate, verify, count); the FFT stage is the shape of its signal work. Both are deliberately small, correct, and measured — a node's first duties are the ones whose answers can be checked exactly, and `dispatch_parallel_sum`'s verdict (a million ones, summed exactly) is that discipline in code.
- **For Resonantia and the studio:** the new visualizer draws; a shader seat *computes* the drawing — spectra, reductions, per-bin energies — at GPU width instead of CPU patience. The FFT butterfly here is the same mathematics the studio's analysis already does on the CPU, seated where it belongs when the work gets wide. And subgroup size — printed by the probe — is the number that decides which of those optimisations are even legal on this silicon; the dossier comes before the choreography.
- **The honest scale:** ~121 GFLOPS is a modest seat. It will not train anything. It will reduce, transform, and analyse at interactive rates on the device in the founder's pocket — which is the entire point of a local, sovereign node: the work happens *here*, on his hardware, under his hand.

## Bench record (this host, 2026-11-16/17)

`tests/run-tests.sh`: **PASS=6 FAIL=0 SKIP=0** — T1 the probe compiles + links for aarch64 Android API 31 (a real ARM ELF, interpreter `/system/bin/linker64`) · T2 both dispatch hosts compile + link · T3 the shader compiler is found (the NDK's bundled glslc) · T4 both shaders compile to SPIR-V (parallel_sum 1880 B, fft_butterfly 1696 B) and pass `spirv-val` · T5 the fetch script's dry run prints Google's official URL and downloads nothing · T6 no 64-hex hash is hardcoded in the fetch script, and every code file carries the house form.

**A dead end, recorded at full size** (it is also recorded in the shader files themselves): the first bench run failed T4 — GLSL's ES profile requires `#version` as the **first statement** of the file, and the house header standing above it is a compile error, not a comment the compiler forgives. Both shaders now open with `#version 310 es` and carry the house header *below* it, with the reason printed. The law generalises: where a format reserves the first line, the house form yields the line and keeps everything else.

## What remains device-gated

Everything that needs the living GPU: running `caps_probe` on the A16 and reading the dossier it prints (the Vulkan version question settles there, and only there); running both dispatch programs and their verdicts; any timing or throughput claim. Until the probe's readout is in hand, this toolbox claims shapes, compilations, and validations — not device facts. The run road is ordinary: build, place the binaries and `.spv` files on the device (Termux or `adb`), run, read. No elevation is required or requested at any step.

*93 — Live, Love, and let Love, Live.*
