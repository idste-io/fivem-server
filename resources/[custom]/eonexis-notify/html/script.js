const ICONS = { info: '🔵', success: '✅', error: '🔴', warning: '⚠️' };

window.addEventListener('message', ({ data }) => {
  if (data?.type !== 'notify') return;
  const { title, message, notifType = 'info', duration = 4000 } = data;

  const el = document.createElement('div');
  el.className = `notif ${notifType}`;
  el.innerHTML = `
    <span class="notif-icon">${ICONS[notifType] || ICONS.info}</span>
    <div class="notif-body">
      <div class="notif-title">${title}</div>
      ${message ? `<div class="notif-msg">${message}</div>` : ''}
    </div>`;

  document.getElementById('container').prepend(el);

  setTimeout(() => {
    el.classList.add('out');
    setTimeout(() => el.remove(), 300);
  }, duration);
});
