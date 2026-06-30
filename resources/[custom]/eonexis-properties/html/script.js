let currentProp = null;

window.addEventListener('message', function(e) {
    const d = e.data;
    if (d.action === 'show') {
        const p = d.prop;
        currentProp = p;
        document.getElementById('prop-icon').textContent  = p.icon  || '🏠';
        document.getElementById('prop-label').textContent = p.label;
        document.getElementById('prop-desc').textContent  = p.desc;
        document.getElementById('prop-type').textContent  = p.type === 'house' ? 'House' : 'Business';
        document.getElementById('prop-price').textContent = '$' + p.price.toLocaleString();
        document.getElementById('btn-buy').classList.toggle('hidden',  !!p.owned);
        document.getElementById('btn-sell').classList.toggle('hidden', !p.owned);
        document.getElementById('btn-home').classList.toggle('hidden', !p.owned || p.type !== 'house');
        document.getElementById('overlay').classList.remove('hidden');
    } else if (d.action === 'hide') {
        document.getElementById('overlay').classList.add('hidden');
    }
});

function post(action, extra) {
    fetch('https://eonexis-properties/' + action, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(Object.assign({ id: currentProp?.id }, extra))
    });
}

function buyProp()  { post('buy'); }
function sellProp() { post('sell'); }
function setHome()  { post('setHome'); }
function close_()   { post('close'); document.getElementById('overlay').classList.add('hidden'); }

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') close_();
});

// UI scale from eonexis-settings
window.addEventListener('message', function(e) {
    if (e.data && e.data.action === 'setScale') {
        document.body.style.transform = 'scale(' + e.data.scale + ')';
        document.body.style.transformOrigin = 'center center';
    }
});
