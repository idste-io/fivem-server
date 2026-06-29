#!/bin/bash
# Eonexis Discord Bot — VPS Setup Script
# Run once: bash /opt/fivem-server/bot/setup.sh

set -e

BOT_DIR="/opt/eonexis-bot"
SRC_DIR="/opt/fivem-server/bot"

echo "[setup] Installing Eonexis Discord Bot..."

# Copy bot files to permanent location
mkdir -p "$BOT_DIR/data"
rsync -av --exclude='.env' --exclude='node_modules' --exclude='data/*.json' \
    "$SRC_DIR/" "$BOT_DIR/"

# Install Node.js deps
cd "$BOT_DIR"
npm install --production

# Create .env if not exists
if [ ! -f "$BOT_DIR/.env" ]; then
    cp "$BOT_DIR/.env.example" "$BOT_DIR/.env"
    echo ""
    echo "⚠️  IMPORTANT: Edit $BOT_DIR/.env and fill in your bot token!"
    echo "   nano $BOT_DIR/.env"
    echo ""
fi

# Create systemd service
cat > /etc/systemd/system/eonexis-bot.service << 'EOF'
[Unit]
Description=Eonexis Discord Bot
After=network.target fivem.service
Wants=fivem.service

[Service]
Type=simple
WorkingDirectory=/opt/eonexis-bot
ExecStart=/usr/bin/node /opt/eonexis-bot/index.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=eonexis-bot
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable eonexis-bot

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit /opt/eonexis-bot/.env — add your BOT_TOKEN and other values"
echo "2. Register slash commands: cd /opt/eonexis-bot && node deploy-commands.js"
echo "3. Start the bot: systemctl start eonexis-bot"
echo "4. View logs: journalctl -u eonexis-bot -f"
echo ""
