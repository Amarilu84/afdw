# Here you will find copy & paste style commands that will teach you how to use AFDW. These are only some examples:

**Note:** The normal guided run (no flags) does an encrypted-noise fill, attempts controller discard (or zero-fallback), then creates a single partition and formats **exFAT** to mimic “factory fresh.”
You can customize behavior with the flags below.

---

## AFDW Usage Examples

### 1) Guided (interactive) run — “factory fresh” (noise + zero/discard + exFAT)

```bash
sudo ./afdw.sh
```

### 2) Non-interactive “factory fresh” (no prompts; be careful!)

```bash
sudo ./afdw.sh --device /dev/sdb --non-interactive --erase-confirm ERASE
```

### 3) Noise + Zero, but **skip formatting** (leave raw wiped media)

```bash
sudo ./afdw.sh --device /dev/sdb --no-format
```

Tip: add `--fast` to auto-skip noise if DISCARD/TRIM isn’t supported.

### 4) **Noise only** (no zero, no format)

```bash
sudo ./afdw.sh --device /dev/sdb --noise-only
```

If you want to format afterwards without wiping again, run:

```bash
sudo ./afdw.sh --device /dev/sdb --skip-wipe
```

### 5) **Zero only** (fastest single pass), no format

```bash
sudo ./afdw.sh --device /dev/sdb --zero-only
```

### 6) **Format only** (no wiping): make a single partition and exFAT

* MBR (msdos; default):

```bash
sudo ./afdw.sh --device /dev/sdb --skip-wipe --force-format
```

* GPT with Microsoft Basic Data + custom label:

```bash
sudo ./afdw.sh --device /dev/sdb --skip-wipe --gpt --label CUSTOM --label-text "ARCHIVE01" --force-format
```

### 7) Force (re)format even if a filesystem is detected

```bash
sudo ./afdw.sh --device /dev/sdb --force-format
```

### 8) Use GPT instead of MBR (applies to the format step)

```bash
sudo ./afdw.sh --device /dev/sdb --gpt
```

### 9) Custom exFAT volume label (A–Z0–9 up to 11 chars, uppercased)

```bash
sudo ./afdw.sh --device /dev/sdb --label CUSTOM --label-text "MEDIA_01"
```

### 10) Strict verification (fail the run if any verify step fails)

```bash
sudo ./afdw.sh --device /dev/sdb --strict
```

### 11) FAST mode (if DISCARD unsupported, auto-skip noise to save time)

```bash
sudo ./afdw.sh --device /dev/sdb --fast
```

### 12) Dry-run (show what would happen; no writes)

```bash
./afdw.sh --device /dev/sdb --dry-run
```

### 13) Dependency doctor (no writes) / Auto-install deps (Debian/Ubuntu)

```bash
./afdw.sh --doctor
sudo ./afdw.sh --install-deps
```

### 14) Power-off suppression (don’t power-off/eject at the end)

```bash
sudo ./afdw.sh --device /dev/sdb --no-poweroff
```

### 15) Danger: allow system disk (root) — only if you really know what you’re doing

```bash
sudo ./afdw.sh --device /dev/sda --genius
```

---

## Notes

* Replace `/dev/sdb` with the correct device (e.g., `/dev/mmcblk0` for SD cards).
  The interactive flow lists disks up front.
* If `pv` is installed, AFDW shows live **progress % and ETA** during long writes. Otherwise, `dd` shows a simpler progress counter.
* For a label only, or to switch MBR↔GPT without wiping, use **format-only** examples (`--skip-wipe`).
