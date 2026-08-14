/* =============================================================================
   static/js/profile.js — User Profile Panel, Medical Background & Preferences
   ============================================================================= */

function animateCounter(elId, target, duration) {
  const el = document.getElementById(elId);
  if (!el) return;
  const start = 0;
  const step = target / (duration / 16);
  let current = start;
  const timer = setInterval(() => {
    current += step;
    if (current >= target) { current = target; clearInterval(timer); }
    el.textContent = Math.floor(current);
  }, 16);
}

function loadProfilePanel() {
  $.get('/api/me', function (res) {
    if (res.authenticated && res.user) {
      const u = res.user;
      const initial = u.username.charAt(0).toUpperCase();
      $('#profile-display-name').text(u.username);
      $('#profile-display-email').text(u.email);
      $('#profile-avatar-large').text(initial);
      $('#profile-new-name').val(u.username);
      if (u.age) $('#profile-age').val(u.age);
      if (u.gender) $('#profile-gender').val(u.gender);
      if (u.medical_notes) $('#profile-medical-notes').val(u.medical_notes);

      if (u.settings_json) {
        try {
          const s = typeof u.settings_json === 'string' ? JSON.parse(u.settings_json) : u.settings_json;
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
    }
  });

  $.get('/api/user/stats', function (res) {
    if (res.success) {
      const s = res.stats;
      animateCounter('stat-messages', s.total_messages, 600);
      animateCounter('stat-sessions', s.total_sessions, 600);

      if (s.member_since) {
        const joined = new Date(s.member_since);
        const now = new Date();
        const days = Math.max(1, Math.floor((now - joined) / 86400000));
        animateCounter('stat-days', days, 600);
      }
    }
  });

  setFeedback('name-feedback', '', '');
  setFeedback('medical-feedback', '', '');
  setFeedback('password-feedback', '', '');
  $('#profile-old-password, #profile-new-password, #profile-confirm-password').val('');
}

function setFeedback(elId, msg, type) {
  const el = $('#' + elId);
  el.text(msg).removeClass('success error');
  if (type) el.addClass(type);
}

function saveMedicalProfile() {
  const age = $('#profile-age').val();
  const gender = $('#profile-gender').val();
  const notes = $('#profile-medical-notes').val() ? $('#profile-medical-notes').val().trim() : '';

  $('#btn-save-medical').prop('disabled', true).html('<i class="fa-solid fa-spinner fa-spin"></i> Saving…');
  $.ajax({
    url: '/api/user/medical-profile',
    type: 'POST',
    contentType: 'application/json',
    data: JSON.stringify({ age: age, gender: gender, medical_notes: notes }),
    success: function (res) {
      if (res.success) {
        setFeedback('medical-feedback', '✓ ' + res.message, 'success');
        showToast('Medical profile updated successfully!', 'success');
      } else {
        setFeedback('medical-feedback', res.message || 'Save failed.', 'error');
        showToast(res.message || 'Save failed.', 'error');
      }
    },
    error: function (xhr) {
      const msg = (xhr.responseJSON && xhr.responseJSON.message) ? xhr.responseJSON.message : 'Save failed.';
      setFeedback('medical-feedback', msg, 'error');
      showToast(msg, 'error');
    },
    complete: function () {
      $('#btn-save-medical').prop('disabled', false).html('<i class="fa-solid fa-heart-pulse"></i> Save Medical Profile');
    }
  });
}

function saveDisplayName() {
  const name = $('#profile-new-name').val().trim();
  if (!name) { setFeedback('name-feedback', 'Name cannot be empty.', 'error'); return; }
  $('#btn-save-name').prop('disabled', true).html('<i class="fa-solid fa-spinner fa-spin"></i> Saving…');
  $.ajax({
    url: '/api/user/update-name',
    type: 'POST',
    contentType: 'application/json',
    data: JSON.stringify({ username: name }),
    success: function (res) {
      if (res.success) {
        const initial = name.charAt(0).toUpperCase();
        $('#sidebar-username').text(name);
        $('#sidebar-avatar').text(initial);
        $('#profile-display-name').text(name);
        $('#profile-avatar-large').text(initial);
        setFeedback('name-feedback', '✓ ' + res.message, 'success');
        showToast('Display name updated!', 'success');
      } else {
        setFeedback('name-feedback', res.message, 'error');
      }
    },
    error: function (xhr) {
      const msg = xhr.responseJSON ? xhr.responseJSON.message : 'Update failed.';
      setFeedback('name-feedback', msg, 'error');
    },
    complete: function () {
      $('#btn-save-name').prop('disabled', false).html('<i class="fa-solid fa-floppy-disk"></i> Save');
    }
  });
}

function savePassword() {
  const oldPw = $('#profile-old-password').val();
  const newPw = $('#profile-new-password').val();
  const confPw = $('#profile-confirm-password').val();

  if (!oldPw || !newPw || !confPw) {
    setFeedback('password-feedback', 'Please fill in all password fields.', 'error'); return;
  }
  if (newPw !== confPw) {
    setFeedback('password-feedback', 'New passwords do not match.', 'error'); return;
  }
  if (newPw.length < 6) {
    setFeedback('password-feedback', 'Password must be at least 6 characters.', 'error'); return;
  }

  $('#btn-save-password').prop('disabled', true).html('<i class="fa-solid fa-spinner fa-spin"></i> Updating…');
  $.ajax({
    url: '/api/user/update-password',
    type: 'POST',
    contentType: 'application/json',
    data: JSON.stringify({ old_password: oldPw, new_password: newPw }),
    success: function (res) {
      if (res.success) {
        setFeedback('password-feedback', '✓ ' + res.message, 'success');
        $('#profile-old-password, #profile-new-password, #profile-confirm-password').val('');
        showToast('Password updated successfully!', 'success');
      } else {
        setFeedback('password-feedback', res.message, 'error');
      }
    },
    error: function (xhr) {
      const msg = xhr.responseJSON ? xhr.responseJSON.message : 'Password update failed.';
      setFeedback('password-feedback', msg, 'error');
    },
    complete: function () {
      $('#btn-save-password').prop('disabled', false).html('<i class="fa-solid fa-lock"></i> Update Password');
    }
  });
}
