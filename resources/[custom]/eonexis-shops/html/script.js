const shopEl   = document.getElementById('shop');
const shopName = document.getElementById('shop-name');
const itemList = document.getElementById('item-list');
const cashDisp = document.getElementById('cash-display');

let items = [];

function post(action, data = {}) {
  fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  });
}

function fmt(n) { return '$' + Number(n).toLocaleString(); }

function renderItems() {
  itemList.innerHTML = '';
  items.forEach(item => {
    const row = document.createElement('div');
    row.className = 'item-row';
    row.innerHTML = `
      <div class="item-icon">${item.icon}</div>
      <div class="item-info">
        <div class="item-label">${item.label}</div>
        <div class="item-desc">${item.desc}</div>
      </div>
      <div class="item-price">${fmt(item.price)}</div>
      <button class="btn-buy" onclick="buyItem('${item.id}')">Buy</button>
    `;
    itemList.appendChild(row);
  });
}

function buyItem(id) {
  post('buy', { id });
}

window.addEventListener('message', e => {
  const d = e.data;
  if (d.action === 'open') {
    items = d.items || [];
    shopName.textContent = d.shopLabel || '24/7 Store';
    renderItems();
    shopEl.classList.remove('hidden');
  } else if (d.action === 'close') {
    shopEl.classList.add('hidden');
  } else if (d.action === 'updateCash') {
    cashDisp.textContent = fmt(d.cash);
  }
});

document.addEventListener('keydown', e => {
  if (e.key === 'Escape') post('close');
});

// UI scale from eonexis-settings
window.addEventListener('message', function(e) {
    if (e.data && e.data.action === 'setScale') {
        document.body.style.transform = 'scale(' + e.data.scale + ')';
        document.body.style.transformOrigin = 'center center';
    }
});
