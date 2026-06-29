let prizes = [];
let spinning = false;
let currentAngle = 0;

const canvas = document.getElementById('wheel');
const ctx = canvas.getContext('2d');

function post(action, data) {
    fetch('https://eonexis-casino/' + action, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {})
    });
}

function drawWheel(angle) {
    if (!prizes.length) return;
    const cx = canvas.width / 2, cy = canvas.height / 2, r = cx - 4;
    const seg = (Math.PI * 2) / prizes.length;
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    prizes.forEach((p, i) => {
        const start = angle + i * seg;
        const end   = start + seg;

        ctx.beginPath();
        ctx.moveTo(cx, cy);
        ctx.arc(cx, cy, r, start, end);
        ctx.closePath();
        ctx.fillStyle = p.colour || '#555';
        ctx.fill();
        ctx.strokeStyle = 'rgba(0,0,0,0.3)';
        ctx.lineWidth = 1;
        ctx.stroke();

        // Label
        ctx.save();
        ctx.translate(cx, cy);
        ctx.rotate(start + seg / 2);
        ctx.textAlign = 'right';
        ctx.fillStyle = '#fff';
        ctx.font = 'bold 11px Segoe UI';
        ctx.shadowColor = 'rgba(0,0,0,0.8)';
        ctx.shadowBlur = 4;
        ctx.fillText(p.label, r - 10, 4);
        ctx.restore();
    });

    // Centre circle
    ctx.beginPath();
    ctx.arc(cx, cy, 18, 0, Math.PI * 2);
    ctx.fillStyle = 'hsl(258,85%,50%)';
    ctx.fill();
}

function doSpin() {
    if (spinning) return;
    post('spin');
    document.getElementById('btn-spin').disabled = true;
    document.getElementById('result-msg').classList.add('hidden');
}

function animateTo(targetIndex, onDone) {
    const seg = (Math.PI * 2) / prizes.length;
    // Target: needle at top (−π/2) points to segment targetIndex
    // Segment i starts at currentAngle + i*seg; needle is at -π/2
    // We want: currentAngle + targetIndex*seg + seg/2 = -π/2 + 2πk (mod 2π)
    const targetAngle = -Math.PI / 2 - (targetIndex * seg + seg / 2);
    const fullSpins = Math.PI * 2 * (5 + Math.floor(Math.random() * 3));
    const finalAngle = targetAngle - (currentAngle % (Math.PI * 2)) + fullSpins;

    const duration = 4000;
    const start = performance.now();
    const startAngle = currentAngle;

    function step(now) {
        const t = Math.min((now - start) / duration, 1);
        const eased = 1 - Math.pow(1 - t, 4);
        currentAngle = startAngle + finalAngle * eased;
        drawWheel(currentAngle);
        if (t < 1) {
            requestAnimationFrame(step);
        } else {
            currentAngle = startAngle + finalAngle;
            spinning = false;
            onDone();
        }
    }
    spinning = true;
    requestAnimationFrame(step);
}

window.addEventListener('message', function(e) {
    const d = e.data;
    if (d.action === 'open') {
        prizes = d.prizes;
        document.getElementById('spin-cost').textContent = '$' + d.cost.toLocaleString();
        document.getElementById('casino').classList.remove('hidden');
        document.getElementById('btn-spin').disabled = false;
        document.getElementById('result-msg').classList.add('hidden');
        currentAngle = 0;
        drawWheel(0);
    } else if (d.action === 'close') {
        document.getElementById('casino').classList.add('hidden');
    } else if (d.action === 'spinResult') {
        animateTo(d.prizeIndex - 1, function() {
            const msg = document.getElementById('result-msg');
            msg.textContent = d.prize.type === 'nothing'
                ? '😔 Better luck next time!'
                : '🎉 You won: ' + d.prize.label + '!';
            msg.classList.remove('hidden');
            document.getElementById('btn-spin').disabled = false;
        });
    } else if (d.action === 'error') {
        const msg = document.getElementById('result-msg');
        msg.textContent = '⚠ ' + d.msg;
        msg.classList.remove('hidden');
        document.getElementById('btn-spin').disabled = false;
    }
});
