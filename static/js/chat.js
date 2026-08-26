/* =============================================================================
   static/js/chat.js — Chat Messaging Controller, Markdown & Biopsy Reports
   ============================================================================= */

var _chatMemory = window._chatMemory || [];

function loadDatabaseHistory(onlyUpdateSidebar = false) {
  $.get('/api/history', function (res) {
    if (res.success && res.history && res.history.length > 0) {
      const historyList = $('#history-list').empty();
      const tabHistoryList = $('#history-tab-list').empty();

      if (!onlyUpdateSidebar) {
        $('#welcome-screen').hide();
        const msgGroup = $('#msg-group').empty().show();

        res.history.forEach(item => {
          const timeStr = item.created_at ? fmtTime(new Date(item.created_at)) : fmtTime(new Date());

          if (item.role === 'user') {
            const userHtml = `
                <div class="msg-row user-row" id="db-msg-${item.id}">
                  <div class="msg-avatar user-avatar-msg">${window.currentUserInitial || 'U'}</div>
                  <div class="msg-content-wrap">
                    <div class="msg-bubble">${escapeHtml(item.message)}</div>
                    <div class="msg-meta">
                      <span class="msg-time">${timeStr}</span>
                    </div>
                  </div>
                </div>`;
            msgGroup.append(userHtml);

            const shortText = item.message.length > 30 ? item.message.substring(0, 30) + '…' : item.message;
            const li = $(`
                <li class="history-item" data-msg-id="db-msg-${item.id}">
                  <i class="fa-regular fa-message"></i>
                  <span class="history-title">${escapeHtml(shortText)}</span>
                </li>`);
            li.click(() => {
              switchTab('chat');
              closeSidebar();
              const target = document.getElementById(`db-msg-${item.id}`);
              if (target) target.scrollIntoView({ behavior: 'smooth' });
            });
            historyList.append(li);

            const tabLi = $(`
                <li class="history-tab-item" style="padding:.75rem;border-bottom:1px solid var(--border);cursor:pointer">
                  <div class="history-tab-info">
                    <i class="fa-regular fa-comment-dots" style="color:var(--accent);margin-right:.5rem"></i>
                    <div>
                      <div class="history-tab-text">${escapeHtml(shortText)}</div>
                      <div class="history-tab-date">${timeStr}</div>
                    </div>
                  </div>
                </li>`);
            tabLi.click(() => {
              switchTab('chat');
              const target = document.getElementById(`db-msg-${item.id}`);
              if (target) target.scrollIntoView({ behavior: 'smooth' });
            });
            tabHistoryList.append(tabLi);

          } else if (item.role === 'assistant') {
            const msgId = 'msg-' + item.id;
            const rendered = renderMarkdown(item.message);
            const botHtml = `
                <div class="msg-row ai-row" id="${msgId}">
                  <div class="msg-avatar ai-avatar"><i class="fa-solid fa-heart-pulse"></i></div>
                  <div class="msg-content-wrap">
                    <div class="msg-bubble">${rendered}</div>
                    <div class="msg-meta">
                      <span class="msg-time">${timeStr}</span>
                      <button class="btn-copy-msg" onclick="copyMsg('${msgId}', this)" title="Copy response">
                        <i class="fa-regular fa-copy"></i> Copy
                      </button>
                    </div>
                  </div>
                </div>`;
            msgGroup.append(botHtml);
          }
        });

        scrollBottom();
      } else {
        // Sidebar and History Tab update only (preserves ongoing chat area)
        res.history.forEach(item => {
          if (item.role === 'user') {
            const timeStr = item.created_at ? fmtTime(new Date(item.created_at)) : fmtTime(new Date());
            const shortText = item.message.length > 30 ? item.message.substring(0, 30) + '…' : item.message;
            const li = $(`
                <li class="history-item" data-msg-id="db-msg-${item.id}">
                  <i class="fa-regular fa-message"></i>
                  <span class="history-title">${escapeHtml(shortText)}</span>
                </li>`);
            li.click(() => {
              switchTab('chat');
              closeSidebar();
              const target = document.getElementById(`db-msg-${item.id}`);
              if (target) target.scrollIntoView({ behavior: 'smooth' });
            });
            historyList.append(li);

            const tabLi = $(`
                <li class="history-tab-item" style="padding:.75rem;border-bottom:1px solid var(--border);cursor:pointer">
                  <div class="history-tab-info">
                    <i class="fa-regular fa-comment-dots" style="color:var(--accent);margin-right:.5rem"></i>
                    <div>
                      <div class="history-tab-text">${escapeHtml(shortText)}</div>
                      <div class="history-tab-date">${timeStr}</div>
                    </div>
                  </div>
                </li>`);
            tabLi.click(() => {
              switchTab('chat');
              const target = document.getElementById(`db-msg-${item.id}`);
              if (target) target.scrollIntoView({ behavior: 'smooth' });
            });
            tabHistoryList.append(tabLi);
          }
        });
      }
    } else if (!onlyUpdateSidebar) {
      localStorage.removeItem(HISTORY_KEY);
      _chatMemory = [];
      $('#msg-group').empty().hide();
      $('#welcome-screen').show();
      $('#history-list').html('<li class="history-empty"><i class="fa-regular fa-clock"></i> No recent chats</li>');
      $('#history-tab-list').empty();
    }
  });
}

function clearAllHistory() {
  if (confirm('Are you sure you want to clear your chat history?')) {
    $.post('/api/clear_history', function (res) {
      if (res.success) {
        localStorage.removeItem(HISTORY_KEY);
        _chatMemory = [];
        $('#msg-group').empty().hide();
        $('#welcome-screen').show();
        $('#history-list').html('<li class="history-empty"><i class="fa-regular fa-clock"></i> No recent chats</li>');
        $('#history-tab-list').empty();
        showToast('Chat history cleared permanently.', 'success');
      }
    });
  }
}

function renderMarkdown(txt) {
  if (typeof marked !== 'undefined') {
    marked.setOptions({
      highlight: function (code, lang) {
        if (typeof hljs !== 'undefined' && lang && hljs.getLanguage(lang)) {
          return hljs.highlight(code, { language: lang }).value;
        }
        return code;
      },
      breaks: true
    });
    const parsed = marked.parse(String(txt || ''));
    if (typeof DOMPurify !== 'undefined') {
      return DOMPurify.sanitize(parsed, {
        USE_PROFILES: { html: true },
        ADD_ATTR: ['target', 'rel']
      });
    }
    return parsed;
  }
  return escapeHtml(txt);
}

// ─── Upload Modal Helpers ─────────────────────
let selectedFile = null;

function openUploadModal() {
  selectedFile = null;
  $('#upload-status').empty().hide();
  $('#btn-upload-submit').hide();
  $('#drop-zone').html(`
    <i class="fa-solid fa-cloud-arrow-up drop-icon"></i>
    <p class="drop-text">Drag &amp; drop file, or <strong>browse</strong></p>
    <span class="drop-sub">Supported: PDF, TXT, CSV, JPG, PNG — Max 50MB</span>
  `);
  $('#upload-modal').addClass('open').css('display', 'flex').show();
}

function closeUploadModal() {
  $('#upload-modal').removeClass('open').hide();
}

function handleFileSelection(file) {
  if (!file) return;
  selectedFile = file;
  const sizeMB = (file.size / 1048576).toFixed(2);
  $('#drop-zone').html(`
    <i class="fa-solid fa-file-circle-check drop-icon" style="color:#10a37f"></i>
    <p class="drop-text">${escapeHtml(file.name)}</p>
    <span class="drop-sub">${sizeMB} MB · Click to change file</span>
  `);
  $('#btn-upload-submit').show();
  $('#upload-status').empty().hide();
}

function showUploadStatus(type, msg) {
  const statusBox = $('#upload-status');
  statusBox.removeClass('success error info').addClass(type).html(msg).show();
}

function submitUpload() {
  if (!selectedFile) {
    showToast('Please select a file to upload.', 'error');
    return;
  }

  const fileToUpload = selectedFile;
  const fileName = fileToUpload.name;
  const formData = new FormData();
  formData.append('file', fileToUpload);

  $('#btn-upload-submit').prop('disabled', true).html('<i class="fa-solid fa-spinner fa-spin"></i> Uploading & Processing…');
  showUploadStatus('info', '<i class="fa-solid fa-spinner fa-spin"></i> Processing and extracting document text...');

  $.ajax({
    url: '/upload',
    type: 'POST',
    data: formData,
    contentType: false,
    processData: false,
    success: function (res) {
      $('#btn-upload-submit').prop('disabled', false).text('Upload & Process');
      if (res.success) {
        showUploadStatus('success', res.message || 'File processed successfully!');
        setTimeout(() => {
          closeUploadModal();
          if (res.is_image) {
            if (res.image_path) window.lastUploadedImagePath = res.image_path;
            notifyImageDiagnosisInChat(fileName, res.predictions, res.mode || 'production', res.warning);
          } else {
            if (res.doc_content) window.lastUploadedDocContent = res.doc_content;
            notifyUploadInChat(fileName, res.message, res.doc_content);
          }
        }, 1200);
      } else {
        showUploadStatus('error', res.message || 'Upload processing failed.');
        showToast('Upload failed: ' + (res.message || 'Error processing file'), 'error');
      }
    },
    error: function (xhr) {
      $('#btn-upload-submit').prop('disabled', false).text('Upload & Process');
      let errText = '❌ Upload failed. Please try again.';
      if (xhr && xhr.responseJSON && xhr.responseJSON.message) {
        errText = '❌ ' + xhr.responseJSON.message;
      }
      showUploadStatus('error', errText);
      showToast(errText, 'error');
    }
  });
}

function discussDocumentInChat(fileName) {
  switchTab('chat');
  closeSidebar();
  $('#chat-input').val(`Please review and summarize the attached document "${fileName}" and provide key clinical findings and recommendations.`);
  sendMessage();
}
window.discussDocumentInChat = discussDocumentInChat;

function discussBiopsyInChat(fileName) {
  switchTab('chat');
  closeSidebar();
  $('#chat-input').val(`Please review the histology biopsy findings for ${fileName} and explain the clinical significance and management recommendations.`);
  sendMessage();
}
window.discussBiopsyInChat = discussBiopsyInChat;

function notifyUploadInChat(filename, message, docContent) {
  $('#welcome-screen').hide();
  $('#msg-group').show();

  if (docContent) {
    _chatMemory.push({
      role: 'assistant',
      content: `[Uploaded Document '${filename}']: ` + docContent
    });
  }

  const snippet = docContent ? docContent.substring(0, 260) + (docContent.length > 260 ? '…' : '') : '';

  const notifyHtml = `
    <div class="msg-row ai-row">
      <div class="msg-avatar ai-avatar" style="background:linear-gradient(135deg,var(--accent),#0d9488); color:#fff">
        <i class="fa-solid fa-file-circle-check"></i>
      </div>
      <div class="msg-content-wrap">
        <div class="msg-bubble" style="max-width:580px; width:100%; padding:1.25rem;">
          <div style="display:flex; align-items:center; justify-content:space-between; gap:10px; margin-bottom:8px; border-bottom:1px solid var(--border); padding-bottom:.65rem;">
            <strong style="color:var(--accent); font-size:1.02rem;">
              <i class="fa-solid fa-file-lines" style="margin-right:5px"></i> Document Uploaded &amp; Indexed
            </strong>
            <span style="font-size:.72rem; background:rgba(16,163,127,0.12); color:var(--accent); padding:2px 8px; border-radius:12px; font-weight:700">
              Active Context
            </span>
          </div>
          <div style="font-size:.84rem; color:var(--text-secondary); margin-bottom:10px">
            File: <code>${escapeHtml(filename)}</code>
          </div>
          ${snippet ? `
            <div style="background:var(--bg-primary); border:1px solid var(--border); padding:10px 12px; border-radius:10px; font-size:.8rem; color:var(--text-secondary); line-height:1.45; font-style:italic; margin-bottom:12px;">
              "${escapeHtml(snippet)}"
            </div>
          ` : ''}
          <div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:8px; border-top:1px solid var(--border); padding-top:10px;">
            <span style="font-size:.74rem; color:var(--text-muted)">
              <i class="fa-solid fa-circle-check" style="color:var(--accent); margin-right:3px"></i> Document context is active for questions
            </span>
            <button type="button" class="btn-biopsy-action primary" style="font-size:.78rem; padding:.45rem .95rem;" onclick="discussDocumentInChat('${escapeHtml(filename)}')">
              <i class="fa-solid fa-comments"></i> Discuss in Chat
            </button>
          </div>
        </div>
      </div>
    </div>`;

  $('#msg-group').append(notifyHtml);
  scrollBottom();
  showToast('📄 Document attached & context active!', 'success');
}

function notifyImageDiagnosisInChat(filename, predictions, mode, warning) {
  $('#welcome-screen').hide();
  $('#msg-group').show();

  const modeBadge = mode === 'production' ?
    '<span style="background:rgba(167,139,250,0.15);color:#a78bfa;padding:2px 8px;border-radius:999px;font-size:.72rem;font-weight:700;"><i class="fa-solid fa-brain"></i> PyTorch Deep Learning</span>' :
    '<span style="background:rgba(245,158,11,0.15);color:#fbbf24;padding:2px 8px;border-radius:999px;font-size:.72rem;font-weight:700;"><i class="fa-solid fa-flask"></i> Simulation Engine</span>';

  let detectedList = [];
  if (predictions) {
    for (const [k, v] of Object.entries(predictions)) {
      if (v.positive) detectedList.push(k);
    }
  }

  const labelsMap = {
    steatosis: { name: "Hepatic Steatosis", icon: "fa-droplet", desc: "Intracellular lipid / fat droplet accumulation" },
    fibrosis: { name: "Tissue Fibrosis", icon: "fa-layer-group", desc: "Connective collagen scarring & matrix remodeling" },
    inflammation: { name: "Lobular Inflammation", icon: "fa-fire-flame-curved", desc: "Inflammatory cellular aggregates & immune infiltration" },
    ballooning: { name: "Hepatocyte Ballooning", icon: "fa-expand", desc: "Cellular hydropic degeneration & microstructural swelling" }
  };

  const hasPositive = detectedList.length > 0;
  const bannerTitle = hasPositive ? "Histological Tissue Biomarkers Identified" : "No Pathological Abnormalities Detected";
  const bannerSub = hasPositive
    ? `Elevated probability detected for: ${detectedList.join(', ')}. Clinical follow-up recommended.`
    : "Tissue morphology falls within baseline thresholds across all four screening targets.";
  const bannerBorder = hasPositive ? "rgba(248,113,113,0.3)" : "rgba(52,211,153,0.3)";
  const bannerBg = hasPositive ? "rgba(248,113,113,0.06)" : "rgba(52,211,153,0.06)";
  const bannerIconColor = hasPositive ? "#f87171" : "#34d399";
  const bannerIcon = hasPositive ? "fa-solid fa-triangle-exclamation" : "fa-solid fa-shield-halved";

  let reportHtml = `
    <div class="msg-row ai-row">
      <div class="msg-avatar ai-avatar" style="background: linear-gradient(135deg,#8b5cf6,#6d28d9); color:#fff">
        <i class="fa-solid fa-microscope"></i>
      </div>
      <div class="msg-content-wrap">
        <div class="msg-bubble" style="max-width: 600px; width:100%; padding:1.25rem; display:flex; flex-direction:column; gap:.9rem;">
          
          <!-- Header -->
          <div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:8px; border-bottom:1px solid var(--border); padding-bottom:.65rem;">
            <div>
              <strong style="color:#a78bfa; font-size: 1.02rem; display:block;">
                <i class="fa-solid fa-wand-magic-sparkles" style="margin-right:5px"></i> Histology AI Diagnostic Report
              </strong>
              <span style="color:var(--text-muted); font-size: .75rem; display:block; margin-top:2px;">
                File: <code>${escapeHtml(filename)}</code>
              </span>
            </div>
            ${modeBadge}
          </div>

          <!-- Alert Banner -->
          <div style="background:${bannerBg}; border:1px solid ${bannerBorder}; border-radius:12px; padding:.75rem 1rem; display:flex; align-items:center; gap:.75rem;">
            <div style="font-size:1.3rem; color:${bannerIconColor}; flex-shrink:0;">
              <i class="${bannerIcon}"></i>
            </div>
            <div style="flex:1;">
              <strong style="color:var(--text-primary); font-size:.88rem; display:block;">${bannerTitle}</strong>
              <p style="color:var(--text-secondary); font-size:.76rem; margin:.15rem 0 0; line-height:1.35;">${bannerSub}</p>
            </div>
          </div>

          <!-- 2x2 Biomarker Grid -->
          <div>
            <div style="font-size:.74rem; font-weight:700; color:var(--text-muted); text-transform:uppercase; letter-spacing:.05em; margin-bottom:.6rem;">
              <i class="fa-solid fa-dna" style="margin-right:4px; color:#a78bfa"></i> Biomarker Quantitative Probabilities
            </div>
            <div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(230px, 1fr)); gap:.65rem;">
  `;

  if (predictions) {
    for (const [key, val] of Object.entries(predictions)) {
      const meta = labelsMap[key] || { name: key, icon: "fa-circle-dot", desc: "Histology marker" };
      const statusText = val.positive ? "DETECTED" : "CLEAR";
      const statusClass = val.positive ? "biopsy-badge-detected" : "biopsy-badge-clear";
      const barColor = val.positive ? "#f87171" : "#34d399";
      const probNum = Math.round(val.probability || 0);

      reportHtml += `
        <div style="background:var(--bg-primary); border:1px solid var(--border); border-radius:12px; padding:.8rem .9rem; display:flex; flex-direction:column; gap:.45rem;">
          <div style="display:flex; justify-content:space-between; align-items:flex-start; gap:6px;">
            <div>
              <span style="font-size:.82rem; font-weight:700; color:var(--text-primary); display:block;">
                <i class="fa-solid ${meta.icon}" style="color:${barColor}; margin-right:5px; font-size:.78rem"></i>
                ${meta.name}
              </span>
              <span style="font-size:.68rem; color:var(--text-secondary); display:block; margin-top:2px;">${meta.desc}</span>
            </div>
            <span class="${statusClass}" style="font-size:.68rem; padding:2px 7px;">
              <i class="${val.positive ? 'fa-solid fa-circle-exclamation' : 'fa-solid fa-circle-check'}"></i>
              ${statusText}
            </span>
          </div>
          <div style="display:flex; align-items:center; gap:.6rem; margin-top:2px;">
            <div style="flex:1; height:6px; background:var(--bg-hover); border-radius:4px; overflow:hidden;">
              <div style="width:${probNum}%; height:100%; background:${barColor}; border-radius:4px; transition:width .6s ease;"></div>
            </div>
            <span style="font-size:.75rem; font-weight:700; color:${barColor}; font-variant-numeric:tabular-nums; width:34px; text-align:right;">${probNum}%</span>
          </div>
        </div>
      `;
    }
  }

  reportHtml += `
            </div>
          </div>

          <!-- Clinical Disclaimer & Action Bar -->
          <div style="border-top:1px solid var(--border); padding-top:.75rem; display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:.75rem;">
            <p style="font-size:.72rem; color:var(--text-muted); line-height:1.35; margin:0; max-width:320px;">
              <i class="fa-solid fa-circle-info" style="margin-right:3px"></i>
              PyTorch AI patch screening. Review by a pathologist recommended.
            </p>
            <div style="display:flex; gap:.5rem;">
              <button type="button" class="btn-biopsy-action secondary" style="font-size:.75rem; padding:.45rem .85rem;" onclick="switchTab('biopsy');">
                <i class="fa-solid fa-microscope"></i> Biopsy AI Tab
              </button>
              <button type="button" class="btn-biopsy-action primary" style="font-size:.75rem; padding:.45rem .85rem;" onclick="discussBiopsyInChat('${escapeHtml(filename)}')">
                <i class="fa-solid fa-comments"></i> Discuss in Chat
              </button>
            </div>
          </div>

        </div>
      </div>
    </div>`;

  $('#msg-group').append(reportHtml);
  scrollBottom();
  showToast('🔬 Biopsy image analyzed successfully!', 'success');
}

function copyBiopsyReport() {
  const text = $('#biopsy-report-view').text().trim();
  if (navigator.clipboard) {
    navigator.clipboard.writeText(text).then(() => {
      showToast('Pathology summary copied to clipboard!', 'success');
    });
  } else {
    showToast('Report copied!', 'success');
  }
}
window.copyBiopsyReport = copyBiopsyReport;

function clearBiopsyUpload(e) {
  if (e) e.stopPropagation();
  $('#biopsy-file-input').val('');
  $('#biopsy-preview-box').hide();
  $('#biopsy-drop-zone').show();
  $('#biopsy-status').empty().hide();
  $('#biopsy-report-view').empty().hide();
}
window.clearBiopsyUpload = clearBiopsyUpload;

function handleBiopsyUpload(file) {
  if (!file) return;

  // Show local preview image
  const reader = new FileReader();
  reader.onload = function (e) {
    $('#biopsy-preview-img').attr('src', e.target.result);
    $('#biopsy-preview-name').text(file.name);
    const sizeMb = (file.size / (1024 * 1024)).toFixed(2);
    $('#biopsy-preview-meta').text(`${sizeMb} MB · Histology Slide Patch`);
    $('#biopsy-drop-zone').hide();
    $('#biopsy-preview-box').show();
  };
  reader.readAsDataURL(file);

  $('#biopsy-status').removeClass('error success').addClass('info').html(
    '<i class="fa-solid fa-spinner fa-spin" style="margin-right:6px"></i> Evaluating tissue histology with EfficientNet-B0 PyTorch vision model...'
  ).show();
  $('#biopsy-report-view').empty().hide();

  const formData = new FormData();
  formData.append('file', file);

  $.ajax({
    url: '/upload',
    type: 'POST',
    data: formData,
    processData: false,
    contentType: false,
    success: function (res) {
      if (res.success && res.is_image) {
        window.lastUploadedImagePath = res.image_path;

        // Push biopsy prediction summary into active chat memory for follow-up questions
        let detectedList = [];
        if (res.predictions) {
          let predParts = [];
          for (const [k, v] of Object.entries(res.predictions)) {
            const st = v.positive ? 'DETECTED' : 'NOT DETECTED';
            if (v.positive) detectedList.push(k);
            predParts.push(`${k}: ${st} (${v.probability}%)`);
          }
          _chatMemory.push({
            role: 'assistant',
            content: `[Biopsy Image Analysis for ${file.name}]: ` + predParts.join(', ')
          });
        }

        const modeBadge = res.mode === 'production' ?
          '<span style="background:rgba(167,139,250,0.15);color:#a78bfa;padding:2px 8px;border-radius:999px;font-size:.75rem;font-weight:700;"><i class="fa-solid fa-brain"></i> PyTorch Deep Learning</span>' :
          '<span style="background:rgba(245,158,11,0.15);color:#fbbf24;padding:2px 8px;border-radius:999px;font-size:.75rem;font-weight:700;"><i class="fa-solid fa-flask"></i> Simulation Engine</span>';

        $('#biopsy-status').removeClass('info error').addClass('success').html(
          `<i class="fa-solid fa-circle-check" style="margin-right:6px"></i> Analysis Complete · ${modeBadge}`
        ).show();

        const labelsMap = {
          steatosis: { name: "Hepatic Steatosis", icon: "fa-droplet", desc: "Intracellular lipid / fat droplet accumulation" },
          fibrosis: { name: "Tissue Fibrosis", icon: "fa-layer-group", desc: "Connective collagen scarring & matrix remodeling" },
          inflammation: { name: "Lobular Inflammation", icon: "fa-fire-flame-curved", desc: "Inflammatory cellular aggregates & immune infiltration" },
          ballooning: { name: "Hepatocyte Ballooning", icon: "fa-expand", desc: "Cellular hydropic degeneration & microstructural swelling" }
        };

        const hasPositive = detectedList.length > 0;
        const bannerTitle = hasPositive ? "Histological Tissue Biomarkers Identified" : "No Pathological Abnormalities Detected";
        const bannerSub = hasPositive 
          ? `Elevated probability detected for: ${detectedList.join(', ')}. Clinical follow-up recommended.`
          : "Tissue morphology falls within baseline thresholds across all four screening targets.";
        const bannerBorder = hasPositive ? "rgba(248,113,113,0.3)" : "rgba(52,211,153,0.3)";
        const bannerBg = hasPositive ? "rgba(248,113,113,0.06)" : "rgba(52,211,153,0.06)";
        const bannerIconColor = hasPositive ? "#f87171" : "#34d399";
        const bannerIcon = hasPositive ? "fa-solid fa-triangle-exclamation" : "fa-solid fa-shield-halved";

        let reportHtml = `
          <div style="background:var(--bg-secondary); border:1px solid var(--border); border-radius:18px; padding:1.5rem; display:flex; flex-direction:column; gap:1.25rem;">
            
            <!-- Summary Banner -->
            <div style="background:${bannerBg}; border:1px solid ${bannerBorder}; border-radius:14px; padding:1rem 1.25rem; display:flex; align-items:center; gap:1rem;">
              <div style="font-size:1.5rem; color:${bannerIconColor}; flex-shrink:0;">
                <i class="${bannerIcon}"></i>
              </div>
              <div style="flex:1;">
                <strong style="color:var(--text-primary); font-size:.95rem; display:block;">${bannerTitle}</strong>
                <p style="color:var(--text-secondary); font-size:.8rem; margin:.2rem 0 0; line-height:1.4;">${bannerSub}</p>
              </div>
            </div>

            <!-- Biomarkers 2x2 Grid -->
            <div>
              <div style="font-size:.78rem; font-weight:700; color:var(--text-muted); text-transform:uppercase; letter-spacing:.06em; margin-bottom:.75rem;">
                <i class="fa-solid fa-dna" style="margin-right:5px; color:#a78bfa"></i> Biomarker Quantitative Probabilities
              </div>
              <div class="biopsy-report-grid">
        `;

        if (res.predictions) {
          for (const [key, val] of Object.entries(res.predictions)) {
            const meta = labelsMap[key] || { name: key, icon: "fa-circle-dot", desc: "Histology marker" };
            const statusText = val.positive ? "DETECTED" : "CLEAR";
            const statusClass = val.positive ? "biopsy-badge-detected" : "biopsy-badge-clear";
            const barColor = val.positive ? "#f87171" : "#34d399";
            const probNum = Math.round(val.probability || 0);

            reportHtml += `
              <div class="biopsy-biomarker-card">
                <div class="biopsy-card-header">
                  <div>
                    <span class="biopsy-card-name">
                      <i class="fa-solid ${meta.icon}" style="color:${barColor}; margin-right:6px; font-size:.85rem"></i>
                      ${meta.name}
                    </span>
                    <span class="biopsy-card-desc">${meta.desc}</span>
                  </div>
                  <span class="${statusClass}">
                    <i class="${val.positive ? 'fa-solid fa-circle-exclamation' : 'fa-solid fa-circle-check'}"></i>
                    ${statusText}
                  </span>
                </div>
                <div class="biopsy-progress-wrap">
                  <div class="biopsy-progress-bar">
                    <div class="biopsy-progress-fill" style="width:${probNum}%; background:${barColor};"></div>
                  </div>
                  <span class="biopsy-prob-val" style="color:${barColor}">${probNum}%</span>
                </div>
              </div>
            `;
          }
        }

        reportHtml += `
              </div>
            </div>

            <!-- Clinical Disclaimer & Action Bar -->
            <div style="border-top:1px solid var(--border); padding-top:1.1rem; display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:1rem;">
              <p style="font-size:.74rem; color:var(--text-muted); line-height:1.4; margin:0; max-width:460px;">
                <i class="fa-solid fa-circle-info" style="margin-right:4px"></i>
                AI-assisted histology grading based on patch feature extraction. Results should be verified by a board-certified pathologist.
              </p>
              <div class="biopsy-actions-bar">
                <button type="button" class="btn-biopsy-action secondary" onclick="clearBiopsyUpload(event)">
                  <i class="fa-solid fa-rotate-left"></i> New Slide
                </button>
                <button type="button" class="btn-biopsy-action primary" onclick="discussBiopsyInChat('${escapeHtml(file.name)}')">
                  <i class="fa-solid fa-comments"></i> Discuss in Chat
                </button>
              </div>
            </div>

          </div>
        `;

        $('#biopsy-report-view').html(reportHtml).show();
        notifyImageDiagnosisInChat(file.name, res.predictions, res.mode || 'production', res.warning);
      } else {
        $('#biopsy-status').removeClass('info success').addClass('error').html(
          '<i class="fa-solid fa-triangle-exclamation"></i> ' + escapeHtml(res.message || 'Image analysis failed.')
        ).show();
      }
    },
    error: function (xhr) {
      const msg = xhr.responseJSON ? xhr.responseJSON.message : 'Server upload error.';
      $('#biopsy-status').removeClass('info success').addClass('error').html(
        '<i class="fa-solid fa-triangle-exclamation"></i> ' + escapeHtml(msg)
      ).show();
    }
  });
}

window.handleBiopsyUpload = handleBiopsyUpload;

