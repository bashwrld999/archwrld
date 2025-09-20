echo "6Ghz Wi-Fi + Intel graphics acceleration for existing installations"

bash "$ARCHWRLD_PATH/install/config/hardware/set-wireless-regdom.sh"
bash "$ARCHWRLD_PATH/install/config/hardware/intel.sh"
