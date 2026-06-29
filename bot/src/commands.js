'use strict';
const { SlashCommandBuilder, EmbedBuilder, ButtonBuilder, ButtonStyle, ActionRowBuilder, PermissionFlagsBits } = require('discord.js');
const cfg    = require('./config');
const links  = require('./links');
const fivem  = require('./fivem');

// ── Embed helpers ─────────────────────────────────────────────────────────────

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
        .setName('setadmin')
        .setDescription('[Admin] Grant admin role to a user')
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
        .setDescription('[Admin] Post an announcement to the update channel')
        .addStringOption(o => o.setName('message').setDescription('Message').setRequired(true))
        .setDefaultMemberPermissions(PermissionFlagsBits.ManageGuild),

    new SlashCommandBuilder()
        .setName('unlink')
        .setDescription('Unlink your Discord from your FiveM character'),
];

// ── Command handlers ──────────────────────────────────────────────────────────

async function handleVerify(interaction) {
    await interaction.deferReply({ ephemeral: true });
    const code = interaction.options.getString('code').toUpperCase().trim();

    // Check if already linked
    const existing = links.getByDiscord(interaction.user.id);
    if (existing) {
        return interaction.editReply({ embeds: [
            embed('Already Verified', GREEN)
                .setDescription(`You are already linked to **${existing.playerName}**.\nUse \`/unlink\` first if you want to re-link.`)
        ]});
    }

    const result = await fivem.verifyCode(code);
    if (!result || result.error) {
        return interaction.editReply({ embeds: [
            embed('Invalid Code', RED)
                .setDescription('That code is invalid or has expired.\nIn-game, type `/link` to get a fresh 10-minute code.')
        ]});
    }

    // Save link
    links.set(interaction.user.id, result.license, result.name);
    await fivem.markLinked(code, interaction.user.id);

    // Assign verified role
    try {
        if (cfg.VERIFIED_ROLE_ID) {
            await interaction.member.roles.add(cfg.VERIFIED_ROLE_ID);
        }
    } catch (e) {
        console.warn('[bot] Could not assign verified role:', e.message);
    }

    return interaction.editReply({ embeds: [
        embed('Verified!', GREEN)
            .setDescription(`Welcome, **${result.name}**! ✓\nYour Discord is now linked to your FiveM character.\n\nYou can now use \`/daily\` and \`/balance\` here.`)
    ]});
}

async function handleDaily(interaction) {
    await interaction.deferReply({ ephemeral: true });
    const link = links.getByDiscord(interaction.user.id);

    if (!link) {
        return interaction.editReply({ embeds: [
            embed('Not Linked', RED)
                .setDescription('You need to link your Discord first.\nIn-game: type `/link` to get a code, then use `/verify <code>` here.')
        ]});
    }

    const daily = fivem.claimDiscordDaily(link.license);
    if (!daily.ok) {
        return interaction.editReply({ embeds: [
            embed('Daily Already Claimed', GOLD)
                .setDescription(daily.msg)
        ]});
    }

    // Try to give money online first, fall back to file edit
    const online = await fivem.giveMoneyOnline(link.license, daily.amount, 'discord daily');
    if (!online || !online.ok) {
        fivem.addMoneyOffline(link.license, daily.amount, 'discord daily');
    }

    return interaction.editReply({ embeds: [
        embed('Daily Bonus Claimed!', GREEN)
            .setDescription(`**+$${daily.amount.toLocaleString()}** added to your wallet!`)
            .addFields(
                { name: 'Day Streak', value: `🔥 Day ${daily.streak}`, inline: true },
                { name: 'Streak Bonus', value: `+$${daily.bonus}`, inline: true },
                { name: 'Character', value: link.playerName, inline: true }
            )
    ]});
}

async function handleBalance(interaction) {
    await interaction.deferReply({ ephemeral: true });
    const link = links.getByDiscord(interaction.user.id);

    if (!link) {
        return interaction.editReply({ embeds: [
            embed('Not Linked', RED)
                .setDescription('Use `/verify` to link your Discord to your FiveM character first.')
        ]});
    }

    const data = await fivem.getBalance(link.license) || fivem.getPlayerData(link.license);
    if (!data) {
        return interaction.editReply({ embeds: [
            embed('No Data', RED).setDescription('Could not load your character data. Make sure you have joined the server at least once.')
        ]});
    }

    return interaction.editReply({ embeds: [
        embed(`💰 ${link.playerName}'s Balance`, VIOLET)
            .addFields(
                { name: 'Cash', value: `$${(data.cash||0).toLocaleString()}`, inline: true },
                { name: 'Bank', value: `$${(data.bank||0).toLocaleString()}`, inline: true },
                { name: 'Job', value: data.job || 'Unemployed', inline: true },
            )
            .setDescription(data.offline ? '*Character is currently offline*' : '*Character is online*')
    ]});
}

async function handleStatus(interaction) {
    await interaction.deferReply();
    const info = await fivem.getServerInfo();
    const e = embed(info.online ? '🟢 Server Online' : '🔴 Server Offline', info.online ? GREEN : RED)
        .setDescription(info.online
            ? `**${info.clients}/${info.maxClients}** players online\n\`connect ${cfg.CONNECT_URL}\``
            : 'The server appears to be offline.')
        .addFields({ name: 'Connect', value: `\`${cfg.CONNECT_URL}\``, inline: true });
    await interaction.editReply({ embeds: [e] });
}

async function handlePlayers(interaction) {
    await interaction.deferReply();
    const info = await fivem.getServerInfo();
    const e = embed(`🎮 Online Players (${info.clients}/${info.maxClients})`, VIOLET);
    if (info.players.length === 0) {
        e.setDescription('No players online right now.');
    } else {
        e.setDescription(info.players.slice(0, 25).map((p, i) => `${i+1}. **${p.name}**`).join('\n'));
    }
    await interaction.editReply({ embeds: [e] });
}

async function handleConnect(interaction) {
    const row = new ActionRowBuilder().addComponents(
        new ButtonBuilder().setLabel('Open FiveM').setStyle(ButtonStyle.Link)
            .setURL(`fivem://connect/${cfg.CONNECT_URL}`)
    );
    await interaction.reply({
        embeds: [
            embed('🎮 Connect to Eonexis RP', VIOLET)
                .setDescription(`**Server:** ${cfg.CONNECT_URL}\n**Players:** See \`/players\`\n\nClick the button below or press F8 in FiveM and type:\n\`\`\`connect ${cfg.CONNECT_URL}\`\`\``)
        ],
        components: [row],
    });
}

async function handleSetAdmin(interaction) {
    if (!isAdmin(interaction.member)) {
        return interaction.reply({ content: 'No permission.', ephemeral: true });
    }
    const target = interaction.options.getMember('user');
    await target.roles.add(cfg.ADMIN_ROLE_ID);
    await interaction.reply({ embeds: [
        embed('Admin Role Granted', GREEN)
            .setDescription(`<@${target.id}> now has the admin role.`)
    ]});
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
        return interaction.editReply({ content: `<@${target.id}> is not linked.` });
    }

    const online = await fivem.giveMoneyOnline(link.license, amount, `admin gift from ${interaction.user.username}`);
    if (!online || !online.ok) {
        fivem.addMoneyOffline(link.license, amount, 'admin gift via Discord');
    }

    await interaction.editReply({ embeds: [
        embed('Money Given', GREEN)
            .setDescription(`Gave **$${amount.toLocaleString()}** to **${link.playerName}** (${online?.ok ? 'online' : 'offline — file updated'})`)
    ]});

    // Log to admin channel
    try {
        const adminCh = await interaction.client.channels.fetch(cfg.ADMIN_CHANNEL_ID);
        adminCh.send({ embeds: [
            embed('Admin Action: Give Money', GOLD)
                .setDescription(`**By:** ${interaction.user.username}\n**To:** ${link.playerName}\n**Amount:** $${amount.toLocaleString()}`)
        ]});
    } catch {}
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
        return interaction.editReply({ content: `<@${target.id}> is not linked to a FiveM character.` });
    }

    try {
        const res = await fivem.fivemPost('/kick', { license: link.license, reason });
        if (res && res.ok) {
            await interaction.editReply({ content: `Kicked **${link.playerName}** from the server.` });
        } else {
            await interaction.editReply({ content: `Player is not online or kick failed.` });
        }
    } catch {
        await interaction.editReply({ content: 'Failed to reach server.' });
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
            embed('📢 Server Announcement', GOLD)
                .setDescription(message)
                .setAuthor({ name: interaction.user.username, iconURL: interaction.user.displayAvatarURL() })
        ]});
        await interaction.reply({ content: 'Announcement posted.', ephemeral: true });
    } catch (e) {
        await interaction.reply({ content: `Failed: ${e.message}`, ephemeral: true });
    }
}

async function handleUnlink(interaction) {
    await interaction.deferReply({ ephemeral: true });
    const link = links.getByDiscord(interaction.user.id);
    if (!link) {
        return interaction.editReply({ content: 'You are not linked.' });
    }
    links.remove(interaction.user.id);
    // Remove verified role
    try {
        if (cfg.VERIFIED_ROLE_ID) {
            await interaction.member.roles.remove(cfg.VERIFIED_ROLE_ID);
        }
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
        // Delete old bot messages in verify channel
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
                        'Join the server, type `/link`, then use `/verify <code>` here.\n\n' +
                        '**👋 Join as Member**\n' +
                        'Get basic Discord access without a FiveM character.'
                    )
                    .setFooter({ text: 'Eonexis RP — IDSTE Co. | play.invoxio.work' })
            ],
            components: [row],
        });
        console.log('[bot] Verify message posted.');
    } catch (e) {
        console.error('[bot] Failed to post verify message:', e.message);
    }
}

// ── Button handler ────────────────────────────────────────────────────────────

async function handleButton(interaction) {
    if (interaction.customId === 'verify_start') {
        await interaction.reply({ ephemeral: true, embeds: [
            embed('Verify with FiveM', VIOLET)
                .setDescription(
                    '**Step 1:** Join Eonexis RP in FiveM\n`connect ' + cfg.CONNECT_URL + '`\n\n' +
                    '**Step 2:** In-game, open chat and type `/link`\n\n' +
                    '**Step 3:** Come back here and type `/verify <code>`\n\n' +
                    '*Codes expire after 10 minutes.*'
                )
        ]});
    } else if (interaction.customId === 'member_join') {
        await interaction.deferReply({ ephemeral: true });
        if (cfg.VERIFIED_ROLE_ID) {
            try { await interaction.member.roles.add(cfg.VERIFIED_ROLE_ID); } catch {}
        }
        await interaction.editReply({ embeds: [
            embed('Welcome!', GREEN)
                .setDescription('You now have community member access. Enjoy the server!')
        ]});
    }
}

module.exports = {
    commandDefs,
    postVerifyMessage,
    async handle(interaction) {
        if (interaction.isButton()) return handleButton(interaction);
        if (!interaction.isChatInputCommand()) return;

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
            announce:  handleAnnounce,
            unlink:    handleUnlink,
        };
        if (map[cmd]) await map[cmd](interaction).catch(e => {
            console.error(`[bot] command /${cmd} error:`, e.message);
            interaction.reply({ content: 'Something went wrong.', ephemeral: true }).catch(() => {});
        });
    },
};
