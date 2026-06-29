let currentJob = 'unemployed';

function post(action, data) {
    fetch('https://eonexis-jobs/' + action, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {})
    });
}

window.addEventListener('message', function(e) {
    const d = e.data;
    if (d.action === 'show') {
        currentJob = d.current || 'unemployed';

        const bar = document.getElementById('current-job-bar');
        if (currentJob !== 'unemployed') {
            const job = d.jobs.find(j => j.id === currentJob);
            document.getElementById('current-label').textContent =
                (job ? job.icon + ' ' : '') + 'Current: ' + (job ? job.label : currentJob);
            bar.classList.remove('hidden');
        } else {
            bar.classList.add('hidden');
        }

        const list = document.getElementById('job-list');
        list.innerHTML = d.jobs.map(j => `
            <div class="job-card${j.id === currentJob ? ' active' : ''}">
                <div class="job-icon">${j.icon}</div>
                <div class="job-info">
                    <div class="job-label">${j.label}</div>
                    <div class="job-desc">${j.desc}</div>
                    <div class="job-pay">$${j.pay.min}–$${j.pay.max} per task</div>
                </div>
                ${j.id !== currentJob
                    ? `<button class="btn-select" onclick="selectJob('${j.id}')">Apply</button>`
                    : '<span style="color:hsl(258,85%,65%);font-size:12px;font-weight:700;">✓ Hired</span>'
                }
            </div>
        `).join('');

        document.getElementById('overlay').classList.remove('hidden');
    } else if (d.action === 'hide') {
        document.getElementById('overlay').classList.add('hidden');
    }
});

function selectJob(id) { post('selectJob', { id }); }
function quitJob()      { post('quitJob'); }
function startShift()   { post('startShift'); }
function close_()       { post('close'); document.getElementById('overlay').classList.add('hidden'); }

document.addEventListener('keydown', e => { if (e.key === 'Escape') close_(); });
