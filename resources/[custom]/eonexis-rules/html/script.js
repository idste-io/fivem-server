const overlay = document.getElementById('overlay');

function close() {
  overlay.classList.add('hidden');
  fetch(`https://${GetParentResourceName()}/close`, { method: 'POST', body: '{}' });
}

window.addEventListener('message', ({ data }) => {
  if (data?.type === 'open')  overlay.classList.remove('hidden');
  if (data?.type === 'close') overlay.classList.add('hidden');
});

window.addEventListener('keydown', e => { if (e.key === 'Escape') close(); });
