const treeEl    = document.getElementById('tree');
const skillList = document.getElementById('skill-list');
const progFill  = document.getElementById('progress-fill');
const progText  = document.getElementById('progress-text');

let allSkills   = [];
let currentTier = 0;

function post(action, data = {}) {
  fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  });
}

const tierIcons  = { 1: '🔵', 2: '🟠', 3: '🟣' };
const tierLabels = { 1: 'Tier 1 — Onboarding', 2: 'Tier 2 — Established', 3: 'Tier 3 — Advanced' };

function fmt(n) { return n != null ? '$' + Number(n).toLocaleString() : ''; }

function render() {
  const visible = currentTier === 0 ? allSkills : allSkills.filter(s => s.tier === currentTier);

  // Progress
  const total = allSkills.length;
  const done  = allSkills.filter(s => s.completed).length;
  progFill.style.width = total > 0 ? (done / total * 100) + '%' : '0%';
  progText.textContent = done + ' / ' + total;

  skillList.innerHTML = '';
  let lastTier = 0;

  visible.forEach(skill => {
    if (skill.tier !== lastTier) {
      lastTier = skill.tier;
      const hdr = document.createElement('div');
      hdr.className = 'tier-header';
      hdr.textContent = tierLabels[skill.tier] || ('Tier ' + skill.tier);
      skillList.appendChild(hdr);
    }

    const card = document.createElement('div');
    card.className = 'skill-card' +
      (skill.completed ? ' done' : skill.available ? ' available' : ' locked');

    const tierBadge = `<span class="tier-badge tier${skill.tier}">T${skill.tier}</span>`;
    const rewardStr = skill.reward && skill.reward.cash ? fmt(skill.reward.cash) : '';

    let rightHtml = '';
    if (skill.completed) {
      rightHtml = `<div class="badge-done">✓ Done</div>`;
    } else if (skill.available) {
      rightHtml = `<button class="btn-complete" onclick="complete('${skill.id}')">Complete</button>`;
    } else {
      rightHtml = `<div class="badge-locked">🔒 Locked</div>`;
    }

    card.innerHTML = `
      <div class="skill-icon">${tierIcons[skill.tier] || '⭐'}</div>
      <div class="skill-body">
        <div class="skill-label">${skill.label}</div>
        <div class="skill-desc">${skill.desc}</div>
        ${rewardStr ? `<div class="skill-reward">+${rewardStr}${skill.unlocks ? ' · Unlocks: ' + skill.unlocks : ''}</div>` : ''}
      </div>
      <div class="skill-right">
        ${tierBadge}
        ${rightHtml}
      </div>
    `;
    skillList.appendChild(card);
  });
}

function complete(id) {
  post('complete', { id });
}

function filterTier(tier) {
  currentTier = tier;
  document.querySelectorAll('.tier-tab').forEach((t, i) => {
    t.classList.toggle('active', i === tier);
  });
  render();
}

// Tab buttons have indices 0=All,1=T1,2=T2,3=T3
document.querySelectorAll('.tier-tab').forEach((btn, i) => {
  btn.addEventListener('click', () => filterTier(i));
});

window.addEventListener('message', e => {
  const d = e.data;
  if (d.action === 'open') {
    allSkills = d.skills || [];
    treeEl.classList.remove('hidden');
    render();
  } else if (d.action === 'close') {
    treeEl.classList.add('hidden');
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
