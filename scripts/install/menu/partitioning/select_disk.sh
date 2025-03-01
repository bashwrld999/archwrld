#!/bin/bash

selectDiskMenu() {
  items=$(lsblk -dplnx size -o NAME,SIZE -e 7,11 | tac)
  options=()
  IFS_ORIG=$IFS
  IFS=$'\n'
  for item in ${items}
  do
    options+=("${item}" "")
  done
  IFS=$IFS_ORIG
  diskOption=$(whiptail --backtitle "$whipTitle" --title "Select your disk" --cancel-button "Back" --menu "" 0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
  if [ ! "$?" = "0" ]; then
    return 1
  fi
  DISK=${diskOption%%\ *}
}