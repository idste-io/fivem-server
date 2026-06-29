'use strict';
const {
    SlashCommandBuilder, EmbedBuilder, ButtonBuilder, ButtonStyle,
    ActionRowBuilder, PermissionFlagsBits,
} = require('discord.js');
const cfg  = require('./config');
const links = require('./links');
const fivem = require('./fivem');
const sc    = require('./serverControl');

// ── Embed helpers ──────────────────────────────────────────────────────────────

const VIOLET = 0x9352DB;
const GREEN  = 0x4ADE80;
const RED    = 0xF87171;
const GOLD   = 0xFBBF24;

function embed(title, color = VIOLET) {
    return new EmbedBuilder().setTitle(title).setColor(color)
        .setFooter({ text: 'Eonexis RP — IDSTE Co.' })
        .setTimestamp();
}

function isAdmin(member) {
    return member.id === cfg.OWNER_USER_ID
        || member.roles.cache.has(cfg.ADMIN_ROLE_ID);
}

// ── Channel enforcement ───────────────────────────────────────────────────────

// Maps command names to the channels where they're allowed (null = anywhere)
const CHANNEL_MAP = {
    verify:    cfg.VERIFY_CHANNEL_ID,
    unlink:    cfg.VERIFY_CHANNEL_ID,
    daily:     cfg.CMD_CHANNEL_ID,
    balance:   cfg.CMD_CHANNEL_ID,
    status:    cfg.CMD_CHANNEL_ID,
    players:   cfg.CMD_CHANNEL_ID,
    connect:   cfg.CMD_CHANNEL_ID,
    setadmin:  cfg.ADMIN_CHANNEL_ID,
    givemoney: cfg.ADMIN_CHANNEL_ID,
    kick:      cfg.ADMIN_CHANNEL_ID,
    announce:  cfg.ADMIN_CHANNEL_ID,
    ban:       cfg.ADMIN_CHANNEL_ID,
    logs:      cfg.ADMIN_CHANNEL_ID,
};

const CHANNEL_NAMES = {
    [cfg.VERIFY_CHANNEL_ID]:    '#verify',
    [cfg.CMD_CHANNEL_ID]:       '#cmd',
    [cfg.ADMIN_CHANNEL_ID]:     '#admin',
    [cfg.UPDATE_CHANNEL_ID]:    '#update',
    [cfg.JOIN_LEAVE_CHANNEL_ID]:'#join-leave',
};

function enforceChannel(interaction) {
    const cmd  = interaction.commandName;
    const need = CHANNEL_MAP[cmd];
    if (!need) return true;
    if (interaction.channelId === need) return true;
    const name = CHANNEL_NAMES[need] || `<#${need}>`;
    interaction.reply({
        content: `❌ Use \`/${cmd}\` in ${name} only.`,
        ephemeral: true,
    }).catch(() => {});
    return false;
}

// ── Command definitions ───────────────────────────────────────────────────────

const commandDefs = [
    new SlashCommandBuilder()
        .setName('verify')
        .setDescription('Link your Discord to your FiveM character')
        .addStringOption(o => o.setName('code').setDescription('Code from /link in-game').setRequired(true)),

    new SlashCommandBuilder()
        .setName('daily')
        .setDescription('Claim your daily Discord bonus ($500+ cash in-game)'),

    new SlashCommandBuilder()
        .setName('balance')
        .setDescription('Check your in-game cash and bank balance'),

    new SlashCommandBuilder()
        .setName('status')
        .setDescription('Check the Eonexis RP server status'),

    new SlashCommandBuilder()
        .setName('players')
        .setDescription('See who is currently online in Eonexis RP'),

    new SlashCommandBuilder()
        .setName('connect')
        .setDescription('Get the server connect info and link'),

    new SlashCommandBuilder()
        .setName('unlink')
        .setDescription('Unlink your Discord from your FiveM character'),

    new SlashCommandBuilder()
        .setName('setadmin')
        .setDescription('[Admin] Grant admin role to a Discord user')
        .addUserOption(o => o.setName('user').setDescription('Discord user').setRequired(true))
        .setDefaultMemberPermissions(PermissionFlagsBits.ManageRoles),

    new SlashCommandBuilder()
        .setName('givemoney')
        .setDescription('[Admin] Give in-game cash to a linked player')
        .addUserOption(o => o.setName('user').setDescription('Discord user').setRequired(true))
        .addIntegerOption(o => o.setName('amount').setDescription('Amount').setRequired(true).setMinValue(1))
        .setDefaultMemberPermissions(PermissionFlagsBits.ManageGuild),

    new SlashCommandBuilder()
        .setName('kick')
        .setDescription('[Admin] Kick a player from the FiveM server')
        .addUserOption(o => o.setName('user').setDescription('Discord user').setRequired(true))
        .addStringOption(o => o.setName('reason').setDescription('Reason'))
        .setDefaultMemberPermissions(PermissionFlagsBits.ManageGuild),

    new SlashCommandBuilder()
        .setName('announce')
        .setDescription('[Admin] Post an announcement to #update')
        .addStringOption(o => o.setName('message').setDescription('Announcement text').setRequired(true))
        .setDefaultMemberPermissions(PermissionFlagsBits.ManageGuild),

    new SlashCommandBuilder()
        .setName('ban')
        .setDescription('[Admin] Ban a linked player from the FiveM server')
        .addUserOption(o => o.setName('user').setDescription('Discord user').setRequired(true))
        .addStringOption(o => o.setName('reason').setDescription('Reason'))
        .setDefaultMemberPermissions(PermissionFlagsBits.BanMembers),

    new SlashCommandBuilder()
        .setName('logs')
        .setDescription('[Admin] Show the last 30 lines of FiveM server logs')
        .setDefaultMemberPermissions(PermissionFlagsBits.ManageGuild),
];

// ── Handlers ──────────────────────────────────────────────────────────────────

async function handleVerify(interaction) {
    await interaction.deferReply({ ephemeral: true });
    const code = interaction.options.getString('code').toUpperCase().trim();

    const existing = links.getByDiscord(interaction.user.id);
    if (existing) {
        return interaction.editReply({ embeds: [
            embed('Already Verified', GREEN)
                .setDescription(`You are already linked to **${existing.playerName}**.\nUse \`/unlink\` first to re-link.`)
        ]});
    }

    const result = await fivem.verifyCode(code);
    if (!result || result.error) {
        return interaction.editReply({ embeds: [
            embed('Invalid Code', RED)
                .setDescription('That code is invalid or expired.\nIn-game, type `/link` to get a new 6-character code.')
        ]});
    }

    links.save(interaction.user.id, result.license, result.name);
    await fivem.confirmLinked(code, interaction.user.id);

    if (cfg.VERIFIED_ROLE_ID) {
        try { await interaction.member.roles.add(cfg.VERIFIED_ROLE_ID); } catch {}
    }

    await interaction.editReply({ embeds: [
        embed('✅ Verified!', GREEN)
            .setDescription(`You are now linked as **${result.name}**.\n\nYou can now use \`/daily\`, \`/balance\`, and more in <#${cfg.CMD_CHANNEL_ID}>.`)
    ]});
}

async function handleDaily(interaction) {
    await interaction.deferReply({ ephemeral: true });
    const link = links.getByDiscord(interaction.user.id);
    if (!link) {
        return interaction.editReply({ content: `You need to link your account first. Go to <#${cfg.VERIFY_CHANNEL_ID}>.` });
    }
    const result = await fivem.claimDiscordDaily(interaction.user.id, link.license, link.playerName);
    if (!result.ok) {
        const h = Math.floor(result.remaining / 3600);
        const m = Math.floor((result.remaining % 3600) / 60);
        return interaction.editReply({ embeds: [
            embed('Already Claimed', GOLD)
                .setDescription(`You already claimed your daily bonus today.\nNext claim in **${h}h ${m}m**.`)
        ]});
    }
    return interaction.editReply({ embeds: [
        embed('💰 Daily Bonus Claimed!', GREEN)
            .setDescription(
                `**+$${result.amount}** added to your in-game cash.\n` +
                (result.streak > 1 ? `🔥 **${result.streak}-day streak!** Keep logging in daily for bigger bonuses.\n` : '') +
                `\nCharacter: **${link.playerName}**`
            )
    ]});
}

async function handleBalance(interaction) {
    await interaction.deferReply({ ephemeral: true });
    const link = links.getByDiscord(interaction.user.id);
    if (!link) {
        return interaction.editReply({ content: `Link your account first in <#${cfg.VERIFY_CHANNEL_ID}>.` });
    }
    const data = await fivem.getBalance(link.license);
    if (!data) {
        return interaction.editReply({ content: 'Could not fetch balance. Server may be offline.' });
    }
    return interaction.editReply({ embeds: [
        embed(`💳 ${link.playerName}'s Wallet`, VIOLET)
            .addFields(
                { name: '💵 Cash',   value: `$${(data.cash  ?? 0).toLocaleString()}`, inline: true },
                { name: '🏦 Bank',   value: `$${(data.bank  ?? 0).toLocaleString()}`, inline: true },
                { name: '💼 Job',    value: data.job   || 'Unemployed', inline: true },
            )
            .setDescription(data.offline ? '> Player is currently offline — showing last saved data.' : '')
    ]});
}

async function handleStatus(interaction) {
    await interaction.deferReply();
    try {
        const data = await fivem.fetchCfxData();
        if (!data) throw new Error('offline');
        return interaction.editReply({ embeds: [
            embed('🟢 Eonexis RP — Online', GREEN)
                .addFields(
                    { name: '👥 Players',   value: `${data.clients} / ${data.sv_maxclients}`, inline: true },
                    { name: '🌐 Connect',   value: `\`${cfg.CONNECT_URL}\``, inline: true },
                    { name: '🎮 Build',     value: data.vars?.sv_enforceGameBuild ?? '2944', inline: true },
                )
        ]});
    } catch {
        return interaction.editReply({ embeds: [
            embed('🔴 Eonexis RP — Offline', RED)
                .setDescription('Server is not responding. Check back later.')
        ]});
    }
}

async function handlePlayers(interaction) {
    await interaction.deferReply();
    try {
        const data = await fivem.fetchCfxData();
        if (!data || !data.players?.length) {
            return interaction.editReply({ embeds: [
                embed('No Players Online', GOLD).setDescription('The server is empty right now. Be the first to join!')
            ]});
        }
        const list = data.players.slice(0, 20).map(p => `• **${p.name}** (${p.ping}ms)`).join('\n');
        return interaction.editReply({ embeds: [
            embed(`👥 Online Players (${data.players.length}/${data.sv_maxclients})`, VIOLET)
                .setDescription(list + (data.players.length > 20 ? `\n*…and ${data.players.length - 20} more*` : ''))
        ]});
    } catch {
        return interaction.editReply({ content: 'Could not reach server.' });
    }
}

async function handleConnect(interaction) {
    const row = new ActionRowBuilder().addComponents(
        new ButtonBuilder()
            .setLabel('🎮 Launch FiveM')
            .setURL(`fivem://connect/${cfg.CONNECT_URL}`)
            .setStyle(ButtonStyle.Link),
    );
    return interaction.reply({ embeds: [
        embed('🌐 Connect to Eonexis RP', VIOLET)
            .addFields(
                { name: 'F8 Console',     value: `\`connect ${cfg.CONNECT_URL}\``, inline: false },
                { name: 'Server Address', value: `\`${cfg.CONNECT_URL}\``,         inline: false },
            )
            .setDescription('Click the button below or paste the address into FiveM.')
    ], components: [row] });
}

async function handleSetAdmin(interaction) {
    if (!isAdmin(interaction.member)) {
        return interaction.reply({ content: 'No permission.', ephemeral: true });
    }
    const target = interaction.options.getUser('user');
    try {
        const member = await interaction.guild.members.fetch(target.id);
        await member.roles.add(cfg.ADMIN_ROLE_ID);
        return interaction.reply({ embeds: [
            embed('Admin Granted', GREEN)
                .setDescription(`**${target.username}** has been given the admin role.`)
        ], ephemeral: true });
    } catch (err) {
        return interaction.reply({ content: `Failed: ${err.message}`, ephemeral: true });
    }
}

async function handleGiveMoney(interaction) {
    if (!isAdmin(interaction.member)) {
        return interaction.reply({ content: 'No permission.', ephemeral: true });
    }
    await interaction.deferReply({ ephemeral: true });
    const target = interaction.options.getUser('user');
    const amount = interaction.options.getInteger('amount');
    const link   = links.getByDiscord(target.id);
    if (!link) {
        return interaction.editReply({ content: `${target.username} is not linked to a FiveM character.` });
    }
    const res = await fivem.giveMoney(link.license, amount, `Discord admin gift from ${interaction.user.username}`);
    return interaction.editReply({ embeds: [
        embed(res?.ok ? 'Money Sent' : 'Player Offline', res?.ok ? GREEN : GOLD)
            .setDescription(res?.ok
                ? `Sent **$${amount.toLocaleString()}** to **${link.playerName}**.`
                : `**${link.playerName}** is offline. Money was added to their saved data.`)
    ]});
}

async function handleKick(interaction) {
    if (!isAdmin(interaction.member)) {
        return interaction.reply({ content: 'No permission.', ephemeral: true });
    }
    await interaction.deferReply({ ephemeral: true });
    const target = interaction.options.getUser('user');
    const reason = interaction.options.getString('reason') || 'Kicked by admin via Discord';
    const link   = links.getByDiscord(target.id);
    if (!link) {
        return interaction.editReply({ content: `${target.username} is not linked to a FiveM character.` });
    }
    try {
        const res = await fivem.fivemPost('/kick', { license: link.license, reason });
        if (res && res.ok) {
            return interaction.editReply({ content: `Kicked **${link.playerName}** from the server.` });
        } else {
            return interaction.editReply({ content: `Player is not online or kick failed.` });
        }
    } catch {
        return interaction.editReply({ content: 'Failed to reach server.' });
    }
}

async function handleBan(interaction) {
    if (!isAdmin(interaction.member)) {
        return interaction.reply({ content: 'No permission.', ephemeral: true });
    }
    await interaction.deferReply({ ephemeral: true });
    const target = interaction.options.getUser('user');
    const reason = interaction.options.getString('reason') || 'Banned via Discord admin';
    const link   = links.getByDiscord(target.id);
    if (!link) {
        return interaction.editReply({ content: `${target.username} is not linked to a FiveM character.` });
    }
    try {
        // Kick first (ban persists via future allowlist/anticheat logic)
        await fivem.fivemPost('/kick', { license: link.license, reason: `[BANNED] ${reason}` });
        // Add to ban list file
        const banFile = require('path').join(__dirname, '..', 'data', 'bans.json');
        const fs = require('fs');
        let bans = {};
        try { bans = JSON.parse(fs.readFileSync(banFile, 'utf8')); } catch {}
        bans[link.license] = { discordId: target.id, name: link.playerName, reason, bannedAt: Date.now(), bannedBy: interaction.user.username };
        fs.writeFileSync(banFile, JSON.stringify(bans, null, 2));
        return interaction.editReply({ embeds: [
            embed('🔨 Player Banned', RED)
                .addFields(
                    { name: 'Player',  value: link.playerName, inline: true },
                    { name: 'Discord', value: `<@${target.id}>`, inline: true },
                    { name: 'Reason',  value: reason, inline: false },
                )
        ]});
    } catch (err) {
        return interaction.editReply({ content: `Failed: ${err.message}` });
    }
}

async function handleAnnounce(interaction) {
    if (!isAdmin(interaction.member)) {
        return interaction.reply({ content: 'No permission.', ephemeral: true });
    }
    const message = interaction.options.getString('message');
    try {
        const ch = await interaction.client.channels.fetch(cfg.UPDATE_CHANNEL_ID);
        await ch.send({ embeds: [
            new EmbedBuilder()
                .setTitle('📢 Server Announcement')
                .setColor(GOLD)
                .setDescription(message)
                .setAuthor({ name: interaction.user.username, iconURL: interaction.user.displayAvatarURL() })
                .setFooter({ text: 'Eonexis RP — IDSTE Co.' })
                .setTimestamp()
        ]});
        return interaction.reply({ content: '✅ Announcement posted to <#' + cfg.UPDATE_CHANNEL_ID + '>.', ephemeral: true });
    } catch (e) {
        return interaction.reply({ content: `Failed: ${e.message}`, ephemeral: true });
    }
}

async function handleLogs(interaction) {
    if (!isAdmin(interaction.member)) {
        return interaction.reply({ content: 'No permission.', ephemeral: true });
    }
    await interaction.deferReply({ ephemeral: true });
    const logs = await sc.getLogs(30);
    const truncated = logs.length > 1900 ? '...\n' + logs.slice(-1900) : logs;
    return interaction.editReply({ content: `**FiveM Logs (last 30 lines):**\n\`\`\`\n${truncated || '(empty)'}\n\`\`\`` });
}

async function handleUnlink(interaction) {
    await interaction.deferReply({ ephemeral: true });
    const link = links.getByDiscord(interaction.user.id);
    if (!link) {
        return interaction.editReply({ content: 'You are not linked.' });
    }
    links.remove(interaction.user.id);
    try {
        if (cfg.VERIFIED_ROLE_ID) await interaction.member.roles.remove(cfg.VERIFIED_ROLE_ID);
    } catch {}
    return interaction.editReply({ embeds: [
        embed('Unlinked', GOLD).setDescription(`Your Discord has been unlinked from **${link.playerName}**.`)
    ]});
}

// ── Verify channel setup ──────────────────────────────────────────────────────

async function postVerifyMessage(client) {
    try {
        const ch = await client.channels.fetch(cfg.VERIFY_CHANNEL_ID);
        const messages = await ch.messages.fetch({ limit: 10 });
        for (const [, msg] of messages) {
            if (msg.author.id === client.user.id) await msg.delete().catch(() => {});
        }

        const row = new ActionRowBuilder().addComponents(
            new ButtonBuilder().setCustomId('verify_start').setLabel('🎮 Verify with FiveM').setStyle(ButtonStyle.Primary),
            new ButtonBuilder().setCustomId('member_join').setLabel('👋 Join as Member').setStyle(ButtonStyle.Secondary),
        );

        await ch.send({
            embeds: [
                new EmbedBuilder()
                    .setTitle('⬡  EONEXIS RP  —  VERIFICATION')
                    .setColor(VIOLET)
                    .setDescription(
                        '**Welcome to the Eonexis RP Discord.**\n\n' +
                        'To access all channels, verify your identity below.\n\n' +
                        '**🎮 Verify with FiveM**\n' +
                        'Link your Discord to your in-game character.\n' +
                        'Join the server, type `/link` in-game, then use `/verify <code>` in this channel.\n\n' +
                        '**👋 Join as Member**\n' +
                        'Get basic Discord access without a FiveM character.'
                    )
                    .setFooter({ text: `Eonexis RP — IDSTE Co. | ${cfg.CONNECT_URL}` })
            ],
            components: [row],
        });
        console.log('[bot] Verify message posted.');
    } catch (e) {
        console.error('[bot] Failed to post verify message:', e.message);
    }
}

// ── Button handler ────────────────────────────────────────────────────────────

async function handleAdminButton(interaction) {
    if (!isAdmin(interaction.member)) {
        return interaction.reply({ content: 'Admin only.', ephemeral: true });
    }

    const id = interaction.customId;

    if (id === 'admin_status_refresh') {
        await interaction.deferUpdate();
        const { refreshAdminDashboard } = require('./dashboards');
        await refreshAdminDashboard(interaction.client);
        return;
    }

    if (id === 'admin_restart') {
        await interaction.deferReply({ ephemeral: true });
        const r = await sc.restartServer();
        await interaction.editReply({ content: r.ok ? '✅ FiveM server restarting…' : `❌ Restart failed: ${r.err}` });
        setTimeout(() => {
            const { refreshAdminDashboard } = require('./dashboards');
            refreshAdminDashboard(interaction.client).catch(() => {});
        }, 10000);
        return;
    }

    if (id === 'admin_stop') {
        await interaction.deferReply({ ephemeral: true });
        const r = await sc.stopServer();
        await interaction.editReply({ content: r.ok ? '✅ FiveM server stopped.' : `❌ Stop failed: ${r.err}` });
        setTimeout(() => {
            const { refreshAdminDashboard } = require('./dashboards');
            refreshAdminDashboard(interaction.client).catch(() => {});
        }, 3000);
        return;
    }

    if (id === 'admin_start') {
        await interaction.deferReply({ ephemeral: true });
        const r = await sc.startServer();
        await interaction.editReply({ content: r.ok ? '✅ FiveM server starting…' : `❌ Start failed: ${r.err}` });
        setTimeout(() => {
            const { refreshAdminDashboard } = require('./dashboards');
            refreshAdminDashboard(interaction.client).catch(() => {});
        }, 10000);
        return;
    }

    if (id === 'admin_logs') {
        await interaction.deferReply({ ephemeral: true });
        const logs = await sc.getLogs(25);
        const truncated = logs.length > 1900 ? logs.slice(-1900) : logs;
        return interaction.editReply({ content: `**FiveM Logs:**\n\`\`\`\n${truncated || '(empty)'}\n\`\`\`` });
    }

    if (id === 'admin_modlist') {
        await interaction.deferReply({ ephemeral: true });
        const mods = sc.parseModList();
        if (!mods.length) {
            return interaction.editReply({ content: 'Could not read mod list.' });
        }
        const on  = mods.filter(m => m.enabled).map(m => `✅ ${m.name}`).join('\n');
        const off = mods.filter(m => !m.enabled).map(m => `⬜ ${m.name}`).join('\n');
        return interaction.editReply({ embeds: [
            new EmbedBuilder()
                .setTitle('🧩 Mod List')
                .setColor(VIOLET)
                .addFields(
                    { name: `Enabled (${mods.filter(m=>m.enabled).length})`,  value: on  || '(none)', inline: true },
                    { name: `Disabled (${mods.filter(m=>!m.enabled).length})`, value: off || '(none)', inline: true },
                )
                .setFooter({ text: 'Eonexis RP — IDSTE Co.' })
                .setTimestamp()
        ]});
    }

    if (id === 'admin_players') {
        await interaction.deferReply({ ephemeral: true });
        try {
            const data = await fivem.fetchCfxData();
            if (!data || !data.players?.length) {
                return interaction.editReply({ content: 'No players online.' });
            }
            const list = data.players.map(p => `**${p.name}** — ${p.ping}ms`).join('\n');
            return interaction.editReply({ content: `**Online Players (${data.players.length}/${data.sv_maxclients}):**\n${list}` });
        } catch {
            return interaction.editReply({ content: 'Could not reach server.' });
        }
    }

    if (id === 'admin_deploy') {
        await interaction.deferReply({ ephemeral: true });
        const r = await sc.run('cd /opt/fivem-server && git pull origin master 2>&1 && bash scripts/update.sh <<< y 2>&1 | tail -10');
        const out = (r.out + r.err).slice(-1800) || '(no output)';
        return interaction.editReply({ content: `**Deploy output:**\n\`\`\`\n${out}\n\`\`\`` });
    }
}

async function handleButton(interaction) {
    const id = interaction.customId;
    if (id.startsWith('admin_')) return handleAdminButton(interaction);

    if (id === 'verify_start') {
        return interaction.reply({ ephemeral: true, embeds: [
            embed('Verify with FiveM', VIOLET)
                .setDescription(
                    '**Step 1:** Join Eonexis RP in FiveM\n`connect ' + cfg.CONNECT_URL + '`\n\n' +
                    '**Step 2:** In-game, open chat and type `/link`\n\n' +
                    '**Step 3:** Come back here and type `/verify <code>`\n\n' +
                    '*Codes expire in 10 minutes.*'
                )
        ]});
    }
    if (id === 'member_join') {
        await interaction.deferReply({ ephemeral: true });
        if (cfg.VERIFIED_ROLE_ID) {
            try { await interaction.member.roles.add(cfg.VERIFIED_ROLE_ID); } catch {}
        }
        return interaction.editReply({ embeds: [
            embed('Welcome!', GREEN)
                .setDescription('You now have community member access. Welcome to Eonexis RP!')
        ]});
    }
}

// ── Export ────────────────────────────────────────────────────────────────────

module.exports = {
    commandDefs,
    postVerifyMessage,
    async handle(interaction) {
        if (interaction.isButton()) return handleButton(interaction).catch(e => {
            console.error('[bot] button error:', e.message);
        });
        if (!interaction.isChatInputCommand()) return;

        if (!enforceChannel(interaction)) return;

        const cmd = interaction.commandName;
        const map = {
            verify:    handleVerify,
            daily:     handleDaily,
            balance:   handleBalance,
            status:    handleStatus,
            players:   handlePlayers,
            connect:   handleConnect,
            setadmin:  handleSetAdmin,
            givemoney: handleGiveMoney,
            kick:      handleKick,
            ban:       handleBan,
            announce:  handleAnnounce,
            logs:      handleLogs,
            unlink:    handleUnlink,
        };
        if (map[cmd]) await map[cmd](interaction).catch(e => {
            console.error(`[bot] /${cmd} error:`, e.message);
            interaction.reply({ content: 'Something went wrong.', ephemeral: true }).catch(() => {});
        });
    },
};
