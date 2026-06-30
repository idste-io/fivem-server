'use strict';
let state = { cash: 0, bank: 0, job: 'unemployed', licenses: [], isAdmin: false, isPolice: false, dutyOn: false };
let spawnLocs = [], gpsLocs = [], allJobs = [], allLicenses = [];

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
        d.getHours().toString().padStart(2, '0') + ':' + d.getMinutes().toString().padStart(2, '0');
}, 1000);

function openApp(name) {
    document.querySelectorAll('.app-screen').forEach(el => el.classList.remove('active'));
    document.getElementById('home-screen').classList.remove('active');
    const el = document.getElementById('app-' + name);
    if (el) el.classList.add('active');
    // App-specific init
    if (name === 'bank') {
        document.getElementById('b-cash').textContent = '$' + state.cash.toLocaleString();
        document.getElementById('b-bank').textContent = '$' + state.bank.toLocaleString();
    }
    if (name === 'jobboard') {
        renderJobBoard();
    }
    if (name === 'work') {
        document.getElementById('w-job').textContent = state.job || 'unemployed';
        const jobDef = allJobs.find(j => j.id === state.job);
        document.getElementById('work-app-title').textContent = jobDef ? (jobDef.icon + ' ' + jobDef.label) : 'Work';
    }
    if (name === 'policeapp') {
        updateDutyUI();
    }
    if (name === 'players') post('getPlayers');
    if (name === 'gps') renderGPS();
    if (name === 'stats') post('getStats');
}

function goHome() {
    document.querySelectorAll('.app-screen').forEach(el => el.classList.remove('active'));
    document.getElementById('home-screen').classList.add('active');
}

// ── Job board ─────────────────────────────────────────────────────────────────

function switchJobTab(tab) {
    document.querySelectorAll('.jb-tab').forEach(t => t.classList.add('hidden'));
    document.querySelectorAll('.tab-btn').forEach(t => t.classList.remove('active'));
    document.getElementById('jb-' + tab).classList.remove('hidden');
    event.target.classList.add('active');
}

function renderJobBoard() {
    document.getElementById('j-current').textContent = state.job || 'unemployed';
    renderJobList();
    renderLicenseList();
}

function renderJobList() {
    const el = document.getElementById('job-list');
    if (!allJobs.length) { el.innerHTML = '<p class="hint">Loading jobs...</p>'; return; }
    el.innerHTML = allJobs.map(j => {
        const isCurrent = j.id === state.job;
        const licReq = j.license;
        const hasLic = !licReq || state.licenses.includes(licReq);
        const licDef = licReq ? allLicenses.find(l => l.id === licReq) : null;

        let btn = '';
        if (isCurrent) {
            btn = `<button class="job-btn active-job" disabled>✔ Active</button>`;
        } else if (!hasLic && licDef) {
            btn = `<button class="job-btn need-lic" onclick="waypointToLicense('${licDef.id}')">📍 Get ${licDef.label}</button>`;
        } else {
            btn = `<button class="job-btn apply-btn" onclick="applyJob('${j.id}')">Apply</button>`;
        }
        return `<div class="job-card ${isCurrent ? 'current' : ''}">
          <div class="job-head">
            <span class="job-icon">${j.icon || '💼'}</span>
            <span class="job-name">${j.label}</span>
            <span class="job-pay">$${j.pay.min}–$${j.pay.max}</span>
          </div>
          <div class="job-desc">${j.desc || ''}</div>
          ${licReq ? `<div class="job-lic ${hasLic ? 'ok' : 'missing'}">🪪 ${licDef ? licDef.label : licReq} ${hasLic ? '✓' : '✗'}</div>` : ''}
          <div class="job-actions">${btn}</div>
        </div>`;
    }).join('');
}

function renderLicenseList() {
    const el = document.getElementById('license-list');
    if (!allLicenses.length) { el.innerHTML = '<p class="hint">Loading...</p>'; return; }
    el.innerHTML = allLicenses.map(l => {
        const owned = state.licenses.includes(l.id);
        return `<div class="lic-card ${owned ? 'owned' : ''}">
          <div class="lic-name">${l.label}</div>
          <div class="lic-meta">Cost: $${l.cost.toLocaleString()} • ${l.desc || ''}</div>
          ${owned
            ? '<div class="lic-status owned-badge">✔ Owned</div>'
            : `<button class="job-btn need-lic" onclick="waypointToLicense('${l.id}')">📍 Directions</button>`}
        </div>`;
    }).join('');
}

function applyJob(jobId) {
    post('applyJob', { jobId });
    // Close phone so player can walk to job center
    setTimeout(() => post('close'), 300);
}

function doQuitJob() {
    post('quitJob');
    goHome();
}

function waypointToLicense(licId) {
    post('waypointToLicense', { licId });
    setTimeout(() => post('close'), 300);
}

// ── Police app ────────────────────────────────────────────────────────────────

function updateDutyUI() {
    const btn = document.getElementById('duty-toggle-btn');
    const status = document.getElementById('police-duty-status');
    if (state.dutyOn) {
        status.textContent = '🟢 On Duty';
        btn.textContent = '⏹ Go Off Duty';
    } else {
        status.textContent = '🔴 Off Duty';
        btn.textContent = '▶ Go On Duty';
    }
}

// ── App visibility based on job ───────────────────────────────────────────────

function refreshJobApps() {
    const job = state.job;
    const isPolice = job === 'police';
    const isEmployed = job && job !== 'unemployed';
    const isAdmin = state.isAdmin;

    // Work app: visible when employed and not police
    document.getElementById('app-work-btn').classList.toggle('hidden', !isEmployed || isPolice);
    // Police app: only for police job
    document.getElementById('app-police-btn').classList.toggle('hidden', !isPolice);
    // Admin: admin-only
    document.getElementById('admin-app-btn').classList.toggle('hidden', !isAdmin);

    // If admin, unhide everything
    if (isAdmin) {
        document.getElementById('app-work-btn').classList.remove('hidden');
        document.getElementById('app-police-btn').classList.remove('hidden');
    }
}

// ── Misc ──────────────────────────────────────────────────────────────────────

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

function doChute(id)   { post('spawnParachute', { id }); }
function doTaxi(id)    { post('spawnBuilding',  { id }); }
function doDeposit()   { const a = document.getElementById('txAmount').value; post('deposit',  { amount: parseInt(a) }); }
function doWithdraw()  { const a = document.getElementById('txAmount').value; post('withdraw', { amount: parseInt(a) }); }

// ── Message handler ───────────────────────────────────────────────────────────

window.addEventListener('message', function(e) {
    const d = e.data;
    if (d.action === 'open') {
        state.cash = d.cash; state.bank = d.bank; state.job = d.job;
        state.licenses = d.licenses || []; state.isAdmin = !!d.isAdmin; state.dutyOn = !!d.dutyOn;
        if (d.jobs)     allJobs = d.jobs;
        if (d.licDefs)  allLicenses = d.licDefs;
        refreshJobApps();
        document.getElementById('phone').classList.remove('hidden');
        goHome();
    } else if (d.action === 'close') {
        document.getElementById('phone').classList.add('hidden');
    } else if (d.action === 'updateMoney') {
        state.cash = d.cash; state.bank = d.bank;
        document.getElementById('b-cash').textContent = '$' + d.cash.toLocaleString();
        document.getElementById('b-bank').textContent = '$' + d.bank.toLocaleString();
    } else if (d.action === 'updateJob') {
        state.job = d.job;
        state.licenses = d.licenses || state.licenses;
        state.dutyOn = false;
        refreshJobApps();
    } else if (d.action === 'setSpawnLocs') {
        spawnLocs = d.locs; renderSpawn(d.locs);
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
        state.isAdmin = !!d.isAdmin;
        refreshJobApps();
    } else if (d.action === 'setDuty') {
        state.dutyOn = !!d.dutyOn;
        updateDutyUI();
    } else if (d.action === 'setWorkStatus') {
        document.getElementById('w-status').textContent = d.status || 'No active task';
    } else if (d.action === 'setScale') {
        document.body.style.transform = 'scale(' + d.scale + ')';
        document.body.style.transformOrigin = 'center center';
    } else if (d.action === 'controllerCursor') {
        moveCtrlCursor(d.x, d.y);
    } else if (d.action === 'controllerClick') {
        clickCtrlAt(d.x, d.y);
    } else if (d.action === 'controllerBack') {
        // B button → go back to home, or close if already home
        if (document.getElementById('home-screen').classList.contains('active')) {
            post('close');
            document.getElementById('phone').classList.add('hidden');
        } else {
            goHome();
        }
    }
});

// ── Controller cursor support (driven by eonexis-settings) ───────────────────
let _ctrlCursor = null;
function ensureCtrlCursor() {
    if (_ctrlCursor) return _ctrlCursor;
    _ctrlCursor = document.createElement('div');
    _ctrlCursor.style.cssText = 'position:fixed;width:18px;height:18px;border-radius:50%;'
        + 'border:2px solid #9352DB;background:rgba(147,82,219,0.4);pointer-events:none;'
        + 'transform:translate(-50%,-50%);z-index:99999;box-shadow:0 0 8px rgba(147,82,219,0.8);';
    document.body.appendChild(_ctrlCursor);
    return _ctrlCursor;
}
function moveCtrlCursor(x, y) {
    const c = ensureCtrlCursor();
    c.style.display = 'block';
    c.style.left = (x * window.innerWidth) + 'px';
    c.style.top  = (y * window.innerHeight) + 'px';
}
function clickCtrlAt(x, y) {
    const el = document.elementFromPoint(x * window.innerWidth, y * window.innerHeight);
    if (el) el.click();
}
