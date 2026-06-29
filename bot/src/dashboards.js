'use strict';
const { EmbedBuilder, ButtonBuilder, ButtonStyle, ActionRowBuilder } = require('discord.js');
const cfg = require('./config');
const fivem = require('./fivem');
const sc = require('./serverControl');

const VIOLET = 0x9352DB;
const GREEN  = 0x4ADE80;
const RED    = 0xF87171;
const GOLD   = 0xFBBF24;
const BLUE   = 0x60A5FA;

function e(title, color = VIOLET) {
    return new EmbedBuilder().setTitle(title).setColor(color)
        .setFooter({ text: 'Eonexis RP — IDSTE Co. | play.invoxio.work' })
        .setTimestamp();
}

// Delete all bot messages in a channel
async function clearBotMessages(ch, client) {
    try {
        const msgs = await ch.messages.fetch({ limit: 20 });
        for (const [, m] of msgs) {
            if (m.author.id === client.user.id) await m.delete().catch(() => {});
        }
    } catch {}
}

// ── #cmd channel dashboard ────────────────────────────────────────────────────

async function postCmdDashboard(client) {
    try {
        const ch = await client.channels.fetch(cfg.CMD_CHANNEL_ID);
        await clearBotMessages(ch, client);
        await ch.send({ embeds: [
            e('⬡  EONEXIS RP  —  PLAYER COMMANDS', VIOLET)
                .setDescription(
                    '**Use these slash commands in this channel:**\n\n' +
                    '`/verify <code>` — Link your Discord to your FiveM character\n' +
                    '`/daily` — Claim your daily $500 bonus (24h cooldown, streak bonus)\n' +
                    '`/balance` — See your in-game cash and bank balance\n' +
                    '`/status` — Live server status and player count\n' +
                    '`/players` — See who is currently online\n' +
                    '`/connect` — Get the FiveM connect link\n' +
                    '`/unlink` — Disconnect your Discord from FiveM\n\n' +
                    '> To link your account: join the server, type `/link` in-game, then use `/verify <code>` here.'
                )
        ]});
        console.log('[bot] #cmd dashboard posted');
    } catch (e) {
        console.error('[bot] cmd dashboard error:', e.message);
    }
}

// ── #join-leave channel dashboard ────────────────────────────────────────────

async function postJoinLeaveDashboard(client) {
    try {
        const ch = await client.channels.fetch(cfg.JOIN_LEAVE_CHANNEL_ID);
        await clearBotMessages(ch, client);
        await ch.send({ embeds: [
            e('⬡  EONEXIS RP  —  SERVER ACTIVITY', BLUE)
                .setDescription(
                    'This channel logs **FiveM server join/leave events** in real time.\n\n' +
                    '🟢 **Player Join** — posted when someone connects to the server\n' +
                    '🔴 **Player Leave** — posted when someone disconnects\n' +
                    '📊 **Player Ping** — current player list posted every 4 hours\n\n' +
                    '> Live events only — historical logs are not shown here.'
                )
        ]});
        console.log('[bot] #join-leave dashboard posted');
    } catch (e) {
        console.error('[bot] join-leave dashboard error:', e.message);
    }
}

// ── #update channel dashboard ─────────────────────────────────────────────────

async function postUpdateDashboard(client) {
    try {
        const ch = await client.channels.fetch(cfg.UPDATE_CHANNEL_ID);
        await clearBotMessages(ch, client);
        await ch.send({ embeds: [
            e('⬡  EONEXIS RP  —  SERVER UPDATES', GOLD)
                .setDescription(
                    'This channel receives **automated server status posts** every 12 hours,\n' +
                    'plus admin announcements.\n\n' +
                    '📡 Server status + player count — every 12h\n' +
                    '📢 Admin announcements via `/announce`\n' +
                    '🔔 Mod updates and maintenance notices\n\n' +
                    `> Connect at: \`${cfg.CONNECT_URL}\``
                )
        ]});
        console.log('[bot] #update dashboard posted');
    } catch (e) {
        console.error('[bot] update dashboard error:', e.message);
    }
}

// ── #admin channel dashboard ──────────────────────────────────────────────────

async function buildAdminEmbed(serverStatus, serverData) {
    const online = serverStatus === 'active';
    const players = serverData ? serverData.clients : 0;
    const maxPlayers = serverData ? serverData.sv_maxclients : 64;

    return e('⬡  EONEXIS RP  —  ADMIN CONSOLE', online ? GREEN : RED)
        .addFields(
            {
                name: '🖥️  Server Status',
                value: online
                    ? `🟢 **Online** — ${players}/${maxPlayers} players`
                    : `🔴 **Offline / Down**`,
                inline: true,
            },
            {
                name: '🌐  Connect',
                value: `\`${cfg.CONNECT_URL}\``,
                inline: true,
            },
            {
                name: '​', value: '​', inline: true,
            },
            {
                name: '⚙️  Admin Commands (use in this channel)',
                value: [
                    '`/setadmin @user` — Grant admin role',
                    '`/givemoney @user <amount>` — Give in-game cash',
                    '`/kick @user [reason]` — Kick from FiveM server',
                    '`/announce <message>` — Post to #update channel',
                ].join('\n'),
                inline: false,
            },
            {
                name: '🔧  Server Controls (buttons below)',
                value: 'Use the buttons below to restart, stop, or check server status.\nMod list and logs are also available.',
                inline: false,
            }
        );
}

function adminControlRows() {
    const row1 = new ActionRowBuilder().addComponents(
        new ButtonBuilder().setCustomId('admin_restart').setLabel('🔄 Restart FiveM').setStyle(ButtonStyle.Danger),
        new ButtonBuilder().setCustomId('admin_stop').setLabel('⏹ Stop Server').setStyle(ButtonStyle.Danger),
        new ButtonBuilder().setCustomId('admin_start').setLabel('▶ Start Server').setStyle(ButtonStyle.Success),
        new ButtonBuilder().setCustomId('admin_status_refresh').setLabel('🔃 Refresh Status').setStyle(ButtonStyle.Secondary),
    );
    const row2 = new ActionRowBuilder().addComponents(
        new ButtonBuilder().setCustomId('admin_logs').setLabel('📋 View Logs').setStyle(ButtonStyle.Secondary),
        new ButtonBuilder().setCustomId('admin_modlist').setLabel('🧩 Mod List').setStyle(ButtonStyle.Secondary),
        new ButtonBuilder().setCustomId('admin_deploy').setLabel('🚀 Deploy Update').setStyle(ButtonStyle.Primary),
        new ButtonBuilder().setCustomId('admin_players').setLabel('👥 Player List').setStyle(ButtonStyle.Secondary),
    );
    return [row1, row2];
}

async function postAdminDashboard(client) {
    try {
        const ch = await client.channels.fetch(cfg.ADMIN_CHANNEL_ID);
        await clearBotMessages(ch, client);

        let serverData = null;
        let serverStatus = 'unknown';
        try {
            serverStatus = await sc.getStatus();
            serverData = await fivem.fetchCfxData();
        } catch {}

        const embed = await buildAdminEmbed(serverStatus, serverData);

        await ch.send({
            embeds: [embed],
            components: adminControlRows(),
        });
        console.log('[bot] #admin dashboard posted');
    } catch (err) {
        console.error('[bot] admin dashboard error:', err.message);
    }
}

// ── All dashboards ────────────────────────────────────────────────────────────

async function postAllDashboards(client) {
    await Promise.allSettled([
        postCmdDashboard(client),
        postJoinLeaveDashboard(client),
        postUpdateDashboard(client),
        postAdminDashboard(client),
    ]);
}

// Refresh admin dashboard without clearing (update in place)
async function refreshAdminDashboard(client) {
    try {
        const ch = await client.channels.fetch(cfg.ADMIN_CHANNEL_ID);
        const msgs = await ch.messages.fetch({ limit: 10 });
        let dashMsg = null;
        for (const [, m] of msgs) {
            if (m.author.id === client.user.id && m.components.length > 0) {
                dashMsg = m;
                break;
            }
        }

        let serverData = null;
        let serverStatus = 'unknown';
        try {
            serverStatus = await sc.getStatus();
            serverData = await fivem.fetchCfxData();
        } catch {}

        const embed = await buildAdminEmbed(serverStatus, serverData);

        if (dashMsg) {
            await dashMsg.edit({ embeds: [embed], components: adminControlRows() });
        } else {
            await postAdminDashboard(client);
        }
    } catch (e) {
        console.error('[bot] refreshAdminDashboard error:', e.message);
    }
}

module.exports = {
    postAllDashboards,
    postCmdDashboard,
    postJoinLeaveDashboard,
    postUpdateDashboard,
    postAdminDashboard,
    refreshAdminDashboard,
};
