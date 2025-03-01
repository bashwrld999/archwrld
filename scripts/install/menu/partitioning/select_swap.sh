#!/bin/bash

srcDir=$(dirname "$(realpath "$0")")

selectSwapOption() {
  unset swapType
  unset hibernateType

  if [ -f "$srcDir/install.conf" ]; then
    sed -i '/^swapType=/d' "$srcDir/install.conf"
  fi

  options=()
  options+=("none" "")
  options+=("Swap File" "(recommended)")
  options+=("Swap Partition" "")
  result=$(whiptail --backtitle "${whipTitle}" --title "Select Swap Option" --menu "" --default-item "Swap File" 0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
  if [ ! "$?" = "0" ]; then
    return 1
  fi
  case "$result" in
  "none")
    unset swapType
    unset hibernateType
    return 2
    ;;
  "Swap Partition")
    SWAP_TYPE="partition"
    ;;
  "Swap File")
    SWAP_TYPE="file"
    ;;
  esac
}

selectHibernateOption() {
  unset hibernateType
  if [ -f "$srcDir/install.conf" ]; then
    sed -i '/^hibernateType=/d' "$srcDir/install.conf"
  fi
  options=()
  options+=("without Hibernate" "")
  options+=("with Hibernate" "")
  result=$(whiptail --backtitle "${whipTitle}" --title "Select Hibernate Option" --cancel-button "Back" --menu "" 0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
  if [ ! "$?" = "0" ]; then
    return 1
  fi
  case "$result" in
  "without Hibernate") ;;
  "with Hibernate")
    hibernateType="hibernate"
    ;;
  esac
}

# returning the swap size in MiB
getSwapSpace() {
  local disk="$rootPartition"
  [ -z "$disk" ] && disk="$DISK"
  availableSpace=$(lsblk -dnb -o SIZE "$disk")
  spaceThreshold=$((availableSpace * 10 / 100))
  totalMemory=$(awk '/^MemTotal/ {print $2}' /proc/meminfo)
  totalMemory=$((totalMemory * 1024))
  swapSize=0
  GiB4=$((4 * 1024 * 1024 * 1024))
  GiB8=$((${GiB4} * 2))
  if [ "$totalMemory" -lt "${GiB4}" ]; then
    swapSize=$(($totalMemory * 2))
  elif [ "$totalMemory" -lt "${GiB8}" ]; then
    swapSize=${GiB8}
  else
    swapSize=$totalMemory
  fi

  if [ "$hibernateType" != "hibernate" ]; then
    swapSize=$(($swapSize < ${GiB8} ? $swapSize : ${GiB8}))
  fi

  swapSize=$(echo $swapSize | awk '{print int($1*1.1+0.5)}')
  swapSize=$(printf "%.0f\n" "$swapSize")

  if [ "$hibernateType" != "hibernate" ]; then
    swapSize=$(($swapSize > $spaceThreshold ? $spaceThreshold : $swapSize))
  fi

  swapSize=$(echo $swapSize | awk '{print int($1/1024/1024+0.5)}')

  swapSize=$(printf "%.0f\n" "$swapSize")
  echo $swapSize
}
