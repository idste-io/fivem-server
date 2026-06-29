// Eonexis Loading Screen — FiveM NUI integration

const statusMsg   = document.getElementById('statusMsg');
const progressFill = document.getElementById('progressFill');
const progressGlow = document.getElementById('progressGlow');
const progressPct  = document.getElementById('progressPct');
const tipText      = document.getElementById('tipText');

const TIPS = [
  "Eonexis — your world, your rules.",
  "Use /help in chat to see all available commands.",
  "Report bugs or suggestions in our Discord.",
  "Custom mods and events update automatically.",
  "Connect with friends: share the server IP in the FiveM launcher.",
  "The city never sleeps — neither do we.",
];

let tipIndex = 0;
function rotateTip() {
  tipText.style.opacity = '0';
  setTimeout(() => {
    tipText.textContent = TIPS[tipIndex % TIPS.length];
    tipText.style.opacity = '1';
    tipIndex++;
  }, 500);
}
rotateTip();
setInterval(rotateTip, 6000);

// Map FiveM load states to human-readable messages
const STATE_LABELS = {
  'loadingscreen'         : 'Preparing connection...',
  'receiveHostInformation': 'Receiving host info...',
  'getOrCreatePlayer'     : 'Creating player...',
  'beforeEnsure'          : 'Loading resources...',
  'perfDataFile'          : 'Loading data files...',
  'loadMap'               : 'Loading map...',
  'loadingInitialResources': 'Starting resources...',
  'done'                  : 'Almost there...',
};

// Handle FiveM loading events
window.addEventListener('message', function(e) {
  const data = e.data;
  if (!data || !data.eventName) return;

  switch (data.eventName) {
    case 'loadProgress': {
      const pct = Math.round((data.loadFraction || 0) * 100);
      setProgress(pct);
      break;
    }
    case 'startPrepProgress': {
      setStatus(STATE_LABELS[data.type] || 'Loading...');
      break;
    }
    case 'dataFilesEntry': {
      setStatus('Loading data files...');
      break;
    }
    case 'performMapLoadFunction': {
      setStatus('Loading map...');
      break;
    }
    case 'onClientResourceStart': {
      setStatus(`Starting ${data.resourceName || 'resources'}...`);
      break;
    }
    case 'shutdown': {
      setStatus('Entering the city...');
      setProgress(100);
      // Signal FiveM we're done — allows manual shutdown mode to proceed
      setTimeout(() => {
        SendNuiMessage(JSON.stringify({ type: 'shutdown' }));
      }, 800);
      break;
    }
  }
});

function setProgress(pct) {
  const clamped = Math.max(0, Math.min(100, pct));
  progressFill.style.width = clamped + '%';
  progressPct.textContent  = clamped + '%';
  progressGlow.style.opacity = clamped > 0 ? '1' : '0';
  progressGlow.style.right = (100 - clamped) + '%';
  progressGlow.style.transform = 'translate(50%, -50%)';
}

function setStatus(msg) {
  statusMsg.style.opacity = '0';
  setTimeout(() => {
    statusMsg.textContent = msg;
    statusMsg.style.opacity = '1';
  }, 150);
}

// Animate progress during initial load so it doesn't look frozen
let fakePct = 0;
const fakeInterval = setInterval(() => {
  if (fakePct >= 15) { clearInterval(fakeInterval); return; }
  fakePct += 0.5;
  setProgress(fakePct);
}, 100);
