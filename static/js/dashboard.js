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

// ── GRADE HELPERS ──────────────────────────────────────────────────────
function gradeColor(grade) {
  switch(grade) {
    case 'A': return '#16A34A';
    case 'B': return '#2563EB';
    case 'C': return '#CA8A04';
    case 'D': return '#DC2626';
    default:  return '#92400E';
  }
}

function gradeLabel(grade) {
  switch(grade) {
    case 'A': return '🏆 Grade A — Premium Amber';
    case 'B': return '✅ Grade B — Good Quality';
    case 'C': return '⚠️ Grade C — Acceptable';
    case 'D': return '🔬 Grade D — Below Standard';
    default:  return '❓ Unknown';
  }
}

function gradeBadgeHTML(grade) {
  const color = gradeColor(grade);
  const label = gradeLabel(grade);
  return `<span style="
    display:inline-flex; align-items:center; gap:6px;
    padding:4px 12px; border-radius:20px; font-weight:700;
    font-size:0.75rem;
    background:${color}20;
    color:${color};
    border:1.5px solid ${color}40;">
    ${label}
  </span>`;
}

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
      'Welcome back, ' + (userData.first_name || userData.username) + ' 🐝';
  }
}
loadUserInfo();

// ── LOAD DASHBOARD STATS ───────────────────────────────────────────────
function loadDashboardStats() {
  fetch(API + '/dashboard/', {
    headers: { 'Authorization': 'Bearer ' + token }
  })
  .then(function(r) {
    if (r.status === 401) { window.location.href = '/'; return; }
    return r.json();
  })
  .then(function(data) {
    if (!data) return;

    // Update hero pills
    document.getElementById('statTotal').textContent  = data.total || 0;
    document.getElementById('statPass').textContent   = (data.pass_rate || 0) + '%';
    document.getElementById('historyBadge').textContent = data.total || 0;

    // Update stat cards with GRADE system
    document.getElementById('cardTotal').textContent = data.total || 0;
    document.getElementById('cardPassRate').textContent = (data.pass_rate || 0) + '% pass rate';

    // Grade A = quality, Grade B = intermediate (map old to new)
    var gradeA = data.quality      || 0;
    var gradeB = data.intermediate || 0;
    var gradeC = data.poor         || 0;

    document.getElementById('cardQuality').textContent      = gradeA;
    document.getElementById('cardIntermediate').textContent = gradeB;
    document.getElementById('cardPoor').textContent         = gradeC;

    // Update stat card labels to show grades
    var labels = document.querySelectorAll('.stat-label');
    if (labels[1]) labels[1].textContent = 'Grade A & B';
    if (labels[2]) labels[2].textContent = 'Grade C';
    if (labels[3]) labels[3].textContent = 'Grade D';

    // Reports
    document.getElementById('rTotal').textContent        = data.total || 0;
    document.getElementById('rQuality').textContent      = gradeA;
    document.getElementById('rIntermediate').textContent = gradeB;
    document.getElementById('rPoor').textContent         = gradeC;
    document.getElementById('rPassRate').textContent     = (data.pass_rate || 0) + '%';

    // Recent list
    var list = document.getElementById('recentList');
    if (!data.recent || data.recent.length === 0) {
      list.innerHTML = '<div style="text-align:center; color:var(--text-light);' +
        'padding:20px; font-size:0.85rem;">No assessments yet. Start by assessing honey!</div>';
      return;
    }
    list.innerHTML = '';
    data.recent.forEach(function(a) {
      var grade = a.quality_result;
      var color = gradeColor(grade);
      var label = gradeLabel(grade);
      var date  = new Date(a.assessed_at).toLocaleDateString('en-GB');
      list.innerHTML +=
        '<div class="mini-card">' +
          '<div style="width:42px;height:42px;border-radius:12px;' +
               'background:' + color + '20;border:1.5px solid ' + color + '40;' +
               'display:flex;align-items:center;justify-content:center;' +
               'font-size:1.3rem;font-weight:900;color:' + color + ';flex-shrink:0;">' +
            grade +
          '</div>' +
          '<div class="mini-card-info">' +
            '<div class="mini-card-name">' + (a.sample_label || 'Sample') + '</div>' +
            '<div class="mini-card-date">' + date + '</div>' +
          '</div>' +
          '<span style="display:inline-flex;align-items:center;padding:4px 10px;' +
               'border-radius:20px;font-weight:700;font-size:0.72rem;' +
               'background:' + color + '15;color:' + color + ';' +
               'border:1.5px solid ' + color + '30;">' +
            label.split('—')[0].trim() +
          '</span>' +
        '</div>';
    });
  })
  .catch(function() {
    document.getElementById('recentList').innerHTML =
      '<div style="text-align:center;color:var(--text-light);padding:20px;">Failed to load.</div>';
  });
}
loadDashboardStats();

// ── LOAD HISTORY ───────────────────────────────────────────────────────
function loadHistory() {
  fetch(API + '/assess/history/', {
    headers: { 'Authorization': 'Bearer ' + token }
  })
  .then(function(r) { return r.json(); })
  .then(function(data) { allHistory = data; renderHistory(data); })
  .catch(function() { showToast('Failed to load history.'); });
}

function renderHistory(data) {
  var tbody = document.getElementById('historyBody');
  if (!data || data.length === 0) {
    tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;' +
      'padding:20px;color:var(--text-light);">No assessments found.</td></tr>';
    return;
  }
  tbody.innerHTML = '';
  data.forEach(function(a) {
    var grade = a.quality_result;
    var color = gradeColor(grade);
    var label = gradeLabel(grade);
    var rgb   = a.rgb_result || {};
    var date  = new Date(a.assessed_at).toLocaleDateString('en-GB');
    var pfund = rgb.pfund_mm    ? rgb.pfund_mm + ' mm'   : '--';
    var hue   = rgb.hue         ? rgb.hue + '°'           : '--';
    var usda  = rgb.pfund_grade ? rgb.pfund_grade          : '--';

    tbody.innerHTML +=
      '<tr>' +
        '<td>' + date + '</td>' +
        '<td><b>' + (a.sample_label || '--') + '</b></td>' +
        '<td>' +
          '<div style="display:flex;align-items:center;gap:8px;">' +
            '<div style="width:28px;height:28px;border-radius:8px;' +
                 'background:' + color + ';display:flex;align-items:center;' +
                 'justify-content:center;font-weight:900;font-size:13px;color:#fff;">' +
              grade +
            '</div>' +
            '<span style="font-size:0.78rem;color:' + color + ';font-weight:600;">' +
              label.split('—')[1] ? label.split('—')[1].trim() : label +
            '</span>' +
          '</div>' +
        '</td>' +
        '<td style="font-family:monospace;font-size:0.8rem;">' + pfund + '</td>' +
        '<td style="font-family:monospace;font-size:0.8rem;">' + hue + '</td>' +
        '<td style="font-size:0.8rem;">' + usda + '</td>' +
        '<td style="font-family:monospace;font-size:0.8rem;">' +
          (rgb.rg_ratio || '--') +
        '</td>' +
        '<td>' +
          '<span style="display:inline-flex;align-items:center;' +
               'padding:3px 10px;border-radius:20px;font-weight:700;' +
               'font-size:0.7rem;background:' + color + '15;' +
               'color:' + color + ';border:1px solid ' + color + '30;">' +
            grade +
          '</span>' +
        '</td>' +
      '</tr>';
  });
}

function filterHistory() {
  var search = document.getElementById('historySearch').value.toLowerCase();
  var filter = document.getElementById('historyFilter').value;
  var filtered = allHistory.filter(function(a) {
    var matchSearch = !search ||
      (a.sample_label || '').toLowerCase().includes(search);
    var matchFilter = !filter || a.quality_result === filter;
    return matchSearch && matchFilter;
  });
  renderHistory(filtered);
}

// ── IMAGE PREVIEW ──────────────────────────────────────────────────────
function previewImage(e) {
  var file = e.target.files[0];
  if (!file) return;
  document.getElementById('uploadIcon').textContent  = '✅';
  document.getElementById('uploadTitle').textContent = file.name;
  document.getElementById('uploadSub').textContent   = 'Image ready for analysis';
}

// ── RUN ASSESSMENT ─────────────────────────────────────────────────────
function runAssessment() {
  var file  = document.getElementById('assessFile').files[0];
  var label = document.getElementById('sampleLabel').value.trim() || 'Sample';
  if (!file) { showToast('Please select an image first'); return; }

  document.getElementById('step1').className = 'step done';
  document.getElementById('step1').querySelector('.step-num').textContent = '✓';
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
    var grade = a.quality_result;
    var color = gradeColor(grade);

    // Animate RGB bars
    document.getElementById('rBar').style.width   = (r/255*100) + '%';
    document.getElementById('gBar').style.width   = (g/255*100) + '%';
    document.getElementById('bBar').style.width   = (b/255*100) + '%';
    document.getElementById('avgBar').style.width = Math.min(ratio/2*100, 100) + '%';
    document.getElementById('rVal').textContent   = r;
    document.getElementById('gVal').textContent   = g;
    document.getElementById('bVal').textContent   = b;
    document.getElementById('avgVal').textContent = ratio;

    // Grade badge
    var badge = document.getElementById('resultBadge');
    badge.innerHTML = gradeBadgeHTML(grade);
    badge.className = '';

    // Result table
    document.getElementById('resR').textContent    = r;
    document.getElementById('resG').textContent    = g;
    document.getElementById('resB').textContent    = b;
    document.getElementById('resRG').textContent   = ratio;
    document.getElementById('resDate').textContent =
      new Date(a.assessed_at).toLocaleDateString('en-GB');

    // Description
    document.getElementById('resultDesc').textContent = a.description || '';

    // Show result panel
    var panel = document.getElementById('resultPanel');
    panel.classList.add('show');
    panel.style.borderColor = color;

    // Add grade info to result panel
    var gradeInfo = document.getElementById('gradeInfo');
    if (!gradeInfo) {
      gradeInfo = document.createElement('div');
      gradeInfo.id = 'gradeInfo';
      panel.insertBefore(gradeInfo, panel.firstChild);
    }
    gradeInfo.innerHTML =
      '<div style="display:flex;align-items:center;gap:16px;' +
           'padding:14px;background:' + color + '10;' +
           'border-radius:12px;margin-bottom:14px;' +
           'border:1px solid ' + color + '30;">' +
        '<div style="width:56px;height:56px;border-radius:50%;' +
             'background:' + color + ';display:flex;align-items:center;' +
             'justify-content:center;font-size:24px;font-weight:900;' +
             'color:#fff;flex-shrink:0;box-shadow:0 4px 12px ' + color + '50;">' +
          grade +
        '</div>' +
        '<div>' +
          '<div style="font-size:0.68rem;text-transform:uppercase;' +
               'letter-spacing:0.1em;color:var(--text-light);margin-bottom:4px;">' +
            'Professional Grade' +
          '</div>' +
          '<div style="font-size:1rem;font-weight:700;color:' + color + ';">' +
            gradeLabel(grade) +
          '</div>' +
          '<div style="font-size:0.78rem;color:var(--text-light);margin-top:2px;">' +
            'Pfund: ' + (rgb.pfund_mm||'--') + 'mm &nbsp;|&nbsp; ' +
            'HUE: ' + (rgb.hue||'--') + '° &nbsp;|&nbsp; ' +
            'USDA: ' + (rgb.pfund_grade||'--') +
          '</div>' +
          '<div style="font-size:0.72rem;margin-top:4px;">' +
            '<span style="background:' + color + '15;color:' + color + ';' +
                 'padding:2px 10px;border-radius:10px;font-weight:600;">' +
              'Confidence: ' + (a.confidence||0) + '%' +
            '</span>' +
          '</div>' +
        '</div>' +
      '</div>';

    // Steps
    document.getElementById('step2').className = 'step done';
    document.getElementById('step2').querySelector('.step-num').textContent = '✓';
    document.getElementById('step3').className = 'step done';
    document.getElementById('step3').querySelector('.step-num').textContent = '✓';
    document.getElementById('step4').className = 'step active';

    showToast(gradeLabel(grade));
    loadDashboardStats();

    // QR
    if (a.qr_certificate && a.qr_certificate.qr_image) {
      var qrImg = '<img src="' + a.qr_certificate.qr_image +
                  '" style="width:100%;height:100%;object-fit:contain;"/>';
      document.getElementById('assessQR').innerHTML     = qrImg;
      document.getElementById('qrPreviewBox').innerHTML = qrImg;

      document.getElementById('qrDetailBox').innerHTML =
        '<div style="display:flex;flex-direction:column;gap:10px;">' +
          _qrDetailRow('Sample ID',    a.sample_label || '--') +
          _qrDetailRow('Grade',        gradeLabel(grade)) +
          _qrDetailRow('USDA Class',   (rgb.pfund_grade||'--') +
            ' (' + (rgb.pfund_code||'--') + ')') +
          _qrDetailRow('Pfund Value',  (rgb.pfund_mm||'--') + ' mm') +
          _qrDetailRow('HUE Angle',    (rgb.hue||'--') + '°') +
          _qrDetailRow('Confidence',   (a.confidence||0) + '%') +
          _qrDetailRow('Date',
            new Date(a.assessed_at).toLocaleDateString('en-GB')) +
          _qrDetailRow('Assessor',
            (userData.first_name||userData.username||'--')) +
        '</div>' +
        '<div style="margin-top:14px;padding:10px;' +
             'background:rgba(245,158,11,0.07);border-radius:10px;' +
             'border:1px solid rgba(245,158,11,0.2);' +
             'font-size:0.75rem;color:var(--text-light);line-height:1.5;">' +
          '⚠️ Colour screening only. Lab testing recommended for full certification.' +
        '</div>';

      document.getElementById('step4').className = 'step done';
      document.getElementById('step4').querySelector('.step-num').textContent = '✓';
    }
  })
  .catch(function() { showToast('Error connecting to server.'); });
}

function _qrDetailRow(label, value) {
  return '<div style="display:flex;justify-content:space-between;' +
         'padding:8px 0;border-bottom:1px solid rgba(217,119,6,0.08);">' +
    '<span style="font-size:0.78rem;color:var(--text-light);">' + label + '</span>' +
    '<span style="font-size:0.78rem;font-weight:600;color:var(--comb-dark);">' +
      value + '</span>' +
  '</div>';
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
    var a     = data.assessment;
    var grade = a.quality_result;
    var color = gradeColor(grade);
    var label = gradeLabel(grade);

    document.getElementById('quickBadge').innerHTML = gradeBadgeHTML(grade);
    document.getElementById('quickDesc').textContent = a.recommendation || a.description || '';
    document.getElementById('quickResult').style.display = 'block';
    loadDashboardStats();
    showToast('Result: ' + label);
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
    document.getElementById('pFirstName').value      = data.first_name || '';
    document.getElementById('pLastName').value       = data.last_name  || '';
    document.getElementById('pEmail').value          = data.email      || '';
    document.getElementById('pPhone').value          = data.phone      || '';
    document.getElementById('pRegion').value         = data.region     || '';
    document.getElementById('pUsername').textContent = data.username   || '--';
    document.getElementById('pRole').textContent     = data.role       || '--';
    document.getElementById('pSince').textContent    =
      data.created_at
        ? new Date(data.created_at).toLocaleDateString('en-GB') : '--';
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
    dashboard:  'Welcome back 🐝',
    assess:     'Assess Honey 🔬',
    history:    'Assessment History 📋',
    qr:         'QR Certificates 📲',
    parameters: 'RGB Parameters 📊',
    reports:    'Reports & Analytics 📈',
    profile:    'My Profile 👤',
    settings:   'Settings ⚙️',
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
  setTimeout(function() { t.classList.remove('show'); }, 3500);
}

// ── LOGOUT ─────────────────────────────────────────────────────────────
function logout() {
  localStorage.removeItem('access_token');
  localStorage.removeItem('refresh_token');
  localStorage.removeItem('user');
  window.location.href = '/';
}