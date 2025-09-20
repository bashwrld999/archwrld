echo "Switch to ArchWRLD Chromium for synchronized theme switching"

if archwrld-cmd-present chromium; then
  set_theme_colors() {
    if [[ -f ~/.config/archwrld/current/theme/chromium.theme ]]; then
      chromium --no-startup-window --set-theme-color="$(<~/.config/archwrld/current/theme/chromium.theme)"
    else
      # Use a default, neutral grey if theme doesn't have a color
      chromium --no-startup-window --set-theme-color="28,32,39"
    fi
  }

  archwrld-pkg-drop chromium
  archwrld-pkg-add archwrld-chromium

  if pgrep -x chromium; then
    if gum confirm "Chromium must be restarted. Ready?"; then
      pkill -x chromium
      set_theme_colors
    fi
  else
    set_theme_colors
  fi
fi
