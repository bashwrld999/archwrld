#!/bin/bash

displayWarning() {
  whiptail --backtitle "$whipTitle" --title "$1" --yesno "Selected device: "$2"\n\nALL DATA WILL BE ERASED!\n\nContinue?" --defaultno 0 0 3>&1 1>&2 2>&3
  return "$?"
}

partitionDiskMenu() {
  options=()
  if [[ ! -d "/sys/firmware/efi" ]]; then
    options+=("Auto Partitions (gpt)" "")
  else
    options+=("Auto Partitions (gpt,efi)" "")
  fi
  options+=("Edit Partitions manually (cfdisk)" "")
  options+=("Edit Partitions manually (cgdisk)" "")

  partitionOption=$(whiptail --backtitle "$whipTitle" --title "Disk Partitions" --cancel-button "Back" --menu "" 0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
  if [ ! "$?" = "0" ]; then
    return 1
  fi
  selectDiskMenu
  if [ ! "$?" = "0" ]; then
    return 3
  fi
  case ${partitionOption} in
  "Auto Partitions (gpt)")
    menuFlow selectSwapOption selectHibernateOption
    if [ "$?" == "1" ]; then
      return 3
    fi
    if (displayWarning "Auto Partitions (gpt)" "$DISK"); then
      partitionDisks
    fi
    ;;
  "Auto Partitions (gpt,efi)")
    menuFlow selectSwapOption selectHibernateOption
    if [ "$?" == "1" ]; then
      return 3
    fi
    if (displayWarning "Auto Partitions (gpt,efi)" "$DISK"); then
      partitionDisks efi
    fi
    ;;
  "Edit Partitions manually (cfdisk)")
    cfdisk ${DISK}
    menu selectPartitionMenu "$DISK"
    return "$?"
    ;;
  "Edit Partitions manually (cgdisk)")
    cgdisk ${DISK}
    menu selectPartitionMenu "$DISK"
    return "$?"
    ;;
  esac

  if [[ ! -z "$bootPartitionNum" ]] && [[ ! -z "$rootPartitionNum" ]]; then
    if [[ ${DISK} =~ "nvme" ]]; then
      bootPartition="${DISK}p${bootPartitionNum}"
      rootPartition="${DISK}p${rootPartitionNum}"
      [[ -n "$swapPartitionNum" ]] && SWAP_PARTITION="${DISK}p${swapPartitionNum}"
    else
      bootPartition="${DISK}${bootPartitionNum}"
      rootPartition="${DISK}${rootPartitionNum}"
      [[ -n "$swapPartitionNum" ]] && SWAP_PARTITION="${DISK}${swapPartitionNum}"
    fi
    menu formatPartitionsMenu
    return "$?"
  fi
}

# $1 either efi or bios
# It will automatically create a swap partition if user chose swap partition
partitionDisks() {
  sgdisk -Z ${DISK}         # zap all on disk
  sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

  bootPartitionNum=1
  rootPartitionNum=2
  unset swapPartitionNum

  if [[ "$1" != "efi" ]]; then
    sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK} # partition 1 (BIOS Boot Partition)
    bootPartitionNum=2
    rootPartitionNum=3
  fi

  sgdisk -n ${bootPartitionNum}::+512M --typecode=${bootPartitionNum}:ef00 --change-name=${bootPartitionNum}:'BOOT' ${DISK} # partition 1 (Boot Partition)
  if [[ -n "$swapType" && "$swapType" == "partition" ]]; then
    swapSize=$(getSwapSpace)
    if [ $swapSize -gt 0 ]; then
      sgdisk -n ${rootPartitionNum}::+${swapSize}M --typecode=${rootPartitionNum}:8200 --change-name=${rootPartitionNum}:'SWAP' ${DISK} # partition 2 (Swap)
      swapPartitionNum=${rootPartitionNum}
      rootPartitionNum=$((rootPartitionNum + 1))
    fi
  fi
  sgdisk -n ${rootPartitionNum}::-0 --typecode=${rootPartitionNum}:8300 --change-name=${rootPartitionNum}:'ROOT' ${DISK} # partition 2 (Root), default start, remaining
}
