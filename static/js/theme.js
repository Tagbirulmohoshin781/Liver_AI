/* =============================================================================
   static/js/theme.js — Dynamic Theme Engine, Accent Swatches & Font Scaling
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
    '--bg-input': '#181818',
    '--bg-hover': '#242424',
    '--border': '#2a2a2a',
    '--text-primary': '#ffffff',
    '--text-secondary': '#a0a0a0',
    '--text-muted': '#666666',
    '--user-bubble': '#181818'
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
  dark: 'Dark Mode',
  oled: 'OLED Pure Black',
  midnight: 'Midnight Blue',
  nordic: 'Nordic Slate',
  cyberpunk: 'Cyberpunk Neon',
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

  // Highlight active theme preset pill
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
  const px = parseInt(sizePx, 10) || 16;
  document.documentElement.style.fontSize = px + 'px';
  $('#font-size-val-mobile').text(px + 'px');
  if (!skipSave) saveSettings();
}

function applyAccentColor(accentColor, hoverColor, glowColor, colorName, skipSave) {
  document.documentElement.style.setProperty('--accent', accentColor);
  document.documentElement.style.setProperty('--accent-hover', hoverColor || accentColor);
  document.documentElement.style.setProperty('--accent-glow', glowColor || 'rgba(16,163,127,0.15)');
  localStorage.setItem('liverAI_accentName', colorName || 'teal');

  // Highlight active swatch UI if element exists
  $('.color-swatch').removeClass('active');
  if (colorName && colorName !== 'custom') {
    $(`#swatch-${colorName}`).addClass('active');
  }

  if (!skipSave) saveSettings();
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
    }
    if (s.temperature) {
      $('#setting-temp-range').val(s.temperature);
      $('#setting-temp-val').text(s.temperature + ' (Low / Factual)');
    }
  } catch (e) { }
}

function saveSettings() {
  const accentName = localStorage.getItem('liverAI_accentName') || 'teal';
  const settingsObj = {
    lightMode: currentThemeMode === 'light',
    themeMode: currentThemeMode,
    fontSize: $('#font-size-range-mobile').val(),
    style: currentStyle,
    temperature: parseFloat($('#setting-temp-range').val() || 0.25),
    accent: {
      color: getComputedStyle(document.documentElement).getPropertyValue('--accent').trim(),
      hover: getComputedStyle(document.documentElement).getPropertyValue('--accent-hover').trim(),
      glow: getComputedStyle(document.documentElement).getPropertyValue('--accent-glow').trim(),
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

function adjustColor(hex, amt) {
  let usePound = false;
  if (hex[0] === '#') { hex = hex.slice(1); usePound = true; }
  const num = parseInt(hex, 16);
  let r = (num >> 16) + amt;
  if (r > 255) r = 255; else if (r < 0) r = 0;
  let b = ((num >> 8) & 0x00FF) + amt;
  if (b > 255) b = 255; else if (b < 0) b = 0;
  let g = (num & 0x0000FF) + amt;
  if (g > 255) g = 255; else if (g < 0) g = 0;
  return (usePound ? '#' : '') + (g | (b << 8) | (r << 16)).toString(16);
}

function hexToRgba(hex, alpha) {
  hex = hex.replace('#', '');
  if (hex.length === 3) hex = hex.split('').map(c => c + c).join('');
  const num = parseInt(hex, 16);
  return `rgba(${(num >> 16) & 255}, ${(num >> 8) & 255}, ${num & 255}, ${alpha})`;
}

// Global Window Exports
window.applyTheme = applyTheme;
window.applyFontSize = applyFontSize;
window.applyAccentColor = applyAccentColor;
window.setResponseStyle = setResponseStyle;
window.loadSettings = loadSettings;
window.saveSettings = saveSettings;
window.openSettings = openSettings;
window.adjustColor = adjustColor;
window.hexToRgba = hexToRgba;

