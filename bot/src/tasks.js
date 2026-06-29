'use strict';
const cron  = require('node-cron');
const { EmbedBuilder } = require('discord.js');
const cfg   = require('./config');
const fivem = require('./fivem');

const VIOLET = 0x9352DB;
const GREEN  = 0x4ADE80;
const RED    = 0xF87171;

const ACTIVE_MODS = [
    'loading-screen', 'eonexis-notify', 'eonexis-economy', 'eonexis-hud', 'eonexis-rules',
    'eonexis-welcomegift', 'eonexis-discord', 'eonexis-weather', 'eonexis-emotes',
    'eonexis-admintools', 'eonexis-nameplate', 'eonexis-fuel', 'eonexis-speedometer',
    'eonexis-spawn', 'eonexis-anticheat', 'eonexis-properties', 'eonexis-vehicles',
    'eonexis-jobs', 'eonexis-inventory', 'eonexis-controller', 'eonexis-gps',
    'eonexis-phone', 'eonexis-daily', 'eonexis-casino', 'eonexis-smallresources',
    'eonexis-shops', 'eonexis-hunger', 'eonexis-discord-notify', 'eonexis-skilltree',
    'eonexis-quests', 'eonexis-robbery', 'eonexis-racing', 'eonexis-discord-link',
];

async function postStatus(client) {
    try {
        const ch   = await client.channels.fetch(cfg.UPDATE_CHANNEL_ID);
        const info = await fivem.getServerInfo();
        const e    = new EmbedBuilder()
            .setTitle(info.online ? '🟢 Server Status — Online' : '🔴 Server Status — Offline')
            .setColor(info.online ? GREEN : RED)
            .setTimestamp()
            .setFooter({ text: 'Eonexis RP — IDSTE Co.' });

        if (info.online) {
            e.setDescription(`**${info.clients}/${info.maxClients}** players connected\n\`\`\`connect ${cfg.CONNECT_URL}\`\`\``)
             .addFields({
                 name: `📦 Active Mods (${ACTIVE_MODS.length})`,
                 value: ACTIVE_MODS.join(', '),
             });
        } else {
            e.setDescription('The server appears to be offline. The team has been notified.');
        }

        await ch.send({ embeds: [e] });
        console.log('[bot] Status post sent.');
    } catch (err) {
        console.error('[bot] Status post failed:', err.message);
    }
}

async function postPlayerPing(client) {
    try {
        const ch   = await client.channels.fetch(cfg.JOIN_LEAVE_CHANNEL_ID);
        const info = await fivem.getServerInfo();
        const e    = new EmbedBuilder()
            .setTitle(`🎮 Current Players (${info.clients}/${info.maxClients})`)
            .setColor(VIOLET)
            .setTimestamp()
            .setFooter({ text: 'Eonexis RP — Updated every 4 hours' });

        if (info.players.length === 0) {
            e.setDescription('No players online right now.');
        } else {
            e.setDescription(info.players.slice(0, 30).map((p, i) => `${i+1}. **${p.name}**`).join('\n'));
        }

        await ch.send({ embeds: [e] });
        console.log('[bot] Player ping sent.');
    } catch (err) {
        console.error('[bot] Player ping failed:', err.message);
    }
}

function startTasks(client) {
    // Status post every 12 hours (at 00:00 and 12:00 UTC)
    cron.schedule('0 0,12 * * *', () => postStatus(client));

    // Player ping every 4 hours
    cron.schedule('0 */4 * * *', () => postPlayerPing(client));

    console.log('[bot] Cron tasks started (status: 12h, players: 4h)');
}

module.exports = { startTasks, postStatus, postPlayerPing };
