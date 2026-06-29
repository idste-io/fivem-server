'use strict';
const { Client, GatewayIntentBits, Partials, ActivityType } = require('discord.js');
const cfg        = require('./src/config');
const commands   = require('./src/commands');
const tasks      = require('./src/tasks');
const { startHttpServer } = require('./src/httpServer');

if (!cfg.BOT_TOKEN) {
    console.error('[bot] ERROR: BOT_TOKEN not set in .env');
    process.exit(1);
}

const client = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMembers,
        GatewayIntentBits.GuildMessages,
        GatewayIntentBits.MessageContent,
    ],
    partials: [Partials.Message, Partials.Channel, Partials.GuildMember],
});

client.once('ready', async () => {
    console.log(`[bot] Logged in as ${client.user.tag}`);

    // Set activity
    client.user.setActivity(`${cfg.CONNECT_URL} | /status`, { type: ActivityType.Playing });

    // Start tasks
    tasks.startTasks(client);

    // Start HTTP server for FiveM events
    startHttpServer(client);

    // Post verify message
    await commands.postVerifyMessage(client);

    // Post initial status
    await tasks.postStatus(client);

    console.log('[bot] Ready.');
});

client.on('interactionCreate', async interaction => {
    try {
        await commands.handle(interaction);
    } catch (e) {
        console.error('[bot] Interaction error:', e);
    }
});

client.on('error', e => console.error('[bot] Client error:', e.message));

client.login(cfg.BOT_TOKEN).catch(e => {
    console.error('[bot] Login failed:', e.message);
    process.exit(1);
});
