echo "Replace volume control GUI with a TUI"

if archwrld-cmd-missing wiremix; then
  archwrld-pkg-add wiremix
  archwrld-pkg-drop pavucontrol
  archwrld-refresh-applications
  archwrld-refresh-waybar
fi
