const hud      = document.getElementById('hud');
const hpBar    = document.getElementById('hp-bar');
const hpVal    = document.getElementById('hp-val');
const armBar   = document.getElementById('arm-bar');
const armVal   = document.getElementById('arm-val');
const speedBlk = document.getElementById('speed-block');
const speedVal = document.getElementById('speed-val');
const speedUnit= document.getElementById('speed-unit');
const street   = document.getElementById('street-name');
const clock    = document.getElementById('clock');

window.addEventListener('message', ({ data }) => {
  if (!data?.type) return;

  if (data.type === 'show') {
    hud.classList.toggle('hidden', !data.visible);
    return;
  }

  if (data.type === 'update') {
    hpBar.style.width  = data.hp + '%';
    hpVal.textContent  = data.hp;
    armBar.style.width = data.armour + '%';
    armVal.textContent = data.armour;

    hpBar.style.background = data.hp > 50 ? 'hsl(152,80%,45%)' :
                             data.hp > 25 ? 'hsl(38,95%,60%)'  : 'hsl(0,72%,51%)';

    if (data.inVeh) {
      speedBlk.classList.remove('hidden');
      speedVal.textContent  = data.speed;
      speedUnit.textContent = data.unit;
    } else {
      speedBlk.classList.add('hidden');
    }

    street.textContent = data.street;
    clock.textContent  = data.time;
  }
});
