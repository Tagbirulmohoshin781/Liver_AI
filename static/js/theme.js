/* =============================================================================
   static/js/theme.js — Dynamic Theme Engine, Custom Color Studio & Font Scaling
   ============================================================================= */

var SETTINGS_KEY = window.SETTINGS_KEY || 'liverAI_settings';
let currentStyle = 'easy';
let currentThemeMode = 'dark';

const THEME_PRESETS = {
  dark: {
    '--bg-primary': '#212121',
    '--bg-secondary': '#2f2f2f',
    '--bg-sidebar': '#171717',
    '--bg-input': '#2f2f2f',
    '--bg-hover': '#3a3a3a',
    '--border': '#3f3f3f',
    '--text-primary': '#ececec',
    '--text-secondary': '#8e8ea0',
    '--text-muted': '#6b6b7b',
    '--user-bubble': '#2f2f2f'
  },
  oled: {
    '--bg-primary': '#000000',
    '--bg-secondary': '#0f0f0f',
    '--bg-sidebar': '#050505',
    '--bg-input': '#141414',
    '--bg-hover': '#222222',
    '--border': '#262626',
    '--text-primary': '#ffffff',
    '--text-secondary': '#a0a0a0',
    '--text-muted': '#666666',
    '--user-bubble': '#141414'
  },
  midnight: {
    '--bg-primary': '#0b1329',
    '--bg-secondary': '#111c38',
    '--bg-sidebar': '#070d1e',
    '--bg-input': '#18264a',
    '--bg-hover': '#1e2d56',
    '--border': '#1e293b',
    '--text-primary': '#f1f5f9',
    '--text-secondary': '#94a3b8',
    '--text-muted': '#64748b',
    '--user-bubble': '#18264a'
  },
  nordic: {
    '--bg-primary': '#1e2430',
    '--bg-secondary': '#283040',
    '--bg-sidebar': '#161b24',
    '--bg-input': '#2b3446',
    '--bg-hover': '#343f54',
    '--border': '#3b465c',
    '--text-primary': '#e5e9f0',
    '--text-secondary': '#d8dee9',
    '--text-muted': '#8892b0',
    '--user-bubble': '#2b3446'
  },
  cyberpunk: {
    '--bg-primary': '#120924',
    '--bg-secondary': '#1c0d38',
    '--bg-sidebar': '#0a0418',
    '--bg-input': '#241246',
    '--bg-hover': '#30185c',
    '--border': '#42207a',
    '--text-primary': '#f3e8ff',
    '--text-secondary': '#c084fc',
    '--text-muted': '#8b5cf6',
    '--user-bubble': '#241246'
  },
  emerald: {
    '--bg-primary': '#071813',
    '--bg-secondary': '#0d2820',
    '--bg-sidebar': '#05110d',
    '--bg-input': '#103329',
    '--bg-hover': '#17473a',
    '--border': '#1b5042',
    '--text-primary': '#e6f7f2',
    '--text-secondary': '#86d3bd',
    '--text-muted': '#4e9983',
    '--user-bubble': '#103329'
  },
  rose: {
    '--bg-primary': '#1a0f18',
    '--bg-secondary': '#271725',
    '--bg-sidebar': '#130b12',
    '--bg-input': '#341f31',
    '--bg-hover': '#432840',
    '--border': '#4c2647',
    '--text-primary': '#fae8f5',
    '--text-secondary': '#f0abfc',
    '--text-muted': '#a855f7',
    '--user-bubble': '#341f31'
  },
  sepia: {
    '--bg-primary': '#fbf0d9',
    '--bg-secondary': '#f4e4c1',
    '--bg-sidebar': '#ede0c4',
    '--bg-input': '#ede0c4',
    '--bg-hover': '#e4d3b0',
    '--border': '#d8c49d',
    '--text-primary': '#433422',
    '--text-secondary': '#685338',
    '--text-muted': '#8b7355',
    '--user-bubble': '#ede0c4'
  },
  light: {
    '--bg-primary': '#ffffff',
    '--bg-secondary': '#f8fafc',
    '--bg-sidebar': '#ffffff',
    '--bg-input': '#f1f5f9',
    '--bg-hover': '#e2e8f0',
    '--border': '#cbd5e1',
    '--text-primary': '#0f172a',
    '--text-secondary': '#475569',
    '--text-muted': '#64748b',
    '--user-bubble': '#f1f5f9'
  }
};

const THEME_NAMES = {
  dark: 'Dark (Default)',
  oled: 'OLED Black',
  midnight: 'Midnight Navy',
  nordic: 'Nordic Slate',
  cyberpunk: 'Cyberpunk Neon',
  emerald: 'Emerald Forest',
  rose: 'Rose Pine',
  sepia: 'Warm Sepia',
  light: 'Light Clean'
};

function applyTheme(themeModeInput, skipSave) {
  let mode = 'dark';
  if (typeof themeModeInput === 'boolean') {
    mode = themeModeInput ? 'light' : 'dark';
  } else if (typeof themeModeInput === 'string' && THEME_PRESETS[themeModeInput]) {
    mode = themeModeInput;
  }
  currentThemeMode = mode;

  const preset = THEME_PRESETS[mode] || THEME_PRESETS.dark;
  Object.keys(preset).forEach(key => {
    document.documentElement.style.setProperty(key, preset[key], 'important');
    if (document.body) document.body.style.setProperty(key, preset[key], 'important');
  });

  document.documentElement.setAttribute('data-theme', mode);
  if (document.body) document.body.setAttribute('data-theme', mode);

  // Update active theme indicator badge
  const displayName = THEME_NAMES[mode] || mode;
  $('#active-theme-indicator').html(`<i class="fa-solid fa-circle-check" style="margin-right:4px"></i> ${displayName} Active`);

  // Highlight active theme preset card
  $('.theme-preset-btn').removeClass('active');
  $(`#theme-btn-${mode}`).addClass('active');

  if (!skipSave) saveSettings();
}

// Delegated click handler for theme buttons
$(document).on('click', '.theme-preset-btn', function (e) {
  e.preventDefault();
  const mode = $(this).data('theme') || $(this).attr('id').replace('theme-btn-', '');
  if (mode && THEME_PRESETS[mode]) {
    applyTheme(mode);
  }
});

function applyFontSize(sizePx, skipSave) {
  const px = parseInt(sizePx, 10) || 15;
  document.documentElement.style.fontSize = px + 'px';
  $('#font-size-val-mobile').text(px + 'px');
  if (!skipSave) saveSettings();
}

function adjustColor(hex, amt) {
  if (!hex) return '#10a37f';
  let usePound = false;
  if (hex.startsWith('#')) { hex = hex.slice(1); usePound = true; }
  if (hex.length === 3) {
    hex = hex.split('').map(c => c + c).join('');
  }
  const num = parseInt(hex, 16);
  if (isNaN(num)) return usePound ? '#10a37f' : '10a37f';

  let r = (num >> 16) + amt;
  let g = ((num >> 8) & 0x00ff) + amt;
  let b = (num & 0x0000ff) + amt;

  r = Math.min(255, Math.max(0, r));
  g = Math.min(255, Math.max(0, g));
  b = Math.min(255, Math.max(0, b));

  const rHex = r.toString(16).padStart(2, '0');
  const gHex = g.toString(16).padStart(2, '0');
  const bHex = b.toString(16).padStart(2, '0');

  return (usePound ? '#' : '') + rHex + gHex + bHex;
}

function hexToRgba(hex, alpha) {
  if (!hex) return `rgba(16, 163, 127, ${alpha})`;
  let cleanHex = hex.replace('#', '');
  if (cleanHex.length === 3) {
    cleanHex = cleanHex.split('').map(c => c + c).join('');
  }
  const num = parseInt(cleanHex, 16);
  if (isNaN(num)) return `rgba(16, 163, 127, ${alpha})`;
  const r = (num >> 16) & 255;
  const g = (num >> 8) & 255;
  const b = num & 255;
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

function applyAccentColor(accentColor, hoverColor, glowColor, colorName, skipSave) {
  if (!accentColor) return;
  if (!accentColor.startsWith('#') && !accentColor.startsWith('rgb')) {
    accentColor = '#' + accentColor;
  }

  // Calculate hover & glow automatically if needed
  if (!hoverColor || colorName === 'custom') {
    hoverColor = adjustColor(accentColor, -25);
  }
  if (!glowColor || colorName === 'custom') {
    glowColor = hexToRgba(accentColor, 0.18);
  }

  document.documentElement.style.setProperty('--accent', accentColor, 'important');
  document.documentElement.style.setProperty('--accent-hover', hoverColor || accentColor, 'important');
  document.documentElement.style.setProperty('--accent-glow', glowColor || 'rgba(16,163,127,0.18)', 'important');
  if (document.body) {
    document.body.style.setProperty('--accent', accentColor, 'important');
    document.body.style.setProperty('--accent-hover', hoverColor || accentColor, 'important');
    document.body.style.setProperty('--accent-glow', glowColor || 'rgba(16,163,127,0.18)', 'important');
  }

  localStorage.setItem('liverAI_accentName', colorName || 'teal');
  localStorage.setItem('liverAI_accentColor', accentColor);

  // Update Swatch UI active state
  $('.color-swatch').removeClass('active');
  if (colorName && colorName !== 'custom') {
    $(`#swatch-${colorName}`).addClass('active');
    $('#custom-color-badge').html('<i class="fa-solid fa-palette" style="margin-right:4px"></i> Preset Active');
    $('#custom-color-card').removeClass('active');
  } else {
    // Custom color active
    $('#custom-color-badge').html('<i class="fa-solid fa-wand-magic-sparkles" style="margin-right:4px"></i> Custom Active');
    $('#custom-color-card').addClass('active');
  }

  // Synchronize custom color inputs & preview
  if (accentColor.startsWith('#')) {
    const cleanHex = accentColor.replace('#', '').toUpperCase();
    $('#custom-color-picker').val(accentColor);
    $('#custom-color-hex-input').val(cleanHex);
    $('#custom-color-preview-box').css('background-color', accentColor);
    $('#custom-live-preview-dot').css('background-color', accentColor);
    $('#custom-live-preview-text').css('color', accentColor);
  }

  if (!skipSave) saveSettings();
}

function handleCustomColorInput(hex) {
  if (!hex) return;
  const cleanHex = hex.replace('#', '').toUpperCase();
  $('#custom-color-hex-input').val(cleanHex);
  $('#custom-color-preview-box').css('background-color', hex);
  $('#custom-live-preview-dot').css('background-color', hex);
  $('#custom-live-preview-text').css('color', hex);
  applyAccentColor(hex, adjustColor(hex, -25), hexToRgba(hex, 0.18), 'custom');
}

function handleCustomHexInput(val) {
  if (!val) return;
  let clean = val.replace(/[^0-9A-Fa-f]/g, '');
  if (clean.length === 6 || clean.length === 3) {
    const fullHex = '#' + (clean.length === 3 ? clean.split('').map(c => c + c).join('') : clean);
    $('#custom-color-picker').val(fullHex);
    $('#custom-color-preview-box').css('background-color', fullHex);
    $('#custom-live-preview-dot').css('background-color', fullHex);
    $('#custom-live-preview-text').css('color', fullHex);
    applyAccentColor(fullHex, adjustColor(fullHex, -25), hexToRgba(fullHex, 0.18), 'custom');
  }
}

function handleCustomHexBlur(val) {
  let clean = (val || '').replace(/[^0-9A-Fa-f]/g, '');
  if (clean.length === 3) {
    clean = clean.split('').map(c => c + c).join('');
  }
  if (clean.length !== 6) {
    // Revert to current accent color
    const curr = getComputedStyle(document.documentElement).getPropertyValue('--accent').trim() || '#10a37f';
    $('#custom-color-hex-input').val(curr.replace('#', '').toUpperCase());
  } else {
    $('#custom-color-hex-input').val(clean.toUpperCase());
  }
}

function triggerCustomColorPicker() {
  $('#custom-color-picker').click();
}

function copyCurrentAccentHex() {
  const currentAccent = getComputedStyle(document.documentElement).getPropertyValue('--accent').trim() || '#10a37f';
  if (navigator.clipboard) {
    navigator.clipboard.writeText(currentAccent).then(() => {
      $('#copy-hex-icon').removeClass('fa-copy').addClass('fa-check');
      setTimeout(() => {
        $('#copy-hex-icon').removeClass('fa-check').addClass('fa-copy');
      }, 1500);
    });
  }
}

function setResponseStyle(style, skipSave) {
  currentStyle = style;
  $('.style-pill').removeClass('active');
  $(`.style-pill[onclick*="${style}"]`).addClass('active');
  $(`#pill-${style}-mobile`).addClass('active');
  if (!skipSave) saveSettings();
}

function loadSettings() {
  try {
    const s = JSON.parse(localStorage.getItem(SETTINGS_KEY) || '{}');
    if (s.themeMode && THEME_PRESETS[s.themeMode]) {
      applyTheme(s.themeMode, true);
    } else if (s.lightMode !== undefined) {
      applyTheme(!!s.lightMode, true);
    }
    if (s.fontSize) {
      $('#font-size-range-mobile').val(s.fontSize);
      applyFontSize(s.fontSize, true);
    }
    if (s.style) {
      setResponseStyle(s.style, true);
    }
    if (s.accent) {
      applyAccentColor(s.accent.color, s.accent.hover, s.accent.glow, s.accent.name, true);
      if (s.accent.color && s.accent.color.startsWith('#')) {
        $('#custom-color-picker').val(s.accent.color);
        $('#custom-color-hex-input').val(s.accent.color.replace('#', '').toUpperCase());
        $('#custom-color-preview-box').css('background-color', s.accent.color);
      }
    }
    if (s.temperature) {
      $('#setting-temp-range').val(s.temperature);
      $('#setting-temp-val').text(s.temperature + ' (Low / Factual)');
    }
  } catch (e) { }
}

function saveSettings() {
  const accentName = localStorage.getItem('liverAI_accentName') || 'teal';
  const accentColor = getComputedStyle(document.documentElement).getPropertyValue('--accent').trim() || '#10a37f';
  const settingsObj = {
    lightMode: currentThemeMode === 'light',
    themeMode: currentThemeMode,
    fontSize: $('#font-size-range-mobile').val() || '15',
    style: currentStyle,
    temperature: parseFloat($('#setting-temp-range').val() || 0.25),
    accent: {
      color: accentColor,
      hover: getComputedStyle(document.documentElement).getPropertyValue('--accent-hover').trim() || adjustColor(accentColor, -25),
      glow: getComputedStyle(document.documentElement).getPropertyValue('--accent-glow').trim() || hexToRgba(accentColor, 0.18),
      name: accentName
    }
  };
  localStorage.setItem(SETTINGS_KEY, JSON.stringify(settingsObj));

  // Sync settings to database if authenticated
  if (window.currentUserId) {
    $.ajax({
      url: '/api/user/settings',
      type: 'POST',
      contentType: 'application/json',
      data: JSON.stringify(settingsObj)
    });
  }
}

function openSettings() {
  if (typeof switchTab === 'function') {
    switchTab('settings');
  }
  if (typeof closeSidebar === 'function') {
    closeSidebar();
  }
}

// Global Window Exports
window.applyTheme = applyTheme;
window.applyFontSize = applyFontSize;
window.applyAccentColor = applyAccentColor;
window.handleCustomColorInput = handleCustomColorInput;
window.handleCustomHexInput = handleCustomHexInput;
window.handleCustomHexBlur = handleCustomHexBlur;
window.triggerCustomColorPicker = triggerCustomColorPicker;
window.copyCurrentAccentHex = copyCurrentAccentHex;
window.setResponseStyle = setResponseStyle;
window.loadSettings = loadSettings;
window.saveSettings = saveSettings;
window.openSettings = openSettings;
window.adjustColor = adjustColor;
window.hexToRgba = hexToRgba;


