let state = { cash: 0, bank: 0, job: 'unemployed' };
let spawnLocs = [];
let gpsLocs = [];

function post(action, data) {
    fetch('https://eonexis-phone/' + action, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {})
    });
}

// Clock
setInterval(() => {
    const d = new Date();
    document.getElementById('clock').textContent =
        d.getHours().toString().padStart(2,'0') + ':' + d.getMinutes().toString().padStart(2,'0');
}, 1000);

function openApp(name) {
    document.querySelectorAll('.app-screen').forEach(el => el.classList.remove('active'));
    document.getElementById('home-screen').classList.remove('active');

    const el = document.getElementById('app-' + name);
    if (el) el.classList.add('active');

    if (name === 'bank') {
        document.getElementById('b-cash').textContent = '$' + state.cash.toLocaleString();
        document.getElementById('b-bank').textContent = '$' + state.bank.toLocaleString();
    }
    if (name === 'jobs') {
        document.getElementById('j-current').textContent = state.job;
    }
    if (name === 'players') {
        post('getPlayers');
    }
    if (name === 'gps') {
        renderGPS();
    }
    if (name === 'stats') {
        post('getStats');
    }
}

function goHome() {
    document.querySelectorAll('.app-screen').forEach(el => el.classList.remove('active'));
    document.getElementById('home-screen').classList.add('active');
}

function renderSpawn(locs) {
    const el = document.getElementById('spawn-list');
    el.innerHTML = locs.map(l => `
        <div class="spawn-card">
            <div class="spawn-name">${l.label}</div>
            <div class="spawn-desc">${l.desc}</div>
            <div class="spawn-btns">
                <button class="btn-chute" onclick="doChute('${l.id}')">🪂 Parachute (Free)</button>
                <button class="btn-taxi"  onclick="doTaxi('${l.id}')">🚕 Building ($500)</button>
            </div>
        </div>
    `).join('');
}

function renderGPS() {
    const el = document.getElementById('gps-list');
    el.innerHTML = gpsLocs.map(l => `
        <div class="gps-row">
            <div class="gps-name">${l.label}</div>
            <button class="btn-wp" onclick="setWaypoint(${l.x}, ${l.y})">📍 Go</button>
        </div>
    `).join('') || '<p class="hint">No GPS points available.</p>';
}

function setWaypoint(x, y) {
    fetch('https://eonexis-phone/setWaypoint', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ x, y })
    });
    post('close');
}

function doChute(id)  { post('spawnParachute', { id }); }
function doTaxi(id)   { post('spawnBuilding',  { id }); }
function doDeposit()  { const a = document.getElementById('txAmount').value; post('deposit',  { amount: parseInt(a) }); }
function doWithdraw() { const a = document.getElementById('txAmount').value; post('withdraw', { amount: parseInt(a) }); }

window.addEventListener('message', function(e) {
    const d = e.data;
    if (d.action === 'open') {
        state = { cash: d.cash, bank: d.bank, job: d.job };
        document.getElementById('phone').classList.remove('hidden');
        goHome();
    } else if (d.action === 'close') {
        document.getElementById('phone').classList.add('hidden');
    } else if (d.action === 'updateMoney') {
        state.cash = d.cash; state.bank = d.bank;
        document.getElementById('b-cash').textContent = '$' + d.cash.toLocaleString();
        document.getElementById('b-bank').textContent = '$' + d.bank.toLocaleString();
    } else if (d.action === 'setSpawnLocs') {
        spawnLocs = d.locs;
        renderSpawn(d.locs);
    } else if (d.action === 'setGPSLocs') {
        gpsLocs = d.locs;
    } else if (d.action === 'showPlayers') {
        const el = document.getElementById('player-list');
        el.innerHTML = d.players.map(p =>
            `<div class="player-row"><span class="player-id">[${p.id}]</span> ${p.name}</div>`
        ).join('') || '<p class="hint">No players online.</p>';
    } else if (d.action === 'setCharData') {
        if (d.char) {
            document.getElementById('char-name-ph').textContent   = d.char.name   || '—';
            document.getElementById('char-gender-ph').textContent = d.char.gender  ? (d.char.gender.charAt(0).toUpperCase() + d.char.gender.slice(1)) : '—';
            document.getElementById('char-outfit-ph').textContent = d.char.outfit  || '—';
            document.getElementById('char-bio-ph').textContent    = d.char.bio     || '—';
        }
    } else if (d.action === 'setStats') {
        document.getElementById('stat-cash').textContent  = '$' + (d.cash || 0).toLocaleString();
        document.getElementById('stat-bank').textContent  = '$' + (d.bank || 0).toLocaleString();
        document.getElementById('stat-job').textContent   = d.job  || 'Unemployed';
        document.getElementById('stat-skill').textContent = 'Level ' + (d.skill || 1);
    } else if (d.action === 'setAdmin') {
        const btn = document.getElementById('admin-app-btn');
        if (btn) btn.classList.toggle('hidden', !d.isAdmin);
    }
});
