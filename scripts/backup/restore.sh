#!/usr/bin/env bash
set -euo pipefail

# Usage: ./restore.sh <backup_dir> <target_host> <target_user>
# Example: ./restore.sh /backups/server-01/full-2025-10-30 10.0.0.10 devops

BACKUP_DIR=${1:-}
HOST=${2:-}
USER=${3:-}
if [[ -z "$BACKUP_DIR" || -z "$HOST" || -z "$USER" ]]; then
  echo "Usage: $0 <backup_dir> <target_host> <target_user>"
  exit 1
fi

# Restore /home and /etc (careful in production!)
rsync -aHAX --numeric-ids --info=stats2 "$BACKUP_DIR/home/" "$USER@$HOST:/home/"
rsync -aHAX --numeric-ids --info=stats2 "$BACKUP_DIR/etc/" "$USER@$HOST:/etc/"

echo "Restore complete. Review changes on $HOST."



