#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# Define ArchWRLD locations
export ARCHWRLD_PATH="$HOME/.local/share/archwrld"
export ARCHWRLD_INSTALL="$ARCHWRLD_PATH/install"
export ARCHWRLD_INSTALL_LOG_FILE="/var/log/archwrld-install.log"
export PATH="$ARCHWRLD_PATH/bin:$PATH"

# Install
source "$ARCHWRLD_INSTALL/helpers/all.sh"
source "$ARCHWRLD_INSTALL/preflight/all.sh"
source "$ARCHWRLD_INSTALL/packaging/all.sh"
source "$ARCHWRLD_INSTALL/config/all.sh"
source "$ARCHWRLD_INSTALL/login/all.sh"
source "$ARCHWRLD_INSTALL/post-install/all.sh"
