#!/bin/bash

srcDir=$(dirname "$(realpath "$0")")
source "${srcDir}/global_fn.sh"
if [ $? -ne 0 ]; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

source "${srcDir}/menu/menu.sh"

mainmenu() {
  options=()
  options+=("Disk Partitions" "")
  options+=("Select Partitions and Install" "")
  sel=$(whiptail --backtitle "$whipTitle" --title "Main Menu" --menu "" --cancel-button "Exit" 0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
  if [ ! "$?" = "0" ]; then
    return 1
  fi
  case ${sel} in
  "Disk Partitions")
    menu partitionDiskMenu
    exitcode="$?"
    ;;
  "Select Partitions and Install")
    menu selectPartitionMenu
    exitcode="$?"
    ;;
  esac
  if [ "$exitcode" = "2" ]; then
    return 1
  fi
  return 3
}

if [ -f "$srcDir/install.conf" ]; then
  source "$srcDir/install.conf"
fi

if [ ! -z "$bootPartition" ] && [ ! -z "$rootPartition" ]; then
  whiptail --backtitle "$whipTitle" --title "Continue Script" --yesno "Continue the script with the current partition setup?" 0 0
  if [ ! "$?" = "0" ]; then
    unset bootPartition
    unset rootPartition
    unset swapPartition
    sed -i '/bootPartition=/d' "$srcDir/install.conf"
    sed -i '/rootPartition=/d' "$srcDir/install.conf"
    sed -i '/swapPartition=/d' "$srcDir/install.conf"
    menu mainmenu
  fi
else
  menu mainmenu
fi
