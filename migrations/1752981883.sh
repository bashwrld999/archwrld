echo "Replace wofi with walker as the default launcher"

if archwrld-cmd-missing walker; then
  archwrld-pkg-add walker-bin libqalculate

  archwrld-pkg-drop wofi
  rm -rf ~/.config/wofi

  mkdir -p ~/.config/walker
  cp -r ~/.local/share/archwrld/config/walker/* ~/.config/walker/
fi
