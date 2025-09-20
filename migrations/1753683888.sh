echo "Adding ArchWRLD version info to fastfetch"
if ! grep -q "archwrld" ~/.config/fastfetch/config.jsonc; then
  cp ~/.local/share/archwrld/config/fastfetch/config.jsonc ~/.config/fastfetch/
fi

