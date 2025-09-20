echo "Add the new ristretto theme as an option"

if [[ ! -L ~/.config/archwrld/themes/ristretto ]]; then
  ln -nfs ~/.local/share/archwrld/themes/ristretto ~/.config/archwrld/themes/
fi
