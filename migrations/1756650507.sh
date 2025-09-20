echo "Fix JetBrains font setting"

if [[ $(archwrld-font-current) == JetBrains* ]]; then
  archwrld-font-set "JetBrainsMono Nerd Font"
fi
