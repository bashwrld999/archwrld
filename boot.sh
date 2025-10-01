#!/bin/bash

# Set install mode to online since boot.sh is used for curl installations
export ARCHWRLD_ONLINE_INSTALL=true

ansi_art='
 █████╗ ██████╗  ██████╗██╗  ██╗██╗    ██╗██████╗ ██╗     ██████╗ 
██╔══██╗██╔══██╗██╔════╝██║  ██║██║    ██║██╔══██╗██║     ██╔══██╗
███████║██████╔╝██║     ███████║██║ █╗ ██║██████╔╝██║     ██║  ██║
██╔══██║██╔══██╗██║     ██╔══██║██║███╗██║██╔══██╗██║     ██║  ██║
██║  ██║██║  ██║╚██████╗██║  ██║╚███╔███╔╝██║  ██║███████╗██████╔╝
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚══════╝╚═════╝ '

clear
echo -e "\n$ansi_art\n"

sudo pacman -Syu --noconfirm --needed git

# Use custom repo if specified, otherwise default to bashwrld999/archwrld
ARCHWRLD_REPO="${ARCHWRLD_REPO:-bashwrld999/archwrld}"

echo -e "\nCloning ArchWRLD from: https://github.com/${ARCHWRLD_REPO}.git"
rm -rf ~/.local/share/archwrld/
git clone "https://github.com/${ARCHWRLD_REPO}.git" ~/.local/share/archwrld >/dev/null

# Use custom branch if instructed, otherwise default to master
ARCHWRLD_REF="${ARCHWRLD_REF:-master}"
if [[ $ARCHWRLD_REF != "master" ]]; then
  echo -e "\e[32mUsing branch: $ARCHWRLD_REF\e[0m"
  cd ~/.local/share/archwrld
  git fetch origin "${ARCHWRLD_REF}" && git checkout "${ARCHWRLD_REF}"
  cd -
fi

echo -e "\nInstallation starting..."
source ~/.local/share/archwrld/install.sh
