#!/usr/bin/env bash

## name: rsync-backup.bash
## author: Dat (and AI)
## description: Simple rsync backup with auto-mount via UUID.
## usage: bash rsync_backup.sh [--dry-run]

########################## CONFIG ##########################
SRC="$HOME"
UUID="FFEA-317F"
DST_DIR="rsync_backup"

OPTS=(
    --recursive
    --verbose
    --human-readable
    --delete
    --update
    --info=progress2
    --size-only
    --inplace
)

INCLUDE_PATTERNS=(
    "/Documents/.NPublic"
    "/Documents/.NPublic/*"
)

EXCLUDE_PATTERNS=(
    ".*"
    "/Templates"
    "/Downloads"
)

LOG="$HOME/Templates/rsync_backup.log"
LOCKFILE="/tmp/rsync_backup_${UUID}.lock"
DRY_RUN=false
############################################################

set -euo pipefail

# Arguments
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --help)
            echo "Usage: $0 [--dry-run]"
            exit 0
            ;;
    esac
done

[[ "$DRY_RUN" == true ]] && OPTS+=(--dry-run)

# Ensure single instance
if [ -f "$LOCKFILE" ]; then
    echo "Backup already running." >&2
    exit 1
fi
touch "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT

# Required commands
for cmd in rsync udisksctl findmnt; do
    command -v "$cmd" >/dev/null || { echo "Error: missing $cmd"; exit 1; }
done

# Logging
mkdir -p "$(dirname "$LOG")"
log() {
    printf '[%s] %s\n' "$(date '+%F %T')" "$*" | tee -a "$LOG"
}

log "Backup starting..."
log "Searching for UUID $UUID"

# Mount device
DEVICE_SYMLINK=$(find /dev/disk/by-uuid -type l -iname "$UUID" | head -n1)
[[ -z "$DEVICE_SYMLINK" ]] && { log "Drive not found!"; exit 1; }

DEVICE=$(readlink -f "$DEVICE_SYMLINK")
MOUNT_POINT=$(findmnt -rno TARGET "$DEVICE" || true)

if [[ -z "$MOUNT_POINT" ]]; then
    log "Mounting device..."
    udisksctl mount -b "$DEVICE" >> "$LOG" 2>&1
    sleep 2
    MOUNT_POINT=$(findmnt -rno TARGET "$DEVICE")
fi

log "Mounted at: $MOUNT_POINT"

# Rsync target directory
BACKUP_DIR="$MOUNT_POINT/$DST_DIR"
mkdir -p "$BACKUP_DIR"

# Rsync execution
RSYNC_ARGS=("${OPTS[@]}")
for p in "${INCLUDE_PATTERNS[@]}"; do RSYNC_ARGS+=("--include=$p"); done
for p in "${EXCLUDE_PATTERNS[@]}"; do RSYNC_ARGS+=("--exclude=$p"); done
RSYNC_ARGS+=("--log-file=$LOG")

log "Running rsync..."
rsync "${RSYNC_ARGS[@]}" "$SRC/" "$BACKUP_DIR/" | tee -a "$LOG"

# Unmount
log "Unmounting..."
udisksctl unmount -b "$DEVICE" >> "$LOG" 2>&1 || true

log "Backup completed successfully."
echo "Done."
