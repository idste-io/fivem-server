'use strict';
const { REST, Routes } = require('discord.js');
const cfg = require('./src/config');
const { commandDefs } = require('./src/commands');

const rest = new REST({ version: '10' }).setToken(cfg.BOT_TOKEN);

(async () => {
    try {
        console.log('Registering slash commands...');
        await rest.put(
            Routes.applicationGuildCommands(cfg.CLIENT_ID, cfg.GUILD_ID),
            { body: commandDefs.map(c => c.toJSON()) }
        );
        console.log('Done! Commands registered to guild', cfg.GUILD_ID);
    } catch (e) {
        console.error('Failed:', e.message);
    }
})();
