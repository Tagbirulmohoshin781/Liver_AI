/* =============================================================================
   static/js/admin.js — Admin Dashboard Controller, Message Logs & User Management
   ============================================================================= */

var _adminUsersCache = window._adminUsersCache || [];
var _currentEditingUserId = null;
var _currentResetPasswordUserId = null;

function switchAdminSubTab(subTab) {
  $('.admin-tab-btn').removeClass('active');
  $('#admin-subtab-btn-' + subTab).addClass('active');

  $('.admin-subtab-view').hide();
  $('#admin-subtab-view-' + subTab).show();

  if (subTab === 'diagnostics') {
    loadSystemDiagnostics();
  } else if (subTab === 'audit') {
    loadAllSystemMessages();
  } else if (subTab === 'users') {
    loadAdminUsers();
  }
}
window.switchAdminSubTab = switchAdminSubTab;

function updateAdminStats() {
  $.get('/api/admin/stats', function (res) {
    if (res.success && res.stats) {
      const s = res.stats;
      $('#admin-stat-total-users').text(s.total_users);
      $('#admin-stat-total-msgs').text(s.total_messages);
      $('#admin-stat-active-users').text(s.active_users);
      $('#admin-stat-new-today').text(s.new_users_today);
      $('#admin-stat-msgs-today').text(s.messages_today);
      const now = new Date();
      $('#admin-stats-updated').text(now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }));
    }
  });
}

function loadSystemDiagnostics() {
  $('#admin-diag-status-body').html(`
    <div style="text-align:center; padding:2rem; color:var(--text-muted)">
      <i class="fa-solid fa-spinner fa-spin" style="margin-right:.5rem"></i> Loading live system telemetry...
    </div>
  `);

  $.get('/api/admin/system/status', function (res) {
    if (res.success) {
      const m = res.metrics || {};
      const v = res.vision || {};
      const p = res.pipeline || {};

      let html = `
        <div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(240px, 1fr)); gap:1rem; margin-bottom:1.5rem">
          <div class="stat-card" style="padding:1.2rem; text-align:left; align-items:flex-start">
            <div style="display:flex; justify-content:space-between; width:100%; align-items:center; margin-bottom:.5rem">
              <span style="font-size:.78rem; font-weight:700; color:var(--text-muted); text-transform:uppercase">Database Engine</span>
              <span class="cap-status active">${escapeHtml(m.db_type || 'SQLite')}</span>
            </div>
            <div style="font-size:1.4rem; font-weight:700; color:var(--text-primary); margin-bottom:.3rem">${m.db_size_mb || 0} MB</div>
            <div style="font-size:.75rem; color:var(--text-secondary)">Integrity Check: <strong style="color:#34d399">${escapeHtml(m.integrity || 'OK')}</strong></div>
          </div>

          <div class="stat-card" style="padding:1.2rem; text-align:left; align-items:flex-start">
            <div style="display:flex; justify-content:space-between; width:100%; align-items:center; margin-bottom:.5rem">
              <span style="font-size:.78rem; font-weight:700; color:var(--text-muted); text-transform:uppercase">Histology AI Vision</span>
              <span class="cap-status active">PyTorch</span>
            </div>
            <div style="font-size:1.1rem; font-weight:700; color:#a78bfa; margin-bottom:.3rem">EfficientNet-B0</div>
            <div style="font-size:.75rem; color:var(--text-secondary)">Biomarker Engine: <strong style="color:var(--text-primary)">4 Pathology Targets</strong></div>
          </div>

          <div class="stat-card" style="padding:1.2rem; text-align:left; align-items:flex-start">
            <div style="display:flex; justify-content:space-between; width:100%; align-items:center; margin-bottom:.5rem">
              <span style="font-size:.78rem; font-weight:700; color:var(--text-muted); text-transform:uppercase">LLM & Knowledge RAG</span>
              <span class="cap-status active">Active</span>
            </div>
            <div style="font-size:1.1rem; font-weight:700; color:#38bdf8; margin-bottom:.3rem">Gemini 2.5 Flash</div>
            <div style="font-size:.75rem; color:var(--text-secondary)">Vector Store: <strong style="color:var(--text-primary)">Pinecone Vector Index</strong></div>
          </div>
        </div>

        <div style="background:var(--bg-primary); border:1px solid var(--border); border-radius:14px; padding:1.25rem;">
          <h4 style="font-size:.9rem; font-weight:700; color:var(--text-primary); margin-bottom:.75rem">
            <i class="fa-solid fa-screwdriver-wrench" style="color:#fbbf24; margin-right:6px"></i> Database & System Maintenance Actions
          </h4>
          <div style="display:flex; flex-wrap:wrap; gap:.75rem">
            <button type="button" class="btn-danger-outline" onclick="openPurgeHistoryModal()">
              <i class="fa-solid fa-trash-can"></i> Purge System Chat Logs
            </button>
            <button type="button" class="topbar-btn" onclick="updateAdminStats(); showToast('System telemetry refreshed!','success');">
              <i class="fa-solid fa-rotate"></i> Sync Diagnostics
            </button>
          </div>
        </div>
      `;
      $('#admin-diag-status-body').html(html);
    }
  });
}
window.loadSystemDiagnostics = loadSystemDiagnostics;

function loadAllSystemMessages() {
  $('#admin-msg-count-label').text('Fetching messages...');
  $('#admin-messages-stream-body').html(`
    <div style="text-align:center; padding:2rem; color:var(--text-muted)">
      <i class="fa-solid fa-spinner fa-spin" style="margin-right:.5rem"></i> Loading all user messages...
    </div>
  `);

  $.get('/api/admin/all-history', function (res) {
    if (res.success && res.history) {
      const body = $('#admin-messages-stream-body').empty();
      const msgs = res.history;

      $('#admin-msg-count-label').text(msgs.length + ' Total System Messages Logged');

      if (!msgs.length) {
        body.html('<div style="text-align:center; padding:2rem; color:var(--text-muted)"><i class="fa-regular fa-comments"></i> No user chat messages recorded yet.</div>');
        return;
      }

      msgs.forEach(item => {
        const isUser = item.role === 'user';
        const bg = isUser ? 'var(--bg-secondary)' : 'rgba(167,139,250,0.06)';
        const border = isUser ? 'var(--border)' : 'rgba(167,139,250,0.22)';
        const timeStr = item.created_at ? new Date(item.created_at).toLocaleString() : '';
        const userTag = isUser
          ? `<strong style="color:var(--text-primary)"><i class="fa-solid fa-user" style="color:var(--accent); margin-right:4px"></i>${escapeHtml(item.username)} (${escapeHtml(item.email)})</strong>`
          : `<strong style="color:#a78bfa"><i class="fa-solid fa-robot" style="margin-right:4px"></i>LiverAI Assistant → ${escapeHtml(item.username)}</strong>`;

        const formattedContent = isUser
          ? escapeHtml(item.message).replace(/\n/g, '<br/>')
          : (typeof renderMarkdown === 'function' ? renderMarkdown(item.message) : escapeHtml(item.message).replace(/\n/g, '<br/>'));

        body.append(`
          <div style="background:${bg}; border:1px solid ${border}; padding:.85rem 1.1rem; border-radius:10px; font-size:.85rem; position:relative; display:flex; flex-direction:column; gap:.4rem;" id="admin-msg-card-${item.id}">
            <div style="display:flex; justify-content:space-between; align-items:center; font-size:.75rem; color:var(--text-muted); padding-bottom:.35rem; border-bottom:1px dashed var(--border)">
              <span>${userTag}</span>
              <div style="display:flex; align-items:center; gap:.6rem">
                <span style="font-size:.7rem"><i class="fa-regular fa-clock" style="margin-right:3px"></i>${timeStr}</span>
                <button type="button" onclick="deleteAdminMessage(${item.id})" title="Delete message" style="background:transparent; border:none; color:var(--danger); cursor:pointer; font-size:.75rem; padding:2px">
                  <i class="fa-solid fa-trash-can"></i>
                </button>
              </div>
            </div>
            <div class="markdown-body" style="color:var(--text-primary); line-height:1.55; font-size:.84rem; word-break:break-word;">${formattedContent}</div>
          </div>
        `);
      });
    } else {
      $('#admin-msg-count-label').text('Error');
      $('#admin-messages-stream-body').html('<div style="text-align:center; padding:2rem; color:var(--danger)">Failed to load messages log.</div>');
    }
  }).fail(function () {
    $('#admin-msg-count-label').text('Error');
    $('#admin-messages-stream-body').html('<div style="text-align:center; padding:2rem; color:var(--danger)">Server error while loading system messages.</div>');
  });
}
window.loadAllSystemMessages = loadAllSystemMessages;

function deleteAdminMessage(mid) {
  if (!confirm('Are you sure you want to delete this message record?')) return;
  $.ajax({
    url: `/api/admin/message/${mid}`,
    type: 'DELETE',
    success: function (res) {
      if (res.success) {
        $(`#admin-msg-card-${mid}`).fadeOut(250, function () { $(this).remove(); });
        showToast('Message deleted.', 'success');
        updateAdminStats();
      } else {
        showToast(res.message || 'Failed to delete message.', 'error');
      }
    }
  });
}
window.deleteAdminMessage = deleteAdminMessage;

function loadAdminUsers() {
  if (!window.currentUserIsAdmin) {
    showToast('Access denied: Admin permissions required.', 'error');
    switchTab('chat');
    return;
  }

  updateAdminStats();

  $('#admin-users-tbody').html(`
      <tr>
        <td colspan="6" style="padding:2rem; text-align:center; color:var(--text-muted)">
          <i class="fa-solid fa-spinner fa-spin" style="margin-right:.5rem"></i> Fetching user database...
        </td>
      </tr>
    `);

  $.get('/api/admin/users', function (res) {
    if (res.success && res.users) {
      _adminUsersCache = res.users;
      $('#admin-user-count-label').text(`${res.users.length} Users Total`);
      renderAdminUserList(res.users);
    } else {
      showToast('Failed to load admin user list.', 'error');
    }
  });
}
window.loadAdminUsers = loadAdminUsers;

function renderAdminUserList(users) {
  const tbody = $('#admin-users-tbody').empty();
  if (!users.length) {
    tbody.html('<tr><td colspan="6" style="padding:2rem; text-align:center; color:var(--text-muted)">No users found.</td></tr>');
    return;
  }

  users.forEach(u => {
    const isMe = u.id === window.currentUserId;
    const initial = u.username ? u.username.charAt(0).toUpperCase() : 'U';
    const joined = u.created_at ? new Date(u.created_at).toLocaleDateString() : 'N/A';
    const roleBadge = u.is_admin
      ? `<span style="background:rgba(167,139,250,0.15); color:#a78bfa; padding:2px 8px; border-radius:12px; font-size:.75rem; font-weight:600"><i class="fa-solid fa-user-shield"></i> Admin</span>`
      : `<span style="background:rgba(16,163,127,0.12); color:var(--accent); padding:2px 8px; border-radius:12px; font-size:.75rem; font-weight:600">User</span>`;

    const meTag = isMe ? `<span style="font-size:.7rem; color:var(--accent); margin-left:4px">(You)</span>` : '';

    const row = `
        <tr data-user-id="${u.id}">
          <td style="padding:.75rem 1rem; border-bottom:1px solid var(--border);">
            <div style="display:flex; align-items:center; gap:.6rem;">
              <div style="width:30px; height:30px; border-radius:50%; background:var(--accent); color:#fff; display:flex; align-items:center; justify-content:center; font-size:.75rem; font-weight:700;">${initial}</div>
              <div>
                <strong style="color:var(--text-primary); font-size:.875rem;">${escapeHtml(u.username)}</strong>${meTag}
                <div style="font-size:.72rem; color:var(--text-muted)">ID: #${u.id}</div>
              </div>
            </div>
          </td>
          <td style="padding:.75rem 1rem; border-bottom:1px solid var(--border); color:var(--text-secondary); font-size:.82rem;">${escapeHtml(u.email)}</td>
          <td style="padding:.75rem 1rem; border-bottom:1px solid var(--border); font-size:.82rem;">
            ${roleBadge}
            ${!isMe ? `
              <button type="button" onclick="toggleUserAdminRole(${u.id}, ${!!u.is_admin})" title="Change Role" style="background:transparent; border:none; color:var(--text-muted); cursor:pointer; font-size:.75rem; margin-left:4px">
                <i class="fa-solid fa-arrows-rotate"></i>
              </button>` : ''}
          </td>
          <td style="padding:.75rem 1rem; border-bottom:1px solid var(--border); color:var(--text-muted); font-size:.82rem;">${joined}</td>
          <td style="padding:.75rem 1rem; border-bottom:1px solid var(--border); color:var(--text-muted); font-size:.82rem; text-align:center;">
            <span style="background:var(--bg-hover); padding:2px 8px; border-radius:10px; font-weight:600">${u.message_count || 0}</span>
          </td>
          <td style="padding:.75rem 1rem; border-bottom:1px solid var(--border); text-align:right;">
            <div style="display:flex; gap:.4rem; justify-content:flex-end;">
              <button class="topbar-btn" onclick="openEditUserModal(${u.id})" title="Edit User Details" style="padding:4px 8px; font-size:.75rem;">
                <i class="fa-solid fa-user-pen"></i> Edit
              </button>
              <button class="topbar-btn" onclick="openResetPasswordModal(${u.id}, '${escapeHtml(u.username)}')" title="Reset Password" style="padding:4px 8px; font-size:.75rem;">
                <i class="fa-solid fa-key"></i> Key
              </button>
              <button class="topbar-btn" onclick="viewUserHistory(${u.id}, '${escapeHtml(u.username)}')" title="View chat logs" style="padding:4px 8px; font-size:.75rem;">
                <i class="fa-solid fa-eye"></i> Log
              </button>
              <button class="topbar-btn" onclick="clearUserHistoryByAdmin(${u.id}, '${escapeHtml(u.username)}')" title="Clear User History" style="padding:4px 8px; font-size:.75rem; color:#f59e0b">
                <i class="fa-solid fa-broom"></i>
              </button>
              ${!isMe ? `
              <button class="btn-danger-outline" onclick="deleteUserByAdmin(${u.id}, '${escapeHtml(u.username)}')" title="Delete account" style="padding:4px 8px; font-size:.75rem;">
                <i class="fa-solid fa-trash"></i>
              </button>` : ''}
            </div>
          </td>
        </tr>
      `;
    tbody.append(row);
  });
}
window.renderAdminUserList = renderAdminUserList;

function filterAdminUserList() {
  const query = $('#admin-user-search').val().toLowerCase().trim();
  if (!query) {
    renderAdminUserList(_adminUsersCache);
    return;
  }
  const filtered = _adminUsersCache.filter(u =>
    (u.username && u.username.toLowerCase().includes(query)) ||
    (u.email && u.email.toLowerCase().includes(query))
  );
  renderAdminUserList(filtered);
}
window.filterAdminUserList = filterAdminUserList;

function openEditUserModal(uid) {
  _currentEditingUserId = uid;
  $.get(`/api/admin/user/${uid}/profile`, function (res) {
    if (res.success && res.user) {
      const u = res.user;
      $('#admin-edit-username').val(u.username || '');
      $('#admin-edit-email').val(u.email || '');
      $('#admin-edit-age').val(u.age || '');
      $('#admin-edit-gender').val(u.gender || '');
      $('#admin-edit-notes').val(u.medical_notes || '');
      $('#admin-edit-isadmin').prop('checked', !!u.is_admin);
      $('#admin-edit-feedback').text('');
      $('#admin-edit-user-modal').addClass('open').css('display', 'flex').show();
    } else {
      showToast('Could not fetch user details: ' + (res.message || 'Error'), 'error');
    }
  }).fail(function(xhr) {
    showToast('Failed to load user profile: ' + (xhr.responseJSON?.message || 'Access error'), 'error');
  });
}
window.openEditUserModal = openEditUserModal;

function closeEditUserModal() {
  $('#admin-edit-user-modal').removeClass('open').hide();
  _currentEditingUserId = null;
}
window.closeEditUserModal = closeEditUserModal;

function submitAdminEditUser() {
  if (!_currentEditingUserId) return;
  const username = $('#admin-edit-username').val().trim();
  const email = $('#admin-edit-email').val().trim();
  const age = $('#admin-edit-age').val();
  const gender = $('#admin-edit-gender').val();
  const medical_notes = $('#admin-edit-notes').val().trim();
  const is_admin = $('#admin-edit-isadmin').is(':checked');

  if (!username || !email) {
    $('#admin-edit-feedback').css('color', 'var(--danger)').text('Username and email are required.');
    return;
  }

  $.ajax({
    url: `/api/admin/user/${_currentEditingUserId}/update`,
    type: 'POST',
    contentType: 'application/json',
    data: JSON.stringify({ username, email, age, gender, medical_notes, is_admin }),
    success: function (res) {
      if (res.success) {
        showToast('User profile updated successfully!', 'success');
        closeEditUserModal();
        loadAdminUsers();
      } else {
        $('#admin-edit-feedback').css('color', 'var(--danger)').text(res.message || 'Update failed.');
      }
    },
    error: function(xhr) {
      $('#admin-edit-feedback').css('color', 'var(--danger)').text(xhr.responseJSON?.message || 'Server error.');
    }
  });
}
window.submitAdminEditUser = submitAdminEditUser;

function openResetPasswordModal(uid, username) {
  _currentResetPasswordUserId = uid;
  $('#admin-reset-pw-target').text(username);
  $('#admin-reset-new-pw').val('');
  $('#admin-reset-feedback').text('');
  $('#admin-reset-pw-modal').addClass('open').css('display', 'flex').show();
}
window.openResetPasswordModal = openResetPasswordModal;

function closeResetPasswordModal() {
  $('#admin-reset-pw-modal').removeClass('open').hide();
  _currentResetPasswordUserId = null;
}
window.closeResetPasswordModal = closeResetPasswordModal;

function submitAdminResetPassword() {
  if (!_currentResetPasswordUserId) return;
  const new_password = $('#admin-reset-new-pw').val().trim();
  if (new_password.length < 6) {
    $('#admin-reset-feedback').css('color', 'var(--danger)').text('Password must be at least 6 characters.');
    return;
  }

  $.ajax({
    url: `/api/admin/user/${_currentResetPasswordUserId}/reset-password`,
    type: 'POST',
    contentType: 'application/json',
    data: JSON.stringify({ new_password }),
    success: function (res) {
      if (res.success) {
        showToast('User password reset successfully!', 'success');
        closeResetPasswordModal();
      } else {
        $('#admin-reset-feedback').css('color', 'var(--danger)').text(res.message || 'Failed to reset password.');
      }
    },
    error: function(xhr) {
      $('#admin-reset-feedback').css('color', 'var(--danger)').text(xhr.responseJSON?.message || 'Server error.');
    }
  });
}
window.submitAdminResetPassword = submitAdminResetPassword;

function toggleUserAdminRole(uid, currentIsAdmin) {
  const newRole = currentIsAdmin ? 'Standard User' : 'Admin';
  if (!confirm(`Change this user's role to ${newRole}?`)) return;

  $.ajax({
    url: `/api/admin/user/${uid}/toggle-role`,
    type: 'POST',
    success: function (res) {
      if (res.success) {
        showToast(res.message, 'success');
        loadAdminUsers();
      } else {
        showToast(res.message || 'Role change failed.', 'error');
      }
    },
    error: function(xhr) {
      showToast(xhr.responseJSON?.message || 'Failed to toggle role.', 'error');
    }
  });
}
window.toggleUserAdminRole = toggleUserAdminRole;

function clearUserHistoryByAdmin(uid, username) {
  if (!confirm(`Permanently clear all chat history records for user "${username}"?`)) return;
  $.ajax({
    url: `/api/admin/user/${uid}/clear-history`,
    type: 'DELETE',
    success: function (res) {
      if (res.success) {
        showToast(`Chat history for ${username} cleared.`, 'success');
        loadAdminUsers();
      } else {
        showToast(res.message || 'Failed to clear history.', 'error');
      }
    },
    error: function(xhr) {
      showToast(xhr.responseJSON?.message || 'Failed to clear history.', 'error');
    }
  });
}
window.clearUserHistoryByAdmin = clearUserHistoryByAdmin;

function openPurgeHistoryModal() {
  $('#admin-purge-modal').addClass('open').css('display', 'flex').show();
}
window.openPurgeHistoryModal = openPurgeHistoryModal;

function closePurgeHistoryModal() {
  $('#admin-purge-modal').removeClass('open').hide();
}
window.closePurgeHistoryModal = closePurgeHistoryModal;

function submitPurgeHistory() {
  const days = $('#admin-purge-timeframe').val();
  if (!confirm('Are you certain you want to purge chat history logs? This action is permanent.')) return;

  $.ajax({
    url: '/api/admin/system/purge-history',
    type: 'POST',
    contentType: 'application/json',
    data: JSON.stringify({ days: parseInt(days, 10) }),
    success: function (res) {
      if (res.success) {
        showToast('System chat logs purged successfully!', 'success');
        closePurgeHistoryModal();
        updateAdminStats();
        loadAllSystemMessages();
      } else {
        showToast(res.message || 'Purge failed.', 'error');
      }
    },
    error: function(xhr) {
      showToast(xhr.responseJSON?.message || 'Purge failed.', 'error');
    }
  });
}
window.submitPurgeHistory = submitPurgeHistory;

function deleteUserByAdmin(uid, username) {
  if (!confirm(`Are you sure you want to permanently delete user account "${username}"?`)) return;

  $.ajax({
    url: `/api/admin/user/${uid}/delete`,
    type: 'DELETE',
    success: function (res) {
      if (res.success) {
        showToast(`User ${username} deleted.`, 'success');
        loadAdminUsers();
      } else {
        showToast(res.message || 'Failed to delete user.', 'error');
      }
    },
    error: function(xhr) {
      showToast(xhr.responseJSON?.message || 'Failed to delete user.', 'error');
    }
  });
}
window.deleteUserByAdmin = deleteUserByAdmin;

var _currentUserAuditHistory = [];

function viewUserHistory(uid, username) {
  _currentUserAuditHistory = [];
  $('#admin-modal-username').text(username);
  $('#admin-modal-search').val('');
  $('#admin-history-modal').addClass('open').css('display', 'flex').show();
  $('#admin-history-modal-body').html('<div style="text-align:center; padding:2rem; color:var(--text-muted)"><i class="fa-solid fa-spinner fa-spin"></i> Loading user history...</div>');

  $.get(`/api/admin/user/${uid}/history`, function (res) {
    if (res.success && res.history) {
      _currentUserAuditHistory = res.history;
      renderUserAuditHistoryList(_currentUserAuditHistory);
    } else {
      $('#admin-history-modal-body').html('<div style="text-align:center; padding:2rem; color:var(--text-muted)">No chat history found for this user.</div>');
    }
  }).fail(function(xhr) {
    $('#admin-history-modal-body').html('<div style="text-align:center; padding:2rem; color:var(--danger)">Failed to load user history: ' + (xhr.responseJSON?.message || 'Access error') + '</div>');
  });
}
window.viewUserHistory = viewUserHistory;

function renderUserAuditHistoryList(items) {
  const body = $('#admin-history-modal-body').empty();
  if (!items || !items.length) {
    body.html('<div style="text-align:center; padding:2rem; color:var(--text-muted)">No matching chat records found.</div>');
    return;
  }

  items.forEach(item => {
    const isUser = item.role === 'user';
    const roleLabel = isUser ? 'User' : 'LiverAI Assistant';
    const bg = isUser ? 'var(--bg-secondary)' : 'rgba(167,139,250,0.06)';
    const border = isUser ? 'var(--border)' : 'rgba(167,139,250,0.22)';
    const timeStr = item.created_at ? new Date(item.created_at).toLocaleString() : '';

    const formattedContent = isUser
      ? escapeHtml(item.message).replace(/\n/g, '<br/>')
      : (typeof renderMarkdown === 'function' ? renderMarkdown(item.message) : escapeHtml(item.message).replace(/\n/g, '<br/>'));

    body.append(`
      <div style="background:${bg}; border:1px solid ${border}; padding:.85rem 1.1rem; border-radius:10px; font-size:.85rem; display:flex; flex-direction:column; gap:.4rem;">
        <div style="display:flex; justify-content:space-between; align-items:center; font-size:.75rem; color:var(--text-muted); padding-bottom:.35rem; border-bottom:1px dashed var(--border)">
          <strong style="color:${isUser ? 'var(--accent)' : '#a78bfa'}; display:flex; align-items:center; gap:5px">
            <i class="${isUser ? 'fa-solid fa-user' : 'fa-solid fa-robot'}"></i> ${roleLabel}
          </strong>
          <span><i class="fa-regular fa-clock" style="margin-right:3px"></i>${timeStr}</span>
        </div>
        <div class="markdown-body" style="color:var(--text-primary); line-height:1.55; font-size:.84rem; word-break:break-word;">${formattedContent}</div>
      </div>
    `);
  });
}
window.renderUserAuditHistoryList = renderUserAuditHistoryList;

function filterModalAuditHistory() {
  const q = ($('#admin-modal-search').val() || '').toLowerCase().trim();
  if (!q) {
    renderUserAuditHistoryList(_currentUserAuditHistory);
    return;
  }
  const filtered = _currentUserAuditHistory.filter(item => {
    return (item.message && item.message.toLowerCase().includes(q)) ||
           (item.role && item.role.toLowerCase().includes(q)) ||
           (item.created_at && String(item.created_at).toLowerCase().includes(q));
  });
  renderUserAuditHistoryList(filtered);
}
window.filterModalAuditHistory = filterModalAuditHistory;

function closeAdminHistoryModal() {
  $('#admin-history-modal').removeClass('open').hide();
}
window.closeAdminHistoryModal = closeAdminHistoryModal;

function inspectAllSystemHistory() {
  switchAdminSubTab('audit');
}
window.inspectAllSystemHistory = inspectAllSystemHistory;
