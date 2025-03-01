#!/bin/bash

showDiskMenu=true
selectPartitionMenu() {
  if [[ -n "${1}" ]]; then
    DISK="${1}"
  elif [ "$showDiskMenu" == true ]; then
    selectDiskMenu
    if [ ! "$?" = "0" ]; then
      return 1
    fi
  fi

  showDiskMenu=true
  unsetAllVariables

  bootPartition="$(selectSpecificPartitionMenu boot)"
  if [ ! "$?" = "0" ]; then
    return 1
  fi

  rootPartition="$(selectSpecificPartitionMenu root)"
  if [ ! "$?" = "0" ]; then
    showDiskMenu=false
    return 3
  fi

  menu selectSwapPartitionMenu
  if [ ! "$?" = "0" ]; then
    showDiskMenu=false
    return 3
  fi

  msg="Selected devices:\n\n"
	msg="${msg}boot: ${bootPartition}\n"
	msg="${msg}root: ${rootPartition}\n"
	msg="${msg}swap: ${SWAP_OPTION}\n\n"
  msg="${msg}Continue?"
  if (whiptail --backtitle "$TITLE" --title "Install" --yesno "$msg" --defaultno 0 0); then
    menu formatPartitionsMenu
    return "$?"
  else
    unsetAllVariables
    return 1
  fi
}

selectSpecificPartitionMenu() {
  items=$(lsblk -pln -o NAME,SIZE -e 7,11 "$DISK")
  options=()
  IFS_ORIG=$IFS
  IFS=$'\n'
  for item in ${items}
  do
    if [[ "${item%%\ *}" == "$DISK" ]]; then
      continue
    fi
    options+=("$item" "")
  done
  IFS=$IFS_ORIG

  result=$(whiptail --backtitle "$TITLE" --title "Select Partitions" --cancel-button "Back" --menu "Select $1 device:" 0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
  if [ ! "$?" = "0" ]; then
    unsetAllVariables
    return 1
  fi
  echo "${result%%\ *}"
}

selectSwapPartitionMenu() {
  SWAP_OPTION="none"
  menu selectSwapOption
  if [ "$?" == "1" ]; then
    unsetAllVariables
    return 1
  fi
  if [ "$SWAP_TYPE" == "partition" ]; then
    if [ -z "$DISK" ]; then
      selectDiskMenu
    fi
    SWAP_PARTITION="$(selectSpecificPartitionMenu swap)"
    if [ ! "$?" = "0" ]; then
      unsetAllVariables
      return 3
    fi
    SWAP_OPTION="$SWAP_PARTITION"
  fi


  if [[ -z "$SWAP_PARTITION" && "$SWAP_TYPE" == "file" && "$1" != "swapOnly" ]]; then
    menu selectHibernateOption
    if [ "$?" == "1" ]; then
      unsetAllVariables
      return 3
    fi
    if [ "$HIBERNATE_TYPE" == "hibernate" ]; then
      SWAP_OPTION="Swap File (with Hibernation)"
    else
      SWAP_OPTION="Swap File (without Hibernation)"
    fi
  fi
}

unsetAllVariables() {
  unset bootPartition
  unset rootPartition
  unset swapPartition
}