'use strict';

const RES = 'eonexis-settings';
let state = {
    firstRun: false,
    scale: 'normal',
    presets: [],
    toggles: [],
    toggleState: {},
    links: {},
};

function $(id) { return document.getElementById(id); }
function post(cb, body) {
    return fetch(`https://${RES}/${cb}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body || {}),
    }).catch(() => {});
}

// ── Scale ───────────────────────────────────────────────────────────────────

function applyScaleValue(v) {
    $('scaler').style.transform = `scale(${v})`;
}

function renderScales() {
    const list = $('scale-list');
    list.innerHTML = '';
    state.presets.forEach(p => {
        const div = document.createElement('div');
        div.className = 'scale-item' + (p.id === state.scale ? ' selected' : '');
        div.innerHTML = `<div class="scale-name">${p.label}</div><div class="scale-val">${Math.round(p.value * 100)}%</div>`;
        div.onclick = () => selectScale(p.id, p.value);
        list.appendChild(div);
    });
}

function selectScale(id, value) {
    state.scale = id;
    renderScales();
    applyScaleValue(value);
    $('scale-preview-text').style.fontSize = (15 * value) + 'px';
    post('setScale', { scale: id });
}

// ── Toggles ─────────────────────────────────────────────────────────────────

function renderToggles() {
    const list = $('toggle-list');
    list.innerHTML = '';
    state.toggles.forEach(t => {
        const on = state.toggleState[t.id] !== false;
        const row = document.createElement('div');
        row.className = 'toggle-row';
        row.innerHTML = `<span class="toggle-label">${t.label}</span>
            <div class="switch ${on ? 'on' : ''}" data-id="${t.id}"><div class="knob"></div></div>`;
        row.querySelector('.switch').onclick = (e) => {
            const sw = e.currentTarget;
            const newVal = !sw.classList.contains('on');
            sw.classList.toggle('on', newVal);
            state.toggleState[t.id] = newVal;
            post('setToggle', { id: t.id, value: newVal });
        };
        list.appendChild(row);
    });
}

// ── Keybinds ──────────────────────────────────────────────────────────────────

function renderKeybinds() {
    const list = $('keybind-list');
    list.innerHTML = '';
    (state.keybinds || []).forEach(k => {
        const row = document.createElement('div');
        row.className = 'keybind-row';
        row.innerHTML = `<span class="keybind-label">${k.label}</span><span class="keybind-key">${k.default}</span>`;
        list.appendChild(row);
    });
}

// ── Tabs ──────────────────────────────────────────────────────────────────────

function initTabs() {
    document.querySelectorAll('.tab').forEach(tab => {
        tab.onclick = () => {
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.tab-pane').forEach(p => p.classList.remove('active'));
            tab.classList.add('active');
            document.querySelector(`.tab-pane[data-pane="${tab.dataset.tab}"]`).classList.add('active');
        };
    });
}

// ── Account links ───────────────────────────────────────────────────────────────

function initLinks() {
    $('btn-link').onclick    = () => post('openLink', { url: state.links.linkUrl });
    $('btn-webapp').onclick  = () => post('openLink', { url: state.links.webapp });
    $('btn-discord').onclick = () => post('openLink', { url: state.links.discord });
}

// ── Open / close ────────────────────────────────────────────────────────────────

function openPanel(d) {
    state.firstRun    = d.firstRun;
    state.scale       = d.scale || 'normal';
    state.presets     = d.presets || [];
    state.keybinds    = d.keybinds || [];
    state.toggles     = d.toggles || [];
    state.toggleState = d.toggleState || {};
    state.links       = { webapp: d.webapp, discord: d.discord, linkUrl: d.linkUrl };

    $('panel-title').textContent = d.firstRun ? 'Welcome — Set Up Your UI' : 'Settings';
    $('firstrun-banner').classList.toggle('hidden', !d.firstRun);
    $('btn-finish').classList.toggle('hidden', !d.firstRun);
    $('btn-close').classList.toggle('hidden', d.firstRun);

    applyScaleValue(d.scaleValue || 1.0);
    renderScales();
    renderToggles();
    renderKeybinds();

    $('overlay').classList.remove('hidden');
}

function closePanel() {
    $('overlay').classList.add('hidden');
    $('ctrl-cursor').classList.add('hidden');
}

// ── Controller cursor ───────────────────────────────────────────────────────────

function moveCursor(x, y) {
    const cur = $('ctrl-cursor');
    cur.classList.remove('hidden');
    cur.style.left = (x * window.innerWidth) + 'px';
    cur.style.top  = (y * window.innerHeight) + 'px';
}

function clickAt(x, y) {
    const el = document.elementFromPoint(x * window.innerWidth, y * window.innerHeight);
    if (el) el.click();
}

// ── Message handler ─────────────────────────────────────────────────────────────

window.addEventListener('message', e => {
    const d = e.data;
    if (!d) return;
    if (d.action === 'open')  openPanel(d);
    if (d.action === 'close') closePanel();
    if (d.action === 'setScale') {
        // external scale apply (when not in panel) — only affects our root if open
        if (!$('overlay').classList.contains('hidden')) applyScaleValue(d.scale);
    }
    if (d.action === 'controllerClick') clickAt(d.x, d.y);
    if (d.action === 'controllerBack') {
        if (state.firstRun) return; // can't back out of first run
        post('close');
        closePanel();
    }
    if (d.action === 'controllerCursor') moveCursor(d.x, d.y);
});

// also reflect cursor position pushed via setCursor messages
window.addEventListener('message', e => {
    if (e.data && e.data.action === 'cursorPos') moveCursor(e.data.x, e.data.y);
});

// ── Buttons ─────────────────────────────────────────────────────────────────────

$('btn-close').onclick  = () => { post('close'); closePanel(); };
$('btn-finish').onclick = () => { post('finishFirstRun'); closePanel(); };

document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && !state.firstRun) { post('close'); closePanel(); }
});

initTabs();
initLinks();
