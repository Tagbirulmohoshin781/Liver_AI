/* =============================================================================
   static/js/main.js — Global Application Utilities, Tab Router & Event Listeners
   ============================================================================= */

var HISTORY_KEY = window.HISTORY_KEY || 'liverAI_chat_history';

// Toast Notifications
function showToast(msg, type = 'info') {
  const container = document.getElementById('toast-container');
  if (!container) return;
  const icons = {
    success: 'fa-circle-check',
    error: 'fa-circle-exclamation',
    info: 'fa-circle-info',
    warning: 'fa-triangle-exclamation'
  };
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerHTML = `<i class="fa-solid ${icons[type] || 'fa-circle-info'}"></i> <span>${escapeHtml(msg)}</span>`;
  container.appendChild(toast);

  setTimeout(() => {
    toast.classList.add('out');
    setTimeout(() => toast.remove(), 250);
  }, 3500);
}

// Global View & Router Switchers
function showLogin() {
  $('#chat-view').hide();
  const lv = document.getElementById('login-view');
  if (lv) { lv.style.display = 'flex'; }
  toggleAuthMode('signin');
  setTimeout(function() {
    if (typeof initAuthParticles === 'function') initAuthParticles();
  }, 80);
}

function showChat() {
  $('#login-view').hide().css('display', 'none');
  // Show chat-view as flex row (sidebar + main)
  const cv = document.getElementById('chat-view');
  if (cv) { cv.style.display = 'flex'; cv.style.flexDirection = 'row'; }
  switchTab('chat');
  // On sign-in open a fresh new-chat window; populate sidebar/history only
  $('#msg-group').empty().hide();
  $('#welcome-screen').show();
  loadDatabaseHistory(true); // sidebar + history tab only, not main chat area
}

function switchTab(tabName) {
  $('.sidebar-nav-btn').removeClass('active');
  $('#nav-btn-' + tabName).addClass('active');

  // All tab content divs use #tab-* (not #tab-content-*)
  $('.tab-content').removeClass('active').hide();
  const tabEl = $('#tab-' + tabName);
  if (tabEl.length) {
    tabEl.addClass('active');
    // Most tabs use flex, except history which is block-ish
    const displayMode = ['chat', 'biopsy', 'admin', 'settings', 'profile'].includes(tabName) ? 'flex' : 'block';
    tabEl.css('display', displayMode).show();
  }

  if (tabName === 'profile') {
    loadProfilePanel();
  } else if (tabName === 'admin') {
    loadAdminUsers();
  }
}

// ─── Auth Mode Switching (Sign In <-> Sign Up) ─────────────────
function toggleAuthMode(mode) {
  showAuthError('');
  if (mode === 'signup') {
    $('#auth-signin-view').hide();
    $('#auth-signup-view').fadeIn(220);
    $('#signup-name').focus();
  } else {
    $('#auth-signup-view').hide();
    $('#auth-signin-view').fadeIn(220);
    $('#login-email').focus();
  }
}
window.toggleAuthMode = toggleAuthMode;

// Backwards compatibility alias
function toggleAuthTab(tab) {
  toggleAuthMode(tab);
}
window.toggleAuthTab = toggleAuthTab;

function showAuthError(msg, target = 'all') {
  if (msg) {
    if (target === 'signup') {
      $('#signup-error-text').text(msg);
      $('#signup-error').show();
      $('#login-error').hide();
    } else {
      $('#login-error-text').text(msg);
      $('#login-error').show();
      $('#signup-error').hide();
    }
  } else {
    $('#login-error-text').text('');
    $('#login-error').hide();
    $('#signup-error-text').text('');
    $('#signup-error').hide();
  }
}
window.showAuthError = showAuthError;

// ─── Forgot Password Modal Handlers ────────────────────────────
function openForgotModal() {
  const currentEmail = $('#login-email').val().trim();
  if (currentEmail) {
    $('#forgot-email').val(currentEmail);
  }
  $('#forgot-modal').fadeIn(200).css('display', 'flex');
  setTimeout(() => $('#forgot-email').focus(), 150);
}
window.openForgotModal = openForgotModal;

function closeForgotModal() {
  $('#forgot-modal').fadeOut(180);
}
window.closeForgotModal = closeForgotModal;

function handleForgotSubmit() {
  const email = $('#forgot-email').val().trim();
  if (!email) {
    showToast('Please enter a valid email address.', 'warning');
    return;
  }
  const btn = $('#btn-forgot-submit');
  btn.prop('disabled', true).html('<span>Sending Instructions…</span> <i class="fa-solid fa-spinner fa-spin"></i>');
  
  setTimeout(() => {
    btn.prop('disabled', false).html('<span>Send Reset Link</span> <i class="fa-solid fa-paper-plane auth-btn-icon"></i>');
    closeForgotModal();
    showToast(`Password recovery link dispatched to ${email}`, 'success');
  }, 900);
}
window.handleForgotSubmit = handleForgotSubmit;

// ─── Ambient Neural Network Particle Canvas ───────────────────
var _authParticlesRunning = false;
function initAuthParticles() {
  const canvas = document.getElementById('auth-particles-canvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  if (!ctx) return;

  let width = canvas.width = window.innerWidth;
  let height = canvas.height = window.innerHeight;

  window.addEventListener('resize', () => {
    if ($('#login-view').is(':visible')) {
      width = canvas.width = window.innerWidth;
      height = canvas.height = window.innerHeight;
    }
  });

  const particles = [];
  const particleCount = Math.min(Math.floor(window.innerWidth / 28), 45);
  const colors = ['rgba(56, 189, 248, ', 'rgba(96, 165, 250, ', 'rgba(255, 255, 255, '];

  for (let i = 0; i < particleCount; i++) {
    particles.push({
      x: Math.random() * width,
      y: Math.random() * height,
      vx: (Math.random() - 0.5) * 0.55,
      vy: (Math.random() - 0.5) * 0.55,
      radius: Math.random() * 2.2 + 1.2,
      baseAlpha: Math.random() * 0.5 + 0.3,
      color: colors[Math.floor(Math.random() * colors.length)]
    });
  }

  if (_authParticlesRunning) return;
  _authParticlesRunning = true;

  function render() {
    if (!$('#login-view').is(':visible')) {
      _authParticlesRunning = false;
      return;
    }

    ctx.clearRect(0, 0, width, height);

    // Draw connecting lines between close particles
    for (let i = 0; i < particles.length; i++) {
      for (let j = i + 1; j < particles.length; j++) {
        const dx = particles[i].x - particles[j].x;
        const dy = particles[i].y - particles[j].y;
        const dist = Math.sqrt(dx * dx + dy * dy);

        if (dist < 125) {
          const alpha = (1 - dist / 125) * 0.22;
          ctx.strokeStyle = `rgba(56, 189, 248, ${alpha})`;
          ctx.lineWidth = 0.85;
          ctx.beginPath();
          ctx.moveTo(particles[i].x, particles[i].y);
          ctx.lineTo(particles[j].x, particles[j].y);
          ctx.stroke();
        }
      }
    }

    // Draw nodes
    for (let i = 0; i < particles.length; i++) {
      const p = particles[i];
      p.x += p.vx;
      p.y += p.vy;

      if (p.x < 0) p.x = width;
      if (p.x > width) p.x = 0;
      if (p.y < 0) p.y = height;
      if (p.y > height) p.y = 0;

      ctx.fillStyle = p.color + p.baseAlpha + ')';
      ctx.shadowBlur = 8;
      ctx.shadowColor = 'rgba(56, 189, 248, 0.6)';
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
      ctx.fill();
      ctx.shadowBlur = 0;
    }

    requestAnimationFrame(render);
  }

  requestAnimationFrame(render);
}
window.initAuthParticles = initAuthParticles;

function togglePw(inputId, btn) {
  const inp = document.getElementById(inputId);
  if (!inp) return;
  if (inp.type === 'password') {
    inp.type = 'text';
    $(btn).html('<i class="fa-regular fa-eye-slash"></i>');
  } else {
    inp.type = 'password';
    $(btn).html('<i class="fa-regular fa-eye"></i>');
  }
}


function handleSocialComingSoon(provider) {
  showToast(`${provider} sign-in coming soon! Please use Google, GitHub, Facebook, or Email.`, 'info');
}

// Sidebar Drawer
function closeSidebar() {
  $('#sidebar').removeClass('mobile-open');
  $('#sidebar-overlay').removeClass('open');
}

function toggleMobileSidebar() {
  $('#sidebar').toggleClass('mobile-open');
  $('#sidebar-overlay').toggleClass('open');
}

// Text & Time Utilities
function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

function renderMarkdown(txt) {
  if (!txt) return '';
  if (typeof marked !== 'undefined') {
    try {
      marked.setOptions({
        highlight: function (code, lang) {
          if (typeof hljs !== 'undefined' && lang && hljs.getLanguage(lang)) {
            return hljs.highlight(code, { language: lang }).value;
          }
          return code;
        },
        breaks: true,
        gfm: true
      });
      const parsed = marked.parse(String(txt));
      if (typeof DOMPurify !== 'undefined') {
        return DOMPurify.sanitize(parsed, {
          USE_PROFILES: { html: true },
          ADD_ATTR: ['target', 'rel']
        });
      }
      return parsed;
    } catch (e) {
      console.warn('[Markdown Parser Error]', e);
    }
  }
  return escapeHtml(txt).replace(/\n/g, '<br/>');
}
window.renderMarkdown = renderMarkdown;
window.escapeHtml = escapeHtml;

function fmtTime(d) {
  return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}

function scrollBottom() {
  const area = document.getElementById('messages-area');
  if (area) area.scrollTop = area.scrollHeight;
}

function clearChat() {
  _chatMemory = [];
  $('#msg-group').empty().hide();
  $('#welcome-screen').show();
}

// Document Ready Initialization
$(document).ready(function () {
  // ── Chat input: auto-grow textarea ──────────────────
  $('#chat-input').on('input', function () {
    this.style.height = 'auto';
    this.style.height = Math.min(this.scrollHeight, 200) + 'px';
    const hasText = this.value.trim().length > 0;
    $('#btn-send').toggleClass('active', hasText);
  });

  // ── Send on Enter (Shift+Enter for newline) ──────────
  $('#chat-input').on('keydown', function (e) {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  });

  // ── Send button click ────────────────────────────────
  $('#btn-send').on('click', function (e) {
    e.preventDefault();
    sendMessage();
  });

  // Bind file input change listener
  $('#file-input').on('change', function () {
    if (this.files && this.files[0]) {
      handleFileSelection(this.files[0]);
    }
  });

  // ── Biopsy AI file input change listener ──────────────
  $('#biopsy-file-input').on('change', function () {
    if (this.files && this.files[0]) {
      if (typeof handleBiopsyUpload === 'function') {
        handleBiopsyUpload(this.files[0]);
      }
    }
  });

  // Drag & drop handlers on drop-zone
  const dropZone = document.getElementById('drop-zone');
  if (dropZone) {
    dropZone.addEventListener('dragover', (e) => {
      e.preventDefault();
      dropZone.classList.add('drag-over');
    });
    dropZone.addEventListener('dragleave', () => {
      dropZone.classList.remove('drag-over');
    });
    dropZone.addEventListener('drop', (e) => {
      e.preventDefault();
      dropZone.classList.remove('drag-over');
      if (e.dataTransfer.files && e.dataTransfer.files[0]) {
        handleFileSelection(e.dataTransfer.files[0]);
      }
    });
  }

  // ── Biopsy drag & drop handlers ───────────────────────
  const biopsyDropZone = document.getElementById('biopsy-drop-zone');
  if (biopsyDropZone) {
    biopsyDropZone.addEventListener('dragover', (e) => {
      e.preventDefault();
      biopsyDropZone.classList.add('drag-over');
    });
    biopsyDropZone.addEventListener('dragleave', () => {
      biopsyDropZone.classList.remove('drag-over');
    });
    biopsyDropZone.addEventListener('drop', (e) => {
      e.preventDefault();
      biopsyDropZone.classList.remove('drag-over');
      if (e.dataTransfer.files && e.dataTransfer.files[0]) {
        if (typeof handleBiopsyUpload === 'function') {
          handleBiopsyUpload(e.dataTransfer.files[0]);
        }
      }
    });
  }

  // Check active session on startup: require explicit login on fresh project open
  const isExplicitlyAuthenticated = sessionStorage.getItem('liverai_auth') === '1';
  if (isExplicitlyAuthenticated) {
    $.get('/api/me', function (res) {
      if (res.authenticated && res.user) {
        applyUserData(res.user);
        showChat();
      } else {
        sessionStorage.removeItem('liverai_auth');
        showLogin();
      }
    }).fail(function () {
      showLogin();
    });
  } else {
    // Clear lingering server session and start on login screen
    $.post('/api/logout', function() {
      showLogin();
    }).always(function() {
      showLogin();
    });
  }

  loadSettings();
});

// ─── Toggle Sidebar ──────────────────────────────────
function toggleSidebar() {
  $('#sidebar').toggleClass('mobile-open');
  $('#sidebar-overlay').toggleClass('open');
}
window.toggleSidebar = toggleSidebar;

// ─── Send Suggestion Chip ──────────────────────────
function sendSuggestion(chipEl) {
  const text = chipEl ? chipEl.innerText.trim() : '';
  if (!text) return;
  $('#chat-input').val(text).trigger('input');
  sendMessage();
}
window.sendSuggestion = sendSuggestion;

// ─── Core Send Message ──────────────────────────────
function sendMessage() {
  const input = $('#chat-input');
  const msg = input.val().trim();
  if (!msg) return;

  // Switch to chat tab
  switchTab('chat');

  // Render user message
  $('#welcome-screen').hide();
  $('#msg-group').show();
  const timeStr = fmtTime(new Date());
  const userInitial = window.currentUserInitial || 'U';
  const userHtml = `
    <div class="msg-row user-row">
      <div class="msg-avatar user-avatar-msg">${escapeHtml(userInitial)}</div>
      <div class="msg-content-wrap">
        <div class="msg-bubble">${escapeHtml(msg)}</div>
        <div class="msg-meta"><span class="msg-time">${timeStr}</span></div>
      </div>
    </div>`;
  $('#msg-group').append(userHtml);

  // Clear input
  input.val('').css('height', 'auto');
  $('#btn-send').removeClass('active');
  scrollBottom();

  // Add to memory
  _chatMemory.push({ role: 'user', content: msg });

  // Streaming AI response
  const botMsgId = 'bot-msg-' + Date.now();
  const botHtml = `
    <div class="msg-row ai-row" id="${botMsgId}">
      <div class="msg-avatar ai-avatar"><i class="fa-solid fa-heart-pulse"></i></div>
      <div class="msg-content-wrap">
        <div class="msg-bubble" id="${botMsgId}-bubble"><span class="typing-dot"></span><span class="typing-dot"></span><span class="typing-dot"></span></div>
        <div class="msg-meta">
          <span class="msg-time">${timeStr}</span>
          <button class="btn-copy-msg" onclick="copyMsg('${botMsgId}', this)" title="Copy"><i class="fa-regular fa-copy"></i> Copy</button>
        </div>
      </div>
    </div>`;
  $('#msg-group').append(botHtml);
  scrollBottom();

  // Build context
  const history = _chatMemory.slice(-12);
  const imageContext = window.lastUploadedImagePath || null;
  const docContext = window.lastUploadedDocContent || null;

  $.ajax({
    url: '/api/v1/chat',
    type: 'POST',
    contentType: 'application/json',
    data: JSON.stringify({ message: msg, history: history, upload_id: imageContext, image_path: imageContext, doc_content: docContext }),
    success: function (res) {
      if (res && res.response) {
        const rendered = renderMarkdown(res.response);
        $('#' + botMsgId + '-bubble').html(rendered);
        _chatMemory.push({ role: 'assistant', content: res.response });

        // Reload sidebar history without clearing active chat UI
        if (typeof loadDatabaseHistory === 'function') {
          loadDatabaseHistory(true);
        }
      } else {
        $('#' + botMsgId + '-bubble').html('<span style="color:var(--danger)">No response received. Please try again.</span>');
      }
      scrollBottom();
    },
    error: function (xhr) {
      // Fallback attempt to /chat
      $.ajax({
        url: '/chat',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({ message: msg, history: history, upload_id: imageContext, image_path: imageContext, doc_content: docContext }),
        success: function (res) {
          if (res && res.response) {
            const rendered = renderMarkdown(res.response);
            $('#' + botMsgId + '-bubble').html(rendered);
            _chatMemory.push({ role: 'assistant', content: res.response });
            if (typeof loadDatabaseHistory === 'function') loadDatabaseHistory(true);
          } else {
            $('#' + botMsgId + '-bubble').html('<span style="color:var(--danger)">No response received. Please try again.</span>');
          }
          scrollBottom();
        },
        error: function (xhr2) {
          const errMsg = xhr2.responseJSON ? xhr2.responseJSON.error || xhr2.responseJSON.message : 'Server error. Please try again.';
          $('#' + botMsgId + '-bubble').html('<span style="color:var(--danger)">⚠️ ' + escapeHtml(errMsg) + '</span>');
          scrollBottom();
        }
      });
    }
  });
}
window.sendMessage = sendMessage;

// ─── Copy message text ───────────────────────────────
function copyMsg(msgId, btn) {
  const bubble = document.getElementById(msgId + '-bubble');
  if (!bubble) return;
  const text = bubble.innerText || bubble.textContent;
  navigator.clipboard.writeText(text).then(() => {
    $(btn).html('<i class="fa-solid fa-check"></i> Copied');
    setTimeout(() => $(btn).html('<i class="fa-regular fa-copy"></i> Copy'), 2000);
  }).catch(() => {
    showToast('Copy failed — please select and copy manually.', 'warning');
  });
}

// ─── Explicit Window Binding ─────────────────────────
window.showLogin = showLogin;
window.showChat = showChat;
window.switchTab = switchTab;
window.toggleSidebar = toggleSidebar;
window.sendSuggestion = sendSuggestion;
window.sendMessage = sendMessage;
window.copyMsg = copyMsg;
window.clearChat = clearChat;



