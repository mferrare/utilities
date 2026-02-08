#!/usr/bin/env bash
# Borg backup script (reads /etc/borg/cx105.env)

set -euo pipefail

export PATH=/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin
umask 077

# Environment file is assume to live at same location as this script
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Get environment variables and export
ENVFILE="$SCRIPT_DIR/borg_backup.env"
if [[ -r "$ENVFILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENVFILE"
fi
export BORG_REPO
export BACKUP_DIRS

# Get passphrase and export
export BORG_PASSPHRASE=$(grep -m1 -E '^[[:space:]]*[^#[:space:]]' "${SCRIPT_DIR}/$BORG_PASS_FILE_PATH")

log() { printf "%s %s\n" "$(date -Is)" "$*" >&2; }

LOCKFILE="/var/lock/borg-backup.lock"
exec 9>"$LOCKFILE"
if ! flock -n 9; then
  log "Another backup is already running; exiting"
  EXIT_STATUS=3
  export EXIT_STATUS
  exit $EXIT_STATUS
fi

EXIT_STATUS=0
trap 'log "Backup interrupted"; EXIT_STATUS=2; export EXIT_STATUS; exit $EXIT_STATUS' INT TERM

EXCLUDES=(
  '--exclude' '/proc'
  '--exclude' '/sys'
  '--exclude' '/dev'
  '--exclude' '/run'
  '--exclude' '/tmp'
  '--exclude' '/var/tmp'
  '--exclude' '/var/cache'
  '--exclude' '/var/log'
  '--exclude' '/var/lib/lxcfs'
  '--exclude' '/swapfile'
  '--exclude' '/home/*/.cache/*'
)

if [[ -n "${EXTRA_EXCLUDES:-}" ]]; then
  for pat in ${EXTRA_EXCLUDES}; do
    [[ -z "$pat" ]] && continue
    EXCLUDES+=('--exclude' "$pat")
  done
fi

log "Starting Borg backup to ${BORG_REPO}"

backup_exit=0
if borg create \
  --stats --show-rc --compression lz4 \
  --exclude-caches \
  "${EXCLUDES[@]}" \
  "${BORG_REPO}::${HOSTNAME}-$(date -Is)" \
  ${BACKUP_DIRS}; then
  backup_exit=0
else
  backup_exit=$?
fi
log "Create phase exit=$backup_exit"

log "Pruning archives"
prune_exit=0
if borg prune \
  --list \
  --glob-archives "${HOSTNAME}-*" \
  --show-rc \
  --keep-daily    7 \
  --keep-weekly   4 \
  --keep-monthly  6 \
  "$BORG_REPO"; then
  prune_exit=0
else
  prune_exit=$?
fi
log "Prune phase exit=$prune_exit"

log "Compacting repository"
compact_exit=0
if borg compact "$BORG_REPO"; then
  compact_exit=0
else
  compact_exit=$?
fi
log "Compact exit=$compact_exit"

EXIT_STATUS=$backup_exit
(( prune_exit   > EXIT_STATUS )) && EXIT_STATUS=$prune_exit
(( compact_exit > EXIT_STATUS )) && EXIT_STATUS=$compact_exit

# Treat warnings (RC=1) as success
if [[ "$EXIT_STATUS" -eq 1 ]]; then
  EXIT_STATUS=0
fi

case "$EXIT_STATUS" in
  0) log "Backup, Prune, and Compact finished successfully" ;;
  *) log "Backup finished with errors (exit=$EXIT_STATUS)" ;;
esac

export EXIT_STATUS
exit "$EXIT_STATUS"

