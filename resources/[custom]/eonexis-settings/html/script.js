'use strict';

const RES = 'eonexis-settings';
let state = {
    firstRun: false,
    scale: 1.0,
    keybinds: [],
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

// ── Scale slider ─────────────────────────────────────────────────────────────

function updateScaleUI(v) {
    const slider = $('scale-slider');
    if (slider) slider.value = v;
    const pctEl = $('scale-pct');
    if (pctEl) pctEl.textContent = Math.round(v * 100) + '%';
    const prev = $('scale-preview-text');
    if (prev) prev.style.fontSize = Math.round(16 * v) + 'px';
}

function initSlider() {
    const slider = $('scale-slider');
    if (!slider) return;
    slider.addEventListener('input', () => {
        const v = parseFloat(slider.value);
        updateScaleUI(v);
        post('setScale', { value: v });
    });
    $('scale-reset').addEventListener('click', () => {
        slider.value = 1.0;
        updateScaleUI(1.0);
        post('setScale', { value: 1.0 });
    });
}

// ── Toggles ──────────────────────────────────────────────────────────────────

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

// ── Keybinds ─────────────────────────────────────────────────────────────────

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

// ── Tabs ─────────────────────────────────────────────────────────────────────

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

// ── Account links ─────────────────────────────────────────────────────────────

function initLinks() {
    $('btn-link').onclick    = () => post('openLink', { url: state.links.linkUrl });
    $('btn-webapp').onclick  = () => post('openLink', { url: state.links.webapp });
    $('btn-discord').onclick = () => post('openLink', { url: state.links.discord });
}

// ── Open / close ──────────────────────────────────────────────────────────────

function openPanel(d) {
    state.firstRun    = d.firstRun;
    state.scale       = typeof d.scale === 'number' ? d.scale : 1.0;
    state.keybinds    = d.keybinds    || [];
    state.toggles     = d.toggles     || [];
    state.toggleState = d.toggleState || {};
    state.links       = { webapp: d.webapp, discord: d.discord, linkUrl: d.linkUrl };

    $('panel-title').textContent = d.firstRun ? 'Welcome — Set Up Your UI' : 'Settings';
    $('firstrun-banner').classList.toggle('hidden', !d.firstRun);
    $('btn-finish').classList.toggle('hidden', !d.firstRun);
    $('btn-close').classList.toggle('hidden', d.firstRun);

    updateScaleUI(state.scale);
    renderToggles();
    renderKeybinds();

    $('overlay').classList.remove('hidden');
}

function closePanel() {
    $('overlay').classList.add('hidden');
    $('ctrl-cursor').classList.add('hidden');
}

// ── Controller cursor ─────────────────────────────────────────────────────────

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

// ── Message handler ───────────────────────────────────────────────────────────

window.addEventListener('message', e => {
    const d = e.data;
    if (!d) return;
    if (d.action === 'open')  { openPanel(d); return; }
    if (d.action === 'close') { closePanel(); return; }
    if (d.action === 'setScale') {
        // Settings panel body itself doesn't scale — it IS the control panel
        // But update the slider + preview to reflect the new value
        if (typeof d.scale === 'number') updateScaleUI(d.scale);
        return;
    }
    if (d.action === 'controllerClick') { clickAt(d.x, d.y); return; }
    if (d.action === 'controllerBack') {
        if (state.firstRun) return;
        post('close'); closePanel(); return;
    }
    if (d.action === 'controllerCursor') { moveCursor(d.x, d.y); return; }
});

// ── Buttons ───────────────────────────────────────────────────────────────────

$('btn-close').onclick  = () => { post('close'); closePanel(); };
$('btn-finish').onclick = () => { post('finishFirstRun'); closePanel(); };

document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && !state.firstRun) { post('close'); closePanel(); }
});

initTabs();
initLinks();
initSlider();
