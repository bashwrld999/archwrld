echo "Make new Osaka Jade theme available as new default"

if [[ ! -L ~/.config/archwrld/themes/osaka-jade ]]; then
  rm -rf ~/.config/archwrld/themes/osaka-jade
  git -C ~/.local/share/archwrld checkout -f themes/osaka-jade
  ln -nfs ~/.local/share/archwrld/themes/osaka-jade ~/.config/archwrld/themes/osaka-jade
fi
