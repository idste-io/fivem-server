'use strict';

let currentJob   = 'unemployed';
let myLicenses   = [];
let allJobs      = [];
let currentLicId = null;

function post(action, data) {
    fetch('https://eonexis-jobs/' + action, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {})
    });
}

function hasLicense(licId) {
    if (!licId) return true;
    return myLicenses.includes(licId);
}

function licBadge(job) {
    if (!job.license) return '';
    const owned = hasLicense(job.license);
    const icon  = owned ? '🪪 ' : '🔒 ';
    const text  = job.license.replace('_', ' ');
    return `<span class="job-lic ${owned ? 'owned' : 'missing'}">${icon}${text}</span>`;
}

function renderJobs(jobs) {
    const list = document.getElementById('job-list');
    list.innerHTML = jobs.map(j => {
        const isCurrent = j.id === currentJob;
        const locked    = j.license && !hasLicense(j.license);
        return `
        <div class="job-card${isCurrent ? ' active' : ''}${locked ? ' locked' : ''}">
          <div class="job-icon">${j.icon}</div>
          <div class="job-info">
            <div class="job-label">${j.label}</div>
            <div class="job-desc">${j.desc}</div>
            <div class="job-pay">$${j.pay.min}–$${j.pay.max} per task</div>
            ${licBadge(j)}
          </div>
          ${isCurrent
            ? '<span style="color:hsl(258,85%,65%);font-size:11px;font-weight:700;flex-shrink:0;">✓ Hired</span>'
            : locked
              ? `<button class="btn-locked" onclick="selectJob('${j.id}')">Get License</button>`
              : `<button class="btn-select" onclick="selectJob('${j.id}')">Apply</button>`}
        </div>`;
    }).join('');
}

function filterJobs() {
    const q = document.getElementById('searchInput').value.toLowerCase();
    const filtered = allJobs.filter(j =>
        j.label.toLowerCase().includes(q) || j.desc.toLowerCase().includes(q)
    );
    renderJobs(filtered);
}

window.addEventListener('message', function(e) {
    const d = e.data;
    if (!d) return;

    if (d.action === 'show') {
        currentJob  = d.current || 'unemployed';
        myLicenses  = d.licenses || [];
        allJobs     = d.jobs || [];

        const bar = document.getElementById('current-job-bar');
        if (currentJob !== 'unemployed') {
            const job = allJobs.find(j => j.id === currentJob);
            document.getElementById('current-label').textContent =
                (job ? job.icon + ' ' : '') + (job ? job.label : currentJob);
            bar.classList.remove('hidden');
        } else {
            bar.classList.add('hidden');
        }
        document.getElementById('searchInput').value = '';
        renderJobs(allJobs);
        document.getElementById('overlay').classList.remove('hidden');
    }

    if (d.action === 'hide') {
        document.getElementById('overlay').classList.add('hidden');
    }

    if (d.action === 'setLicenses') {
        myLicenses = d.licenses || [];
        if (allJobs.length) renderJobs(allJobs);
    }

    if (d.action === 'showLicMenu') {
        const lic = d.license;
        currentLicId = lic.id;
        document.getElementById('licTitle').textContent = lic.label;
        document.getElementById('licDesc').textContent  = lic.desc;
        document.getElementById('licCost').textContent  = '$' + lic.cost.toLocaleString();

        const owned   = d.owned;
        const ownedBadge = document.getElementById('licOwnedBadge');
        const buyBtn  = document.getElementById('licBuyBtn');
        if (owned) {
            ownedBadge.classList.remove('hidden');
            buyBtn.disabled = true;
        } else {
            ownedBadge.classList.add('hidden');
            buyBtn.disabled = false;
        }
        document.getElementById('lic-overlay').classList.remove('hidden');
    }

    if (d.action === 'hideLicMenu') {
        document.getElementById('lic-overlay').classList.add('hidden');
        currentLicId = null;
    }
});

function selectJob(id) { post('selectJob', { id }); }
function quitJob()      { post('quitJob'); }
function startShift()   { post('startShift'); }
function buyLic()       { if (currentLicId) post('buyLicense', { id: currentLicId }); }
function closeLic()     { post('closeLic'); document.getElementById('lic-overlay').classList.add('hidden'); }
function close_()       { post('close'); document.getElementById('overlay').classList.add('hidden'); }

document.addEventListener('keydown', e => {
    if (e.key === 'Escape') { close_(); closeLic(); }
});

// ── Resize handle ──────────────────────────────────────────────────────────────
(function() {
    const panel  = document.getElementById('panel');
    const handle = document.getElementById('resizeHandle');
    if (!handle || !panel) return;

    let dragging = false, startX, startY, startW, startH;

    handle.addEventListener('mousedown', e => {
        dragging = true;
        startX = e.clientX; startY = e.clientY;
        startW = panel.offsetWidth; startH = panel.offsetHeight;
        e.preventDefault();
    });

    document.addEventListener('mousemove', e => {
        if (!dragging) return;
        const newW = Math.max(380, startW + (e.clientX - startX));
        const newH = Math.max(300, startH + (e.clientY - startY));
        panel.style.width  = newW + 'px';
        panel.style.height = newH + 'px';
        panel.style.maxHeight = newH + 'px';
    });

    document.addEventListener('mouseup', () => { dragging = false; });
})();
