echo "Add minimal starship prompt to terminal"

if archwrld-cmd-missing starship; then
  archwrld-pkg-add starship
  cp $ARCHWRLD_PATH/config/starship.toml ~/.config/starship.toml
fi
