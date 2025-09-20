echo "Add new matte black theme"

if [[ ! -L "~/.config/archwrld/themes/matte-black" ]]; then
  ln -snf ~/.local/share/archwrld/themes/matte-black ~/.config/archwrld/themes/
fi
