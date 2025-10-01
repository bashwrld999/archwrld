# Set links for Nautilius action icons
sudo ln -snf /usr/share/icons/Adwaita/symbolic/actions/go-previous-symbolic.svg /usr/share/icons/Yaru/scalable/actions/go-previous-symbolic.svg
sudo ln -snf /usr/share/icons/Adwaita/symbolic/actions/go-next-symbolic.svg /usr/share/icons/Yaru/scalable/actions/go-next-symbolic.svg

# Setup theme links
mkdir -p ~/.config/archwrld/themes
for f in ~/.local/share/archwrld/themes/*; do ln -nfs "$f" ~/.config/archwrld/themes/; done

# Set initial theme
mkdir -p ~/.config/archwrld/current
ln -snf ~/.config/archwrld/themes/horizon ~/.config/archwrld/current/theme
ln -snf ~/.config/archwrld/current/theme/backgrounds/1-rose-pine.png ~/.config/archwrld/current/background

# Set specific app links for current theme
ln -snf ~/.config/archwrld/current/theme/neovim.lua ~/.config/nvim/lua/plugins/theme.lua

mkdir -p ~/.config/btop/themes
ln -snf ~/.config/archwrld/current/theme/btop.theme ~/.config/btop/themes/current.theme

mkdir -p ~/.config/mako
ln -snf ~/.config/archwrld/current/theme/mako.ini ~/.config/mako/config

mkdir -p ~/.config/eza
ln -snf ~/.config/archwrld/current/theme/eza.yml ~/.config/eza/theme.yml

# Add managed policy directories for Chromium and Brave for theme changes
sudo mkdir -p /etc/chromium/policies/managed
sudo chmod a+rw /etc/chromium/policies/managed

sudo mkdir -p /etc/brave/policies/managed
sudo chmod a+rw /etc/brave/policies/managed
