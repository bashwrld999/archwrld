# Set default XCompose that is triggered with CapsLock
tee ~/.XCompose >/dev/null <<EOF
include "%H/.local/share/archwrld/default/xcompose"

# Identification
<Multi_key> <space> <n> : "$ARCHWRLD_USER_NAME"
<Multi_key> <space> <e> : "$ARCHWRLD_USER_EMAIL"
EOF
