# Install all base packages
mapfile -t packages < <(grep -v '^#' "$ARCHWRLD_INSTALL/archwrld-base.packages" | grep -v '^$')
sudo pacman -S --noconfirm --needed "${packages[@]}"
