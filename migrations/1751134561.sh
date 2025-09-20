echo "Add ArchWRLD Package Repository"

archwrld-refresh-pacman-mirrorlist

if ! grep -q "archwrld" /etc/pacman.conf; then
  sudo sed -i '/^\[core\]/i [archwrld]\nSigLevel = Optional TrustAll\nServer = https:\/\/pkgs.archwrld.org\/$arch\n' /etc/pacman.conf
  sudo systemctl restart systemd-timesyncd
  sudo pacman -Syu --noconfirm
fi
