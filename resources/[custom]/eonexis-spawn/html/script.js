function post(action, data) {
    fetch('https://eonexis-spawn/' + action, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {})
    });
}

function makeBtn(label, desc, onClick) {
    const btn = document.createElement('button');
    btn.className = 'spawn-btn';
    btn.innerHTML = `<div class="name">${label}</div><div class="desc">${desc}</div>`;
    btn.addEventListener('click', onClick);
    return btn;
}

window.addEventListener('message', function(e) {
    const d = e.data;
    if (d.action === 'show') {
        const list = document.getElementById('spawn-list');
        list.innerHTML = '';
        // Standard spawn points
        d.spawns.forEach(sp => {
            list.appendChild(makeBtn(sp.label, sp.desc,
                () => post('selectSpawn', { index: sp.index })));
        });
        document.getElementById('overlay').classList.remove('hidden');

    } else if (d.action === 'extraOptions') {
        // Prepend last-location + home options at the top
        const list = document.getElementById('spawn-list');
        d.opts.forEach(opt => {
            const tag = opt.type === 'home' ? '🏠 ' : '📍 ';
            const btn = makeBtn(tag + opt.label, opt.desc, () => {
                if (opt.type === 'home') {
                    post('spawnHome', { x:opt.x, y:opt.y, z:opt.z, h:opt.h, label:opt.label });
                } else {
                    post('spawnLastLocation', { x:opt.x, y:opt.y, z:opt.z, h:opt.h });
                }
            });
            btn.style.borderColor = opt.type === 'home' ? 'hsl(150,60%,40%)' : 'hsl(40,80%,50%)';
            list.insertBefore(btn, list.firstChild);
        });

    } else if (d.action === 'hide') {
        document.getElementById('overlay').classList.add('hidden');
    }
});

// UI scale from eonexis-settings
window.addEventListener('message', function(e) {
    if (e.data && e.data.action === 'setScale') {
        document.body.style.transform = 'scale(' + e.data.scale + ')';
        document.body.style.transformOrigin = 'center center';
    }
});
