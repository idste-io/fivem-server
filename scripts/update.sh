#!/bin/bash
# FiveM server update script
# Usage: bash /opt/fivem/scripts/update.sh
# Pulls latest config/resources from GitHub and restarts the server.

set -euo pipefail

REPO_DIR="/opt/fivem-config"
SERVER_DIR="/opt/fivem"
LOG_FILE="/var/log/fivem/update-$(date +%Y%m%d-%H%M%S).log"

mkdir -p /var/log/fivem

exec > >(tee -a "$LOG_FILE") 2>&1

echo "[fivem-update] $(date) — starting update"

# Pull latest config from GitHub
if [ -d "$REPO_DIR/.git" ]; then
  echo "[fivem-update] pulling latest from GitHub..."
  git -C "$REPO_DIR" pull --ff-only
else
  echo "[fivem-update] cloning repo..."
  git clone https://github.com/idste-io/fivem-server.git "$REPO_DIR"
fi

# Sync resources
echo "[fivem-update] syncing resources..."
rsync -av --delete "$REPO_DIR/resources/" "$SERVER_DIR/resources/"

# Sync server.cfg
echo "[fivem-update] syncing server.cfg..."
cp "$REPO_DIR/server.cfg" "$SERVER_DIR/server.cfg"

# Restart service
echo "[fivem-update] restarting fivem.service..."
systemctl restart fivem

echo "[fivem-update] done. Server status:"
systemctl is-active fivem || true
