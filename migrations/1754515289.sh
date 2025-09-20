echo "Update and restart Walker to resolve stuck ArchWRLD menu"

sudo pacman -Syu --noconfirm walker-bin
archwrld-restart-walker
