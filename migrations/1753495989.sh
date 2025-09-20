echo "Allow updating of timezone by right-clicking on the clock (or running archwrld-cmd-tzupdate)"

if archwrld-cmd-missing tzupdate; then
  bash "$ARCHWRLD_PATH/install/config/timezones.sh"
  archwrld-refresh-waybar
fi
