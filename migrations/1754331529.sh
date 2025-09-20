echo "Update Waybar for new ArchWRLD menu"

if ! grep -q "" ~/.config/waybar/config.jsonc; then
  archwrld-refresh-waybar
fi
