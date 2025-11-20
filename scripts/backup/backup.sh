#!/usr/bin/env bash
set -euo pipefail

# Usage: BACKUP_SRC_USER@HOST:/path BACKUP_DEST_DIR
# Example: ./backup.sh devops@10.0.0.10:/ /backups/server-01

SRC=${1:-}
DEST=${2:-}
if [[ -z "$SRC" || -z "$DEST" ]]; then
  echo "Usage: $0 <user@host:/> <dest_dir>"
  exit 1
fi

mkdir -p "$DEST"

# Full weekly backup of application related data, devops /home & /etc
INCLUDE=()
INCLUDE+=("/home/")
INCLUDE+=("/etc/")
INCLUDE+=("/var/lib/docker/volumes/")

RSYNC_OPTS=("-aHAX" "--numeric-ids" "--delete" "--partial" "--info=stats2" "--exclude" "/proc/*" "--exclude" "/sys/*" "--exclude" "/dev/*" "--exclude" "/tmp/*")

DATE=$(date +%F)
TARGET="$DEST/full-$DATE"
mkdir -p "$TARGET"

for path in "${INCLUDE[@]}"; do
  rsync "${RSYNC_OPTS[@]}" "$SRC$path" "$TARGET$path"
done

echo "Backup completed to $TARGET"



