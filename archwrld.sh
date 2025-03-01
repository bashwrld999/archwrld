#!/usr/bin/env bash
#|---/ /+--------------------------+---/ /|#
#|--/ /-| Main installation script |--/ /-|#
#|-/ /--| BashWRLD999              |-/ /--|#
#|/ /---+--------------------------+/ /---|#

echo -ne "
------------------------------------------------------------
                     _ __          _______  _      _____  
      /\            | |\ \        / /  __ \| |    |  __ \ 
     /  \   _ __ ___| |_\ \  /\  / /| |__) | |    | |  | |
    / /\ \ | '__/ __| '_ \ \/  \/ / |  _  /| |    | |  | |
   / ____ \| | | (__| | | \  /\  /  | | \ \| |____| |__| |
  /_/    \_\_|  \___|_| |_|\/  \/   |_|  \_\______|_____/ 
------------------------------------------------------------
"

#--------------------------------#
# import variables and functions #
#--------------------------------#
scrDir=$(dirname "$(realpath "$0")")
source "${scrDir}/scripts/install/global_fn.sh"
if [ $? -ne 0 ]; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

while getopts idrs RunStep; do
  case $RunStep in
  i) flg_Install=1 ;;
  d)
    flg_Install=1
    export use_default="--noconfirm"
    ;;
  r) flg_Restore=1 ;;
  s) flg_Service=1 ;;
  *)
    echo "...valid options are..."
    echo "i : [i]nstall hyprland without configs"
    echo "d : install hyprland [d]efaults without configs --noconfirm"
    echo "r : [r]estore config files"
    echo "s : enable system [s]ervices"
    exit 1
    ;;
  esac
done

if [ $OPTIND -eq 1 ]; then
  if ! pkg_installed libnewt; then
    sudo pacman --noconfirm -S libnewt
  fi

  options=()
  options+=("Install Arch" "")
  options+=("Install Arch without Configs" "")
  options+=("Restore Config Files" "")
  options+=("Enable System Services" "")
  options+=("Configure" "")
  sel=$(whiptail --backtitle "$whipTitle" --title "Main Menu" --menu "" --cancel-button "Exit" 0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)

  case ${sel} in
  "Install Arch")
    flg_Install=1
    flg_Restore=1
    flg_Service=1
    ;;
  "Install Arch without Configs")
    flg_Install=1
    flg_Service=1
    ;;
  "Restore Config Files")
    flg_Restore=1
    ;;
  "Enable System Services")
    flg_Service=1
    ;;
  "Configure")
    echo Config
    ;;
  esac
fi

#--------------------#
# permissions        #
#--------------------#
chmod -R +x "${scrDir}/scripts/install"

#--------------------#
# pre-install script #
#--------------------#
if [ ${flg_Install} -eq 1 ] && [ ${flg_Restore} -eq 1 ]; then
  echo -ne "
                  _         _       _ _
   ___ ___ ___   |_|___ ___| |_ ___| | |
  | . |  _| -_|  | |   |_ -|  _| .'| | |
  |  _|_| |___|  |_|_|_|___|_| |__,|_|_|
  |_|

"

  "${scrDir}/scripts/install/0_preinstall.sh"
fi
