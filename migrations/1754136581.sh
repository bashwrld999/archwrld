echo "Start screensaver automatically after 1 minute and stop before locking"

if ! grep -q "archwrld-launch-screensaver" ~/.config/hypr/hypridle.conf; then
  archwrld-refresh-hypridle
  archwrld-refresh-hyprlock
fi
