window.addEventListener('message', function(e) {
    const data = e.data;
    if (data.action === 'show') {
        const list = document.getElementById('spawn-list');
        list.innerHTML = '';
        data.spawns.forEach(sp => {
            const btn = document.createElement('button');
            btn.className = 'spawn-btn';
            btn.innerHTML = `<div class="name">${sp.label}</div><div class="desc">${sp.desc}</div>`;
            btn.addEventListener('click', () => {
                fetch('https://eonexis-spawn/selectSpawn', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ index: sp.index })
                });
            });
            list.appendChild(btn);
        });
        document.getElementById('overlay').classList.remove('hidden');
    } else if (data.action === 'hide') {
        document.getElementById('overlay').classList.add('hidden');
    }
});
