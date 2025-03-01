#!/bin/bash

srcDir=$(dirname "$(realpath "$0")")
source "${srcDir}/global_fn.sh"
if [ $? -ne 0 ]; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

formatPartitionsMenu() {
  if [[ -z "$BOOT_PARTITION" || -z "$ROOT_PARTITION" ]]; then
    return 1
  fi

  options=()
  options+=("Format partitions" "")
  options+=("Mount and Install" "")
  result=$(whiptail --backtitle "${whipTitle}" --title "Format and Install" --menu "" 0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
  if [ ! "$?" = "0" ]; then
    unset bootPartition
    unset rootPartition
    unset swapPartition
    return 1
  fi
  case "$result" in
  "Format partitions")
    if (whiptail --backtitle "${whipTitle}" --title "Format partitions" \
      --yesno "Are you sure you want to format these partitions?\nAll data on selected partitions will be erased!" --defaultno 0 0); then

      setupBootPartition
      local bootExitCode="$?"
      setupRootPartition
      local rootExitCode="$?"
      if [[ -n "$SWAP_PARTITION" && "$SWAP_PARTITION" != "none" ]]; then
        setupSwapPartition
      fi
      if [[ ! "$bootExitCode" = "0" && ! "$rootExitCode" = "0" ]]; then
        return 3
      else
        configurationMenuScript
        if [ ! "$?" = "0" ]; then
          return 3
        fi
        return 2
      fi
    fi
    ;;
  "Mount and Install")
    configurationMenuScript
    if [ ! "$?" = "0" ]; then
      return 3
    fi
    return 2
    ;;
  esac
}

setupBootPartition() {
  umount -R /mnt &>/dev/null
  options=()
  options+=("fat32" "(recommended)")
  options+=("ext4" "")
  result=$(whiptail --backtitle "${whipTitle}" --title "Format boot partition" --menu "Select partition format for boot ($bootPartition):" 0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
  if [ ! "$?" = "0" ]; then
    return 1
  fi
  case "$result" in
  "fat32")
    mkfs.vfat -F32 -n "BOOT" "${bootPartition}"
    ;;
  "ext4")
    yes | mkfs.ext4 -L "BOOT" "${bootPartition}"
    ;;
  esac
}

setupRootPartition() {
  umount -R /mnt &>/dev/null
  options=()
  options+=("ext4" "(recommended)")
  options+=("btrfs" "")
  options+=("xfs" "")
  result=$(whiptail --backtitle "${whipTitle}" --title "Format root partition" --menu "Select partition format for root ($rootPartition):" 0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
  if [ ! "$?" = "0" ]; then
    return 1
  fi
  case "$result" in
  "ext4")
    yes | mkfs.ext4 -L "ROOT" "${rootPartition}"
    ;;
  "btrfs")
    mkfs.btrfs -L "ROOT" -f "${rootPartition}"
    ;;
  "xfs")
    mkfs.xfs -L "ROOT" -f "${rootPartition}"
    ;;
  esac
}

setupSwapPartition() {
  umount -R /mnt &>/dev/null
  options=()
  options+=("swap" "")
  result=$(whiptail --backtitle "${whipTitle}" --title "Format swap partition" --menu "Select partition format for swap ($swapPartition):" 0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
  if [ ! "$?" = "0" ]; then
    return 1
  fi
  case "$result" in
  "swap")
    mkswap -L "SWAP" "${swapPartition}"
    ;;
  esac
}
