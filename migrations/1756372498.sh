echo "Add eza themeing"

mkdir -p ~/.config/eza

if [ -f ~/.config/archwrld/current/theme/eza.yml ]; then
  ln -snf ~/.config/archwrld/current/theme/eza.yml ~/.config/eza/theme.yml
fi

