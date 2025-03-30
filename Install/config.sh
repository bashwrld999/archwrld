function sanitize_variable() {
  local VARIABLE="$1"
  local VARIABLE=$(echo "$VARIABLE" | sed "s/![^ ]*//g")       # remove disabled
  local VARIABLE=$(echo "$VARIABLE" | sed -r "s/ {2,}/ /g")    # remove unnecessary white spaces
  local VARIABLE=$(echo "$VARIABLE" | sed 's/^[[:space:]]*//') # trim leading
  local VARIABLE=$(echo "$VARIABLE" | sed 's/[[:space:]]*$//') # trim trailing
  echo "$VARIABLE"
}

function check_variables_value() {
  local NAME="$1"
  local VALUE="$2"
  if [ -z "$VALUE" ]; then
    echo "$NAME environment variable must have a value."
    exit 1
  fi
}

function check_variables_boolean() {
  local NAME="$1"
  local VALUE="$2"
  check_variables_list "$NAME" "$VALUE" "true false" "true" "true"
}

function check_variables_list() {
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

function check_variables_equals() {
  local NAME1="$1"
  local NAME2="$2"
  local VALUE1="$3"
  local VALUE2="$4"
  if [ "$VALUE1" != "$VALUE2" ]; then
    echo "$NAME1 and $NAME2 must be equal [$VALUE1, $VALUE2]."
    exit 1
  fi
}

function check_variables_size() {
  local NAME="$1"
  local SIZE_EXPECT="$2"
  local SIZE="$3"
  if [ "$SIZE_EXPECT" != "$SIZE" ]; then
    echo "$NAME array size [$SIZE] must be [$SIZE_EXPECT]."
    exit 1
  fi
}

function sanitize_variables() {
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

function check_variables() {
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
