echo "Install swayOSD to show volume status"

if archwrld-cmd-missing swayosd-server; then
  archwrld-pkg-add swayosd
  setsid uwsm app -- swayosd-server &>/dev/null &
fi
