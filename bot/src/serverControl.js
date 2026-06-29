'use strict';
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const SERVER_CFG = '/opt/fivem-server/resources/../server.cfg';
const SERVER_CFG_REAL = '/opt/fivem-server/server.cfg';

function run(cmd) {
    return new Promise((resolve) => {
        exec(cmd, { timeout: 15000 }, (err, stdout, stderr) => {
            resolve({ ok: !err, out: stdout || '', err: stderr || '', code: err?.code ?? 0 });
        });
    });
}

async function restartServer() {
    return run('systemctl restart fivem');
}

async function stopServer() {
    return run('systemctl stop fivem');
}

async function startServer() {
    return run('systemctl start fivem');
}

async function getStatus() {
    const r = await run('systemctl is-active fivem');
    return r.out.trim(); // 'active' or 'inactive' or 'failed'
}

async function getLogs(lines = 30) {
    const r = await run(`journalctl -u fivem --no-pager -n ${lines} --output=cat`);
    return r.out.trim();
}

// Parse server.cfg for ensured mods and their enabled state
function parseModList() {
    try {
        const cfg = fs.readFileSync(SERVER_CFG_REAL, 'utf8');
        const mods = [];
        for (const line of cfg.split('\n')) {
            const active  = line.match(/^\s*ensure\s+([\w-]+)/);
            const comment = line.match(/^\s*#\s*ensure\s+([\w-]+)/);
            if (active)  mods.push({ name: active[1],  enabled: true  });
            if (comment) mods.push({ name: comment[1], enabled: false });
        }
        return mods;
    } catch {
        return [];
    }
}

// Toggle a mod: comment out or uncomment its ensure line
async function toggleMod(modName, enable) {
    try {
        const cfg = fs.readFileSync(SERVER_CFG_REAL, 'utf8');
        let updated;
        if (enable) {
            // Uncomment: "# ensure modname" → "ensure modname"
            updated = cfg.replace(
                new RegExp(`^(\\s*)#\\s*(ensure\\s+${modName}\\s*)$`, 'gm'),
                '$1$2'
            );
        } else {
            // Comment out: "ensure modname" → "# ensure modname"
            updated = cfg.replace(
                new RegExp(`^(\\s*)(ensure\\s+${modName}\\s*)$`, 'gm'),
                '$1# $2'
            );
        }
        if (updated === cfg) return { ok: false, msg: `Mod "${modName}" not found in server.cfg` };
        fs.writeFileSync(SERVER_CFG_REAL, updated, 'utf8');
        // Also rsync to /opt/fivem for active config
        await run(`cp ${SERVER_CFG_REAL} /opt/fivem/server.cfg`);
        return { ok: true };
    } catch (e) {
        return { ok: false, msg: e.message };
    }
}

// Get FiveM resource restart via txAdmin rcon or direct
async function restartMod(modName) {
    // Use FiveM server console via screen/tmux or rcon if available
    // Best effort: signal the resource via FiveM HTTP admin API
    const r = await run(`fivem-rcon "restart ${modName}" 2>/dev/null || true`);
    return r;
}

module.exports = { run, restartServer, stopServer, startServer, getStatus, getLogs, parseModList, toggleMod };
