const API = 'http://127.0.0.1:8000/api';
let allHistory = [];
let lastAssessment = null;

// ── AUTH CHECK ─────────────────────────────────────────────────────────
var token = localStorage.getItem('access_token');
var userData = JSON.parse(localStorage.getItem('user') || '{}');
if (!token) { window.location.href = '/'; }

// ── DATE ───────────────────────────────────────────────────────────────
var now = new Date();
document.getElementById('datechip').textContent =
  now.toLocaleDateString('en-GB', {day:'2-digit', month:'short', year:'numeric'});

// ── LOAD USER INFO ─────────────────────────────────────────────────────
function loadUserInfo() {
  if (userData.username) {
    var initials = ((userData.first_name||'?')[0] +
                   (userData.last_name||'')[0]).toUpperCase();
    document.getElementById('userAvatar').textContent = initials || '?';
    document.getElementById('userName').textContent =
      (userData.first_name + ' ' + userData.last_name).trim() || userData.username;
    document.getElementById('userRole').textContent = userData.role || 'User';
    document.getElementById('topbarTitle').textContent =
      'Welcome back, ' + (userData.first_name || userData.username) + ' \uD83D\uDC1D';
  }
}
loadUserInfo();

// ── LOAD DASHBOARD STATS ───────────────────────────────────────────────
function loadDashboardStats() {
  fetch(API + '/dashboard/', {
    headers: { 'Authorization': 'Bearer ' + token }
  })
  .then(function(r) { return r.json(); })
  .then(function(data) {
    document.getElementById('cardTotal').textContent        = data.total || 0;
    document.getElementById('cardQuality').textContent      = data.quality || 0;
    document.getElementById('cardIntermediate').textContent = data.intermediate || 0;
    document.getElementById('cardPoor').textContent         = data.poor || 0;
    document.getElementById('cardPassRate').textContent     = (data.pass_rate || 0) + '% pass rate';
    document.getElementById('statTotal').textContent        = data.total || 0;
    document.getElementById('statPass').textContent         = (data.pass_rate || 0) + '%';
    document.getElementById('historyBadge').textContent     = data.total || 0;
    document.getElementById('rTotal').textContent           = data.total || 0;
    document.getElementById('rQuality').textContent         = data.quality || 0;
    document.getElementById('rIntermediate').textContent    = data.intermediate || 0;
    document.getElementById('rPoor').textContent            = data.poor || 0;
    document.getElementById('rPassRate').textContent        = (data.pass_rate || 0) + '%';

    var list = document.getElementById('recentList');
    if (!data.recent || data.recent.length === 0) {
      list.innerHTML = '<div style="text-align:center; color:var(--text-light);' +
        'padding:20px; font-size:0.85rem;">No assessments yet. Start by assessing honey!</div>';
      return;
    }
    list.innerHTML = '';
    data.recent.forEach(function(a) {
      var badgeClass = a.quality_result === 'quality' ? 'badge-quality'
        : a.quality_result === 'intermediate' ? 'badge-intermediate' : 'badge-poor';
      var label = a.quality_result === 'quality' ? 'Quality'
        : a.quality_result === 'intermediate' ? 'Intermediate' : 'Poor';
      var date = new Date(a.assessed_at).toLocaleDateString('en-GB');
      list.innerHTML +=
        '<div class="mini-card">' +
          '<div style="font-size:1.6rem;">&#x1F36F;</div>' +
          '<div class="mini-card-info">' +
            '<div class="mini-card-name">' + (a.sample_label || 'Sample') + '</div>' +
            '<div class="mini-card-date">' + date + '</div>' +
          '</div>' +
          '<span class="badge ' + badgeClass + '">' + label + '</span>' +
        '</div>';
    });
  })
  .catch(function() {
    document.getElementById('recentList').innerHTML =
      '<div style="text-align:center; color:var(--text-light); padding:20px;">Failed to load.</div>';
  });
}
loadDashboardStats();

// ── LOAD HISTORY ───────────────────────────────────────────────────────
function loadHistory() {
  fetch(API + '/assess/history/', {
    headers: { 'Authorization': 'Bearer ' + token }
  })
  .then(function(r) { return r.json(); })
  .then(function(data) {
    allHistory = data;
    renderHistory(data);
  })
  .catch(function() { showToast('Failed to load history.'); });
}

function renderHistory(data) {
  var tbody = document.getElementById('historyBody');
  if (!data || data.length === 0) {
    tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;' +
      'padding:20px; color:var(--text-light);">No assessments found.</td></tr>';
    return;
  }
  tbody.innerHTML = '';
  data.forEach(function(a) {
    var badgeClass = a.quality_result === 'quality' ? 'badge-quality'
      : a.quality_result === 'intermediate' ? 'badge-intermediate' : 'badge-poor';
    var label = a.quality_result === 'quality' ? 'Quality'
      : a.quality_result === 'intermediate' ? 'Intermediate' : 'Poor';
    var rgb  = a.rgb_result || {};
    var date = new Date(a.assessed_at).toLocaleDateString('en-GB');
    tbody.innerHTML +=
      '<tr>' +
        '<td>' + date + '</td>' +
        '<td>' + (a.sample_label || '--') + '</td>' +
        '<td>' + (rgb.r_avg   || '--') + '</td>' +
        '<td>' + (rgb.g_avg   || '--') + '</td>' +
        '<td>' + (rgb.b_avg   || '--') + '</td>' +
        '<td>' + (rgb.rg_ratio|| '--') + '</td>' +
        '<td><span class="badge ' + badgeClass + '">' + label + '</span></td>' +
      '</tr>';
  });
}

function filterHistory() {
  var search = document.getElementById('historySearch').value.toLowerCase();
  var filter = document.getElementById('historyFilter').value;
  var filtered = allHistory.filter(function(a) {
    var matchSearch = !search || (a.sample_label||'').toLowerCase().includes(search);
    var matchFilter = !filter || a.quality_result === filter;
    return matchSearch && matchFilter;
  });
  renderHistory(filtered);
}

// ── IMAGE PREVIEW ──────────────────────────────────────────────────────
function previewImage(e) {
  var file = e.target.files[0];
  if (!file) return;
  document.getElementById('uploadIcon').textContent  = '\u2705';
  document.getElementById('uploadTitle').textContent = file.name;
  document.getElementById('uploadSub').textContent   = 'Image ready for analysis';
}

// ── RUN ASSESSMENT ─────────────────────────────────────────────────────
function runAssessment() {
  var file  = document.getElementById('assessFile').files[0];
  var label = document.getElementById('sampleLabel').value.trim() || 'Sample';
  if (!file) { showToast('Please select an image first'); return; }

  document.getElementById('step1').className = 'step done';
  document.getElementById('step1').querySelector('.step-num').textContent = '\u2713';
  document.getElementById('step2').className = 'step active';
  showToast('Analysing image...');

  var formData = new FormData();
  formData.append('image', file);
  formData.append('sample_label', label);

  fetch(API + '/assess/', {
    method: 'POST',
    headers: { 'Authorization': 'Bearer ' + token },
    body: formData,
  })
  .then(function(r) { return r.json(); })
  .then(function(data) {
    if (!data.assessment) { showToast('Assessment failed. Try again.'); return; }

    lastAssessment = data.assessment;
    var a   = data.assessment;
    var rgb = a.rgb_result || {};
    var r   = rgb.r_avg    || 0;
    var g   = rgb.g_avg    || 0;
    var b   = rgb.b_avg    || 0;
    var ratio = rgb.rg_ratio || 0;

    // Show QR image
if (a.qr_certificate && a.qr_certificate.qr_image) {
    var qrImg = '<img src="' + a.qr_certificate.qr_image +
                '" style="width:100%;height:100%;object-fit:contain;"/>';
    document.getElementById('assessQR').innerHTML    = qrImg;
    document.getElementById('qrPreviewBox').innerHTML = qrImg;

    // Fill QR detail page
    document.getElementById('qrDetailBox').innerHTML =
        '<table class="param-table">' +
            '<tr><td>Sample ID</td><td>' + (a.sample_label||'--') + '</td></tr>' +
            '<tr><td>Result</td><td>' + (a.quality_result||'--').toUpperCase() + '</td></tr>' +
            '<tr><td>Date</td><td>' + new Date(a.assessed_at).toLocaleDateString('en-GB') + '</td></tr>' +
            '<tr><td>Assessor</td><td>' + (userData.first_name||userData.username||'--') + '</td></tr>' +
        '</table>';

    // Complete step 4
    document.getElementById('step4').className = 'step done';
    document.getElementById('step4').querySelector('.step-num').textContent = '\u2713';
}

    // Animate bars
    document.getElementById('rBar').style.width   = (r/255*100) + '%';
    document.getElementById('gBar').style.width   = (g/255*100) + '%';
    document.getElementById('bBar').style.width   = (b/255*100) + '%';
    document.getElementById('avgBar').style.width = Math.min(ratio/2*100, 100) + '%';
    document.getElementById('rVal').textContent   = r;
    document.getElementById('gVal').textContent   = g;
    document.getElementById('bVal').textContent   = b;
    document.getElementById('avgVal').textContent = ratio;

    var badgeClass = a.quality_result === 'quality' ? 'badge-quality'
      : a.quality_result === 'intermediate' ? 'badge-intermediate' : 'badge-poor';
    var label2 = a.quality_result === 'quality' ? 'Quality'
      : a.quality_result === 'intermediate' ? 'Intermediate' : 'Poor';

    var badge = document.getElementById('resultBadge');
    badge.textContent = label2;
    badge.className   = 'badge ' + badgeClass;

    document.getElementById('resR').textContent    = r;
    document.getElementById('resG').textContent    = g;
    document.getElementById('resB').textContent    = b;
    document.getElementById('resRG').textContent   = ratio;
    document.getElementById('resDate').textContent =
      new Date(a.assessed_at).toLocaleDateString('en-GB');
    document.getElementById('resultDesc').textContent = a.description || '';
    document.getElementById('resultPanel').classList.add('show');

    document.getElementById('step2').className = 'step done';
    document.getElementById('step2').querySelector('.step-num').textContent = '\u2713';
    document.getElementById('step3').className = 'step done';
    document.getElementById('step3').querySelector('.step-num').textContent = '\u2713';
    document.getElementById('step4').className = 'step active';

    showToast('Assessment complete! Result: ' + label2);
    loadDashboardStats();
  })
  .catch(function() { showToast('Error connecting to server.'); });
}

// ── QUICK ASSESS ───────────────────────────────────────────────────────
function quickAssess(e) {
  var file = e.target.files[0];
  if (!file) return;
  showToast('Quick analysing...');

  var formData = new FormData();
  formData.append('image', file);
  formData.append('sample_label', 'Quick-' + Date.now());

  fetch(API + '/assess/', {
    method: 'POST',
    headers: { 'Authorization': 'Bearer ' + token },
    body: formData,
  })
  .then(function(r) { return r.json(); })
  .then(function(data) {
    if (!data.assessment) return;
    var a = data.assessment;
    var badgeClass = a.quality_result === 'quality' ? 'badge-quality'
      : a.quality_result === 'intermediate' ? 'badge-intermediate' : 'badge-poor';
    var label = a.quality_result === 'quality' ? 'Quality'
      : a.quality_result === 'intermediate' ? 'Intermediate' : 'Poor';
    document.getElementById('quickBadge').innerHTML =
      '<span class="badge ' + badgeClass + '">' + label + '</span>';
    document.getElementById('quickDesc').textContent = a.description || '';
    document.getElementById('quickResult').style.display = 'block';
    loadDashboardStats();
    showToast('Quick result: ' + label);
  })
  .catch(function() { showToast('Error during quick assess.'); });
}

// ── LOAD PROFILE ───────────────────────────────────────────────────────
function loadProfile() {
  fetch(API + '/auth/profile/', {
    headers: { 'Authorization': 'Bearer ' + token }
  })
  .then(function(r) { return r.json(); })
  .then(function(data) {
    document.getElementById('pFirstName').value         = data.first_name || '';
    document.getElementById('pLastName').value          = data.last_name  || '';
    document.getElementById('pEmail').value             = data.email      || '';
    document.getElementById('pPhone').value             = data.phone      || '';
    document.getElementById('pRegion').value            = data.region     || '';
    document.getElementById('pUsername').textContent    = data.username   || '--';
    document.getElementById('pRole').textContent        = data.role       || '--';
    document.getElementById('pSince').textContent       =
      data.created_at ? new Date(data.created_at).toLocaleDateString('en-GB') : '--';
  });
}

// ── SAVE PROFILE ───────────────────────────────────────────────────────
function saveProfile() {
  var payload = {
    first_name: document.getElementById('pFirstName').value,
    last_name:  document.getElementById('pLastName').value,
    email:      document.getElementById('pEmail').value,
    phone:      document.getElementById('pPhone').value,
    region:     document.getElementById('pRegion').value,
  };
  fetch(API + '/auth/profile/', {
    method: 'PUT',
    headers: {
      'Authorization': 'Bearer ' + token,
      'Content-Type':  'application/json',
    },
    body: JSON.stringify(payload),
  })
  .then(function(r) { return r.json(); })
  .then(function(data) {
    localStorage.setItem('user', JSON.stringify(data));
    userData = data;
    loadUserInfo();
    showToast('Profile updated successfully!');
  })
  .catch(function() { showToast('Failed to update profile.'); });
}

// ── EXPORT CSV ─────────────────────────────────────────────────────────
function exportCSV() {
  fetch(API + '/export/csv/', {
    headers: { 'Authorization': 'Bearer ' + token }
  })
  .then(function(r) { return r.blob(); })
  .then(function(blob) {
    var url = window.URL.createObjectURL(blob);
    var a   = document.createElement('a');
    a.href  = url;
    a.download = 'honeygrade_assessments.csv';
    a.click();
    window.URL.revokeObjectURL(url);
  });
}

// ── DOWNLOAD QR ────────────────────────────────────────────────────────
function downloadQR() {
  var img = document.getElementById('qrPreviewBox').querySelector('img');
  if (!img) {
    showToast('No QR code yet. Complete an assessment first.');
    return;
  }
  var a = document.createElement('a');
  a.href = img.src; a.download = 'honeygrade_qr.png'; a.click();
}

// ── PAGE NAVIGATION ────────────────────────────────────────────────────
function showPage(id) {
  document.querySelectorAll('.page').forEach(function(p) {
    p.classList.remove('active');
  });
  document.getElementById('page-' + id).classList.add('active');
  closeSidebar();
  var titles = {
    dashboard:  'Welcome back \uD83D\uDC1D',
    assess:     'Assess Honey \uD83D\uDD2C',
    history:    'Assessment History \uD83D\uDCCB',
    qr:         'QR Certificates \uD83D\uDCF2',
    parameters: 'RGB Parameters \uD83D\uDCCA',
    reports:    'Reports & Analytics \uD83D\uDCC8',
    profile:    'My Profile \uD83D\uDC64',
    settings:   'Settings \u2699\uFE0F',
  };
  document.getElementById('topbarTitle').textContent = titles[id] || 'HoneyGrade';
}

function setActive(id) {
  document.querySelectorAll('.nav-item').forEach(function(b) {
    b.classList.remove('active');
  });
  if (id) {
    var el = document.getElementById('nav-' + id);
    if (el) el.classList.add('active');
  }
}

function setBnav(id) {
  document.querySelectorAll('.bnav-item').forEach(function(b) {
    b.classList.remove('active');
  });
  var el = document.getElementById('bnav-' + id);
  if (el) el.classList.add('active');
}

// ── SIDEBAR ────────────────────────────────────────────────────────────
function toggleSidebar() {
  document.getElementById('sidebar').classList.toggle('open');
  document.getElementById('sidebarOverlay').classList.toggle('show');
}
function closeSidebar() {
  document.getElementById('sidebar').classList.remove('open');
  document.getElementById('sidebarOverlay').classList.remove('show');
}

// ── TOAST ──────────────────────────────────────────────────────────────
function showToast(msg) {
  var t = document.getElementById('toast');
  t.textContent = msg;
  t.classList.add('show');
  setTimeout(function() { t.classList.remove('show'); }, 3200);
}

// ── LOGOUT ─────────────────────────────────────────────────────────────
function logout() {
  localStorage.removeItem('access_token');
  localStorage.removeItem('refresh_token');
  localStorage.removeItem('user');
  window.location.href = '/';
}