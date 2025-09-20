echo "Update Waybar CSS to dim unused workspaces"

if ! grep -q "#workspaces button\.empty" ~/.config/waybar/style.css; then
  archwrld-refresh-config waybar/style.css
  archwrld-restart-waybar
fi
