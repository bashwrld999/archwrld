echo "Install Impala as new wifi selection TUI"

if archwrld-cmd-missing impala; then
  archwrld-pkg-add impala
  archwrld-refresh-waybar
fi
