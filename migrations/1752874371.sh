echo "Add Catppuccin Latte light theme"

if [[ ! -L "~/.config/archwrld/themes/catppuccin-latte" ]]; then
  ln -snf ~/.local/share/archwrld/themes/catppuccin-latte ~/.config/archwrld/themes/
fi
