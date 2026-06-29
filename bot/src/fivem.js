'use strict';
const fs  = require('fs');
const cfg = require('./config');

// ── CFX public API ───────────────────────────────────────────────────────────

async function fetchJson(url) {
    const { default: fetch } = await import('node-fetch');
    const res = await fetch(url, { signal: AbortSignal.timeout(8000) });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json();
}

async function getServerInfo() {
    try {
        const data = await fetchJson(`https://servers-frontend.fivem.net/api/servers/single/${cfg.FIVEM_SERVER_ID}`);
        const sv = data.Data;
        return {
            online:      true,
            hostname:    sv.vars?.sv_hostname?.replace(/\^\d/g, '') || 'Eonexis',
            clients:     sv.clients || 0,
            maxClients:  sv.sv_maxclients || 64,
            players:     sv.players || [],
        };
    } catch {
        return { online: false, clients: 0, maxClients: 64, players: [] };
    }
}

// ── FiveM resource HTTP API ───────────────────────────────────────────────────

async function fivemGet(path) {
    const { default: fetch } = await import('node-fetch');
    const res = await fetch(`${cfg.FIVEM_HOST}/eonexis-discord-link${path}`, {
        headers: { 'x-bot-secret': cfg.BOT_SECRET },
        signal: AbortSignal.timeout(5000),
    });
    return res.json();
}

async function fivemPost(path, body) {
    const { default: fetch } = await import('node-fetch');
    const res = await fetch(`${cfg.FIVEM_HOST}/eonexis-discord-link${path}`, {
        method: 'POST',
        headers: { 'x-bot-secret': cfg.BOT_SECRET, 'content-type': 'application/json' },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(5000),
    });
    return res.json();
}

async function verifyCode(code) {
    try { return await fivemGet(`/verify?code=${encodeURIComponent(code)}`); }
    catch { return null; }
}

async function markLinked(code, discordId) {
    try { return await fivemPost('/linked', { code, discordId }); }
    catch { return null; }
}

async function getBalance(license) {
    try { return await fivemGet(`/balance?license=${encodeURIComponent(license)}`); }
    catch { return null; }
}

async function giveMoneyOnline(license, amount, reason) {
    try { return await fivemPost('/givemoney', { license, amount, reason }); }
    catch { return null; }
}

// ── Economy file (offline player support) ────────────────────────────────────

function readEconomy() {
    try { return JSON.parse(fs.readFileSync(cfg.ECONOMY_FILE, 'utf8')); }
    catch { return {}; }
}

function writeEconomy(data) {
    fs.writeFileSync(cfg.ECONOMY_FILE, JSON.stringify(data, null, 2));
}

function getPlayerData(license) {
    return readEconomy()[license] || null;
}

function addMoneyOffline(license, amount, reason) {
    const eco = readEconomy();
    if (!eco[license]) return false;
    eco[license].cash = (eco[license].cash || 0) + amount;
    writeEconomy(eco);
    return true;
}

// ── Discord daily tracking ────────────────────────────────────────────────────

function readDailyDB() {
    try { return JSON.parse(fs.readFileSync(cfg.DISCORD_DAILY_FILE, 'utf8')); }
    catch { return {}; }
}

function writeDailyDB(data) {
    fs.mkdirSync(require('path').dirname(cfg.DISCORD_DAILY_FILE), { recursive: true });
    fs.writeFileSync(cfg.DISCORD_DAILY_FILE, JSON.stringify(data, null, 2));
}

const DAILY_AMOUNT    = 500;
const DAILY_COOLDOWN  = 24 * 60 * 60 * 1000;  // 24hrs

function claimDiscordDaily(license) {
    const db  = readDailyDB();
    const now = Date.now();
    const rec = db[license] || { lastClaim: 0, streak: 0 };

    if (now - rec.lastClaim < DAILY_COOLDOWN) {
        const remaining = rec.lastClaim + DAILY_COOLDOWN - now;
        const hrs = Math.floor(remaining / 3600000);
        const mins = Math.floor((remaining % 3600000) / 60000);
        return { ok: false, msg: `Already claimed. Next claim in **${hrs}h ${mins}m**.` };
    }

    // Update streak
    if (now - rec.lastClaim < DAILY_COOLDOWN * 2) {
        rec.streak = (rec.streak || 0) + 1;
    } else {
        rec.streak = 1;
    }
    rec.lastClaim = now;
    db[license] = rec;
    writeDailyDB(db);

    const bonus = Math.min(rec.streak * 50, 500);
    const total = DAILY_AMOUNT + bonus;

    return { ok: true, amount: total, streak: rec.streak, bonus };
}

module.exports = {
    getServerInfo,
    verifyCode,
    markLinked,
    getBalance,
    giveMoneyOnline,
    getPlayerData,
    addMoneyOffline,
    claimDiscordDaily,
};
