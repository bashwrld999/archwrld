#!/bin/bash

set -euo pipefail

#------------------------------------------------------------------------------------------------------#
# COLORS
magentabg="\e[1;45m"
yellowbg="\e[1;43m"
yellowl="\e[93m"
greenbg="\e[1;42m"
magenta="\e[35m"
yellow="\e[33m"
bluebg="\e[1;44m"
cyanbg="\e[1;46m"
bwhite="\e[0;97m"
green="\e[32m"
redbg="\e[1;41m"
blue="\e[94m"
cyan="\e[36m"
red="\e[31m"
white="\e[0m"
nc="\e[0m"
# END COLORS
#------------------------------------------------------------------------------------------------------#
# MENU FUNCTIONS
printLogo() {
  echo -e "${blue}
                    -@
                   .##@
                  .####@
                  @#####@
                . *######@            ${white}                     _ __          _______  _      _____  ${blue}
               .##@o@#####@           ${white}      /\            | |\ \        / /  __ \| |    |  __ \ ${blue}
              /############@          ${white}     /  \   _ __ ___| |_\ \  /\  / /| |__) | |    | |  | |${blue}
             /##############@         ${white}    / /\ \ | '__/ __| '_ \ \/  \/ / |  _  /| |    | |  | |${blue}
            @######@**%######@        ${white}   / ____ \| | | (__| | | \  /\  /  | | \ \| |____| |__| |${blue}
           @######\`     %#####o       ${white}  /_/    \_\_|  \___|_| |_|\/  \/   |_|  \_\______|_____/ ${blue}
          @######@       ######%
        -@#######h       ######@.\`
       /#####h**\`\`       \`**%@####@
      @H@*\`                    \`*%#@
     *\`                            \`* ${white}\n\n"
}

title() {
  echo -e "\n\n${magenta}###${nc}----------------------------------------${magenta}[ ${bwhite}$1${nc} ${magenta}]${nc}----------------------------------------${magenta}###\n"
}

select_menu() {
  local title="$1"   # The title passed as the first argument
  shift              # Shift past the title argument
  local options=()   # Array to hold options
  local callbacks=() # Array to hold callback functions
  local choice

  # Parse input arguments: alternating options and callback functions
  while (($# > 0)); do
    options+=("$1")   # Add option to options array
    callbacks+=("$2") # Add callback function to callbacks array
    shift 2           # Shift past the option and its callback
  done

  # Display the title
  title "$title"

  # Display the options to the user
  echo -e "${yellow}  >  Make a selection:${nc}\n"
  for i in "${!options[@]}"; do
    echo -e "     [$((i + 1))]  ${options[$i]}"
  done

  # Prompt the user to enter their choice
  echo -e "\n${blue}  Enter a number: ${nc}\n"
  read -r -p "  ==> " choice
  echo -e ""

  # Validate the input
  if [[ "$choice" =~ ^[0-9]+$ ]]; then
    if [[ "$choice" -ge 1 && "$choice" -le "${#options[@]}" ]]; then
      local selected_option="${options[$((choice - 1))]}"
      local selected_callback="${callbacks[$((choice - 1))]}"

      # Call the selected callback function
      if declare -f "$selected_callback" >/dev/null; then
        # Call the corresponding callback function
        "$selected_callback"
      else
        echo "Callback function '$selected_callback' not defined."
      fi
    else
      invalid
      return 1
    fi
  else
    invalid
    return 1
  fi
}

# END MENU FUNCTIONS
#------------------------------------------------------------------------------------------------------#
# FUNCTIONS
loadConfig() {
  if [ -e $config_file ]; then
    source $config_file
  else
    echo "Config file ${config_file} could not be found."
    exit 1
  fi
}
#------------------------------------------------------------------------------------------------------#
init() {
  init_log_trace "$LOG_TRACE"
  init_log_file "$LOG_FILE" "$ARCHWRLD_LOG_FILE"
  #loadkeys "$KEYS"
}

init_log_trace() {
  local ENABLE="$1"
  if [ "$ENABLE" == "true" ]; then
    set -o xtrace
  fi
}

init_log_file() {
  local ENABLE="$1"
  local FILE="$2"
  if [ "$ENABLE" == "true" ]; then
    exec &> >(tee -a "$FILE")
  fi
}
#------------------------------------------------------------------------------------------------------#
sanitize_variable() {
  local VARIABLE="$1"
  local VARIABLE=$(echo "$VARIABLE" | sed "s/![^ ]*//g")       # remove disabled
  local VARIABLE=$(echo "$VARIABLE" | sed -r "s/ {2,}/ /g")    # remove unnecessary white spaces
  local VARIABLE=$(echo "$VARIABLE" | sed 's/^[[:space:]]*//') # trim leading
  local VARIABLE=$(echo "$VARIABLE" | sed 's/[[:space:]]*$//') # trim trailing
  echo "$VARIABLE"
}

sanitize_variables() {
  DEVICE=$(sanitize_variable "$DEVICE")
  PARTITION_MODE=$(sanitize_variable "$PARTITION_MODE")
  PARTITION_CUSTOM_PARTED_UEFI=$(sanitize_variable "$PARTITION_CUSTOM_PARTED_UEFI")
  PARTITION_CUSTOM_PARTED_BIOS=$(sanitize_variable "$PARTITION_CUSTOM_PARTED_BIOS")
  FILE_SYSTEM_TYPE=$(sanitize_variable "$FILE_SYSTEM_TYPE")
  SWAP_SIZE=$(sanitize_variable "$SWAP_SIZE")
  KERNELS=$(sanitize_variable "$KERNELS")
  KERNELS_COMPRESSION=$(sanitize_variable "$KERNELS_COMPRESSION")
  KERNELS_PARAMETERS=$(sanitize_variable "$KERNELS_PARAMETERS")
  AUR_PACKAGE=$(sanitize_variable "$AUR_PACKAGE")
  DISPLAY_DRIVER=$(sanitize_variable "$DISPLAY_DRIVER")
  DISPLAY_DRIVER_HARDWARE_VIDEO_ACCELERATION_INTEL=$(sanitize_variable "$DISPLAY_DRIVER_HARDWARE_VIDEO_ACCELERATION_INTEL")
  SYSTEMD_HOMED_STORAGE=$(sanitize_variable "$SYSTEMD_HOMED_STORAGE")
  SYSTEMD_HOMED_STORAGE_LUKS_TYPE=$(sanitize_variable "$SYSTEMD_HOMED_STORAGE_LUKS_TYPE")
  BOOTLOADER=$(sanitize_variable "$BOOTLOADER")
  CUSTOM_SHELL=$(sanitize_variable "$CUSTOM_SHELL")
  DESKTOP_ENVIRONMENT=$(sanitize_variable "$DESKTOP_ENVIRONMENT")
  DISPLAY_MANAGER=$(sanitize_variable "$DISPLAY_MANAGER")
  SYSTEMD_UNITS=$(sanitize_variable "$SYSTEMD_UNITS")

  for I in "${BTRFS_SUBVOLUMES_MOUNTPOINTS[@]}"; do
    IFS=',' read -ra SUBVOLUME <<<"$I"
    if [ "${SUBVOLUME[0]}" == "root" ]; then
      BTRFS_SUBVOLUME_ROOT=("${SUBVOLUME[@]}")
    elif [ "${SUBVOLUME[0]}" == "swap" ]; then
      BTRFS_SUBVOLUME_SWAP=("${SUBVOLUME[@]}")
    fi
  done

  for I in "${PARTITION_MOUNT_POINTS[@]}"; do #SC2153
    IFS='=' read -ra PARTITION_MOUNT_POINT <<<"$I"
    if [ "${PARTITION_MOUNT_POINT[1]}" == "/boot" ]; then
      PARTITION_BOOT_NUMBER="${PARTITION_MOUNT_POINT[0]}"
    elif [ "${PARTITION_MOUNT_POINT[1]}" == "/" ]; then
      PARTITION_ROOT_NUMBER="${PARTITION_MOUNT_POINT[0]}"
    fi
  done
}
#------------------------------------------------------------------------------------------------------#
check_variables() {
  check_variables_value "KEYS" "$KEYS"
  check_variables_boolean "LOG_TRACE" "$LOG_TRACE"
  check_variables_boolean "LOG_FILE" "$LOG_FILE"
  check_variables_value "DEVICE" "$DEVICE"
  if [ "$DEVICE" == "auto" ]; then
    local DEVICE_BOOT=$(lsblk -oMOUNTPOINT,PKNAME -P -M | grep 'MOUNTPOINT="/run/archiso/bootmnt"' | sed 's/.*PKNAME="\(.*\)".*/\1/') #SC2155
    if [ -n "$DEVICE_BOOT" ]; then
      local DEVICE_BOOT="/dev/$DEVICE_BOOT"
    fi
    local DEVICE_DETECTED="false"
    if [ -e "/dev/sda" ] && [ "$DEVICE_BOOT" != "/dev/sda" ]; then
      if [ "$DEVICE_DETECTED" == "true" ]; then
        echo "Auto device is ambigous, detected $DEVICE and /dev/sda."
        exit 1
      fi
      DEVICE_DETECTED="true"
      DEVICE_SDA="true"
      DEVICE="/dev/sda"
    fi
    if [ -e "/dev/nvme0n1" ] && [ "$DEVICE_BOOT" != "/dev/nvme0n1" ]; then
      if [ "$DEVICE_DETECTED" == "true" ]; then
        echo "Auto device is ambigous, detected $DEVICE and /dev/nvme0n1."
        exit 1
      fi
      DEVICE_DETECTED="true"
      DEVICE_NVME="true"
      DEVICE="/dev/nvme0n1"
    fi
    if [ -e "/dev/vda" ] && [ "$DEVICE_BOOT" != "/dev/vda" ]; then
      if [ "$DEVICE_DETECTED" == "true" ]; then
        echo "Auto device is ambigous, detected $DEVICE and /dev/vda."
        exit 1
      fi
      DEVICE_DETECTED="true"
      DEVICE_VDA="true"
      DEVICE="/dev/vda"
    fi
    if [ -e "/dev/mmcblk0" ] && [ "$DEVICE_BOOT" != "/dev/mmcblk0" ]; then
      if [ "$DEVICE_DETECTED" == "true" ]; then
        echo "Auto device is ambigous, detected $DEVICE and /dev/mmcblk0."
        exit 1
      fi
      DEVICE_DETECTED="true"
      DEVICE_MMC="true"
      DEVICE="/dev/mmcblk0"
    fi
  fi
  check_variables_boolean "DEVICE_TRIM" "$DEVICE_TRIM"
  check_variables_boolean "LVM" "$LVM"
  check_variables_equals "LUKS_PASSWORD" "LUKS_PASSWORD_RETYPE" "$LUKS_PASSWORD" "$LUKS_PASSWORD_RETYPE"
  check_variables_list "FILE_SYSTEM_TYPE" "$FILE_SYSTEM_TYPE" "ext4 btrfs xfs f2fs reiserfs" "true" "true"
  check_variables_size "BTRFS_SUBVOLUME_ROOT" ${#BTRFS_SUBVOLUME_ROOT[@]} 3
  check_variables_list "BTRFS_SUBVOLUME_ROOT" "${BTRFS_SUBVOLUME_ROOT[2]}" "/" "true" "true"
  if [ -n "$SWAP_SIZE" ]; then
    check_variables_size "BTRFS_SUBVOLUME_SWAP" ${#BTRFS_SUBVOLUME_SWAP[@]} 3
  fi
  for I in "${BTRFS_SUBVOLUMES_MOUNTPOINTS[@]}"; do
    IFS=',' read -ra SUBVOLUME <<<"$I"
    check_variables_size "SUBVOLUME" ${#SUBVOLUME[@]} 3
  done
  check_variables_list "PARTITION_MODE" "$PARTITION_MODE" "auto custom manual" "true" "true"
  check_variables_value "PARTITION_BOOT_NUMBER" "$PARTITION_BOOT_NUMBER"
  check_variables_value "PARTITION_ROOT_NUMBER" "$PARTITION_ROOT_NUMBER"
  check_variables_boolean "GPT_AUTOMOUNT" "$GPT_AUTOMOUNT"
  if [ "$GPT_AUTOMOUNT" == "true" ] && [ "$LVM" == "true" ]; then
    echo "LVM not possible in combination with GPT partition automounting."
    exit 1
  fi
  check_variables_equals "WIFI_KEY" "WIFI_KEY_RETYPE" "$WIFI_KEY" "$WIFI_KEY_RETYPE"
  check_variables_value "PING_HOSTNAME" "$PING_HOSTNAME"
  check_variables_boolean "REFLECTOR" "$REFLECTOR"
  check_variables_value "PACMAN_MIRROR" "$PACMAN_MIRROR"
  check_variables_boolean "PACMAN_PARALLEL_DOWNLOADS" "$PACMAN_PARALLEL_DOWNLOADS"
  check_variables_list "KERNELS" "$KERNELS" "linux-lts linux-lts-headers linux-hardened linux-hardened-headers linux-zen linux-zen-headers" "false" "false"
  check_variables_list "KERNELS_COMPRESSION" "$KERNELS_COMPRESSION" "gzip bzip2 lzma xz lzop lz4 zstd" "false" "true"
  check_variables_list "AUR_PACKAGE" "$AUR_PACKAGE" "paru-bin yay-bin paru yay aurman" "true" "true"
  check_variables_list "DISPLAY_DRIVER" "$DISPLAY_DRIVER" "auto intel amdgpu ati nvidia nvidia-lts nvidia-dkms nvidia-470xx-dkms nvidia-390xx-dkms nvidia-340xx-dkms nouveau" "false" "true"
  check_variables_boolean "KMS" "$KMS"
  check_variables_boolean "FASTBOOT" "$FASTBOOT"
  check_variables_boolean "FRAMEBUFFER_COMPRESSION" "$FRAMEBUFFER_COMPRESSION"
  check_variables_boolean "DISPLAY_DRIVER_DDX" "$DISPLAY_DRIVER_DDX"
  check_variables_boolean "DISPLAY_DRIVER_HARDWARE_VIDEO_ACCELERATION" "$DISPLAY_DRIVER_HARDWARE_VIDEO_ACCELERATION"
  check_variables_list "DISPLAY_DRIVER_HARDWARE_VIDEO_ACCELERATION_INTEL" "$DISPLAY_DRIVER_HARDWARE_VIDEO_ACCELERATION_INTEL" "intel-media-driver libva-intel-driver" "false" "true"
  check_variables_value "TIMEZONE" "$TIMEZONE"
  check_variables_value "LOCALES" "$LOCALES"
  check_variables_value "LOCALE_CONF" "$LOCALE_CONF"
  check_variables_value "KEYMAP" "$KEYMAP"
  check_variables_value "HOSTNAME" "$HOSTNAME"
  check_variables_value "USER_NAME" "$USER_NAME"
  check_variables_value "USER_PASSWORD" "$USER_PASSWORD"
  check_variables_equals "ROOT_PASSWORD" "ROOT_PASSWORD_RETYPE" "$ROOT_PASSWORD" "$ROOT_PASSWORD_RETYPE"
  check_variables_equals "USER_PASSWORD" "USER_PASSWORD_RETYPE" "$USER_PASSWORD" "$USER_PASSWORD_RETYPE"
  check_variables_boolean "SYSTEMD_HOMED" "$SYSTEMD_HOMED"
  check_variables_list "SYSTEMD_HOMED_STORAGE" "$SYSTEMD_HOMED_STORAGE" "auto luks subvolume directory fscrypt cifs" "true" "true"
  check_variables_list "SYSTEMD_HOMED_STORAGE_LUKS_TYPE" "$SYSTEMD_HOMED_STORAGE_LUKS_TYPE" "auto ext4 btrfs xfs" "true" "true"
  if [ "$SYSTEMD_HOMED" == "true" ]; then
    if [ "$SYSTEMD_HOMED_STORAGE" == "fscrypt" ]; then
      check_variables_list "FILE_SYSTEM_TYPE" "$FILE_SYSTEM_TYPE" "ext4 f2fs" "true" "true"
    fi
    if [ "$SYSTEMD_HOMED_STORAGE" == "cifs" ]; then
      check_variables_value "SYSTEMD_HOMED_CIFS[\"domain]\"" "${SYSTEMD_HOMED_CIFS_DOMAIN["domain"]}"
      check_variables_value "SYSTEMD_HOMED_CIFS[\"service\"]" "${SYSTEMD_HOMED_CIFS_SERVICE["size"]}"
    fi
  fi
  check_variables_value "HOOKS" "$HOOKS"
  check_variables_boolean "UKI" "$UKI"
  check_variables_list "BOOTLOADER" "$BOOTLOADER" "auto grub refind systemd efistub" "true" "true"
  check_variables_boolean "SECURE_BOOT" "$SECURE_BOOT"
  check_variables_list "CUSTOM_SHELL" "$CUSTOM_SHELL" "bash zsh dash fish" "true" "true"
  check_variables_list "DESKTOP_ENVIRONMENT" "$DESKTOP_ENVIRONMENT" "hyprland gnome kde xfce mate cinnamon lxde i3-wm i3-gaps deepin budgie bspwm awesome qtile openbox leftwm dusk" "false" "true"
  check_variables_list "DISPLAY_MANAGER" "$DISPLAY_MANAGER" "auto gdm sddm lightdm lxdm" "true" "true"
  check_variables_boolean "PACKAGES_MULTILIB" "$PACKAGES_MULTILIB"
  check_variables_boolean "PACKAGES_INSTALL" "$PACKAGES_INSTALL"
  check_variables_boolean "PROVISION" "$PROVISION"
  check_variables_boolean "VAGRANT" "$VAGRANT"
  check_variables_boolean "REBOOT" "$REBOOT"
}

check_variables_value() {
  local NAME="$1"
  local VALUE="$2"
  if [ -z "$VALUE" ]; then
    echo "$NAME environment variable must have a value."
    exit 1
  fi
}

check_variables_boolean() {
  local NAME="$1"
  local VALUE="$2"
  check_variables_list "$NAME" "$VALUE" "true false" "true" "true"
}

check_variables_list() {
  local NAME="$1"
  local VALUE="$2"
  local VALUES="$3"
  local REQUIRED="$4"
  local SINGLE="$5"

  if [ "$REQUIRED" == "" ] || [ "$REQUIRED" == "true" ]; then
    check_variables_value "$NAME" "$VALUE"
  fi

  if [[ ("$SINGLE" == "" || "$SINGLE" == "true") && "$VALUE" != "" && "$VALUE" =~ " " ]]; then
    echo "$NAME environment variable value [$VALUE] must be a single value of [$VALUES]."
    exit 1
  fi

  if [ "$VALUE" != "" ] && [ -z "$(echo "$VALUES" | grep -F -w "$VALUE")" ]; then #SC2143
    echo "$NAME environment variable value [$VALUE] must be in [$VALUES]."
    exit 1
  fi
}

check_variables_equals() {
  local NAME1="$1"
  local NAME2="$2"
  local VALUE1="$3"
  local VALUE2="$4"
  if [ "$VALUE1" != "$VALUE2" ]; then
    echo "$NAME1 and $NAME2 must be equal [$VALUE1, $VALUE2]."
    exit 1
  fi
}

check_variables_size() {
  local NAME="$1"
  local SIZE_EXPECT="$2"
  local SIZE="$3"
  if [ "$SIZE_EXPECT" != "$SIZE" ]; then
    echo "$NAME array size [$SIZE] must be [$SIZE_EXPECT]."
    exit 1
  fi
}
#------------------------------------------------------------------------------------------------------#
installArch() {
  warning
  facts
  checks
  prepare
  partition
}
#------------------------------------------------------------------------------------------------------#
warning() {
  echo -e "${blue}Welcome to ArchWRLD Install Script${nc}"
  echo ""
  echo -e "${red}Warning"'!'"${nc}"
  echo -e "${red}This script can delete all partitions of the persistent${nc}"
  echo -e "${red}storage and continuing all your data can be lost.${nc}"
  echo ""
  echo -e "Install device: $DEVICE."
  echo -e "Mount points: ${PARTITION_MOUNT_POINTS[*]}."
  echo ""
  if [ "$WARNING_CONFIRM" == "true" ]; then
    read -r -p "Do you want to continue? [y/N] " yn
  else
    yn="y"
    sleep 2
  fi
  case $yn in
  [Yy]*) ;;
  [Nn]*)
    exit 0
    ;;
  *)
    exit 0
    ;;
  esac
}

facts() {
  facts_commons

  if echo "$DEVICE" | grep -q "^/dev/sd[a-z]"; then
    DEVICE_SDA="true" #SC2034
  elif echo "$DEVICE" | grep -q "^/dev/nvme"; then
    DEVICE_NVME="true"
  elif echo "$DEVICE" | grep -q "^/dev/vd[a-z]"; then
    DEVICE_VDA="true"
  elif echo "$DEVICE" | grep -q "^/dev/mmc"; then
    DEVICE_MMC="true"
  fi

  if [ "$DISPLAY_DRIVER" == "auto" ]; then
    case "$GPU_VENDOR" in
    "intel")
      DISPLAY_DRIVER="intel"
      ;;
    "amd")
      DISPLAY_DRIVER="amdgpu"
      ;;
    "nvidia")
      DISPLAY_DRIVER="nvidia"
      ;;
    esac
  fi

  case "$AUR_PACKAGE" in
  "aurman")
    AUR_COMMAND="aurman"
    ;;
  "yay")
    AUR_COMMAND="yay"
    ;;
  "paru")
    AUR_COMMAND="paru"
    ;;
  "yay-bin")
    AUR_COMMAND="yay"
    ;;
  "paru-bin" | *)
    AUR_COMMAND="paru"
    ;;
  esac

  if [ "$BOOTLOADER" == "auto" ]; then
    if [ "$BIOS_TYPE" == "uefi" ]; then
      BOOTLOADER="systemd"
    elif [ "$BIOS_TYPE" == "bios" ]; then
      BOOTLOADER="grub"
    fi
  fi
}

facts_commons() {
  if [ -d /sys/firmware/efi ]; then
    BIOS_TYPE="uefi"
  else
    BIOS_TYPE="bios"
  fi

  if lscpu | grep -q "GenuineIntel"; then
    CPU_VENDOR="intel"
  elif lscpu | grep -q "AuthenticAMD"; then
    CPU_VENDOR="amd"
  else
    CPU_VENDOR=""
  fi

  if lspci -nn | grep "\[03" | grep -qi "intel"; then
    GPU_VENDOR="intel"
  elif lspci -nn | grep "\[03" | grep -qi "amd"; then
    GPU_VENDOR="amd"
  elif lspci -nn | grep "\[03" | grep -qi "nvidia"; then
    GPU_VENDOR="nvidia"
  elif lspci -nn | grep "\[03" | grep -qi "vmware"; then
    GPU_VENDOR="vmware"
  else
    GPU_VENDOR=""
  fi

  if systemd-detect-virt | grep -qi "oracle"; then
    VIRTUALBOX="true"
  else
    VIRTUALBOX="false"
  fi

  if systemd-detect-virt | grep -qi "vmware"; then
    VMWARE="true"
  else
    VMWARE="false"
  fi

  INITRD_MICROCODE=""
  if [ "$VIRTUALBOX" != "true" ] && [ "$VMWARE" != "true" ]; then
    if [ "$CPU_VENDOR" == "intel" ]; then
      INITRD_MICROCODE="intel-ucode.img"
    elif [ "$CPU_VENDOR" == "amd" ]; then
      INITRD_MICROCODE="amd-ucode.img"
    fi
  fi

  USER_NAME_INSTALL="$(whoami)"
  if [ "$USER_NAME_INSTALL" == "root" ]; then
    SYSTEM_INSTALLATION="true"
  else
    SYSTEM_INSTALLATION="false"
  fi
}
#------------------------------------------------------------------------------------------------------#
checks() {
  check_facts
}

check_facts() {
  if [ "$BIOS_TYPE" == "bios" ]; then
    check_variables_list "BOOTLOADER" "$BOOTLOADER" "grub" "true" "true"
  fi

  if [ "$SECURE_BOOT" == "true" ]; then
    check_variables_list "BOOTLOADER" "$BOOTLOADER" "grub refind systemd" "true" "true"
  fi
}
#------------------------------------------------------------------------------------------------------#
prepare() {
  configure_reflector
  configure_time
  prepare_partition
  ask_passwords
  configure_network
}

configure_reflector() {
  if [ "$REFLECTOR" == "false" ]; then
    if systemctl is-active --quiet reflector.service; then
      systemctl stop reflector.service
    fi
  fi
}

configure_time() {
  timedatectl set-ntp true
}

prepare_partition() {
  set +e
  if mountpoint -q "${MNT_DIR}"/boot; then
    umount "${MNT_DIR}"/boot
  fi
  if mountpoint -q "${MNT_DIR}"; then
    umount "${MNT_DIR}"
  fi
  if lvs "$LVM_VOLUME_GROUP"-"$LVM_VOLUME_LOGICAL"; then
    lvchange -an "$LVM_VOLUME_GROUP/$LVM_VOLUME_LOGICAL"
  fi
  if vgs "$LVM_VOLUME_GROUP"; then
    vgchange -an "$LVM_VOLUME_GROUP"
  fi
  if [ -e "/dev/mapper/$LUKS_DEVICE_NAME" ]; then
    if cryptsetup status "$LUKS_DEVICE_NAME " | grep -qi "is active"; then
      cryptsetup close "$LUKS_DEVICE_NAME"
    fi
  fi
  set -e
}

ask_passwords() {
  if [ "$LUKS_PASSWORD" == "ask" ]; then
    ask_password "LUKS" "LUKS_PASSWORD"
  fi

  if [ -n "$WIFI_INTERFACE" ] && [ "$WIFI_KEY" == "ask" ]; then
    ask_password "WIFI" "WIFI_KEY"
  fi

  if [ "$ROOT_PASSWORD" == "ask" ]; then
    ask_password "root" "ROOT_PASSWORD"
  fi

  if [ "$USER_PASSWORD" == "ask" ]; then
    ask_password "user" "USER_PASSWORD"
  fi

  for I in "${!ADDITIONAL_USERS[@]}"; do
    local VALUE=${ADDITIONAL_USERS[$I]}
    local S=()
    IFS='=' read -ra S <<<"$VALUE"
    local USER=${S[0]}
    local PASSWORD=${S[1]}
    local PASSWORD_RETYPE=""

    if [ "$PASSWORD" == "ask" ]; then
      local PASSWORD_TYPED="false"
      while [ "$PASSWORD_TYPED" != "true" ]; do
        read -r -sp "Type user ($USER) password: " PASSWORD
        echo ""
        read -r -sp "Retype user ($USER) password: " PASSWORD_RETYPE
        echo ""
        if [ "$PASSWORD" == "$PASSWORD_RETYPE" ]; then
          local PASSWORD_TYPED="true"
          ADDITIONAL_USERS[I]="$USER=$PASSWORD"
        else
          echo "User ($USER) password don't match. Please, type again."
        fi
      done
    fi
  done
}

ask_password() {
  PASSWORD_NAME="$1"
  PASSWORD_VARIABLE="$2"
  read -r -sp "Type ${PASSWORD_NAME} password: " PASSWORD1
  echo ""
  read -r -sp "Retype ${PASSWORD_NAME} password: " PASSWORD2
  echo ""
  if [[ "$PASSWORD1" == "$PASSWORD2" ]]; then
    declare -n VARIABLE="${PASSWORD_VARIABLE}"
    VARIABLE="$PASSWORD1"
  else
    echo "${PASSWORD_NAME} password don't match. Please, type again."
    ask_password "${PASSWORD_NAME}" "${PASSWORD_VARIABLE}"
  fi
}

configure_network() {
  if [ -n "$WIFI_INTERFACE" ]; then
    iwctl --passphrase "$WIFI_KEY" station "$WIFI_INTERFACE" connect "$WIFI_ESSID"
    sleep 10
  fi

  # only one ping -c 1, ping gets stuck if -c 5
  if ! ping -c 1 -i 2 -W 5 -w 30 "$PING_HOSTNAME"; then
    echo "Network ping check failed. Cannot continue."
    exit 1
  fi
}
#------------------------------------------------------------------------------------------------------#
partition() {
  partprobe -s "$DEVICE"

  # setup
  partition_setup

  # partition
  if [ "$PARTITION_MODE" == "auto" ]; then
    sgdisk --zap-all "$DEVICE"
    sgdisk -o "$DEVICE"
    wipefs -a -f "$DEVICE"
    partprobe -s "$DEVICE"
  fi
  if [ "$PARTITION_MODE" == "auto" ] || [ "$PARTITION_MODE" == "custom" ]; then
    if [ "$BIOS_TYPE" == "uefi" ]; then
      parted -s "$DEVICE" "$PARTITION_PARTED_UEFI"
      if [ -n "$LUKS_PASSWORD" ]; then
        sgdisk -t="$PARTITION_ROOT_NUMBER":8304 "$DEVICE"
      elif [ "$LVM" == "true" ]; then
        sgdisk -t="$PARTITION_ROOT_NUMBER":8e00 "$DEVICE"
      fi
    fi

    if [ "$BIOS_TYPE" == "bios" ]; then
      parted -s "$DEVICE" "$PARTITION_PARTED_BIOS"
    fi

    partprobe -s "$DEVICE"
  fi

  # luks and lvm
  if [ -n "$LUKS_PASSWORD" ]; then
    echo -n "$LUKS_PASSWORD" | cryptsetup --key-size=512 --key-file=- luksFormat --type luks2 "$PARTITION_ROOT"
    echo -n "$LUKS_PASSWORD" | cryptsetup --key-file=- open "$PARTITION_ROOT" "$LUKS_DEVICE_NAME"
    sleep 5
  fi

  if [ "$LVM" == "true" ]; then
    if [ -n "$LUKS_PASSWORD" ]; then
      DEVICE_LVM="/dev/mapper/$LUKS_DEVICE_NAME"
    else
      DEVICE_LVM="$DEVICE_ROOT"
    fi

    if [ "$PARTITION_MODE" == "auto" ]; then
      set +e
      if lvs "$LVM_VOLUME_GROUP"-"$LVM_VOLUME_LOGICAL"; then
        lvremove -y "$LVM_VOLUME_GROUP"/"$LVM_VOLUME_LOGICAL"
      fi
      if vgs "$LVM_VOLUME_GROUP"; then
        vgremove -y "$LVM_VOLUME_GROUP"
      fi
      if pvs "$DEVICE_LVM"; then
        pvremove -y "$DEVICE_LVM"
      fi
      set -e

      pvcreate -y "$DEVICE_LVM"
      vgcreate -y "$LVM_VOLUME_GROUP" "$DEVICE_LVM"
      lvcreate -y -l 100%FREE -n "$LVM_VOLUME_LOGICAL" "$LVM_VOLUME_GROUP"
    fi
  fi

  if [ -n "$LUKS_PASSWORD" ]; then
    DEVICE_ROOT="/dev/mapper/$LUKS_DEVICE_NAME"
  fi
  if [ "$LVM" == "true" ]; then
    DEVICE_ROOT="/dev/mapper/$LVM_VOLUME_GROUP-$LVM_VOLUME_LOGICAL"
  fi

  # format
  if [ "$PARTITION_MODE" != "manual" ]; then
    # Delete patition filesystem in case is reinstalling in an already existing system
    # Not fail on error
    wipefs -a -f "$PARTITION_BOOT" || true
    wipefs -a -f "$DEVICE_ROOT" || true

    ## boot
    if [ "$BIOS_TYPE" == "uefi" ]; then
      mkfs.fat -n ESP -F32 "$PARTITION_BOOT"
    fi
    if [ "$BIOS_TYPE" == "bios" ]; then
      mkfs.ext4 -L boot "$PARTITION_BOOT"
    fi
    ## root
    if [ "$FILE_SYSTEM_TYPE" == "reiserfs" ]; then
      mkfs."$FILE_SYSTEM_TYPE" -f -l root "$DEVICE_ROOT"
    elif [ "$FILE_SYSTEM_TYPE" == "f2fs" ]; then
      mkfs."$FILE_SYSTEM_TYPE" -l root "$DEVICE_ROOT"
    else
      mkfs."$FILE_SYSTEM_TYPE" -L root "$DEVICE_ROOT"
    fi
    ## mountpoint
    for I in "${PARTITION_MOUNT_POINTS[@]}"; do
      if [[ "$I" =~ ^!.* ]]; then
        continue
      fi
      IFS='=' read -ra PARTITION_MOUNT_POINT <<<"$I"
      if [ "${PARTITION_MOUNT_POINT[1]}" == "/boot" ] || [ "${PARTITION_MOUNT_POINT[1]}" == "/" ]; then
        continue
      fi
      local PARTITION_DEVICE="$(partition_device "$DEVICE" "${PARTITION_MOUNT_POINT[0]}")"
      if [ "$FILE_SYSTEM_TYPE" == "reiserfs" ]; then
        mkfs."$FILE_SYSTEM_TYPE" -f "$PARTITION_DEVICE"
      elif [ "$FILE_SYSTEM_TYPE" == "f2fs" ]; then
        mkfs."$FILE_SYSTEM_TYPE" "$PARTITION_DEVICE"
      else
        mkfs."$FILE_SYSTEM_TYPE" "$PARTITION_DEVICE"
      fi
    done
  fi

  # options
  partition_options

  # create
  if [ "$FILE_SYSTEM_TYPE" == "btrfs" ]; then
    # create subvolumes
    mount -o "$PARTITION_OPTIONS" "$DEVICE_ROOT" "${MNT_DIR}"
    for I in "${BTRFS_SUBVOLUMES_MOUNTPOINTS[@]}"; do
      IFS=',' read -ra SUBVOLUME <<<"$I"
      if [ "${SUBVOLUME[0]}" == "swap" ] && [ -z "$SWAP_SIZE" ]; then
        continue
      fi
      btrfs subvolume create "${MNT_DIR}/${SUBVOLUME[1]}"
    done
    umount "${MNT_DIR}"
  fi

  # mount
  partition_mount

  # swap
  if [ -n "$SWAP_SIZE" ]; then
    if [ "$FILE_SYSTEM_TYPE" == "btrfs" ]; then
      SWAPFILE="${BTRFS_SUBVOLUME_SWAP[2]}$SWAPFILE"
      chattr +C "${MNT_DIR}"
      btrfs filesystem mkswapfile --size "${SWAP_SIZE}m" --uuid clear "${MNT_DIR}${SWAPFILE}"
      swapon "${MNT_DIR}${SWAPFILE}"
    else
      dd if=/dev/zero of="${MNT_DIR}$SWAPFILE" bs=1M count="$SWAP_SIZE" status=progress
      chmod 600 "${MNT_DIR}${SWAPFILE}"
      mkswap "${MNT_DIR}${SWAPFILE}"
    fi
  fi

  # set variables
  BOOT_DIRECTORY=/boot
  ESP_DIRECTORY=/boot
  UUID_BOOT=$(blkid -s UUID -o value "$PARTITION_BOOT")
  UUID_ROOT=$(blkid -s UUID -o value "$PARTITION_ROOT")
  PARTUUID_BOOT=$(blkid -s PARTUUID -o value "$PARTITION_BOOT")
  PARTUUID_ROOT=$(blkid -s PARTUUID -o value "$PARTITION_ROOT")
}

partition_setup() {
  # setup
  if [ "$PARTITION_MODE" == "auto" ]; then
    PARTITION_PARTED_FILE_SYSTEM_TYPE="$FILE_SYSTEM_TYPE"
    if [ "$PARTITION_PARTED_FILE_SYSTEM_TYPE" == "f2fs" ]; then
      PARTITION_PARTED_FILE_SYSTEM_TYPE=""
    fi
    PARTITION_PARTED_UEFI="mklabel gpt mkpart ESP fat32 1MiB 512MiB mkpart root $PARTITION_PARTED_FILE_SYSTEM_TYPE 512MiB 100% set 1 esp on"
    PARTITION_PARTED_BIOS="mklabel msdos mkpart primary ext4 4MiB 512MiB mkpart primary $PARTITION_PARTED_FILE_SYSTEM_TYPE 512MiB 100% set 1 boot on"
  elif [ "$PARTITION_MODE" == "custom" ]; then
    PARTITION_PARTED_UEFI="$PARTITION_CUSTOM_PARTED_UEFI"
    PARTITION_PARTED_BIOS="$PARTITION_CUSTOM_PARTED_BIOS"
  fi

  if [ "$DEVICE_SDA" == "true" ]; then
    PARTITION_BOOT="$(partition_device "${DEVICE}" "${PARTITION_BOOT_NUMBER}")"
    PARTITION_ROOT="$(partition_device "${DEVICE}" "${PARTITION_ROOT_NUMBER}")"
    DEVICE_ROOT="$(partition_device "${DEVICE}" "${PARTITION_ROOT_NUMBER}")"
  fi

  if [ "$DEVICE_NVME" == "true" ]; then
    PARTITION_BOOT="$(partition_device "${DEVICE}" "${PARTITION_BOOT_NUMBER}")"
    PARTITION_ROOT="$(partition_device "${DEVICE}" "${PARTITION_ROOT_NUMBER}")"
    DEVICE_ROOT="$(partition_device "${DEVICE}" "${PARTITION_ROOT_NUMBER}")"
  fi

  if [ "$DEVICE_VDA" == "true" ]; then
    PARTITION_BOOT="$(partition_device "${DEVICE}" "${PARTITION_BOOT_NUMBER}")"
    PARTITION_ROOT="$(partition_device "${DEVICE}" "${PARTITION_ROOT_NUMBER}")"
    DEVICE_ROOT="$(partition_device "${DEVICE}" "${PARTITION_ROOT_NUMBER}")"
  fi

  if [ "$DEVICE_MMC" == "true" ]; then
    PARTITION_BOOT="$(partition_device "${DEVICE}" "${PARTITION_BOOT_NUMBER}")"
    PARTITION_ROOT="$(partition_device "${DEVICE}" "${PARTITION_ROOT_NUMBER}")"
    DEVICE_ROOT="$(partition_device "${DEVICE}" "${PARTITION_ROOT_NUMBER}")"
  fi
}

function partition_device() {
  local DEVICE="$1"
  local NUMBER="$2"
  local PARTITION_DEVICE=""

  if [ "$DEVICE_SDA" == "true" ]; then
    PARTITION_DEVICE="${DEVICE}${NUMBER}"
  fi

  if [ "$DEVICE_NVME" == "true" ]; then
    PARTITION_DEVICE="${DEVICE}p${NUMBER}"
  fi

  if [ "$DEVICE_VDA" == "true" ]; then
    PARTITION_DEVICE="${DEVICE}${NUMBER}"
  fi

  if [ "$DEVICE_MMC" == "true" ]; then
    PARTITION_DEVICE="${DEVICE}p${NUMBER}"
  fi

  echo "$PARTITION_DEVICE"
}

partition_options() {
  PARTITION_OPTIONS_BOOT="defaults"
  PARTITION_OPTIONS="defaults"

  if [ "$BIOS_TYPE" == "uefi" ]; then
    PARTITION_OPTIONS_BOOT="$PARTITION_OPTIONS_BOOT,uid=0,gid=0,fmask=0077,dmask=0077"
  fi
  if [ "$DEVICE_TRIM" == "true" ]; then
    PARTITION_OPTIONS_BOOT="$PARTITION_OPTIONS_BOOT,noatime"
    PARTITION_OPTIONS="$PARTITION_OPTIONS,noatime"
    if [ "$FILE_SYSTEM_TYPE" == "f2fs" ]; then
      PARTITION_OPTIONS="$PARTITION_OPTIONS,nodiscard"
    fi
  fi
}

partition_mount() {
  if [ "$FILE_SYSTEM_TYPE" == "btrfs" ]; then
    # mount subvolumes
    mount -o "subvol=${BTRFS_SUBVOLUME_ROOT[1]},$PARTITION_OPTIONS,compress=zstd" "$DEVICE_ROOT" "${MNT_DIR}"
    mkdir -p "${MNT_DIR}"/boot
    mount -o "$PARTITION_OPTIONS_BOOT" "$PARTITION_BOOT" "${MNT_DIR}"/boot
    for I in "${BTRFS_SUBVOLUMES_MOUNTPOINTS[@]}"; do
      IFS=',' read -ra SUBVOLUME <<<"$I"
      if [ "${SUBVOLUME[0]}" == "root" ]; then
        continue
      fi
      if [ "${SUBVOLUME[0]}" == "swap" ] && [ -z "$SWAP_SIZE" ]; then
        continue
      fi
      if [ "${SUBVOLUME[0]}" == "swap" ]; then
        mkdir -p "${MNT_DIR}${SUBVOLUME[2]}"
        chmod 0755 "${MNT_DIR}${SUBVOLUME[2]}"
      else
        mkdir -p "${MNT_DIR}${SUBVOLUME[2]}"
      fi
      mount -o "subvol=${SUBVOLUME[1]},$PARTITION_OPTIONS,compress=zstd" "$DEVICE_ROOT" "${MNT_DIR}${SUBVOLUME[2]}"
    done
  else
    # root
    mount -o "$PARTITION_OPTIONS" "$DEVICE_ROOT" "${MNT_DIR}"

    # boot
    mkdir -p "${MNT_DIR}"/boot
    mount -o "$PARTITION_OPTIONS_BOOT" "$PARTITION_BOOT" "${MNT_DIR}"/boot

    # mount points
    for I in "${PARTITION_MOUNT_POINTS[@]}"; do
      if [[ "$I" =~ ^!.* ]]; then
        continue
      fi
      IFS='=' read -ra PARTITION_MOUNT_POINT <<<"$I"
      if [ "${PARTITION_MOUNT_POINT[1]}" == "/boot" ] || [ "${PARTITION_MOUNT_POINT[1]}" == "/" ]; then
        continue
      fi
      local PARTITION_DEVICE="$(partition_device "${DEVICE}" "${PARTITION_MOUNT_POINT[0]}")"
      mkdir -p "${MNT_DIR}${PARTITION_MOUNT_POINT[1]}"
      mount -o "$PARTITION_OPTIONS" "${PARTITION_DEVICE}" "${MNT_DIR}${PARTITION_MOUNT_POINT[1]}"
    done
  fi
}
# END FUNCTIONS
#------------------------------------------------------------------------------------------------------#
# MENUS
main_menu() {
  select_menu "Main Menu" "Full Install" full_install "Install without Dotfiles" install_without_dotfiles "Restore Dotfiles" restore_dotfiles "Configure" configure
}
# END MENUS
#------------------------------------------------------------------------------------------------------#
# MENUS CALLBACKS
full_install() {
  installArch
}

install_without_dotfiles() {
  installArch
}

restore_dotfiles() {
  echo restore
}

configure() {
  echo config
}
#------------------------------------------------------------------------------------------------------#

# END MENUS CALLBACKS
#------------------------------------------------------------------------------------------------------#

main() {
  local START_TIMESTAMP=$(date -u +"%F %T")

  clear

  config_file="archwrld.conf"

  while getopts "c:" opt; do
    case $opt in
    c) config_file="$OPTARG" ;;
    \?)
      echo "Usage: $0 [-c Config File Name]"
      exit 1
      ;;
    esac
  done

  loadConfig
  sanitize_variables
  check_variables
  init

  printLogo

  until main_menu; do :; done
}

main "$@"
