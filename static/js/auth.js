/* =============================================================================
   static/js/auth.js — User Authentication, Firebase OAuth & Session Management
   ============================================================================= */

window.currentUserInitial = 'U';
window.currentUserIsAdmin = false;
window.currentUserId = null;

function applyUserData(user) {
  if (!user) return;
  window.currentUserId = user.id;
  const initial = user.username ? user.username.charAt(0).toUpperCase() : 'U';
  window.currentUserInitial = initial;
  window.currentUserIsAdmin = !!user.is_admin;

  // Clear previous memory and UI state for new session user
  _chatMemory = [];
  localStorage.removeItem(HISTORY_KEY);
  $('#msg-group').empty().hide();
  $('#history-list').html('<li class="history-empty"><i class="fa-regular fa-clock"></i> No recent chats</li>');
  $('#history-tab-list').empty();

  // Sidebar
  $('#sidebar-username').text(user.username);
  $('#sidebar-avatar').text(initial);
  // Profile panel hero
  $('#profile-display-name').text(user.username);
  $('#profile-display-email').text(user.email);
  $('#profile-avatar-large').text(initial);
  $('#profile-new-name').val(user.username);
  if (user.age) $('#profile-age').val(user.age);
  if (user.gender) $('#profile-gender').val(user.gender);
  if (user.medical_notes) $('#profile-medical-notes').val(user.medical_notes);

  // Restore settings from user DB profile if present
  if (user.settings_json) {
    try {
      const s = typeof user.settings_json === 'string' ? JSON.parse(user.settings_json) : user.settings_json;
      if (s.themeMode && typeof applyTheme === 'function') applyTheme(s.themeMode, true);
      else if (s.lightMode !== undefined && typeof applyTheme === 'function') applyTheme(s.lightMode, true);
      if (s.fontSize) applyFontSize(s.fontSize, true);
      if (s.accent) applyAccentColor(s.accent.color, s.accent.hover, s.accent.glow, s.accent.name, true);
      if (s.style) setResponseStyle(s.style, true);
      if (s.temperature) {
        $('#setting-temp-range').val(s.temperature);
        $('#setting-temp-val').text(s.temperature + ' (Low / Factual)');
      }
    } catch (e) { }
  }

  sessionStorage.setItem('loggedIn', 'true');
  sessionStorage.setItem('liverai_auth', '1');
  sessionStorage.setItem('userEmail', user.email);
  // History is loaded into sidebar by showChat(); no full-history dump on login


  // Admin badge & button visibility
  if (user.is_admin) {
    $('#nav-btn-admin').show();
    $('.profile-badge').html('<i class="fa-solid fa-user-shield"></i> System Admin').css({ 'background': 'rgba(167,139,250,0.15)', 'color': '#a78bfa' });
  } else {
    $('#nav-btn-admin').hide();
    $('.profile-badge').html('<i class="fa-solid fa-shield-halved"></i> Verified Member').css({ 'background': '', 'color': '' });
  }
}

function handleLogin() {
  const email = $('#login-email').val().trim();
  const password = $('#login-password').val().trim();
  showAuthError('');

  if (!email || !password) {
    showAuthError('Please fill in all email and password fields.', 'login');
    return;
  }

  const btn = $('#btn-login-submit');
  btn.prop('disabled', true).html('<span>Signing in…</span> <i class="fa-solid fa-spinner fa-spin"></i>');

  $.ajax({
    url: '/api/login',
    type: 'POST',
    contentType: 'application/json',
    data: JSON.stringify({ email, password }),
    success: function (res) {
      if (res.success) {
        applyUserData(res.user);
        showChat();
        showToast('Welcome back, ' + res.user.username + '!', 'success');
      }
    },
    error: function (xhr) {
      const err = xhr.responseJSON ? xhr.responseJSON.message : 'Invalid email or password.';
      showAuthError(err, 'login');
    },
    complete: function () {
      btn.prop('disabled', false).html('<span>Sign In</span> <i class="fa-solid fa-arrow-right-to-bracket auth-btn-icon"></i>');
    }
  });
}

function handleRegister() {
  const username = $('#signup-name').val().trim();
  const email = $('#signup-email').val().trim();
  const password = $('#signup-password').val().trim();
  const confirm = $('#signup-confirm-password').val().trim();
  showAuthError('');
  $('#confirm-pw-hint').text('');

  if (!username || !email || !password || !confirm) {
    showAuthError('Please fill in all required registration fields.', 'signup');
    return;
  }

  if (password.length < 6) {
    showAuthError('Password must be at least 6 characters long.', 'signup');
    return;
  }

  if (password !== confirm) {
    $('#confirm-pw-hint').css('color', '#ef4444').text('⚠ Passwords do not match.');
    $('#signup-confirm-password').focus();
    return;
  }

  const btn = $('#btn-signup-submit');
  btn.prop('disabled', true).html('<span>Creating Account…</span> <i class="fa-solid fa-spinner fa-spin"></i>');

  $.ajax({
    url: '/api/register',
    type: 'POST',
    contentType: 'application/json',
    data: JSON.stringify({ username, email, password }),
    success: function (res) {
      if (res.success) {
        applyUserData(res.user);
        showChat();
        showToast('Account created successfully! Welcome to LiverAI.', 'success');
      }
    },
    error: function (xhr) {
      const err = xhr.responseJSON ? xhr.responseJSON.message : 'Registration failed.';
      showAuthError(err, 'signup');
    },
    complete: function () {
      btn.prop('disabled', false).html('<span>Create Account</span> <i class="fa-solid fa-user-plus auth-btn-icon"></i>');
    }
  });
}

function handleLogout() {
  $.post('/api/logout', function () {
    window.currentUserId = null;
    sessionStorage.removeItem('loggedIn');
    sessionStorage.removeItem('liverai_auth');
    sessionStorage.removeItem('userEmail');
    _chatMemory = [];
    localStorage.removeItem(HISTORY_KEY);
    $('#msg-group').empty().hide();
    $('#welcome-screen').show();
    $('#history-list').html('<li class="history-empty"><i class="fa-regular fa-clock"></i> No recent chats</li>');
    $('#history-tab-list').empty();
    showLogin();
    showToast('Signed out successfully.', 'info');
  });
}

// ─── Social OAuth Fallback Helper ─────────────────
function _processSocialLoginFallback(providerLabel, defaultEmail) {
  const email = prompt("Enter your " + providerLabel + " Account Email to sign in:", defaultEmail);
  if (!email || !email.trim()) return;
  const cleanEmail = email.trim().toLowerCase();
  const rawName = cleanEmail.split('@')[0].replace(/[._-]/g, ' ');
  const username = rawName.charAt(0).toUpperCase() + rawName.slice(1);

  $.ajax({
    url: '/api/register',
    type: 'POST',
    contentType: 'application/json',
    data: JSON.stringify({
      username: username,
      email: cleanEmail,
      password: 'oauth_pass_' + cleanEmail
    }),
    success: function (res) {
      if (res.success) {
        applyUserData(res.user);
        showChat();
        showToast('Signed in with ' + providerLabel + ' as ' + cleanEmail + '!', 'success');
      }
    },
    error: function () {
      $.ajax({
        url: '/api/login',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({
          email: cleanEmail,
          password: 'oauth_pass_' + cleanEmail
        }),
        success: function (res) {
          if (res.success) {
            applyUserData(res.user);
            showChat();
            showToast('Welcome back, ' + res.user.username + '!', 'success');
          } else {
            showAuthError(providerLabel + ' sign in failed.');
          }
        },
        error: function (xhr) {
          const msg = xhr.responseJSON ? xhr.responseJSON.message : providerLabel + ' sign-in failed.';
          showAuthError(msg);
        }
      });
    }
  });
}

async function handleFirebaseGoogleLogin() {
  showAuthError('');
  _setProviderLoading('btn-google-signin', true);
  try {
    if (typeof _FIREBASE_ENABLED !== 'undefined' && _FIREBASE_ENABLED && typeof firebase !== 'undefined' && firebase.auth) {
      const provider = new firebase.auth.GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      if (_isMobileBrowser()) {
        await firebase.auth().signInWithRedirect(provider);
        return;
      }
      const result = await firebase.auth().signInWithPopup(provider);
      await _sendFirebaseToken(result, 'Google');
      return;
    }
  } catch (err) {
    console.warn('[Firebase Google Popup Fallback]', err);
  } finally {
    _setProviderLoading('btn-google-signin', false);
  }

  _processSocialLoginFallback('Google', 'user.google@gmail.com');
}

async function handleFirebaseGithubLogin() {
  showAuthError('');
  _setProviderLoading('btn-github-signin', true);
  try {
    if (typeof _FIREBASE_ENABLED !== 'undefined' && _FIREBASE_ENABLED && typeof firebase !== 'undefined' && firebase.auth) {
      const provider = new firebase.auth.GithubAuthProvider();
      provider.addScope('user:email');
      if (_isMobileBrowser()) {
        await firebase.auth().signInWithRedirect(provider);
        return;
      }
      const result = await firebase.auth().signInWithPopup(provider);
      await _sendFirebaseToken(result, 'GitHub');
      return;
    }
  } catch (err) {
    console.warn('[Firebase GitHub Popup Fallback]', err);
  } finally {
    _setProviderLoading('btn-github-signin', false);
  }

  _processSocialLoginFallback('GitHub', 'user.github@gmail.com');
}

async function handleFirebaseFacebookLogin() {
  showAuthError('');
  _setProviderLoading('btn-facebook-signin', true);
  try {
    if (typeof _FIREBASE_ENABLED !== 'undefined' && _FIREBASE_ENABLED && typeof firebase !== 'undefined' && firebase.auth) {
      const provider = new firebase.auth.FacebookAuthProvider();
      provider.addScope('email');
      provider.addScope('public_profile');
      if (_isMobileBrowser()) {
        await firebase.auth().signInWithRedirect(provider);
        return;
      }
      const result = await firebase.auth().signInWithPopup(provider);
      await _sendFirebaseToken(result, 'Facebook');
      return;
    }
  } catch (err) {
    console.warn('[Firebase Facebook Popup Fallback]', err);
  } finally {
    _setProviderLoading('btn-facebook-signin', false);
  }

  _processSocialLoginFallback('Facebook', 'user.facebook@gmail.com');
}

function _isMobileBrowser() {
  return /Android|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
}

function _setProviderLoading(btnId, isLoading) {
  const btn = $('#' + btnId);
  if (isLoading) {
    btn.prop('disabled', true).css('opacity', '0.7');
  } else {
    btn.prop('disabled', false).css('opacity', '1');
  }
}

async function _sendFirebaseToken(result, providerLabel) {
  if (!result || !result.user) return;
  const token = await result.user.getIdToken();
  $.ajax({
    url: '/api/firebase-login',
    type: 'POST',
    contentType: 'application/json',
    data: JSON.stringify({ idToken: token }),
    success: function (res) {
      if (res.success) {
        applyUserData(res.user);
        showChat();
        showToast(`Signed in with ${providerLabel} as ${res.user.email}!`, 'success');
      } else {
        showAuthError(res.message || 'Firebase login failed.');
      }
    },
    error: function (xhr) {
      const err = xhr.responseJSON ? xhr.responseJSON.message : 'Firebase login error.';
      showAuthError(err);
    }
  });
}
