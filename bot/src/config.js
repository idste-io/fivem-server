'use strict';
const fs = require('fs');
const path = require('path');

// Load .env manually (no dotenv dep)
const envPath = path.join(__dirname, '..', '.env');
if (fs.existsSync(envPath)) {
    fs.readFileSync(envPath, 'utf8').split('\n').forEach(line => {
        const [key, ...vals] = line.split('=');
        if (key && !key.startsWith('#') && vals.length) {
            process.env[key.trim()] = vals.join('=').trim();
        }
    });
}

module.exports = {
    BOT_TOKEN:          process.env.BOT_TOKEN,
    CLIENT_ID:          process.env.CLIENT_ID          || '1439269702982439005',
    GUILD_ID:           process.env.GUILD_ID           || '1370155044074426368',
    ADMIN_ROLE_ID:      process.env.ADMIN_ROLE_ID      || '1370155044120563887',
    VERIFIED_ROLE_ID:   process.env.VERIFIED_ROLE_ID   || '',
    OWNER_USER_ID:      process.env.OWNER_USER_ID      || '1443842518075707552',

    UPDATE_CHANNEL_ID:    process.env.UPDATE_CHANNEL_ID    || '1521149280495337522',
    ADMIN_CHANNEL_ID:     process.env.ADMIN_CHANNEL_ID     || '1521266367767253052',
    JOIN_LEAVE_CHANNEL_ID:process.env.JOIN_LEAVE_CHANNEL_ID|| '1521265403265941574',
    VERIFY_CHANNEL_ID:    process.env.VERIFY_CHANNEL_ID    || '1521265452402344036',
    CMD_CHANNEL_ID:       process.env.CMD_CHANNEL_ID       || '1521267564402184372',

    FIVEM_HOST:        process.env.FIVEM_HOST        || 'http://127.0.0.1:30120',
    FIVEM_SERVER_ID:   process.env.FIVEM_SERVER_ID   || 'vq3rbm5',
    CONNECT_URL:       process.env.CONNECT_URL        || 'play.invoxio.work',
    BOT_SECRET:        process.env.BOT_SECRET         || 'changeme',
    BOT_HTTP_PORT:     parseInt(process.env.BOT_HTTP_PORT || '3001'),

    LINKS_FILE:        process.env.LINKS_FILE        || path.join(__dirname, '..', 'data', 'links.json'),
    DISCORD_DAILY_FILE:process.env.DISCORD_DAILY_FILE|| path.join(__dirname, '..', 'data', 'discord-daily.json'),
    ECONOMY_FILE:      process.env.ECONOMY_FILE       || '/opt/fivem/resources/[custom]/eonexis-economy/data/players.json',
};
