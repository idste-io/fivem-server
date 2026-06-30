const barsEl    = document.getElementById('bars');
const hFill     = document.getElementById('hunger-fill');
const tFill     = document.getElementById('thirst-fill');
const hVal      = document.getElementById('hunger-val');
const tVal      = document.getElementById('thirst-val');

function setBar(fill, valEl, pct) {
  fill.style.width = Math.max(0, Math.min(100, pct)) + '%';
  valEl.textContent = Math.floor(pct) + '%';
  // Colour shifts red when danger
  if (pct < 20) {
    fill.style.background = '#e74c3c';
  } else if (pct < 40) {
    fill.style.background = '#e67e22';
  } else {
    fill.style.background = fill.classList.contains('hunger') ? '#e67e22' : '#3498db';
  }
}

window.addEventListener('message', e => {
  const d = e.data;
  if (d.action === 'show') {
    barsEl.classList.remove('hidden');
  } else if (d.action === 'hide') {
    barsEl.classList.add('hidden');
  } else if (d.action === 'update') {
    setBar(hFill, hVal, d.hunger);
    setBar(tFill, tVal, d.thirst);
  }
});

// UI scale from eonexis-settings
window.addEventListener('message', function(e) {
    if (e.data && e.data.action === 'setScale') {
        document.body.style.transform = 'scale(' + e.data.scale + ')';
        document.body.style.transformOrigin = 'center center';
    }
});
