#!/bin/bash
# Eonexis FiveM update script
# Usage: bash /opt/fivem-server/scripts/update.sh
# Remote: ssh root@187.124.93.157 "bash /opt/fivem-server/scripts/update.sh"

set -euo pipefail

REPO_DIR="/opt/fivem-server"
SERVER_DIR="/opt/fivem"

mkdir -p /var/log/fivem
LOG="/var/log/fivem/update-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

echo "[eonexis-fivem] $(date) — starting update"

# Pull latest from GitHub
git -C "$REPO_DIR" pull --ff-only
echo "[eonexis-fivem] repo synced"

# Sync server.cfg (does NOT touch license.cfg — key stays safe)
cp "$REPO_DIR/server.cfg" "$SERVER_DIR/server.cfg"

# Sync all resources (system + custom mods)
# --filter='protect ...' keeps runtime data/*.json on the server even when not in GitHub
rsync -av --delete \
  --exclude='.gitkeep' \
  --filter='protect [custom]/*/data/*.json' \
  --filter='protect [custom]/*/data/*.txt' \
  "$REPO_DIR/resources/" "$SERVER_DIR/resources/"
echo "[eonexis-fivem] resources synced"

# Restart server
systemctl restart fivem
sleep 2
STATUS=$(systemctl is-active fivem || true)
echo "[eonexis-fivem] fivem service: $STATUS"
echo "[eonexis-fivem] done ✓"
