'use strict';
let routes = [];
let selectedRoute = 0;

const app     = document.getElementById('app');
const tabs    = document.getElementById('tabs');
const content = document.getElementById('content');
document.getElementById('closeBtn').addEventListener('click', close);

function close() {
  fetch(`https://eonexis-racing/close`, { method: 'POST', body: JSON.stringify({}) });
  app.style.display = 'none';
}

function fmt(seconds) {
  const m = Math.floor(seconds / 60);
  const s = (seconds % 60).toFixed(2).padStart(5, '0');
  return `${m}:${s}`;
}

const medals = ['🥇','🥈','🥉'];

function renderContent() {
  const route = routes[selectedRoute];
  if (!route) { content.innerHTML = '<div class="empty">No data</div>'; return; }
  if (!route.records || route.records.length === 0) {
    content.innerHTML = '<div class="empty">No records yet — be the first to race!</div>';
    return;
  }
  content.innerHTML = route.records.map((r, i) => `
    <div class="record-row">
      <div class="rank">${medals[i] || (i+1)}</div>
      <div class="rname">${r.name}</div>
      <div class="rtime">${fmt(r.time)}</div>
      <div class="rdate">${r.date||''}</div>
    </div>
  `).join('');
}

function renderTabs() {
  tabs.innerHTML = routes.map((r, i) => `
    <button class="tab ${i===selectedRoute?'active':''}" onclick="selectTab(${i})">${r.name}</button>
  `).join('');
}

window.selectTab = function(i) {
  selectedRoute = i;
  renderTabs();
  renderContent();
};

window.addEventListener('message', e => {
  const d = e.data;
  if (d.action === 'open') {
    app.style.display = 'flex';
  } else if (d.action === 'close') {
    app.style.display = 'none';
  } else if (d.action === 'leaderboard') {
    routes = d.data || [];
    selectedRoute = 0;
    renderTabs();
    renderContent();
  }
});
