'use strict';
const fs   = require('fs');
const cfg  = require('./config');

function readLinks() {
    try {
        return JSON.parse(fs.readFileSync(cfg.LINKS_FILE, 'utf8'));
    } catch { return {}; }
}

function writeLinks(data) {
    fs.mkdirSync(require('path').dirname(cfg.LINKS_FILE), { recursive: true });
    fs.writeFileSync(cfg.LINKS_FILE, JSON.stringify(data, null, 2));
}

module.exports = {
    getByDiscord(discordId) {
        return readLinks()[discordId] || null;
    },
    getByLicense(license) {
        const links = readLinks();
        for (const [did, data] of Object.entries(links)) {
            if (data.license === license) return { discordId: did, ...data };
        }
        return null;
    },
    set(discordId, license, playerName) {
        const links = readLinks();
        links[discordId] = { license, playerName, linkedAt: Date.now() };
        writeLinks(links);
    },
    remove(discordId) {
        const links = readLinks();
        delete links[discordId];
        writeLinks(links);
    },
    all() {
        return readLinks();
    },
};
