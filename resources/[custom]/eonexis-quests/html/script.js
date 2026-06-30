'use strict';

let allQuests = [];
let selectedId = null;
let currentCat = 'all';

const app       = document.getElementById('app');
const questList = document.getElementById('questList');
const detail    = document.getElementById('detail');
document.getElementById('closeBtn').addEventListener('click', close);

document.querySelectorAll('.cat-tab').forEach(tab => {
  tab.addEventListener('click', () => {
    document.querySelectorAll('.cat-tab').forEach(t => t.classList.remove('active'));
    tab.classList.add('active');
    currentCat = tab.dataset.cat;
    renderList();
  });
});

function close() {
  fetch(`https://${GetParentResourceName()}/close`, { method: 'POST', body: JSON.stringify({}) });
  app.style.display = 'none';
}

window.addEventListener('message', e => {
  const data = e.data;
  if (data.action === 'open') {
    allQuests = data.quests || [];
    selectedId = null;
    renderList();
    detail.innerHTML = '<div class="empty-state">Select a quest to view details</div>';
    app.style.display = 'flex';
  } else if (data.action === 'close') {
    app.style.display = 'none';
  }
});

function statusOf(q) {
  if (q.completed)  return 'complete';
  if (q.available) {
    const anyDone = q.objectives.some(o => o.completed);
    return anyDone ? 'active' : 'available';
  }
  return 'locked';
}

const catIcon = { story:'📖', side:'⭐', criminal:'💀' };
const statusIcon = { complete:'✓', active:'●', available:'○', locked:'🔒' };
const statusLabel = { complete:'Complete', active:'In Progress', available:'Available', locked:'Locked' };

function renderList() {
  const filtered = currentCat === 'all' ? allQuests : allQuests.filter(q => q.category === currentCat);
  const order = ['active','available','complete','locked'];
  filtered.sort((a, b) => order.indexOf(statusOf(a)) - order.indexOf(statusOf(b)));

  questList.innerHTML = filtered.map(q => {
    const st = statusOf(q);
    const doneCount = q.objectives.filter(o => o.completed).length;
    return `<div class="quest-item ${st} ${selectedId===q.id?'selected':''}" onclick="selectQuest('${q.id}')">
      <div class="q-icon">${catIcon[q.category]||'?'}</div>
      <div class="q-info">
        <div class="q-name">${q.title}</div>
        <div class="q-sub">${st==='complete'?'Done':`${doneCount}/${q.objectives.length} objectives`}</div>
      </div>
    </div>`;
  }).join('');
}

function selectQuest(id) {
  selectedId = id;
  renderList();
  const q = allQuests.find(x => x.id === id);
  if (!q) return;
  const st = statusOf(q);
  detail.innerHTML = `
    <div class="detail-title">${q.title}</div>
    <div class="detail-cat ${q.category}">${q.category.toUpperCase()}</div>
    <div class="detail-desc">${q.desc}</div>
    <div class="section-label">Objectives</div>
    <div class="obj-list">
      ${q.objectives.map(o => `
        <div class="obj-item">
          <div class="obj-check ${o.completed?'done':''}">
            ${o.completed?'✓':''}
          </div>
          <span class="obj-text ${o.completed?'done':''}">${o.text}</span>
        </div>
      `).join('')}
    </div>
    <div class="section-label">Reward</div>
    <div class="reward-box">
      <div class="reward-icon">💵</div>
      <div>
        <div class="reward-label">Cash Reward</div>
        <div class="reward-amount">$${q.reward.toLocaleString()}</div>
      </div>
    </div>
    <div class="status-badge ${st}">${statusLabel[st]}</div>
  `;
}

function GetParentResourceName() {
  return 'eonexis-quests';
}

// Close on Q or Escape — NUI captures keyboard when focused so the game command can't fire
document.addEventListener('keydown', function(e) {
    if (e.key === 'q' || e.key === 'Q' || e.key === 'Escape') close();
});

// UI scale from eonexis-settings
window.addEventListener('message', function(e) {
    if (e.data && e.data.action === 'setScale') {
        document.body.style.transform = 'scale(' + e.data.scale + ')';
        document.body.style.transformOrigin = 'center center';
    }
});
