'use strict';

const TIPS = [
    'Press P to open your phone — stats, GPS, jobs, and more.',
    'Type /link in-game to connect your Discord account and unlock /daily rewards.',
    'Press Q to view your active quests and track your progress.',
    'Visit the Job Center (yellow marker on map) to start earning money.',
    'Press F2 or type /rules to see the server rules.',
    'Daily bonus: claim $500 every 24 hours in-game or via Discord /daily.',
    'Buy a property on the green markers — homes earn passive income.',
    'Visit Premium Deluxe Motorsport to buy vehicles; store them in your garage.',
    'Press E near markers to interact with shops, jobs, and properties.',
    'Spin the Lucky Wheel at the casino for a chance at $50,000 jackpot.',
    'Type /link then /verify in Discord to link your FiveM character.',
    'Complete quests and skill tree tasks for XP and cash bonuses.',
    'Commit store robberies (marked on map) for high-risk, high-reward payouts.',
    'Race routes start at marked checkpoints — top times saved to leaderboard.',
    'The skill tree rewards you for exploring every part of the server.',
];

let tipIdx    = 0;
let targetPct = 0;

function setTip(t) {
    const el = document.getElementById('tipText');
    el.style.transition = 'opacity 0.3s';
    el.style.opacity = 0;
    setTimeout(() => { el.textContent = t; el.style.opacity = 1; }, 300);
}

function rotateTips() {
    setTip(TIPS[tipIdx % TIPS.length]);
    tipIdx++;
}

function updateProgress(pct) {
    targetPct = Math.max(targetPct, pct);
    document.getElementById('progressFill').style.width = targetPct + '%';
    document.getElementById('progressPct').textContent  = targetPct + '%';
    const pills  = document.querySelectorAll('.mg-item');
    const loaded = Math.floor((targetPct / 100) * pills.length);
    pills.forEach((p, i) => p.classList.toggle('loaded', i < loaded));
}

function setStatus(msg, sub) {
    if (msg) document.getElementById('statusMsg').textContent = msg;
    if (sub !== undefined) document.getElementById('subStatus').textContent = sub || '';
}

window.addEventListener('message', function(e) {
    const d = e.data;
    if (!d) return;
    if (d.type === 'progress' || d.eventName === 'loadProgress') {
        const pct = Math.round((d.progress ?? d.frac ?? 0) * 100);
        updateProgress(pct);
        if (d.label) setStatus(d.label);
    }
    if (d.type === 'startInitFunction') setStatus('Initializing…', '');
    if (d.type === 'startDataFileEntries') setStatus('Loading data files…', '');
    if (d.type === 'endDataFileEntries')   setStatus('Data files loaded', '');
    if (d.type === 'downloadProgress') {
        const pct = Math.round((d.done / (d.total || 1)) * 100);
        updateProgress(Math.min(pct, 98));
        const mb  = (d.done  / 1048576).toFixed(1);
        const tot = (d.total / 1048576).toFixed(1);
        setStatus('Downloading resources…', `${mb} MB / ${tot} MB`);
    }
    if (d.type === 'playerActivated') {
        updateProgress(100);
        setStatus('Welcome to Los Santos!', '');
    }
    if (d.type === 'serverMessage' && d.text) setStatus(d.text);
});

// Simulate progress when FiveM sends no events
let sim = 0;
const simTimer = setInterval(() => {
    if (sim >= 95) { clearInterval(simTimer); return; }
    sim += Math.random() * 2.5 + 0.5;
    if (targetPct < sim) updateProgress(Math.min(Math.round(sim), 95));
}, 450);

setTip(TIPS[0]);
setInterval(rotateTips, 5000);

// Live player count from CFX API
fetch('https://servers-frontend.fivem.net/api/servers/single/vq3rbm5')
    .then(r => r.json())
    .then(d => {
        if (d && d.Data) {
            document.getElementById('playerCount').textContent =
                d.Data.clients + ' / ' + d.Data.sv_maxclients;
        }
    })
    .catch(() => {
        document.getElementById('playerCount').textContent = 'Starting…';
    });
