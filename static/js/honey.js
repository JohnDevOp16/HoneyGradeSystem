// ── API BASE URL ──────────────────────────────────────────────────────
const API = 'http://127.0.0.1:8000/api';

// ── TOKEN HELPERS ─────────────────────────────────────────────────────
const getToken  = ()        => localStorage.getItem('access_token');
const setTokens = (a, r)    => {
  localStorage.setItem('access_token',  a);
  localStorage.setItem('refresh_token', r);
};
const clearTokens = ()      => {
  localStorage.removeItem('access_token');
  localStorage.removeItem('refresh_token');
};

// ── AUTH HEADERS ──────────────────────────────────────────────────────
const authHeaders = () => ({
  'Authorization': `Bearer ${getToken()}`,
  'Content-Type':  'application/json',
});

// ── TOAST ─────────────────────────────────────────────────────────────
function showToast(msg) {
  let t = document.getElementById('toast');
  if (!t) {
    t = document.createElement('div');
    t.id = 'toast';
    t.className = 'toast';
    document.body.appendChild(t);
  }
  t.textContent = msg;
  t.classList.add('show');
  setTimeout(() => t.classList.remove('show'), 3200);
}

// ── REDIRECT IF NOT LOGGED IN ─────────────────────────────────────────
function requireAuth() {
  if (!getToken()) {
    window.location.href = '/';
  }
}

// ── LOGOUT ────────────────────────────────────────────────────────────
function logout() {
  clearTokens();
  window.location.href = '/';
}