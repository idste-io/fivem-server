#!/bin/bash
# FiveM server update script
# Pulls latest from GitHub and restarts the server.
# Usage: bash /opt/fivem-server/scripts/update.sh
# Or remotely: ssh root@187.124.93.157 "bash /opt/fivem-server/scripts/update.sh"

set -euo pipefail

REPO_DIR="/opt/fivem-server"
SERVER_DIR="/opt/fivem"

mkdir -p /var/log/fivem
LOG="/var/log/fivem/update-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

echo "[fivem-update] $(date) — starting"

git -C "$REPO_DIR" pull --ff-only
echo "[fivem-update] repo up to date"

rsync -av --delete "$REPO_DIR/resources/" "$SERVER_DIR/resources/"
cp "$REPO_DIR/server.cfg" "$SERVER_DIR/server.cfg"
echo "[fivem-update] files synced"

systemctl restart fivem
echo "[fivem-update] service restarted — $(systemctl is-active fivem)"
