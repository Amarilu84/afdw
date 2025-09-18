# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## \[1.3.0] - 2025-09-17

### Added

* **Zero-pass fallback** triggered automatically if discard verification fails.
* **Progress/ETA** via `pv` for long writes (noise and zero passes), with automatic fallback to `dd status=progress` when `pv` isn’t available.
* **Pre-partition gap wipe** helper that’s **MBR/GPT-aware** and respects protective/primary/backup GPT areas.

# Previous version (1.2) had a big problem where it wasn't correctly formatting the drive in exFat. It was wiping fine but would hang on volume ID.
# This was because we were racing the kernel/udev (partition node not ready yet) and hadn’t set the partition type,
# so blkid/lsblk didn’t report exFAT reliably; we fixed that by adding the partprobe/udevadm settle/rescan loop and setting the type (MBR=0x07, GPT=msftdata).
# After that, the only remaining “fail” was our own verifier flagging the pre-partition gap while --skip-wipe was on, which we changed to SKIP
# (and only FAIL in --strict).
# In my pursuit to find that problem, I added some features and a more robust method of formatting and being mindful of different setups:

* **Verification suite**:

  * Protective **MBR 0x55AA** signature check.
  * **Pre-partition gap** erased check (now SKIP when `--skip-wipe`, FAIL only in `--strict`).
  * Middle/last MiB erased checks.
  * Partition table type matches requested **MBR/GPT**.
  * exFAT filesystem presence, **label** format, **UUID** format (####-####), **1MiB alignment**, and **readable sample** inside partition.
  * MBR **0x07** / GPT **Microsoft Basic Data (EBD0A0A2-…)** partition type validation.
* **Robust partition re-read** flow: `partprobe`, `udevadm settle`, `partx`, `kpartx` (if present), `blockdev --rereadpt`, and **MMC rescan** fallback.
* **Safety checks**: refuse to run in **WSL** or **containers**; refuse **system/root disk** unless `--genius`.
* **Non-interactive mode** with `--device` + `--erase-confirm ERASE`.
* **FAST mode** (`--fast`): if DISCARD unsupported, skip noise pass.
* **Skip/limit modes**: `--skip-wipe`, `--noise-only`, `--zero-only`.
* **Formatting controls**: `--no-format`, `--force-format`, `--gpt`, label modes (`--label RANDOM|CUSTOM`, `--label-text`).
* **mkfs selection**: prefer `mkfs.exfat` (exfatprogs), fallback to `mkexfatfs` (exfat-utils) with **SPC** computed from cluster size & sector size.
* **Cluster-size** auto-pick for exFAT based on partition size (16K/32K/64K/128K).
* **Post-format snapshot** (`lsblk`, `blkid`) and **EXFAT** signature verification.
* **JSON logging** (device metadata, modes, timings) + per-run **text verification log**.
* **Power-off/eject** on success via `udisksctl` (if available).
* **Doctor mode** (`--doctor`) to check environment/deps.
* **Auto-install** optional (`--install-deps`) for Debian/Ubuntu.
* **Trap cleanup** on signals (flush/sync before exit).

### Changed

* Dependency checks tightened; clearer guidance; optional auto-install.
* Partition creation standardizes on **1MiB start**; MBR type set via `sfdisk`; GPT `msftdata` flag set via `parted`.
* Label handling: RANDOM generator (A–Z0–9) or CUSTOM (sanitized, upcased, ≤11 chars).
* Exit codes clarified: **0** success, **2** when verification fails under `--strict`.
* Output styling consolidated under `info/warn/die`; color can be disabled with `--no-color`.

### Fixed

* Race conditions after partitioning by adding multiple re-read paths + MMC rescan.
* Correct **SPC** calculation for `mkexfatfs` when sector size ≠ 512.
* Accurate handling of **pre-partition gap** for both MBR and GPT disks.
* Ensured verification respects `--skip-wipe` (reports SKIP; only FAILs in `--strict`).

---

*(Previous releases for reference)*

## \[1.2] - 2025-09-12

### Added

* Improved dependency checks and clearer README instructions for first-time users.
* Enhanced unmount logic: recursive unmount + lazy fallback for stubborn mounts.
* Double-confirmation safety flow refined (full path + explicit `ERASE` keyword).
* Additional error handling and user feedback messages.

### Changed

* Reorganized and simplified code structure for readability.
* Adjusted script to run cleanly under `bash`.
* Updated README.md with usage instructions and quickstart notes.

---

## \[1.1] - 2025-09-10

### Added

* Flush and sync step before unmount to ensure all writes are committed.
* Initial README.md with TL;DR and usage overview.

### Changed

* Streamlined prompts and confirmations to reduce accidental misuse.
* Minor code cleanups and comments for maintainability.

---

## \[1.0] - 2025-09-08

### Added

* Initial release of **AFDW (Anti-Forensic Drive Wiper)**.
* Core functionality:

  * Detect and list disks.
  * Require full-path confirmation.
  * Securely wipe drives using multiple passes.
  * Basic unmounting routine.
* MIT license.
