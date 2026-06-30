'use strict';
let components = [], current = {}, activeComp = null;

window.addEventListener('message', e => {
    const d = e.data;
    if (d.action === 'open') {
        components = d.components;
        current = d.current;
        renderTabs();
        if (components.length) selectComp(components[0].id);
        document.getElementById('app').classList.remove('hidden');
    } else if (d.action === 'close') {
        document.getElementById('app').classList.add('hidden');
    }
});

function renderTabs() {
    const tabs = document.getElementById('tabs');
    tabs.innerHTML = '';
    components.forEach(c => {
        const el = document.createElement('div');
        el.className = 'tab';
        el.textContent = c.label;
        el.onclick = () => selectComp(c.id);
        el.id = 'tab_' + c.id;
        tabs.appendChild(el);
    });
}

function selectComp(id) {
    activeComp = id;
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
    const tab = document.getElementById('tab_' + id);
    if (tab) tab.classList.add('active');
    updateLabels();
}

function updateLabels() {
    const c = current[String(activeComp)];
    if (!c) return;
    document.getElementById('drawLabel').textContent = `Drawable ${c.drawable} / ${c.maxDraw}`;
    document.getElementById('texLabel').textContent  = `Texture  ${c.texture} / ${c.maxTex}`;
}

function preview() {
    const c = current[String(activeComp)];
    fetch(`https://eonexis-clothing/preview`, {
        method: 'POST',
        body: JSON.stringify({ comp: activeComp, drawable: c.drawable, texture: c.texture })
    });
}

function nextDrawable() {
    const c = current[String(activeComp)]; if (!c) return;
    c.drawable = Math.min(c.drawable + 1, c.maxDraw);
    c.maxTex = 0; c.texture = 0;
    updateLabels(); preview();
}
function prevDrawable() {
    const c = current[String(activeComp)]; if (!c) return;
    c.drawable = Math.max(c.drawable - 1, 0);
    c.maxTex = 0; c.texture = 0;
    updateLabels(); preview();
}
function nextTexture() {
    const c = current[String(activeComp)]; if (!c) return;
    c.texture = Math.min(c.texture + 1, c.maxTex);
    updateLabels(); preview();
}
function prevTexture() {
    const c = current[String(activeComp)]; if (!c) return;
    c.texture = Math.max(c.texture - 1, 0);
    updateLabels(); preview();
}

function save() {
    fetch(`https://eonexis-clothing/save`, { method: 'POST', body: JSON.stringify({}) });
}
function close_() {
    fetch(`https://eonexis-clothing/close`, { method: 'POST', body: JSON.stringify({}) });
}

// UI scale from eonexis-settings
window.addEventListener('message', function(e) {
    if (e.data && e.data.action === 'setScale') {
        document.body.style.transform = 'scale(' + e.data.scale + ')';
        document.body.style.transformOrigin = 'center center';
    }
});
