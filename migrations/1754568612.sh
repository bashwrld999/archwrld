echo "Update Waybar config to fix path issue with update-available icon click"

if grep -q "alacritty --class ArchWRLD --title ArchWRLD -e archwrld-update" ~/.config/waybar/config.jsonc; then
  sed -i 's|\("on-click": "alacritty --class ArchWRLD --title ArchWRLD -e \)archwrld-update"|\1archwrld-update"|' ~/.config/waybar/config.jsonc
  archwrld-restart-waybar
fi
