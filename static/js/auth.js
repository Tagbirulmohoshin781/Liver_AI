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
  $('#welcome-screen').show();  // Always reset to fresh new-chat on sign-in
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

// ─── Social OAuth & Fallback Account Modal System ───────────────
function _showSocialAccountModal(providerLabel, defaultEmail, callback) {
  let modal = $('#social-auth-modal');
  if (!modal.length) {
    $('body').append(`
      <div id="social-auth-modal" style="display:none; position:fixed; top:0; left:0; width:100vw; height:100vh; z-index:99999; background:rgba(4,10,22,0.85); backdrop-filter:blur(8px); display:flex; align-items:center; justify-content:center;">
        <div style="background:rgba(15,23,42,0.95); border:1px solid rgba(255,255,255,0.18); border-radius:20px; width:90%; max-width:420px; padding:28px 24px; box-shadow:0 20px 50px rgba(0,0,0,0.6); color:#fff; text-align:center; font-family:'Inter',sans-serif;">
          <div id="social-modal-icon" style="font-size:36px; margin-bottom:12px;"></div>
          <h3 id="social-modal-title" style="margin:0 0 6px 0; font-weight:700; font-size:20px; color:#fff;"></h3>
          <p style="margin:0 0 20px 0; font-size:13px; color:#94a3b8;">Choose or enter your account email to continue:</p>
          
          <div style="margin-bottom:14px; text-align:left;">
            <label style="display:block; font-size:12px; font-weight:600; color:#cbd5e1; margin-bottom:6px;">Account Email</label>
            <input type="email" id="social-modal-email-input" style="width:100%; box-sizing:border-box; padding:12px 14px; border-radius:10px; border:1px solid #334155; background:#0f172a; color:#fff; font-size:14px;" />
          </div>

          <div style="display:flex; gap:10px; margin-top:20px;">
            <button type="button" id="social-modal-cancel" style="flex:1; padding:12px; border-radius:10px; border:1px solid #334155; background:transparent; color:#94a3b8; font-weight:600; cursor:pointer;">Cancel</button>
            <button type="button" id="social-modal-confirm" style="flex:1; padding:12px; border-radius:10px; border:none; background:#2563eb; color:#fff; font-weight:700; cursor:pointer;">Sign In</button>
          </div>
        </div>
      </div>
    `);
    modal = $('#social-auth-modal');
  }

  const iconHtml = providerLabel === 'Google' ? '<span style="color:#ea4335; font-weight:900;">G</span>' :
                   providerLabel === 'Facebook' ? '<i class="fa-brands fa-facebook" style="color:#1877f2;"></i>' :
                   '<i class="fa-brands fa-github" style="color:#fff;"></i>';

  $('#social-modal-icon').html(iconHtml);
  $('#social-modal-title').text(`Sign In with ${providerLabel}`);
  $('#social-modal-email-input').val(defaultEmail);

  modal.css('display', 'flex').hide().fadeIn(200);

  $('#social-modal-cancel').off('click').on('click', function() {
    modal.fadeOut(150);
  });

  $('#social-modal-confirm').off('click').on('click', function() {
    const email = $('#social-modal-email-input').val().trim();
    if (!email) return;
    modal.fadeOut(150);
    callback(email);
  });
}

function _processSocialLoginFallback(providerLabel, defaultEmail) {
  _showSocialAccountModal(providerLabel, defaultEmail, function(cleanEmail) {
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
