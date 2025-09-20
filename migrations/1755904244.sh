echo "Update fastfetch config with new ArchWRLD logo"

archwrld-refresh-config fastfetch/config.jsonc

mkdir -p ~/.config/archwrld/branding
cp $ARCHWRLD_PATH/icon.txt ~/.config/archwrld/branding/about.txt
