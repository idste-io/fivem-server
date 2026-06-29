let mode = 'dealer';
let allVehicles = [];
let activeCategory = 'All';

function post(action, data) {
    fetch('https://eonexis-vehicles/' + action, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {})
    });
}

function renderCategories(vehicles) {
    const cats = ['All', ...new Set(vehicles.map(v => v.category))];
    const bar = document.getElementById('category-bar');
    bar.innerHTML = cats.map(c =>
        `<button class="cat-btn${c === activeCategory ? ' active' : ''}" onclick="filterCat('${c}')">${c}</button>`
    ).join('');
}

function renderVehicles(vehicles) {
    const list = document.getElementById('vehicle-list');
    const filtered = activeCategory === 'All' ? vehicles : vehicles.filter(v => v.category === activeCategory);
    list.innerHTML = filtered.map(v => `
        <div class="veh-card">
            <div class="veh-info">
                <div class="veh-cat">${v.category}</div>
                <div class="veh-label">${v.label}</div>
                <div class="veh-desc">${v.desc || ''}</div>
            </div>
            ${mode === 'dealer'
                ? `<span class="veh-price">$${v.price.toLocaleString()}</span>
                   <button class="btn-action" onclick="buyVeh('${v.model}')">Buy</button>`
                : `<button class="btn-action" onclick="retrieveVeh('${v.model}')">Retrieve</button>
                   <button class="btn-action btn-sell" onclick="sellVeh('${v.model}')">Sell</button>`
            }
        </div>
    `).join('') || '<p style="color:rgba(255,255,255,0.3);text-align:center;margin-top:32px;">No vehicles</p>';
}

function filterCat(cat) {
    activeCategory = cat;
    renderCategories(allVehicles);
    renderVehicles(allVehicles);
}

window.addEventListener('message', function(e) {
    const d = e.data;
    if (d.action === 'showDealer') {
        mode = 'dealer'; activeCategory = 'All';
        allVehicles = d.vehicles;
        document.getElementById('panel-title').textContent = 'Premium Deluxe Motorsport';
        renderCategories(d.vehicles);
        renderVehicles(d.vehicles);
        document.getElementById('overlay').classList.remove('hidden');
    } else if (d.action === 'showGarage') {
        mode = 'garage'; activeCategory = 'All';
        allVehicles = d.vehicles;
        document.getElementById('panel-title').textContent = 'My Garage';
        renderCategories(d.vehicles);
        renderVehicles(d.vehicles);
        document.getElementById('overlay').classList.remove('hidden');
    } else if (d.action === 'hide') {
        document.getElementById('overlay').classList.add('hidden');
    }
});

function buyVeh(model)      { post('buy',      { model }); }
function retrieveVeh(model) { post('retrieve', { model }); }
function sellVeh(model)     { post('sell',     { model }); }
function close_()           { post('close');   document.getElementById('overlay').classList.add('hidden'); }

document.addEventListener('keydown', e => { if (e.key === 'Escape') close_(); });
