'use strict';

let discordInvite = 'https://discord.gg/jsa8UgGcCD';

window.addEventListener('message', function(e) {
  const data = e.data;
  if (data.type === 'show') {
    discordInvite = data.invite || discordInvite;
    document.getElementById('server-name').textContent = data.server || 'Eonexis';
    document.getElementById('toast').classList.remove('hidden');
  } else if (data.type === 'hide') {
    document.getElementById('toast').classList.add('hidden');
  }
});

function joinDiscord() {
  fetch('https://cfx-nui-eonexis-discord/openDiscord', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({}),
  });
  dismiss();
}

function dismiss() {
  document.getElementById('toast').classList.add('hidden');
  fetch('https://cfx-nui-eonexis-discord/dismiss', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({}),
  });
}

// UI scale from eonexis-settings
window.addEventListener('message', function(e) {
    if (e.data && e.data.action === 'setScale') {
        document.body.style.transform = 'scale(' + e.data.scale + ')';
        document.body.style.transformOrigin = 'center center';
    }
});
