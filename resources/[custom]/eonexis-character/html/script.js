'use strict';

let state = {
    isNew: true,
    outfits: [],
    selectedOutfit: null,
    gender: 'male',
    nameCost: 500,
    originalName: null,
};

function $(id) { return document.getElementById(id); }

function setGender(g) {
    state.gender = g;
    document.querySelectorAll('.gender-btn').forEach(b => b.classList.toggle('active', b.dataset.gender === g));
    renderOutfits();
}

function renderOutfits() {
    const list = $('outfit-list');
    list.innerHTML = '';
    const filtered = state.outfits.filter(o => o.gender === state.gender);
    if (!filtered.length) {
        list.innerHTML = '<div style="color:var(--muted);font-size:12px">No outfits for this gender.</div>';
        return;
    }
    filtered.forEach(outfit => {
        const div = document.createElement('div');
        div.className = 'outfit-item' + (state.selectedOutfit === outfit.id ? ' selected' : '');
        div.innerHTML = `<div class="outfit-name">${outfit.label}</div>
            <div class="outfit-price">${outfit.price === 0 ? 'Free' : '$' + outfit.price.toLocaleString()}</div>`;
        div.onclick = () => selectOutfit(outfit.id);
        list.appendChild(div);
    });
}

function selectOutfit(id) {
    state.selectedOutfit = id;
    document.querySelectorAll('.outfit-item').forEach(el => el.classList.remove('selected'));
    const outfit = state.outfits.find(o => o.id === id);
    if (outfit) {
        const el = document.querySelector(`.outfit-item[onclick*="${id}"]`);
        if (el) el.classList.add('selected');
    }
    renderOutfits();
    updateCostInfo();
}

function updateCostInfo() {
    const name = $('char-name').value.trim();
    const costs = [];
    if (!state.isNew && name && name !== state.originalName && state.nameCost > 0) {
        costs.push(`Name change: $${state.nameCost.toLocaleString()}`);
    }
    const outfit = state.outfits.find(o => o.id === state.selectedOutfit);
    if (!state.isNew && outfit && outfit.price > 0) {
        costs.push(`Outfit: $${outfit.price.toLocaleString()}`);
    }
    const costEl = $('cost-info');
    if (costs.length) {
        costEl.classList.remove('hidden');
        $('cost-label').textContent = 'Cost: ' + costs.join(' + ');
    } else {
        costEl.classList.add('hidden');
    }
}

function showError(msg) {
    const bar = $('error-bar');
    bar.textContent = msg;
    bar.classList.remove('hidden');
    setTimeout(() => bar.classList.add('hidden'), 5000);
}

function save() {
    const name = $('char-name').value.trim();
    if (!name) { showError('Please enter a character name.'); return; }
    if (!state.selectedOutfit) { showError('Please select an outfit.'); return; }
    fetch(`https://eonexis-character/saveCharacter`, {
        method: 'POST',
        body: JSON.stringify({
            name,
            gender: state.gender,
            outfit: state.selectedOutfit,
            bio: $('char-bio').value.trim(),
        }),
    });
}

function cancel() {
    fetch(`https://eonexis-character/closeCharacter`, { method: 'POST', body: '{}' });
}

window.addEventListener('message', e => {
    const d = e.data;
    if (d.action === 'open') {
        $('overlay').classList.remove('hidden');
        state.isNew = d.isNew;
        state.outfits = d.outfits || [];
        state.nameCost = d.nameCost || 500;
        $('panel-title').textContent = d.isNew ? 'Create Your Character' : 'Edit Character';
        if (d.char) {
            $('char-name').value = d.char.name || '';
            $('char-bio').value  = d.char.bio  || '';
            state.originalName   = d.char.name;
            state.gender         = d.char.gender || 'male';
            state.selectedOutfit = d.char.outfit || null;
        } else {
            $('char-name').value = '';
            $('char-bio').value  = '';
            state.originalName   = null;
            state.gender         = 'male';
            state.selectedOutfit = 'basic_m';
        }
        document.querySelectorAll('.gender-btn').forEach(b =>
            b.classList.toggle('active', b.dataset.gender === state.gender));
        renderOutfits();
        updateCostInfo();
    }
    if (d.action === 'close') {
        $('overlay').classList.add('hidden');
        $('error-bar').classList.add('hidden');
    }
    if (d.action === 'showError') {
        showError(d.msg);
    }
});

$('char-name').addEventListener('input', updateCostInfo);

document.addEventListener('keydown', e => {
    if (e.key === 'Escape') cancel();
});

// UI scale from eonexis-settings
window.addEventListener('message', function(e) {
    if (e.data && e.data.action === 'setScale') {
        document.body.style.transform = 'scale(' + e.data.scale + ')';
        document.body.style.transformOrigin = 'center center';
    }
});
