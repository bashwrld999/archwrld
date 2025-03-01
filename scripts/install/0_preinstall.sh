#!/usr/bin/env bash
#|---/ /+-------------------------------------+---/ /|#
#|--/ /-|                                     |--/ /-|#
#|-/ /--| BashWRLD999                         |-/ /--|#
#|/ /---+-------------------------------------+/ /---|#

srcDir=$(dirname "$(realpath "$0")")
source "${srcDir}/global_fn.sh"
if [ $? -ne 0 ]; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

echo -ne "
--------------------------------------------------------------------
                      Installing Prerequisites
--------------------------------------------------------------------
"
# pacman -S --noconfirm --needed archlinux-keyring gptfdisk grub btrfs-progs xfsprogs dosfstools e2fsprogs

# mkdir /mnt
# swapoff -a
# umount -R
unset bootPartition
unset rootPartition
unset swapPartition
unset swapType
unset hibernateType

source "$srcDir/menu/mainmenu.sh"

if [[ -z "$bootPartition" ]] || [[ -z "$rootPartition" ]]; then
  source $srcDir/install/functions/exit.sh
fi
