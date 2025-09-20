# Copy over ArchWRLD configs
mkdir -p ~/.config
cp -R ~/.local/share/archwrld/config/* ~/.config/

# Use default bashrc from ArchWRLD
cp ~/.local/share/archwrld/default/bashrc ~/.bashrc
