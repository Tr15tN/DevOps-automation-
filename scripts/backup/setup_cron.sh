#!/usr/bin/env bash
set -euo pipefail

# Script to set up automated weekly backups via cron
# Run this on the backup VM

echo "🔧 Setting up automated weekly backups..."
echo ""

# Check if running as correct user (not root)
if [ "$EUID" -eq 0 ]; then
  echo "❌ Do not run this script as root. Run as the backup user."
  exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Prompt for backup sources
read -p "Enter backup source user@host (e.g., devops@10.0.0.10): " BACKUP_SOURCE
read -p "Enter backup destination directory (e.g., /backups/server-01): " BACKUP_DEST

# Validate inputs
if [[ -z "$BACKUP_SOURCE" || -z "$BACKUP_DEST" ]]; then
  echo "❌ Both source and destination are required."
  exit 1
fi

# Create destination directory
mkdir -p "$BACKUP_DEST"
echo "✅ Created backup directory: $BACKUP_DEST"

# Test SSH connectivity
echo ""
echo "🔑 Testing SSH connectivity to $BACKUP_SOURCE..."
if ssh -o BatchMode=yes -o ConnectTimeout=5 "$BACKUP_SOURCE" "echo 'SSH connection successful'" 2>/dev/null; then
  echo "✅ SSH connection successful"
else
  echo "❌ SSH connection failed. Please set up SSH key-based authentication:"
  echo ""
  echo "   1. Generate SSH key (if not already done):"
  echo "      ssh-keygen -t rsa -b 4096 -f ~/.ssh/backup_key"
  echo ""
  echo "   2. Copy key to remote server:"
  echo "      ssh-copy-id -i ~/.ssh/backup_key.pub $BACKUP_SOURCE"
  echo ""
  echo "   3. Test connection:"
  echo "      ssh -i ~/.ssh/backup_key $BACKUP_SOURCE"
  echo ""
  exit 1
fi

# Test backup script
echo ""
echo "🧪 Testing backup script..."
if "$SCRIPT_DIR/backup.sh" "$BACKUP_SOURCE:/" "$BACKUP_DEST"; then
  echo "✅ Backup test successful"
else
  echo "❌ Backup test failed. Check the error messages above."
  exit 1
fi

# Create cron job
echo ""
echo "⏰ Setting up weekly cron job (Sundays at 3 AM)..."

CRON_CMD="0 3 * * 0 $SCRIPT_DIR/backup.sh $BACKUP_SOURCE:/ $BACKUP_DEST >> /var/log/backup-$(echo $BACKUP_SOURCE | tr '@:' '-').log 2>&1"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "$SCRIPT_DIR/backup.sh"; then
  echo "⚠️  Cron job already exists. Skipping..."
else
  # Add to crontab
  (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
  echo "✅ Cron job added"
fi

echo ""
echo "📋 Current crontab:"
crontab -l | grep backup || echo "(no backup jobs found)"

echo ""
echo "✅ Setup complete!"
echo ""
echo "📝 Summary:"
echo "   - Backup source: $BACKUP_SOURCE"
echo "   - Backup destination: $BACKUP_DEST"
echo "   - Schedule: Every Sunday at 3:00 AM"
echo "   - Log file: /var/log/backup-$(echo $BACKUP_SOURCE | tr '@:' '-').log"
echo ""
echo "💡 To manually run backup:"
echo "   $SCRIPT_DIR/backup.sh $BACKUP_SOURCE:/ $BACKUP_DEST"
echo ""
echo "💡 To view cron logs:"
echo "   tail -f /var/log/backup-$(echo $BACKUP_SOURCE | tr '@:' '-').log"
echo ""


