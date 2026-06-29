'use strict';
const http = require('http');
const cfg  = require('./config');

// Small HTTP server that receives events from the FiveM server
// FiveM POSTs to http://127.0.0.1:3001/event

function startHttpServer(client) {
    const { EmbedBuilder } = require('discord.js');
    const VIOLET = 0x9352DB;
    const GREEN  = 0x4ADE80;
    const RED    = 0xF87171;

    const server = http.createServer(async (req, res) => {
        // Security: only allow localhost
        const addr = req.socket.remoteAddress;
        if (addr !== '127.0.0.1' && addr !== '::1' && addr !== '::ffff:127.0.0.1') {
            res.writeHead(403);
            return res.end('Forbidden');
        }

        // Check secret header
        if (req.headers['x-bot-secret'] !== cfg.BOT_SECRET) {
            res.writeHead(401);
            return res.end('Unauthorized');
        }

        if (req.method === 'POST' && req.url === '/event') {
            let body = '';
            req.on('data', d => body += d);
            req.on('end', async () => {
                try {
                    const evt = JSON.parse(body);
                    await handleFivemEvent(client, evt);
                } catch (e) {
                    console.error('[httpServer] parse error:', e.message);
                }
                res.writeHead(200);
                res.end('ok');
            });
        } else {
            res.writeHead(404);
            res.end();
        }
    });

    async function handleFivemEvent(client, evt) {
        const joinLeaveCh = await client.channels.fetch(cfg.JOIN_LEAVE_CHANNEL_ID).catch(() => null);
        if (!joinLeaveCh) return;

        if (evt.type === 'join') {
            joinLeaveCh.send({ embeds: [
                new EmbedBuilder()
                    .setColor(GREEN)
                    .setDescription(`→ **${evt.name}** joined the server *(${evt.playerCount}/${evt.maxPlayers} online)*`)
                    .setTimestamp()
            ]});
        } else if (evt.type === 'leave') {
            joinLeaveCh.send({ embeds: [
                new EmbedBuilder()
                    .setColor(RED)
                    .setDescription(`← **${evt.name}** left the server *(${evt.playerCount}/${evt.maxPlayers} online)*`)
                    .setTimestamp()
            ]});
        } else if (evt.type === 'chat') {
            // Future: relay chat messages
        }
    }

    server.listen(cfg.BOT_HTTP_PORT, '127.0.0.1', () => {
        console.log(`[bot] HTTP server listening on 127.0.0.1:${cfg.BOT_HTTP_PORT}`);
    });

    return server;
}

module.exports = { startHttpServer };
