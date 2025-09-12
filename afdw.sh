##!/usr/bin/env bash
# Anti-Forensic Drive Wiper (AFDW)
# Version: 1.2.0
# SPDX-License-Identifier: MIT
# WARNING: This destroys data irreversibly. Use at your own risk.

set -Eeuo pipefail

############################################
#                 Colors                   #
############################################
USE_COLOR=1
for arg in "$@"; do [[ "$arg" == "--no-color" ]] && USE_COLOR=0; done
if [[ -t 1 && $USE_COLOR -eq 1 ]]; then
  RED=$'\e[31m'; GRN=$'\e[32m'; YLW=$'\e[33m'; BLU=$'\e[34m'; MAG=$'\e[35m'; CYN=$'\e[36m'; BLD=$'\e[1m'; RST=$'\e[0m'
else
  RED=; GRN=; YLW=; BLU=; MAG=; CYN=; BLD=; RST=
fi

############################################
#             AFDW v1.2                    #
############################################
splash() {
  clear || true
  cat <<'EOF'
.·:''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''':·.
: : .█████╗.███╗...██╗████████╗██╗............................................... : :
: : ██╔══██╗████╗..██║╚══██╔══╝██║............................................... : :
: : ███████║██╔██╗.██║...██║...██║............................................... : :
: : ██╔══██║██║╚██╗██║...██║...██║............................................... : :
: : ██║..██║██║.╚████║...██║...██║............................................... : :
: : ╚═╝..╚═╝╚═╝..╚═══╝...╚═╝...╚═╝............................................... : :
: : ███████╗.██████╗.██████╗.███████╗███╗...██╗███████╗██╗.██████╗............... : :
: : ██╔════╝██╔═══██╗██╔══██╗██╔════╝████╗..██║██╔════╝██║██╔════╝............... : :
: : █████╗..██║...██║██████╔╝█████╗..██╔██╗.██║███████╗██║██║.................... : :
: : ██╔══╝..██║...██║██╔══██╗██╔══╝..██║╚██╗██║╚════██║██║██║.................... : :
: : ██║.....╚██████╔╝██║..██║███████╗██║.╚████║███████║██║╚██████╗............... : :
: : ╚═╝......╚═════╝.╚═╝..╚═╝╚══════╝╚═╝..╚═══╝╚══════╝╚═╝.╚═════╝............... : :
: : ██████╗.██████╗.██╗██╗...██╗███████╗....██╗....██╗██╗██████╗.███████╗██████╗. : :
: : ██╔══██╗██╔══██╗██║██║...██║██╔════╝....██║....██║██║██╔══██╗██╔════╝██╔══██╗ : :
: : ██║..██║██████╔╝██║██║...██║█████╗......██║.█╗.██║██║██████╔╝█████╗..██████╔╝ : :
: : ██║..██║██╔══██╗██║╚██╗.██╔╝██╔══╝......██║███╗██║██║██╔═══╝.██╔══╝..██╔══██╗ : :
: : ██████╔╝██║..██║██║.╚████╔╝.███████╗....╚███╔███╔╝██║██║.....███████╗██║..██║ : :
: : ╚═════╝.╚═╝..╚═╝╚═╝..╚═══╝..╚══════╝.....╚══╝╚══╝.╚═╝╚═╝.....╚══════╝╚═╝..╚═╝ : :
'·:.....oRioN NetheRstaR.................................................v1.2.....:·'
EOF
  cat <<EOF

${BLD}${CYN}This tool will PERMANENTLY ERASE the selected device.${RST}
${YLW}• No recovery. No undo. We are not responsible for any loss.${RST}
${YLW}• Designed to produce a "factory-fresh" forensic appearance.${RST}
${YLW}• It is extreme low probability that any data can be recovered.${RST}
${RED}• Designed to resist government/national semiconductor LAB recovery.${RST}

EOF
}

############################################
#            Defaults / Options            #
############################################
DEVICE=""
LABEL_MODE="RANDOM"
CUSTOM_LABEL=""
TABLE_TYPE="msdos"     # --gpt to change
DO_FORMAT=1            # --no-format to skip
DO_NOISE=1             # --noise-only to limit
DO_ZERO_FALLBACK=1     # --zero-only to limit
STRICT_VERIFY=0
DRY_RUN=0
NON_INTERACTIVE=0
OVERRIDE_SYSTEM_DISK=0
POWER_OFF=1
FAST=0                 # --fast: if discard unsupported, skip noise pass automatically
SKIP_WIPE=0            # --skip-wipe: skip noise & zero; do format+verify only
AUTO_INSTALL_DEPS=0    # --install-deps: apt-get install required packages (Debian/Ubuntu)
DOCTOR=0               # --doctor: run env/deps checks and exit
LOG_DIR="./afdw_logs"
mkdir -p "$LOG_DIR" || true

# Timing accumulators (seconds). If you already had these elsewhere, keep only one copy.
TIME_NOISE=0; TIME_ERASE=0; TIME_FORMAT=0; TIME_VERIFY=0; TIME_TOTAL=0

usage() {
  cat <<EOF
Usage: sudo $0 [options]

Options:
  --device /dev/sdX         Target device (non-interactive mode)
  --non-interactive         No prompts (requires --device and --erase-confirm ERASE)
  --erase-confirm ERASE     Extra guard for non-interactive runs (CASE SENSITIVE)
  --dry-run                 Print what would run, don't write
  --genius                  Allow system disk targets (dangerous)

  --noise-only              Do encrypted-noise pass only (no discard/zero/format)
  --zero-only               Do zeroing pass only (skip noise, skip format)
  --skip-wipe               Skip wipe passes (noise & zero); format + verify only
  --fast                    If DISCARD unsupported, auto-skip noise to save time

  --no-format               Skip partition+exFAT format
  --gpt                     Use GPT instead of MBR (msdos)
  --label RANDOM|CUSTOM     exFAT label mode (default RANDOM)
  --label-text "NAME1234"   With --label CUSTOM, set exact label (A–Z0–9 up to 11; upcased)
  --strict                  Fail if any verification check fails
  --no-poweroff             Do not power off/eject device on success

  --doctor                  Run environment/dependency checks and exit
  --install-deps            Auto-install required packages (Debian/Ubuntu only)
  --no-color                Disable ANSI colors
  -h, --help                Show this help

Examples:
  sudo $0                                   # Guided mode
  sudo $0 --device /dev/sdb --non-interactive --erase-confirm ERASE
  sudo $0 --device /dev/mmcblk0 --gpt --label CUSTOM --label-text "ARCHIVE01"
  sudo $0 --device /dev/sdb --fast          # Skip noise if DISCARD unsupported
  sudo $0 --device /dev/sdb --skip-wipe     # Only partition + format + verify
  sudo $0 --doctor                          # Check deps & environment, then exit
  sudo $0 --install-deps                    # Install required packages (Debian/Ubuntu)
EOF
}

############################################
#          Arg parsing (simple)            #
############################################
ERASE_CONFIRM=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --device) DEVICE="${2:-}"; shift 2;;
    --non-interactive) NON_INTERACTIVE=1; shift;;
    --erase-confirm) ERASE_CONFIRM="${2:-}"; shift 2;;
    --dry-run) DRY_RUN=1; shift;;
    --genius) OVERRIDE_SYSTEM_DISK=1; shift;;
    --noise-only) DO_NOISE=1; DO_ZERO_FALLBACK=0; DO_FORMAT=0; shift;;
    --zero-only) DO_NOISE=0; DO_ZERO_FALLBACK=1; DO_FORMAT=0; shift;;
    --skip-wipe) DO_NOISE=0; DO_ZERO_FALLBACK=0; SKIP_WIPE=1; shift;;
    --fast) FAST=1; shift;;
    --no-format) DO_FORMAT=0; shift;;
    --gpt) TABLE_TYPE="gpt"; shift;;
    --label) LABEL_MODE="${2:-RANDOM}"; shift 2;;
    --label-text) CUSTOM_LABEL="${2:-}"; shift 2;;
    --strict) STRICT_VERIFY=1; shift;;
    --no-poweroff) POWER_OFF=0; shift;;

    --doctor) DOCTOR=1; shift;;
    --install-deps) AUTO_INSTALL_DEPS=1; shift;;

    --no-color) shift;; # already handled
    -h|--help) usage; exit 0;;
    *) echo "${RED}Unknown option:${RST} $1"; usage; exit 1;;
  esac
done

############################################
#               Utilities                  #
############################################
die() { echo -e "${RED}ERROR:${RST} $*" >&2; exit 1; }
warn(){ echo -e "${YLW}WARN:${RST} $*" >&2; }
info(){ echo -e "${GRN}==>${RST} $*"; }
cmd() { [[ $DRY_RUN -eq 1 ]] && echo "[dry-run] $*" || eval "$@"; }

require_root() { [[ $EUID -eq 0 ]] || die "Run as root (sudo)."; }

# Strict dependency checker with optional auto-install (Debian/Ubuntu)
check_deps() {
  # Always-required tools
  local required=( lsblk dd openssl parted blkid uuidgen blockdev grep awk sed tr wc hexdump )
  # Required when formatting
  local format_req=( mkfs.exfat )
  # Optional helpers
  local optional=( blkdiscard findmnt udisksctl partx kpartx )

  local missing=()
  for b in "${required[@]}"; do command -v "$b" >/dev/null 2>&1 || missing+=("$b"); done
  if [[ $DO_FORMAT -eq 1 ]]; then
    for b in "${format_req[@]}"; do command -v "$b" >/dev/null 2>&1 || missing+=("$b"); done
  fi

  if (( ${#missing[@]} > 0 )); then
    echo -e "${RED}Missing required tools:${RST} ${missing[*]}"
    if [[ $AUTO_INSTALL_DEPS -eq 1 ]] && command -v apt-get >/dev/null 2>&1; then
      echo -e "${GRN}Attempting to install dependencies via apt-get...${RST}"
      local pkgs=( coreutils util-linux openssl parted exfatprogs blkid uuid-runtime )
      apt-get update -y
      apt-get install -y "${pkgs[@]}"
      # Recheck
      local still=()
      for b in "${missing[@]}"; do command -v "$b" >/dev/null 2>&1 || still+=("$b"); done
      (( ${#still[@]} == 0 )) || die "Some tools are still missing after install: ${still[*]}"
    else
      echo -e "${YLW}On Debian/Ubuntu, install:${RST} sudo apt-get install -y coreutils util-linux openssl parted exfatprogs blkid uuid-runtime"
      die "Install the required tools and rerun."
    fi
  fi

  # Optional tools: warn only
  for b in "${optional[@]}"; do
    command -v "$b" >/dev/null 2>&1 || warn "$b not found (optional)"
  done

  info "Dependencies OK."
}

trap_cleanup() {
  echo -e "\n${YLW}Signal caught. Flushing writes and syncing...${RST}"
  sync || true
}
trap trap_cleanup INT TERM

is_system_device() {
  # Return 0 if DEVICE holds current root (or its disk)
  local rootdev rootdisk
  rootdev="$(findmnt -no SOURCE / 2>/dev/null || true)"
  [[ -z "$rootdev" ]] && return 1
  rootdisk="$rootdev"
  rootdisk="${rootdisk%%[0-9]*}"
  rootdisk="${rootdisk/%p/}"
  [[ "$rootdev" == *"mmcblk"* || "$rootdev" == *"nvme"* || "$rootdev" == *"loop"* || "$rootdev" == *"dm-"* ]] && rootdisk="$(echo "$rootdev" | sed -E 's/p?[0-9]+$//')"
  [[ "$DEVICE" == "$rootdisk" ]] && return 0 || return 1
}

human_size() {
  local bytes="$1"
  awk -v b="$bytes" 'function human(x){ s="BKMGTPE"; i=0; while (x>=1024 && i<length(s)-1){x/=1024;i++} return sprintf("%.2f %s", x, substr(s,i+1,1)) } BEGIN{ print human(b) }'
}

partition_name_for() {
  local d="$1"
  # If base name ends with a digit, use p1 (loop0, mmcblk0, nvme0n1, dm-0)
  if [[ "$d" =~ [0-9]$ ]]; then
    echo "${d}p1"
  else
    echo "${d}1"
  fi
}

rand_label() { tr -dc 'A-Z0-9' </dev/urandom | head -c 8; }

cooldown() {
  local secs="$1"
  for ((i=secs;i>0;i--)); do
    printf "\rProceeding in %2d seconds... (Ctrl+C to abort)" "$i"
    sleep 1
  done
  printf "\r%*s\r" 60 ""
}

json_escape() {
  sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

############################################
#               Preflight                  #
############################################
require_root
check_deps

# Early exit for doctor mode (no prompts / no writes)
if [[ $DOCTOR -eq 1 ]]; then
  echo -e "${CYN}Doctor mode:${RST} environment and dependencies look good."
  echo -e "${CYN}Tip:${RST} DISCARD/TRIM support is device-specific; run normally to detect per-device."
  exit 0
fi

splash

# Environment safety
if grep -qEi '(Microsoft|WSL|WSL2)' /proc/version 2>/dev/null; then
  warn "WSL/WSL2 detected. Direct block access can nuke your host. Exiting."
  exit 1
fi
if grep -qE '(docker|lxc)' /proc/1/cgroup 2>/dev/null; then
  warn "Containerized environment detected. Exiting for safety."
  exit 1
fi

# Start total timer
T0_SCRIPT=$(date +%s)

############################################
#           Device selection UX            #
############################################
select_device_guided() {
  echo "${BLD}${BLU}Available block devices (disks only):${RST}"
  if lsblk -D >/dev/null 2>&1; then
    lsblk -dno NAME,TRAN,MODEL,SIZE,ROTA,DISC-MAX | grep -v '^loop' | awk '{printf "  %-12s %-6s %-24s %-8s ROTA=%s DISC=%s\n",$1,$2,$3,$4,$5,$6}'
  else
    lsblk -dno NAME,TRAN,MODEL,SIZE,ROTA | grep -v '^loop' | awk '{printf "  %-12s %-6s %-24s %-8s ROTA=%s\n",$1,$2,$3,$4,$5}'
  fi
  echo
  echo -n "Which device do you wish to wipe? ${BLD}/dev/${RST}"
  read -r shortname
  [[ -z "$shortname" ]] && die "No device entered."
  DEVICE="/dev/$shortname"
}

if [[ -z "$DEVICE" ]]; then
  if [[ $NON_INTERACTIVE -eq 1 ]]; then
    die "--non-interactive requires --device"
  fi
  select_device_guided
fi

[[ -b "$DEVICE" ]] || die "Not a block device: $DEVICE"

# Refuse system disk unless overridden
if is_system_device; then
  if [[ $OVERRIDE_SYSTEM_DISK -ne 1 ]]; then
    die "Refusing to operate on system/root disk ($DEVICE). Use --genius to override (dangerous)."
  else
    warn "System disk override enabled. You can destroy your OS. Proceeding by user choice."
  fi
fi

# Show details & confirm
BYTES="$(blockdev --getsize64 "$DEVICE")"
HUMAN="$(human_size "$BYTES")"
MODEL="$(lsblk -dno MODEL "$DEVICE" 2>/dev/null || true)"
TRAN="$(lsblk -dno TRAN "$DEVICE" 2>/dev/null || true)"

if [[ $NON_INTERACTIVE -eq 0 ]]; then
  echo
  echo -e "${BLD}${CYN}Target:${RST} $DEVICE  ${BLD}${CYN}Size:${RST} $HUMAN  ${BLD}${CYN}Model:${RST} ${MODEL:-unknown}  ${BLD}${CYN}Bus:${RST} ${TRAN:-unknown}"
  echo
  echo -e "To confirm, type the full path again: ${BLD}$DEVICE${RST}"
  read -r confirm_path
  [[ "$confirm_path" != "$DEVICE" ]] && die "Path confirmation mismatch."

  echo -e "Final confirmation (CASE SENSITIVE): Type ${BLD}ERASE${RST} to proceed, or press ${BLD}N${RST} to cancel:"
  read -r final_c
  [[ "$final_c" == "N" || "$final_c" == "n" ]] && die "User cancelled."
  [[ "$final_c" != "ERASE" ]] && die "Final confirmation failed."
  echo
  echo -e "${RED}${BLD}Are you SURE you want to permanently erase ${DEVICE} ($HUMAN)?${RST}"
  cooldown 5
else
  [[ "$ERASE_CONFIRM" == "ERASE" ]] || die "Non-interactive mode requires --erase-confirm ERASE (CASE SENSITIVE)."
fi

############################################
#        Partition suffix determination    #
############################################
PART="$(partition_name_for "$DEVICE")"

############################################
#           Discard capability note        #
############################################
DISCARD_OK=0
if command -v blkdiscard >/dev/null 2>&1; then
  if blkdiscard -t "$DEVICE" >/dev/null 2>&1; then
    DISCARD_OK=1
  fi
fi
if [[ $DISCARD_OK -eq 1 ]]; then
  info "Discard appears supported on $DEVICE."
else
  warn "Discard test failed/unsupported. Will likely fall back to zeroing each sector."
fi

# FAST mode: if discard unsupported and we're otherwise doing noise+zero, skip noise to save time
if [[ $FAST -eq 1 && $DO_NOISE -eq 1 && $DO_ZERO_FALLBACK -eq 1 && $DISCARD_OK -eq 0 ]]; then
  warn "FAST mode: DISCARD unsupported → skipping noise pass."
  DO_NOISE=0
fi

############################################
#            Unmount everything            #
############################################
info "Unmounting any mounted partitions..."
cmd "sync"
cmd "umount -R '${DEVICE}'* 2>/dev/null || true"
cmd "umount -l '${DEVICE}'* 2>/dev/null || true"
if command -v findmnt >/dev/null 2>&1; then
  if findmnt -S "$DEVICE" >/dev/null 2>&1; then
    warn "Some mountpoints still reference $DEVICE. Proceeding anyway (danger!)."
  fi
else
  mount | grep -E "^$DEVICE" && warn "Some mountpoints still reference $DEVICE."
fi

############################################
#              Wipe: Noise pass            #
############################################
if [[ $DO_NOISE -eq 1 ]]; then
  info "Filling device with encrypted noise (AES-256-CTR, throwaway key/iv)..."
  T_NOISE_START=$(date +%s)
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[dry-run] dd if=/dev/zero bs=1M count=$BYTES iflag=count_bytes | openssl enc -aes-256-ctr -K \$(openssl rand -hex 32) -iv \$(openssl rand -hex 16) | dd of='$DEVICE' bs=8M iflag=fullblock oflag=direct status=progress conv=fdatasync"
  else
    set -o pipefail
    dd if=/dev/zero bs=1M count="$BYTES" iflag=count_bytes \
    | openssl enc -aes-256-ctr -K "$(openssl rand -hex 32)" -iv "$(openssl rand -hex 16)" \
    | dd of="$DEVICE" bs=8M iflag=fullblock oflag=direct status=progress conv=fdatasync
    set +o pipefail
  fi
  T_NOISE_END=$(date +%s); TIME_NOISE=$(( T_NOISE_END - T_NOISE_START ))
fi

############################################
#        Ghost erase (discard/verify)      #
############################################
if [[ $DO_ZERO_FALLBACK -eq 1 ]]; then
  info "Attempting controller discard (ghost erase) with verification..."
  T_ERASE_START=$(date +%s)
  if [[ $DISCARD_OK -eq 1 && $DRY_RUN -eq 0 ]]; then
    blkdiscard -v "$DEVICE" 2>/dev/null || true
  else
    echo "[skip] blkdiscard (unsupported or dry-run)"
  fi

  # Verify 3 random 4MiB blocks are all 00 or FF
  NEED_ZERO=0
  BS=$((4*1024*1024))
  for i in 1 2 3; do
    off=$((RANDOM % (BYTES/BS)))
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "[dry-run] verify sample off=$off bs=$BS"
    else
      nz=$(dd if="$DEVICE" bs=$BS skip=$off count=1 2>/dev/null | tr -d '\000' | wc -c)
      nf=$(dd if="$DEVICE" bs=$BS skip=$off count=1 2>/dev/null | tr -d '\377' | wc -c)
      if [[ "$nz" -ne 0 && "$nf" -ne 0 ]]; then NEED_ZERO=1; break; fi
    fi
  done

  if [[ $NEED_ZERO -eq 1 ]]; then
    info "Discard verification failed; performing single zero pass..."
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "[dry-run] dd if=/dev/zero of='$DEVICE' bs=8M count=$BYTES iflag=count_bytes oflag=direct status=progress conv=fdatasync"
    else
      dd if=/dev/zero of="$DEVICE" bs=8M count="$BYTES" iflag=count_bytes oflag=direct status=progress conv=fdatasync
    fi
  else
    info "Blocks sampled show erased pattern (00/FF)."
  fi
  T_ERASE_END=$(date +%s); TIME_ERASE=$(( T_ERASE_END - T_ERASE_START ))
fi

############################################
#           Partition + exFAT format       #
############################################
VOL_LABEL=""
FS_UUID=""
if [[ $DO_FORMAT -eq 1 ]]; then
  info "Partitioning (${TABLE_TYPE}) + exFAT formatting..."
  T_FORMAT_START=$(date +%s)

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[dry-run] parted -a optimal '$DEVICE' --script mklabel $TABLE_TYPE mkpart primary 1MiB 100%"
  else
    parted -a optimal "$DEVICE" --script mklabel "$TABLE_TYPE" mkpart primary 1MiB 100%
    partprobe "$DEVICE" 2>/dev/null || true
    # For loop devices and some kernels, nudge partition nodes to appear:
    if [[ "$DEVICE" == /dev/loop* ]]; then
      partx -u "$DEVICE" 2>/dev/null || true
      kpartx -a "$DEVICE" 2>/dev/null || true
    fi
    # Recompute PART now that the table exists and wait for node
    PART="$(partition_name_for "$DEVICE")"
    for i in {1..20}; do
      [[ -b "$PART" ]] && break
      sleep 0.2
      partprobe "$DEVICE" 2>/dev/null || true
    done
    [[ -b "$PART" ]] || die "Partition node $PART did not appear."
  fi

  # Decide label
  if [[ "$LABEL_MODE" == "CUSTOM" ]]; then
    [[ -z "$CUSTOM_LABEL" ]] && die "--label CUSTOM requires --label-text"
    VOL_LABEL="$(echo "$CUSTOM_LABEL" | tr '[:lower:]' '[:upper:]' | tr -cd 'A-Z0-9' | cut -c1-11)"
  else
    VOL_LABEL="$(rand_label)"
  fi
  GUID="$(uuidgen)"

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[dry-run] mkfs.exfat -L '$VOL_LABEL' -U '$GUID' -c <auto> '$PART'"
  else
    PSIZE=$(blockdev --getsize64 "$PART")
    GIB=$((PSIZE/1024/1024/1024))
    if   (( GIB < 8 ));   then CS="16K"
    elif (( GIB < 32 ));  then CS="32K"
    elif (( GIB < 128 )); then CS="64K"
    else                       CS="128K"
    fi
    mkfs.exfat -L "$VOL_LABEL" -U "$GUID" -c "$CS" "$PART"
  fi

  if [[ $DRY_RUN -eq 0 ]]; then
    FS_UUID="$(blkid -s UUID -o value "$PART" || true)"
  fi
  T_FORMAT_END=$(date +%s); TIME_FORMAT=$(( T_FORMAT_END - T_FORMAT_START ))
fi

############################################
#               Verification               #
############################################
info "Running post-process verification..."
T_VERIFY_START=$(date +%s)
VERIFY_OK=1
VERIFY_LOG="$(mktemp "${LOG_DIR}/verify_XXXX.txt")"
{
  echo "Verification for $DEVICE at $(date -Is)"
  echo "Table: $TABLE_TYPE  Partition: $PART  Label: $VOL_LABEL  UUID: $FS_UUID"
} >> "$VERIFY_LOG"

ver_pass(){ echo "PASS - $1" | tee -a "$VERIFY_LOG"; }
ver_fail(){ echo "FAIL - $1" | tee -a "$VERIFY_LOG"; VERIFY_OK=0; }

# Part 1: MBR signature (for GPT, protective MBR still has 0x55AA)
SIG="$(dd if="$DEVICE" bs=1 skip=$((512-2)) count=2 status=none | hexdump -v -e '1/1 "%02x"')"
if echo "$SIG" | grep -qi "^55aa$"; then ver_pass "MBR signature present (0x55AA)"; else ver_fail "MBR signature missing/invalid"; fi

# Part 2: Pre-partition gap erased
PSTART="$(parted -m "$DEVICE" unit B print | awk -F: '/^1:/{print $2}' | tr -d B || echo 0)"
GAP_START=$((64*1024)); GAP_END=$((PSTART-64*1024))
if (( GAP_END > GAP_START )); then
  GLEN=$(( GAP_END - GAP_START )); (( GLEN > 256*1024 )) && GLEN=$((256*1024))
  NZ=$(dd if="$DEVICE" bs=1 skip="$GAP_START" count="$GLEN" iflag=skip_bytes,count_bytes status=none | tr -d '\000' | wc -c)
  NF=$(dd if="$DEVICE" bs=1 skip="$GAP_START" count="$GLEN" iflag=skip_bytes,count_bytes status=none | tr -d '\377' | wc -c)
  if [[ "$NZ" -eq 0 || "$NF" -eq 0 ]]; then ver_pass "Pre-partition gap erased (00/FF)"; else ver_fail "Pre-partition gap not erased"; fi
else
  ver_fail "Pre-partition gap too small to verify"
fi

# Part 3: Middle block erased (00/FF)
BYTES="$(blockdev --getsize64 "$DEVICE")"
MBS=$((BYTES/1024/1024)); MID=$((MBS/2))
NZ=$(dd if="$DEVICE" bs=1M skip=$MID count=1 status=none | tr -d '\000' | wc -c)
NF=$(dd if="$DEVICE" bs=1M skip=$MID count=1 status=none | tr -d '\377' | wc -c)
if [[ "$NZ" -eq 0 || "$NF" -eq 0 ]]; then ver_pass "Middle block erased (00/FF)"; else ver_fail "Middle block not erased"; fi

# Part 4: Last MiB erased (00/FF)
LAST=$((MBS-1))
NZ=$(dd if="$DEVICE" bs=1M skip=$LAST count=1 status=none | tr -d '\000' | wc -c)
NF=$(dd if="$DEVICE" bs=1M skip=$LAST count=1 status=none | tr -d '\377' | wc -c)
if [[ "$NZ" -eq 0 || "$NF" -eq 0 ]]; then ver_pass "Last block erased (00/FF)"; else ver_fail "Last block not erased"; fi

# Part 5: Partition table type
PT_OUT="$(parted "$DEVICE" --script print 2>/dev/null || true)"
echo "$PT_OUT" | grep -qi "Partition Table: $TABLE_TYPE" && ver_pass "Partition table is $TABLE_TYPE" || ver_fail "Partition table not $TABLE_TYPE"

# Part 6: Volume label pattern
if [[ $DO_FORMAT -eq 1 ]]; then
  LAB="$(blkid -s LABEL -o value "$PART" 2>/dev/null || true)"
  if echo "$LAB" | grep -Eq '^[A-Z0-9]{1,11}$'; then ver_pass "Volume label OK ($LAB)"; else ver_fail "Volume label unexpected ($LAB)"; fi
else
  ver_pass "Format skipped (per options)"
fi

# Part 7: exFAT UUID format ####-####
if [[ $DO_FORMAT -eq 1 ]]; then
  UUIDF="$(blkid -s UUID -o value "$PART" 2>/dev/null || true)"
  if echo "$UUIDF" | grep -Eq '^[A-F0-9]{4}-[A-F0-9]{4}$'; then ver_pass "exFAT UUID format OK ($UUIDF)"; else ver_fail "exFAT UUID unexpected ($UUIDF)"; fi
else
  ver_pass "Format skipped (per options)"
fi

# Part 8: Alignment (1MiB)
if [[ "$PSTART" -eq $((1024*1024)) ]]; then ver_pass "Partition starts at 1MiB (aligned)"; else ver_fail "Partition start offset unexpected ($PSTART bytes)"; fi

# Extra: sample inside partition (if formatted)
if [[ $DO_FORMAT -eq 1 ]]; then
  PSIZE="$(blockdev --getsize64 "$PART")"
  if (( PSIZE > 0 )); then
    off=$(( (RANDOM % (PSIZE/4096)) + 1 ))
    NZ=$(dd if="$PART" bs=4096 skip=$off count=1 status=none | wc -c)
    if (( NZ == 4096 )); then
      ver_pass "Readable sample inside partition (boot/metadata present)"
    else
      ver_fail "Could not read expected block inside partition"
    fi
  fi
fi
T_VERIFY_END=$(date +%s); TIME_VERIFY=$(( T_VERIFY_END - T_VERIFY_START ))

############################################
#                 Logging                  #
############################################
TIME_TOTAL=$(( $(date +%s) - T0_SCRIPT ))

STAMP="$(date +%Y%m%d_%H%M%S)"
JSON_LOG="${LOG_DIR}/afdw_${STAMP}.json"
{
  echo -n '{'
  printf '"timestamp":"%s",' "$(date -Is | json_escape)"
  printf '"device":"%s",' "$(echo "$DEVICE" | json_escape)"
  printf '"size_bytes":%s,' "$BYTES"
  printf '"human_size":"%s",' "$(echo "$HUMAN" | json_escape)"
  printf '"model":"%s",' "$(echo "${MODEL:-unknown}" | json_escape)"
  printf '"bus":"%s",' "$(echo "${TRAN:-unknown}" | json_escape)"
  printf '"table_type":"%s",' "$TABLE_TYPE"
  printf '"formatted":%s,' "$((DO_FORMAT))"
  printf '"label":"%s",' "$(echo "$VOL_LABEL" | json_escape)"
  printf '"uuid":"%s",' "$(echo "$FS_UUID" | json_escape)"
  printf '"discard_attempted":%s,' "$((DISCARD_OK))"
  printf '"verify_passed":%s,' "$((VERIFY_OK))"
  printf '"strict_mode":%s,' "$((STRICT_VERIFY))"
  printf '"fast_mode":%s,' "$((FAST))"
  printf '"skip_wipe":%s,' "$((SKIP_WIPE))"
  printf '"times":{"total":%s,"noise":%s,"erase":%s,"format":%s,"verify":%s},' \
         "$TIME_TOTAL" "$TIME_NOISE" "$TIME_ERASE" "$TIME_FORMAT" "$TIME_VERIFY"
  printf '"dry_run":%s' "$((DRY_RUN))"
  echo '}'
} > "$JSON_LOG"

echo
if [[ $VERIFY_OK -eq 1 ]]; then
  echo -e "${GRN}${BLD}RESULT: PASS ✅ Looks factory-fresh and erased.${RST}"
else
  echo -e "${RED}${BLD}RESULT: FAIL ❌ Check ${VERIFY_LOG} for details.${RST}"
  [[ $STRICT_VERIFY -eq 1 ]] && exit 2
fi
echo -e "Log (text): ${BLU}$VERIFY_LOG${RST}"
echo -e "Log (json): ${BLU}$JSON_LOG${RST}"

############################################
#        Safe power-off / eject (opt)      #
############################################
if [[ $POWER_OFF -eq 1 && $DRY_RUN -eq 0 ]]; then
  if command -v udisksctl >/dev/null 2>&1; then
    info "Powering off device..."
    udisksctl power-off -b "$DEVICE" || warn "Power-off failed; you may safely remove the drive."
  else
    info "Eject tools not present; syncing instead."
    sync
  fi
fi

# Exit codes:
# 0 — success (even if verification found issues unless --strict was set)
# 1 — usage or unrecoverable runtime error
# 2 — verification failed and --strict was set
exit $(( STRICT_VERIFY && VERIFY_OK == 0 ? 2 : 0 ))
