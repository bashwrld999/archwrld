#!/bin/bash

set -euo pipefail

#------------------------------------------------------------------------------------------------------#
# COLORS
MAGENTABG="\e[1;45m"
YELLOWBG="\e[1;43m"
YELLOWL="\e[93m"
GREENBG="\e[1;42m"
MAGENTA="\e[35m"
YELLOW="\e[33m"
BLUEBG="\e[1;44m"
CYANBG="\e[1;46m"
BWHITE="\e[0;97m"
GREEN="\e[32m"
REDBG="\e[1;41m"
BLUE="\e[94m"
CYAN="\e[36m"
RED="\e[31m"
WHITE="\e[0m"
NC="\e[0m"
# END COLORS
#------------------------------------------------------------------------------------------------------#
# MENU FUNCTIONS
print_logo() {
  echo -e "${BLUE}
                    -@
                   .##@
                  .####@
                  @#####@
                . *######@            ${WHITE}                     _ __          _______  _      _____  ${BLUE}
               .##@o@#####@           ${WHITE}      /\            | |\ \        / /  __ \| |    |  __ \ ${BLUE}
              /############@          ${WHITE}     /  \   _ __ ___| |_\ \  /\  / /| |__) | |    | |  | |${BLUE}
             /##############@         ${WHITE}    / /\ \ | '__/ __| '_ \ \/  \/ / |  _  /| |    | |  | |${BLUE}
            @######@**%######@        ${WHITE}   / ____ \| | | (__| | | \  /\  /  | | \ \| |____| |__| |${BLUE}
           @######\`     %#####o       ${WHITE}  /_/    \_\_|  \___|_| |_|\/  \/   |_|  \_\______|_____/ ${BLUE}
          @######@       ######%
        -@#######h       ######@.\`
       /#####h**\`\`       \`**%@####@
      @H@*\`                    \`*%#@
     *\`                            \`* ${WHITE}\n\n"
}

title() {
  echo -e "\n\n${MAGENTA}###${NC}----------------------------------------${MAGENTA}[ ${BWHITE}$1${NC} ${MAGENTA}]${NC}----------------------------------------${MAGENTA}###\n"
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
  echo -e "${YELLOW}  >  Make a selection:${NC}\n"
  for i in "${!options[@]}"; do
    echo -e "     [$((i + 1))]  ${options[$i]}"
  done

  # Prompt the user to enter their choice
  echo -e "\n${BLUE}  Enter a number: ${NC}\n"
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

reload() {
  sleep 0.2
  echo -e "${NC}

  --> [${GREEN}Reloading${NC}] "
}

invalid() {
  sleep 0.2
  echo -e "${RED}
        --------------------------
        ###  ${YELLOW}Invalid Response  ${RED}###
        --------------------------"
  reload
}

# END MENU FUNCTIONS
#------------------------------------------------------------------------------------------------------#
# VARIABLES
WARNING_CONFIRM="true"

COMMOMS_LOADED="true"
PARTITION_BOOT=""
PARTITION_ROOT=""
PARTITION_BOOT_NUMBER=""
PARTITION_ROOT_NUMBER=""
DEVICE_ROOT=""
DEVICE_LVM=""
LUKS_DEVICE_NAME="root"
LVM_VOLUME_GROUP="vg"
LVM_VOLUME_LOGICAL="root"
SWAPFILE="/swapfile"
BOOT_DIRECTORY=""
ESP_DIRECTORY=""
UUID_BOOT=""
UUID_ROOT=""
PARTUUID_BOOT=""
PARTUUID_ROOT=""
CMDLINE_LINUX_ROOT=""
CMDLINE_LINUX=""
BTRFS_SUBVOLUME_ROOT=()
BTRFS_SUBVOLUME_SWAP=()
USER_NAME_INSTALL="root"

MNT_DIR="/mnt"

AUR_PACKAGE="paru-bin"
AUR_COMMAND="paru"

BIOS_TYPE=""
ASCIINEMA=""
DEVICE_SDA="false"
DEVICE_NVME="false"
DEVICE_VDA="false"
DEVICE_MMC="false"
CPU_VENDOR=""
GPU_VENDOR=""
VIRTUALBOX=""
VMWARE=""
SYSTEM_INSTALLATION=""
INITRD_MICROCODE=""

LOG_TRACE="true"
LOG_FILE="false"
USER_NAME="bashwrld"
USER_PASSWORD="ask"
PACKAGES_PIPEWIRE="false"
# END VARIABLES
#------------------------------------------------------------------------------------------------------#
# FUNCTIONS
load_config() {
  if [ -e $CONFIG_FILE ]; then
    source $CONFIG_FILE
  else
    echo "Config file ${CONFIG_FILE} could not be found."
    exit 1
  fi
}
#------------------------------------------------------------------------------------------------------#
function print_step() {
  STEP="$1"
  echo ""
  echo -e "${BLUE}#---> ${STEP} ${NC}"
}

function execute_step() {
  local STEP="$1"
  eval "$STEP"
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
  local startTimestamp=$(date -u +"%T")

  execute_step "warning"
  execute_step "init"
  execute_step "facts"
  execute_step "checks"
  execute_step "prepare"
  execute_step "partition"
  execute_step "install"
  execute_step "configuration"
  execute_step "users"
  if [ -n "$DISPLAY_DRIVER" ]; then
    execute_step "display_driver"
  fi
  execute_step "kernels"
  execute_step "network"
  if [ "$VIRTUALBOX" == "true" ]; then
    execute_step "virtualbox"
  fi
  if [ "$VMWARE" == "true" ]; then
    execute_step "vmware"
  fi
  execute_step "bootloader"
  execute_step "mkinitcpio_configuration"
  execute_step "mkinitcpio"
  if [ -n "$CUSTOM_SHELL" ]; then
    execute_step "custom_shell"
  fi
  if [ -n "$DESKTOP_ENVIRONMENT" ]; then
    execute_step "desktop_environment"
    execute_step "display_manager"
  fi
  execute_step "packages"
  execute_step "end_install"

  local endTimestamp=$(date -u +"%T")
  local installationTime=$(date -u -d @$(($(date -d "$endTimestamp" '+%s') - $(date -d "$startTimestamp" '+%s'))) '+%T')
  echo -e "Installation Start ${WHITE}[$startTimestamp]${NC}\n               End ${WHITE}[$endTimestamp]${NC}\n              Time ${WHITE}[$installationTime]${NC}"
}
#------------------------------------------------------------------------------------------------------#
warning() {
  echo -e "${BLUE}Welcome to ArchWRLD Install Script${NC}"
  echo ""
  echo -e "${RED}Warning"'!'"${NC}"
  echo -e "${RED}This script can delete all partitions of the persistent${NC}"
  echo -e "${RED}storage and continuing all your data can be lost.${NC}"
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

init() {
  print_step "Init"
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

facts() {
  print_step "Facts"

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
  print_step "Checks"

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
  print_step "Prepare"

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
  print_step "Partition"

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
#------------------------------------------------------------------------------------------------------#
function install() {
  print_step "Install"

  local COUNTRIES=()

  pacman-key --init
  pacman-key --populate

  if [ -n "$PACMAN_MIRROR" ]; then
    echo "Server = $PACMAN_MIRROR" >/etc/pacman.d/mirrorlist
  fi
  if [ "$REFLECTOR" == "true" ]; then
    for COUNTRY in "${REFLECTOR_COUNTRIES[@]}"; do
      local COUNTRIES+=(--country "$COUNTRY")
    done
    pacman -Sy --noconfirm reflector
    reflector "${COUNTRIES[@]}" --latest 25 --age 24 --protocol https --completion-percent 100 --sort rate --save /etc/pacman.d/mirrorlist
  fi

  sed -i 's/#Color/Color/' /etc/pacman.conf
  if [ "$PACMAN_PARALLEL_DOWNLOADS" == "true" ]; then
    sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
  else
    sed -i 's/#ParallelDownloads\(.*\)/#ParallelDownloads\1\nDisableDownloadTimeout/' /etc/pacman.conf
  fi

  local PACKAGES=()
  if [ "$LVM" == "true" ]; then
    local PACKAGES+=("lvm2")
  fi
  if [ "$FILE_SYSTEM_TYPE" == "btrfs" ]; then
    local PACKAGES+=("btrfs-progs")
  fi
  if [ "$FILE_SYSTEM_TYPE" == "xfs" ]; then
    local PACKAGES+=("xfsprogs")
  fi
  if [ "$FILE_SYSTEM_TYPE" == "f2fs" ]; then
    local PACKAGES+=("f2fs-tools")
  fi
  if [ "$FILE_SYSTEM_TYPE" == "reiserfs" ]; then
    local PACKAGES+=("reiserfsprogs")
  fi

  pacstrap "${MNT_DIR}" base base-devel linux linux-firmware "${PACKAGES[@]}"

  if [ "$PACMAN_PARALLEL_DOWNLOADS" == "true" ]; then
    sed -i 's/#ParallelDownloads/ParallelDownloads/' "${MNT_DIR}"/etc/pacman.conf
  else
    sed -i 's/#ParallelDownloads\(.*\)/#ParallelDownloads\1\nDisableDownloadTimeout/' "${MNT_DIR}"/etc/pacman.conf
  fi

  if [ "$REFLECTOR" == "true" ]; then
    pacman_install "reflector"
    cat <<EOT >"${MNT_DIR}/etc/xdg/reflector/reflector.conf"
${COUNTRIES[@]}
--latest 25
--age 24
--protocol https
--completion-percent 100
--sort rate
--save /etc/pacman.d/mirrorlist
EOT
    arch-chroot "${MNT_DIR}" reflector "${COUNTRIES[@]}" --latest 25 --age 24 --protocol https --completion-percent 100 --sort rate --save /etc/pacman.d/mirrorlist
    arch-chroot "${MNT_DIR}" systemctl enable reflector.timer
  fi

  if [ "$PACKAGES_MULTILIB" == "true" ]; then
    sed -z -i 's/#\[multilib\]\n#/[multilib]\n/' "${MNT_DIR}"/etc/pacman.conf
  fi
}

function pacman_install() {
  local ERROR="true"
  local PACKAGES=()
  set +e
  IFS=' ' read -ra PACKAGES <<<"$1"
  for VARIABLE in {1..5}; do
    local COMMAND="pacman -Syu --noconfirm --needed ${PACKAGES[*]}"
    if execute_sudo "$COMMAND"; then
      local ERROR="false"
      break
    else
      sleep 10
    fi
  done
  set -e
  if [ "$ERROR" == "true" ]; then
    exit 1
  fi
}

function execute_sudo() {
  local COMMAND="$1"
  if [ "$SYSTEM_INSTALLATION" == "true" ]; then
    arch-chroot "${MNT_DIR}" bash -c "$COMMAND"
  else
    sudo bash -c "$COMMAND"
  fi
}
#------------------------------------------------------------------------------------------------------#
function configuration() {
  print_step "Configuration"

  if [ "$GPT_AUTOMOUNT" != "true" ]; then
    genfstab -U "${MNT_DIR}" >>"${MNT_DIR}/etc/fstab"

    cat <<EOT >>"${MNT_DIR}/etc/fstab"
# efivars
efivarfs /sys/firmware/efi/efivars efivarfs ro,nosuid,nodev,noexec 0 0

EOT

    if [ -n "$SWAP_SIZE" ]; then
      cat <<EOT >>"${MNT_DIR}/etc/fstab"
# swap
$SWAPFILE none swap defaults 0 0

EOT
    fi
  fi

  if [ "$DEVICE_TRIM" == "true" ]; then
    if [ "$GPT_AUTOMOUNT" != "true" ]; then
      if [ "$FILE_SYSTEM_TYPE" == "f2fs" ]; then
        sed -i 's/relatime/noatime,nodiscard/' "${MNT_DIR}"/etc/fstab
      else
        sed -i 's/relatime/noatime/' "${MNT_DIR}"/etc/fstab
      fi
    fi
    arch-chroot "${MNT_DIR}" systemctl enable fstrim.timer
  fi

  arch-chroot "${MNT_DIR}" ln -s -f "$TIMEZONE" /etc/localtime
  arch-chroot "${MNT_DIR}" hwclock --systohc
  for LOCALE in "${LOCALES[@]}"; do
    sed -i "s/#$LOCALE/$LOCALE/" /etc/locale.gen
    sed -i "s/#$LOCALE/$LOCALE/" "${MNT_DIR}"/etc/locale.gen
  done
  for VARIABLE in "${LOCALE_CONF[@]}"; do
    #localectl set-locale "$VARIABLE"
    echo -e "$VARIABLE" >>"${MNT_DIR}"/etc/locale.conf
  done
  locale-gen
  arch-chroot "${MNT_DIR}" locale-gen
  echo -e "$KEYMAP\n$FONT\n$FONT_MAP" >"${MNT_DIR}"/etc/vconsole.conf
  echo "$HOSTNAME" >"${MNT_DIR}"/etc/hostname

  local OPTIONS=""
  if [ -n "$KEYLAYOUT" ]; then
    local OPTIONS="$OPTIONS"$'\n'"    Option \"XkbLayout\" \"$KEYLAYOUT\""
  fi
  if [ -n "$KEYMODEL" ]; then
    local OPTIONS="$OPTIONS"$'\n'"    Option \"XkbModel\" \"$KEYMODEL\""
  fi
  if [ -n "$KEYVARIANT" ]; then
    local OPTIONS="$OPTIONS"$'\n'"    Option \"XkbVariant\" \"$KEYVARIANT\""
  fi
  if [ -n "$KEYOPTIONS" ]; then
    local OPTIONS="$OPTIONS"$'\n'"    Option \"XkbOptions\" \"$KEYOPTIONS\""
  fi

  arch-chroot "${MNT_DIR}" mkdir -p "/etc/X11/xorg.conf.d/"
  cat <<EOT >"${MNT_DIR}/etc/X11/xorg.conf.d/00-keyboard.conf"
# Written by systemd-localed(8), read by systemd-localed and Xorg. It's
# probably wise not to edit this file manually. Use localectl(1) to
# instruct systemd-localed to update it.
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    $OPTIONS
EndSection
EOT

  if [ -n "$SWAP_SIZE" ]; then
    echo "vm.swappiness=10" >"${MNT_DIR}"/etc/sysctl.d/99-sysctl.conf
  fi

  printf "%s\n%s" "$ROOT_PASSWORD" "$ROOT_PASSWORD" | arch-chroot "${MNT_DIR}" passwd
}
#------------------------------------------------------------------------------------------------------#
function users() {
  print_step "Users"

  local USERS_GROUPS="wheel,storage,optical"
  create_user "$USER_NAME" "$USER_PASSWORD" "$USERS_GROUPS"

  for U in "${ADDITIONAL_USERS[@]}"; do
    local S=()
    IFS='=' read -ra S <<<"$U"
    local USER="${S[0]}"
    local PASSWORD="${S[1]}"
    create_user "$USER" "$PASSWORD" "$USERS_GROUPS"
  done

  arch-chroot "${MNT_DIR}" sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

  pacman_install "xdg-user-dirs"

  if [ "$SYSTEMD_HOMED" == "true" ]; then
    arch-chroot "${MNT_DIR}" systemctl enable systemd-homed.service

    cat <<EOT >"${MNT_DIR}/etc/pam.d/nss-auth"
#%PAM-1.0

auth     sufficient pam_unix.so try_first_pass nullok
auth     sufficient pam_systemd_home.so
auth     required   pam_deny.so

account  sufficient pam_unix.so
account  sufficient pam_systemd_home.so
account  required   pam_deny.so

password sufficient pam_unix.so try_first_pass nullok sha512 shadow
password sufficient pam_systemd_home.so
password required   pam_deny.so
EOT

    cat <<EOT >"${MNT_DIR}/etc/pam.d/system-auth"
#%PAM-1.0

auth      substack   nss-auth
auth      optional   pam_permit.so
auth      required   pam_env.so

account   substack   nss-auth
account   optional   pam_permit.so
account   required   pam_time.so

password  substack   nss-auth
password  optional   pam_permit.so

session   required  pam_limits.so
session   optional  pam_systemd_home.so
session   required  pam_unix.so
session   optional  pam_permit.so
EOT
  fi
}

function create_user() {
  local USER=$1
  local PASSWORD=$2
  local USERS_GROUPS=$3
  if [ "$SYSTEMD_HOMED" == "true" ]; then
    create_user_homectl "$USER" "$PASSWORD" "$USERS_GROUPS"
  else
    create_user_useradd "$USER" "$PASSWORD" "$USERS_GROUPS"
  fi
}

function create_user_homectl() {
  local USER=$1
  local PASSWORD=$2
  local USER_GROUPS=$3
  local STORAGE="--storage=directory"
  local IMAGE_PATH="--image-path=${MNT_DIR}/home/$USER"
  local FS_TYPE=""
  local CIFS_DOMAIN=""
  local CIFS_USERNAME=""
  local CIFS_SERVICE=""
  local TZ=${TIMEZONE//\/usr\/share\/zoneinfo\//}
  local L=${LOCALE_CONF[0]//LANG=/}

  if [ "$SYSTEMD_HOMED_STORAGE" != "auto" ]; then
    local STORAGE="--storage=$SYSTEMD_HOMED_STORAGE"
  fi
  if [ "$SYSTEMD_HOMED_STORAGE" == "luks" ] && [ "$SYSTEMD_HOMED_STORAGE_LUKS_TYPE" != "auto" ]; then
    local FS_TYPE="--fs-type=$SYSTEMD_HOMED_STORAGE_LUKS_TYPE"
  fi
  if [ "$SYSTEMD_HOMED_STORAGE" == "luks" ]; then
    local IMAGE_PATH="--image-path=${MNT_DIR}/home/$USER.home"
  fi
  if [ "$SYSTEMD_HOMED_STORAGE" == "cifs" ]; then
    local CIFS_DOMAIN="--cifs-domain=${SYSTEMD_HOMED_CIFS_DOMAIN["domain"]}"
    local CIFS_USERNAME="--cifs-user-name=$USER"
    local CIFS_SERVICE="--cifs-service=${SYSTEMD_HOMED_CIFS_SERVICE["service"]}"
  fi
  if [ "$SYSTEMD_HOMED_STORAGE" == "luks" ] && [ "$SYSTEMD_HOMED_STORAGE_LUKS_TYPE" == "auto" ]; then
    pacman_install "btrfs-progs"
  fi

  systemctl start systemd-homed.service
  sleep 10 # #151 avoid Operation on home <USER> failed: Transport endpoint is not conected.
  # shellcheck disable=SC2086
  homectl create "$USER" --enforce-password-policy=no --real-name="$USER" --timezone="$TZ" --language="$L" $STORAGE $IMAGE_PATH $FS_TYPE $CIFS_DOMAIN $CIFS_USERNAME $CIFS_SERVICE -G "$USER_GROUPS"
  sleep 10 # #151 avoid Operation on home <USER> failed: Transport endpoint is not conected.
  cp -a "/var/lib/systemd/home/." "${MNT_DIR}/var/lib/systemd/home/"
}

function create_user_useradd() {
  local USER=$1
  local PASSWORD=$2
  local USER_GROUPS=$3
  arch-chroot "${MNT_DIR}" useradd -m -G "$USER_GROUPS" -c "$USER" -s /bin/bash "$USER"
  printf "%s\n%s" "$USER_PASSWORD" "$USER_PASSWORD" | arch-chroot "${MNT_DIR}" passwd "$USER"
}

function user_add_groups() {
  local USER="$1"
  local USER_GROUPS="$2"
  if [ "$SYSTEMD_HOMED" == "true" ]; then
    homectl update "$USER" -G "$USER_GROUPS"
  else
    arch-chroot "${MNT_DIR}" usermod -a -G "$USER_GROUPS" "$USER"
  fi
}
#------------------------------------------------------------------------------------------------------#
function display_driver() {
  print_step "display_driver()"

  local PACKAGES_DRIVER_PACMAN="true"
  local PACKAGES_DRIVER=""
  local PACKAGES_DRIVER_MULTILIB=""
  local PACKAGES_DDX=""
  local PACKAGES_VULKAN=""
  local PACKAGES_VULKAN_MULTILIB=""
  local PACKAGES_HARDWARE_ACCELERATION=""
  local PACKAGES_HARDWARE_ACCELERATION_MULTILIB=""
  case "$DISPLAY_DRIVER" in
  "intel")
    local PACKAGES_DRIVER_MULTILIB="lib32-mesa"
    ;;
  "amdgpu")
    local PACKAGES_DRIVER_MULTILIB="lib32-mesa"
    ;;
  "ati")
    local PACKAGES_DRIVER_MULTILIB="lib32-mesa"
    ;;
  "nvidia")
    local PACKAGES_DRIVER="nvidia"
    local PACKAGES_DRIVER_MULTILIB="lib32-nvidia-utils"
    ;;
  "nvidia-lts")
    local PACKAGES_DRIVER="nvidia-lts"
    local PACKAGES_DRIVER_MULTILIB="lib32-nvidia-utils"
    ;;
  "nvidia-dkms")
    local PACKAGES_DRIVER="nvidia-dkms"
    local PACKAGES_DRIVER_MULTILIB="lib32-nvidia-utils"
    ;;
  "nvidia-470xx-dkms")
    local PACKAGES_DRIVER_PACMAN="false"
    local PACKAGES_DRIVER="nvidia-470xx-dkms"
    local PACKAGES_DRIVER_MULTILIB="lib32-nvidia-utils"
    ;;
  "nvidia-390xx-dkms")
    local PACKAGES_DRIVER_PACMAN="false"
    local PACKAGES_DRIVER="nvidia-390xx-dkms"
    local PACKAGES_DRIVER_MULTILIB="lib32-nvidia-utils"
    ;;
  "nvidia-340xx-dkms")
    local PACKAGES_DRIVER_PACMAN="false"
    local PACKAGES_DRIVER="nvidia-340xx-dkms"
    local PACKAGES_DRIVER_MULTILIB="lib32-nvidia-utils"
    ;;
  "nouveau")
    local PACKAGES_DRIVER_MULTILIB="lib32-mesa"
    ;;
  esac
  if [ "$DISPLAY_DRIVER_DDX" == "true" ]; then
    case "$DISPLAY_DRIVER" in
    "intel")
      local PACKAGES_DDX="xf86-video-intel"
      ;;
    "amdgpu")
      local PACKAGES_DDX="xf86-video-amdgpu"
      ;;
    "ati")
      local PACKAGES_DDX="xf86-video-ati"
      ;;
    "nouveau")
      local PACKAGES_DDX="xf86-video-nouveau"
      ;;
    esac
  fi
  if [ "$VULKAN" == "true" ]; then
    case "$DISPLAY_DRIVER" in
    "intel")
      local PACKAGES_VULKAN="vulkan-intel vulkan-icd-loader"
      local PACKAGES_VULKAN_MULTILIB="lib32-vulkan-intel lib32-vulkan-icd-loader"
      ;;
    "amdgpu")
      local PACKAGES_VULKAN="vulkan-radeon vulkan-icd-loader"
      local PACKAGES_VULKAN_MULTILIB="lib32-vulkan-radeon lib32-vulkan-icd-loader"
      ;;
    "ati")
      local PACKAGES_VULKAN="vulkan-radeon vulkan-icd-loader"
      local PACKAGES_VULKAN_MULTILIB="lib32-vulkan-radeon lib32-vulkan-icd-loader"
      ;;
    "nvidia")
      local PACKAGES_VULKAN="nvidia-utils vulkan-icd-loader"
      local PACKAGES_VULKAN_MULTILIB="lib32-nvidia-utils lib32-vulkan-icd-loader"
      ;;
    "nvidia-lts")
      local PACKAGES_VULKAN="nvidia-utils vulkan-icd-loader"
      local PACKAGES_VULKAN_MULTILIB="lib32-nvidia-utils lib32-vulkan-icd-loader"
      ;;
    "nvidia-dkms")
      local PACKAGES_VULKAN="nvidia-utils vulkan-icd-loader"
      local PACKAGES_VULKAN_MULTILIB="lib32-nvidia-utils lib32-vulkan-icd-loader"
      ;;
    "nouveau")
      local PACKAGES_VULKAN=""
      local PACKAGES_VULKAN_MULTILIB=""
      ;;
    esac
  fi
  if [ "$DISPLAY_DRIVER_HARDWARE_VIDEO_ACCELERATION" == "true" ]; then
    case "$DISPLAY_DRIVER" in
    "intel")
      if [ -n "$DISPLAY_DRIVER_HARDWARE_VIDEO_ACCELERATION_INTEL" ]; then
        local PACKAGES_HARDWARE_ACCELERATION="$DISPLAY_DRIVER_HARDWARE_VIDEO_ACCELERATION_INTEL"
        local PACKAGES_HARDWARE_ACCELERATION_MULTILIB=""
      fi
      ;;
    "amdgpu")
      local PACKAGES_HARDWARE_ACCELERATION="libva-mesa-driver"
      local PACKAGES_HARDWARE_ACCELERATION_MULTILIB="lib32-libva-mesa-driver"
      ;;
    "ati")
      local PACKAGES_HARDWARE_ACCELERATION="mesa-vdpau"
      local PACKAGES_HARDWARE_ACCELERATION_MULTILIB="lib32-mesa-vdpau"
      ;;
    "nvidia")
      local PACKAGES_HARDWARE_ACCELERATION="libva-mesa-driver"
      local PACKAGES_HARDWARE_ACCELERATION_MULTILIB="lib32-libva-mesa-driver"
      ;;
    "nvidia-lts")
      local PACKAGES_HARDWARE_ACCELERATION="libva-mesa-driver"
      local PACKAGES_HARDWARE_ACCELERATION_MULTILIB="lib32-libva-mesa-driver"
      ;;
    "nvidia-dkms")
      local PACKAGES_HARDWARE_ACCELERATION="libva-mesa-driver"
      local PACKAGES_HARDWARE_ACCELERATION_MULTILIB="lib32-libva-mesa-driver"
      ;;
    "nvidia-470xx-dkms")
      local PACKAGES_HARDWARE_ACCELERATION="libva-mesa-driver"
      local PACKAGES_HARDWARE_ACCELERATION_MULTILIB="lib32-libva-mesa-driver"
      ;;
    "nvidia-390xx-dkms")
      local PACKAGES_HARDWARE_ACCELERATION="libva-mesa-driver"
      local PACKAGES_HARDWARE_ACCELERATION_MULTILIB="lib32-libva-mesa-driver"
      ;;
    "nvidia-340xx-dkms")
      local PACKAGES_HARDWARE_ACCELERATION="libva-mesa-driver"
      local PACKAGES_HARDWARE_ACCELERATION_MULTILIB="lib32-libva-mesa-driver"
      ;;
    "nouveau")
      local PACKAGES_HARDWARE_ACCELERATION="libva-mesa-driver"
      local PACKAGES_HARDWARE_ACCELERATION_MULTILIB="lib32-libva-mesa-driver"
      ;;
    esac
  fi

  if [ "$PACKAGES_DRIVER_PACMAN" == "true" ]; then
    pacman_install "mesa $PACKAGES_DRIVER $PACKAGES_DDX $PACKAGES_VULKAN $PACKAGES_HARDWARE_ACCELERATION"
  else
    aur_install "mesa $PACKAGES_DRIVER $PACKAGES_DDX $PACKAGES_VULKAN $PACKAGES_HARDWARE_ACCELERATION"
  fi

  if [ "$PACKAGES_MULTILIB" == "true" ]; then
    pacman_install "$PACKAGES_DRIVER_MULTILIB $PACKAGES_VULKAN_MULTILIB $PACKAGES_HARDWARE_ACCELERATION_MULTILIB"
  fi
}
#------------------------------------------------------------------------------------------------------#
function kernels() {
  print_step "Kernel"

  pacman_install "linux-headers"
  if [ -n "$KERNELS" ]; then
    pacman_install "$KERNELS"
  fi
}
#------------------------------------------------------------------------------------------------------#
function network() {
  print_step "Network"

  pacman_install "networkmanager"
  arch-chroot "${MNT_DIR}" systemctl enable NetworkManager.service
}
#------------------------------------------------------------------------------------------------------#
function virtualbox() {
  print_step "VirtualBox"

  pacman_install "virtualbox-guest-utils"
  arch-chroot "${MNT_DIR}" systemctl enable vboxservice.service

  local USER_GROUPS="vboxsf"
  user_add_groups "$USER_NAME" "$USER_GROUPS"

  for U in "${ADDITIONAL_USERS[@]}"; do
    local S=()
    IFS='=' read -ra S <<<"$U"
    local USER=${S[0]}
    user_add_groups "$USER" "$USER_GROUPS"
  done
}

function vmware() {
  print_step "VMWare"

  pacman_install "open-vm-tools"
  arch-chroot "${MNT_DIR}" systemctl enable vmtoolsd.service
}
#------------------------------------------------------------------------------------------------------#
function bootloader() {
  print_step "Bootloader"

  BOOTLOADER_ALLOW_DISCARDS=""

  if [ "$VIRTUALBOX" != "true" ] && [ "$VMWARE" != "true" ]; then
    if [ "$CPU_VENDOR" == "intel" ]; then
      pacman_install "intel-ucode"
    fi
    if [ "$CPU_VENDOR" == "amd" ]; then
      pacman_install "amd-ucode"
    fi
  fi
  if [ "$LVM" == "true" ] || [ -n "$LUKS_PASSWORD" ]; then
    CMDLINE_LINUX_ROOT="root=$DEVICE_ROOT"
  else
    CMDLINE_LINUX_ROOT="root=UUID=$UUID_ROOT"
  fi
  if [ -n "$LUKS_PASSWORD" ]; then
    case "$BOOTLOADER" in
    "grub" | "refind" | "efistub")
      if [ "$DEVICE_TRIM" == "true" ]; then
        BOOTLOADER_ALLOW_DISCARDS=":allow-discards"
      fi
      CMDLINE_LINUX="cryptdevice=UUID=$UUID_ROOT:$LUKS_DEVICE_NAME$BOOTLOADER_ALLOW_DISCARDS"
      ;;
    "systemd")
      if [ "$DEVICE_TRIM" == "true" ]; then
        BOOTLOADER_ALLOW_DISCARDS=" rd.luks.options=discard"
      fi
      CMDLINE_LINUX="rd.luks.name=$UUID_ROOT=$LUKS_DEVICE_NAME$BOOTLOADER_ALLOW_DISCARDS"
      ;;
    esac
  fi
  if [ "$FILE_SYSTEM_TYPE" == "btrfs" ]; then
    CMDLINE_LINUX="$CMDLINE_LINUX rootflags=subvol=${BTRFS_SUBVOLUME_ROOT[1]}"
  fi
  if [ "$KMS" == "true" ]; then
    case "$DISPLAY_DRIVER" in
    "nvidia")
      CMDLINE_LINUX="$CMDLINE_LINUX nvidia-drm.modeset=1"
      ;;
    esac
  fi

  if [ -n "$KERNELS_PARAMETERS" ]; then
    CMDLINE_LINUX="$CMDLINE_LINUX $KERNELS_PARAMETERS"
  fi

  CMDLINE_LINUX=$(trim_variable "$CMDLINE_LINUX")

  if [ "$BIOS_TYPE" == "uefi" ] || [ "$SECURE_BOOT" == "true" ]; then
    pacman_install "efibootmgr"
  fi
  if [ "$SECURE_BOOT" == "true" ]; then
    curl --output PreLoader.efi https://blog.hansenpartnership.com/wp-uploads/2013/PreLoader.efi
    curl --output HashTool.efi https://blog.hansenpartnership.com/wp-uploads/2013/HashTool.efi
    md5sum PreLoader.efi >PreLoader.efi.md5
    md5sum HashTool.efi >HashTool.efi.md5
    echo "4f7a4f566781869d252a09dc84923a82  PreLoader.efi" | md5sum -c -
    echo "45639d23aa5f2a394b03a65fc732acf2  HashTool.efi" | md5sum -c -
  fi

  case "$BOOTLOADER" in
  "grub")
    bootloader_grub
    ;;
  "refind")
    bootloader_refind
    ;;
  "systemd")
    bootloader_systemd
    ;;
  "efistub")
    bootloader_efistub
    ;;
  esac

  if [ "$UKI" == "true" ]; then
    if [ "$GPT_AUTOMOUNT" == "true" ]; then
      echo "$CMDLINE_LINUX rw" >"${MNT_DIR}/etc/kernel/cmdline"
    else
      echo "$CMDLINE_LINUX $CMDLINE_LINUX_ROOT rw" >"${MNT_DIR}/etc/kernel/cmdline"
    fi
  fi

  arch-chroot "${MNT_DIR}" systemctl set-default multi-user.target
}

function bootloader_grub() {
  pacman_install "grub dosfstools"
  arch-chroot "${MNT_DIR}" sed -i 's/GRUB_DEFAULT=0/GRUB_DEFAULT=saved/' /etc/default/grub
  arch-chroot "${MNT_DIR}" sed -i 's/#GRUB_SAVEDEFAULT="true"/GRUB_SAVEDEFAULT="true"/' /etc/default/grub
  arch-chroot "${MNT_DIR}" sed -i -E 's/GRUB_CMDLINE_LINUX_DEFAULT="(.*) quiet"/GRUB_CMDLINE_LINUX_DEFAULT="\1"/' /etc/default/grub
  arch-chroot "${MNT_DIR}" sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="'"$CMDLINE_LINUX"'"/' /etc/default/grub
  {
    echo ""
    echo "# alis"
    echo "GRUB_DISABLE_SUBMENU=y"
  } >>"${MNT_DIR}"/etc/default/grub

  if [ "$BIOS_TYPE" == "uefi" ]; then
    arch-chroot "${MNT_DIR}" grub-install --target=x86_64-efi --bootloader-id=grub --efi-directory="${ESP_DIRECTORY}" --recheck
  fi
  if [ "$BIOS_TYPE" == "bios" ]; then
    arch-chroot "${MNT_DIR}" grub-install --target=i386-pc --recheck "$DEVICE"
  fi

  arch-chroot "${MNT_DIR}" grub-mkconfig -o "${BOOT_DIRECTORY}/grub/grub.cfg"

  if [ "$SECURE_BOOT" == "true" ]; then
    mv {PreLoader,HashTool}.efi "${MNT_DIR}${ESP_DIRECTORY}/EFI/grub"
    cp "${MNT_DIR}${ESP_DIRECTORY}/EFI/grub/grubx64.efi" "${MNT_DIR}${ESP_DIRECTORY}/EFI/systemd/loader.efi"
    arch-chroot "${MNT_DIR}" efibootmgr --unicode --disk "$DEVICE" --part 1 --create --label "Arch Linux (PreLoader)" --loader "/EFI/grub/PreLoader.efi"
  fi

  if [ "$VIRTUALBOX" == "true" ]; then
    echo -n "\EFI\grub\grubx64.efi" >"${MNT_DIR}${ESP_DIRECTORY}/startup.nsh"
  fi
}

function bootloader_refind() {
  pacman_install "refind"
  arch-chroot "${MNT_DIR}" refind-install

  arch-chroot "${MNT_DIR}" rm /boot/refind_linux.conf
  arch-chroot "${MNT_DIR}" sed -i 's/^timeout.*/timeout 5/' "${ESP_DIRECTORY}/EFI/refind/refind.conf"
  arch-chroot "${MNT_DIR}" sed -i 's/^#scan_all_linux_kernels.*/scan_all_linux_kernels false/' "${ESP_DIRECTORY}/EFI/refind/refind.conf"
  #arch-chroot "${MNT_DIR}" sed -i 's/^#default_selection "+,bzImage,vmlinuz"/default_selection "+,bzImage,vmlinuz"/' "${ESP_DIRECTORY}/EFI/refind/refind.conf"

  if [ "$SECURE_BOOT" == "true" ]; then
    mv {PreLoader,HashTool}.efi "${MNT_DIR}${ESP_DIRECTORY}/EFI/refind"
    cp "${MNT_DIR}${ESP_DIRECTORY}/EFI/refind/refind_x64.efi" "${MNT_DIR}${ESP_DIRECTORY}/EFI/refind/loader.efi"
    arch-chroot "${MNT_DIR}" efibootmgr --unicode --disk "$DEVICE" --part 1 --create --label "Arch Linux (PreLoader)" --loader "/EFI/refind/PreLoader.efi"
  fi

  if [ "$UKI" == "false" ]; then
    bootloader_refind_entry "linux"
    if [ -n "$KERNELS" ]; then
      IFS=' ' read -r -a KS <<<"$KERNELS"
      for KERNEL in "${KS[@]}"; do
        if [[ "$KERNEL" =~ ^.*-headers$ ]]; then
          continue
        fi
        bootloader_refind_entry "$KERNEL"
      done
    fi

    if [ "$VIRTUALBOX" == "true" ]; then
      echo -ne "\EFI\refind\refind_x64.efi" >"${MNT_DIR}${ESP_DIRECTORY}/startup.nsh"
    fi
  fi
}

function bootloader_systemd() {
  arch-chroot "${MNT_DIR}" systemd-machine-id-setup
  arch-chroot "${MNT_DIR}" bootctl install

  #arch-chroot "${MNT_DIR}" systemctl enable systemd-boot-update.service

  arch-chroot "${MNT_DIR}" mkdir -p "/etc/pacman.d/hooks/"
  cat <<EOT >"${MNT_DIR}/etc/pacman.d/hooks/systemd-boot.hook"
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Updating systemd-boot...
When = PostTransaction
Exec = /usr/bin/systemctl restart systemd-boot-update.service
EOT

  if [ "$SECURE_BOOT" == "true" ]; then
    mv {PreLoader,HashTool}.efi "${MNT_DIR}${ESP_DIRECTORY}/EFI/systemd"
    cp "${MNT_DIR}${ESP_DIRECTORY}/EFI/systemd/systemd-bootx64.efi" "${MNT_DIR}${ESP_DIRECTORY}/EFI/systemd/loader.efi"
    arch-chroot "${MNT_DIR}" efibootmgr --unicode --disk "$DEVICE" --part 1 --create --label "Arch Linux (PreLoader)" --loader "/EFI/systemd/PreLoader.efi"
  fi

  if [ "$UKI" == "true" ]; then
    cat <<EOT >"${MNT_DIR}${ESP_DIRECTORY}/loader/loader.conf"
# alis
timeout 5
editor 0
EOT
  else
    cat <<EOT >"${MNT_DIR}${ESP_DIRECTORY}/loader/loader.conf"
# alis
timeout 5
default archlinux.conf
editor 0
EOT

    arch-chroot "${MNT_DIR}" mkdir -p "${ESP_DIRECTORY}/loader/entries/"

    bootloader_systemd_entry "linux"
    if [ -n "$KERNELS" ]; then
      IFS=' ' read -r -a KS <<<"$KERNELS"
      for KERNEL in "${KS[@]}"; do
        if [[ "$KERNEL" =~ ^.*-headers$ ]]; then
          continue
        fi
        bootloader_systemd_entry "$KERNEL"
      done
    fi

    if [ "$VIRTUALBOX" == "true" ]; then
      echo -n "\EFI\systemd\systemd-bootx64.efi" >"${MNT_DIR}${ESP_DIRECTORY}/startup.nsh"
    fi
  fi
}

function bootloader_efistub() {
  pacman_install "efibootmgr"

  bootloader_efistub_entry "linux"
  if [ -n "$KERNELS" ]; then
    IFS=' ' read -r -a KS <<<"$KERNELS"
    for KERNEL in "${KS[@]}"; do
      if [[ "$KERNEL" =~ ^.*-headers$ ]]; then
        continue
      fi
      bootloader_efistub_entry "$KERNEL"
    done
  fi
}

function bootloader_refind_entry() {
  local KERNEL="$1"
  local MICROCODE=""

  if [ -n "$INITRD_MICROCODE" ]; then
    local MICROCODE="initrd=/$INITRD_MICROCODE"
  fi

  cat <<EOT >>"${MNT_DIR}${ESP_DIRECTORY}/EFI/refind/refind.conf"
# alis
menuentry "Arch Linux ($KERNEL)" {
    volume   $PARTUUID_BOOT
    loader   /vmlinuz-$KERNEL
    initrd   /initramfs-$KERNEL.img
    icon     /EFI/refind/icons/os_arch.png
    options  "$MICROCODE $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX"
    submenuentry "Boot using fallback initramfs"
        initrd /initramfs-$KERNEL-fallback.img"
    }
    submenuentry "Boot to terminal"
        add_options "systemd.unit=multi-user.target"
    }
}
EOT
}

function bootloader_systemd_entry() {
  local KERNEL="$1"
  local MICROCODE=""

  if [ -n "$INITRD_MICROCODE" ]; then
    local MICROCODE="initrd /$INITRD_MICROCODE"
  fi

  cat <<EOT >>"${MNT_DIR}${ESP_DIRECTORY}/loader/entries/arch-$KERNEL.conf"
title Arch Linux ($KERNEL)
efi /vmlinuz-linux
$MICROCODE
initrd /initramfs-$KERNEL.img
options initrd=initramfs-$KERNEL.img $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX
EOT

  cat <<EOT >>"${MNT_DIR}${ESP_DIRECTORY}/loader/entries/arch-$KERNEL-fallback.conf"
title Arch Linux ($KERNEL, fallback)
efi /vmlinuz-linux
$MICROCODE
initrd /initramfs-$KERNEL-fallback.img
options initrd=initramfs-$KERNEL-fallback.img $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX
EOT
}

function bootloader_efistub_entry() {
  local KERNEL="$1"
  local MICROCODE=""

  if [ "$UKI" == "true" ]; then
    arch-chroot "${MNT_DIR}" efibootmgr --unicode --disk "$DEVICE" --part 1 --create --label "Arch Linux ($KERNEL fallback)" --loader "EFI\linux\archlinux-$KERNEL-fallback.efi" --unicode --verbose
    arch-chroot "${MNT_DIR}" efibootmgr --unicode --disk "$DEVICE" --part 1 --create --label "Arch Linux ($KERNEL)" --loader "EFI\linux\archlinux-$KERNEL.efi" --unicode --verbose
  else
    if [ -n "$INITRD_MICROCODE" ]; then
      local MICROCODE="initrd=\\$INITRD_MICROCODE"
    fi

    arch-chroot "${MNT_DIR}" efibootmgr --unicode --disk "$DEVICE" --part 1 --create --label "Arch Linux ($KERNEL)" --loader /vmlinuz-"$KERNEL" --unicode "$CMDLINE_LINUX $CMDLINE_LINUX_ROOT rw $MICROCODE initrd=\initramfs-$KERNEL.img" --verbose
    arch-chroot "${MNT_DIR}" efibootmgr --unicode --disk "$DEVICE" --part 1 --create --label "Arch Linux ($KERNEL fallback)" --loader /vmlinuz-"$KERNEL" --unicode "$CMDLINE_LINUX $CMDLINE_LINUX_ROOT rw $MICROCODE initrd=\initramfs-$KERNEL-fallback.img" --verbose
  fi
}
#------------------------------------------------------------------------------------------------------#
function mkinitcpio_configuration() {
  print_step "mkinitcpio Configuration"

  if [ "$KMS" == "true" ]; then
    local MKINITCPIO_KMS_MODULES=""
    case "$DISPLAY_DRIVER" in
    "intel")
      local MKINITCPIO_KMS_MODULES="i915"
      ;;
    "amdgpu")
      local MKINITCPIO_KMS_MODULES="amdgpu"
      ;;
    "ati")
      local MKINITCPIO_KMS_MODULES="radeon"
      ;;
    "nvidia" | "nvidia-lts" | "nvidia-dkms")
      local MKINITCPIO_KMS_MODULES="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
      ;;
    "nouveau")
      local MKINITCPIO_KMS_MODULES="nouveau"
      ;;
    esac
    local MODULES="$MODULES $MKINITCPIO_KMS_MODULES"
  fi
  if [ "$DISPLAY_DRIVER" == "intel" ]; then
    local OPTIONS=""
    if [ "$FASTBOOT" == "true" ]; then
      local OPTIONS="$OPTIONS fastboot=1"
    fi
    if [ "$FRAMEBUFFER_COMPRESSION" == "true" ]; then
      local OPTIONS="$OPTIONS enable_fbc=1"
    fi
    if [ -n "$OPTIONS" ]; then
      echo "options i915 $OPTIONS" >"${MNT_DIR}"/etc/modprobe.d/i915.conf
    fi
  fi

  if [ "$LVM" == "true" ]; then
    HOOKS=${HOOKS//!lvm2/lvm2}
  fi
  if [ "$BOOTLOADER" == "systemd" ]; then
    HOOKS=${HOOKS//!systemd/systemd}
    HOOKS=${HOOKS//!sd-vconsole/sd-vconsole}
    if [ -n "$LUKS_PASSWORD" ]; then
      HOOKS=${HOOKS//!sd-encrypt/sd-encrypt}
    fi
  elif [ "$GPT_AUTOMOUNT" == "true" ] && [ -n "$LUKS_PASSWORD" ]; then
    HOOKS=${HOOKS//!systemd/systemd}
    HOOKS=${HOOKS//!sd-vconsole/sd-vconsole}
    HOOKS=${HOOKS//!sd-encrypt/sd-encrypt}
  else
    HOOKS=${HOOKS//!udev/udev}
    HOOKS=${HOOKS//!usr/usr}
    HOOKS=${HOOKS//!keymap/keymap}
    HOOKS=${HOOKS//!consolefont/consolefont}
    if [ -n "$LUKS_PASSWORD" ]; then
      HOOKS=${HOOKS//!encrypt/encrypt}
    fi
  fi

  HOOKS=$(sanitize_variable "$HOOKS")
  MODULES=$(sanitize_variable "$MODULES")
  arch-chroot "${MNT_DIR}" sed -i "s/^HOOKS=(.*)$/HOOKS=($HOOKS)/" /etc/mkinitcpio.conf
  arch-chroot "${MNT_DIR}" sed -i "s/^MODULES=(.*)/MODULES=($MODULES)/" /etc/mkinitcpio.conf

  if [ "$KERNELS_COMPRESSION" != "" ]; then
    arch-chroot "${MNT_DIR}" sed -i 's/^#COMPRESSION="'"$KERNELS_COMPRESSION"'"/COMPRESSION="'"$KERNELS_COMPRESSION"'"/' /etc/mkinitcpio.conf
  fi

  if [ "$KERNELS_COMPRESSION" == "bzip2" ]; then
    pacman_install "bzip2"
  fi
  if [ "$KERNELS_COMPRESSION" == "lzma" ] || [ "$KERNELS_COMPRESSION" == "xz" ]; then
    pacman_install "xz"
  fi
  if [ "$KERNELS_COMPRESSION" == "lzop" ]; then
    pacman_install "lzop"
  fi
  if [ "$KERNELS_COMPRESSION" == "lz4" ]; then
    pacman_install "lz4"
  fi
  if [ "$KERNELS_COMPRESSION" == "zstd" ]; then
    pacman_install "zstd"
  fi

  if [ "$UKI" == "true" ]; then
    mkdir -p "${MNT_DIR}${ESP_DIRECTORY}/EFI/linux"

    mkinitcpio_preset "linux"
    if [ -n "$KERNELS" ]; then
      IFS=' ' read -r -a KS <<<"$KERNELS"
      for KERNEL in "${KS[@]}"; do
        if [[ "$KERNEL" =~ ^.*-headers$ ]]; then
          continue
        fi
        mkinitcpio_preset "$KERNEL"
      done
    fi
  fi
}

function mkinitcpio_preset() {
  local KERNEL="$1"

  cat <<EOT >"${MNT_DIR}/etc/mkinitcpio.d/$KERNEL.preset"
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-$KERNEL"
ALL_microcode=(/boot/*-ucode.img)

PRESETS=('default' 'fallback')

default_uki="${ESP_DIRECTORY}/EFI/linux/archlinux-$KERNEL.efi"

fallback_uki="${ESP_DIRECTORY}/EFI/linux/archlinux-$KERNEL-fallback.efi"
fallback_options="-S autodetect"
EOT
}

function mkinitcpio() {
  print_step "mkinitcpio"

  arch-chroot "${MNT_DIR}" mkinitcpio -P
}
#------------------------------------------------------------------------------------------------------#
function custom_shell() {
  print_step "custom_shell()"

  local CUSTOM_SHELL_PATH=""
  case "$CUSTOM_SHELL" in
  "zsh")
    pacman_install "zsh"
    local CUSTOM_SHELL_PATH="/usr/bin/zsh"
    ;;
  "dash")
    pacman_install "dash"
    local CUSTOM_SHELL_PATH="/usr/bin/dash"
    ;;
  "fish")
    pacman_install "fish"
    local CUSTOM_SHELL_PATH="/usr/bin/fish"
    ;;
  esac

  if [ -n "$CUSTOM_SHELL_PATH" ]; then
    custom_shell_user "root" $CUSTOM_SHELL_PATH
    custom_shell_user "$USER_NAME" $CUSTOM_SHELL_PATH
    for U in "${ADDITIONAL_USERS[@]}"; do
      local S=()
      IFS='=' read -ra S <<<"$U"
      local USER=${S[0]}
      custom_shell_user "$USER" $CUSTOM_SHELL_PATH
    done
  fi
}

function custom_shell_user() {
  local USER="$1"
  local CUSTOM_SHELL_PATH="$2"

  if [ "$SYSTEMD_HOMED" == "true" ] && [ "$USER" != "root" ]; then
    homectl update --shell="$CUSTOM_SHELL_PATH" "$USER"
  else
    arch-chroot "${MNT_DIR}" chsh -s "$CUSTOM_SHELL_PATH" "$USER"
  fi
}
#------------------------------------------------------------------------------------------------------#
function desktop_environment() {
  print_step "desktop_environment()"

  case "$DESKTOP_ENVIRONMENT" in
  "hyprland")
    pacman_install "hyprland"
    ;;
  "gnome")
    pacman_install "gnome"
    ;;
  "kde")
    pacman_install "plasma-meta kde-system-meta kde-utilities-meta kde-graphics-meta kde-multimedia-meta kde-network-meta"
    ;;
  "xfce")
    pacman_install "xfce4 xfce4-goodies xorg-server pavucontrol pulseaudio"
    ;;
  "mate")
    pacman_install "mate mate-extra xorg-server"
    ;;
  "cinnamon")
    pacman_install "cinnamon gnome-terminal xorg-server"
    ;;
  "lxde")
    pacman_install "lxde"
    ;;
  "i3-wm")
    pacman_install "i3-wm i3blocks i3lock i3status dmenu rxvt-unicode xorg-server"
    ;;
  "i3-gaps")
    pacman_install "i3-gaps i3blocks i3lock i3status dmenu rxvt-unicode xorg-server"
    ;;
  "deepin")
    pacman_install "deepin deepin-extra deepin-kwin xorg xorg-server"
    ;;
  "budgie")
    pacman_install "budgie-desktop budgie-desktop-view budgie-screensaver gnome-control-center network-manager-applet gnome"
    ;;
  "bspwm")
    pacman_install "bspwm"
    ;;
  "awesome")
    pacman_install "awesome vicious xterm xorg-server"
    ;;
  "qtile")
    pacman_install "qtile xterm xorg-server"
    ;;
  "openbox")
    pacman_install "openbox obconf xterm xorg-server"
    ;;
  "leftwm")
    aur_install "leftwm-git leftwm-theme-git dmenu xterm xorg-server"
    ;;
  "dusk")
    aur_install "dusk-git dmenu xterm xorg-server"
    ;;
  esac

  arch-chroot "${MNT_DIR}" systemctl set-default graphical.target
}

function display_manager() {
  print_step "display_manager()"

  if [ "$DISPLAY_MANAGER" == "auto" ]; then
    case "$DESKTOP_ENVIRONMENT" in
    "gnome" | "budgie")
      display_manager_gdm
      ;;
    "kde")
      display_manager_sddm
      ;;
    "lxde")
      display_manager_lxdm
      ;;
    "hyprland" | "xfce" | "mate" | "cinnamon" | "i3-wm" | "i3-gaps" | "deepin" | "bspwm" | "awesome" | "qtile" | "openbox" | "leftwm" | "dusk")
      display_manager_lightdm
      ;;
    esac
  else
    case "$DISPLAY_MANAGER" in
    "gdm")
      display_manager_gdm
      ;;
    "sddm")
      display_manager_sddm
      ;;
    "lightdm")
      display_manager_lightdm
      ;;
    "lxdm")
      display_manager_lxdm
      ;;
    esac
  fi
}

function display_manager_gdm() {
  pacman_install "gdm"
  arch-chroot "${MNT_DIR}" systemctl enable gdm.service
}

function display_manager_sddm() {
  pacman_install "sddm"
  arch-chroot "${MNT_DIR}" systemctl enable sddm.service
}

function display_manager_lightdm() {
  pacman_install "lightdm lightdm-gtk-greeter"
  arch-chroot "${MNT_DIR}" systemctl enable lightdm.service
  user_add_groups_lightdm

  if [ "$DESKTOP_ENVIRONMENT" == "deepin" ]; then
    arch-chroot "${MNT_DIR}" sed -i 's/^#greeter-session=.*/greeter-session=lightdm-deepin-greeter/' /etc/lightdm/lightdm.conf
    arch-chroot "${MNT_DIR}" systemctl enable lightdm.service
  fi
}

function display_manager_lxdm() {
  pacman_install "lxdm"
  arch-chroot "${MNT_DIR}" systemctl enable lxdm.service
}

function user_add_groups_lightdm() {
  arch-chroot "${MNT_DIR}" groupadd -r "autologin"
  user_add_groups "$USER_NAME" "autologin"

  for U in "${ADDITIONAL_USERS[@]}"; do
    local S=()
    IFS='=' read -ra S <<<"$U"
    local USER=${S[0]}
    user_add_groups "$USER" "autologin"
  done
}
#------------------------------------------------------------------------------------------------------#
function packages() {
  print_step "Packages"

  if [ "$PACKAGES_INSTALL" == "true" ]; then
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

    aur_command_install "$AUR_PACKAGE"

    listPkgDefault="${1:-"./Install/Hosts/Default/packages.lst"}"
    listPkgHost="${1:-"./Install/Hosts/${HOSTNAME}/packages.lst"}"
    archPkg=()
    aurPkg=()
    ofs=$IFS
    IFS='|'

    process_package_list "${listPkgDefault}"
    process_package_list "${listPkgHost}"

    IFS=${ofs}

    if [[ ${#archPkg[@]} -gt 0 ]]; then
      pacman_install "${archPkg[@]}"
    fi

    if [[ ${#aurPkg[@]} -gt 0 ]]; then
      aur_install "${aurPkg[@]}"
    fi
  fi
}

function aur_command_install() {
  pacman_install "git"
  local PACKAGE="$1"
  execute_aur "rm -rf /home/$USER_NAME/.archwrld && mkdir -p /home/$USER_NAME/.archwrld/aur && cd /home/$USER_NAME/.archwrld/aur && git clone https://aur.archlinux.org/${PACKAGE}.git && (cd $PACKAGE && makepkg -si --noconfirm) && rm -rf /home/$USER_NAME/.archwrld"
}

function execute_aur() {
  local COMMAND="$1"
  if [ "$SYSTEM_INSTALLATION" == "true" ]; then
    arch-chroot "${MNT_DIR}" sed -i 's/^%wheel ALL=(ALL:ALL) ALL$/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
    arch-chroot "${MNT_DIR}" bash -c "echo -e \"$USER_PASSWORD\n$USER_PASSWORD\n$USER_PASSWORD\n$USER_PASSWORD\n\" | su $USER_NAME -s /usr/bin/bash -c \"$COMMAND\""
    arch-chroot "${MNT_DIR}" sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL$/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
  else
    bash -c "$COMMAND"
  fi
}

process_package_list() {
  local listPkg="$1"

  # Loop through the package list
  while read -r pkg deps; do
    pkg="${pkg// /}" # Remove spaces from the package name
    if [ -z "${pkg}" ]; then
      continue
    fi

    # Check dependencies
    if [ ! -z "${deps}" ]; then
      deps="${deps%"${deps##*[![:space:]]}"}" # Strip trailing spaces from dependencies
      while read -r cdep; do
        pass=$(cut -d '#' -f 1 "${listPkg}" | awk -F '|' -v chk="${cdep}" '{if($1 == chk) {print 1;exit}}')
        if [ -z "${pass}" ]; then
          if pkg_installed "${cdep}"; then
            pass=1
          else
            break
          fi
        fi
      done < <(echo "${deps}" | xargs -n1)

      # Skip package if dependencies are missing
      if [[ ${pass} -ne 1 ]]; then
        echo -e "\033[0;33m[skip]\033[0m ${pkg} is missing (${deps}) dependency..."
        continue
      fi
    fi

    # Check if the package is installed or available
    if pkg_installed "${pkg}"; then
      echo -e "\033[0;33m[skip]\033[0m ${pkg} is already installed..."
    elif pkg_available "${pkg}"; then
      repo=$(pacman -Si "${pkg}" | awk -F ': ' '/Repository / {print $2}')
      echo -e "\033[0;32m[${repo}]\033[0m queueing ${pkg} from official arch repo..."
      archPkg+=("${pkg}")
    elif aur_available "${pkg}"; then
      echo -e "\033[0;34m[aur]\033[0m queueing ${pkg} from arch user repo..."
      aurhPkg+=("${pkg}")
    else
      echo "Error: unknown package ${pkg}..."
    fi
  done < <(cut -d '#' -f 1 "${listPkg}")
}

function aur_install() {
  local ERROR="true"
  local PACKAGES=()
  set +e
  which "$AUR_COMMAND"
  if [ "$AUR_COMMAND" != "0" ]; then
    aur_command_install "$USER_NAME" "$AUR_PACKAGE"
  fi
  IFS=' ' read -ra PACKAGES <<<"$1"
  for VARIABLE in {1..5}; do
    local COMMAND="$AUR_COMMAND -Syu --noconfirm --needed ${PACKAGES[*]}"
    if execute_aur "$COMMAND"; then
      local ERROR="false"
      break
    else
      sleep 10
    fi
  done
  set -e
  if [ "$ERROR" == "true" ]; then
    return
  fi
}

function pkg_installed() {
  local PkgIn=$1

  local COMMAND="pacman -Qi ${PkgIn}"
  if arch-chroot "${MNT_DIR}" bash -c "$COMMAND" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

function pkg_available() {
  local PkgIn=$1

  if pacman -Si "${PkgIn}" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

function aur_available() {
  local PkgIn=$1

  if ${AUR_COMMAND} -Si "${PkgIn}" &>/dev/null; then
    return 0
  else
    return 1
  fi
}
#------------------------------------------------------------------------------------------------------#
function end_install() {
  echo ""
  echo -e "${GREEN}Arch Linux installed successfully"'!'"${NC}"
  echo ""

  mkdir -p "${MNT_DIR}"/home/${USER_NAME}/.archwrld
  cp -r ./* "${MNT_DIR}"/home/${USER_NAME}/.archwrld
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
  clear

  CONFIG_FILE="archwrld.conf"

  while getopts "c:" opt; do
    case $opt in
    c) CONFIG_FILE="$OPTARG" ;;
    \?)
      echo "Usage: $0 [-c Config File Name]"
      exit 1
      ;;
    esac
  done

  load_config
  sanitize_variables
  check_variables

  print_logo

  until main_menu; do :; done
}

main "$@"
