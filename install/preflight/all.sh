source $ARCHWRLD_INSTALL/preflight/guard.sh
source $ARCHWRLD_INSTALL/preflight/begin.sh
run_logged $ARCHWRLD_INSTALL/preflight/show-env.sh
run_logged $ARCHWRLD_INSTALL/preflight/pacman.sh
run_logged $ARCHWRLD_INSTALL/preflight/migrations.sh
run_logged $ARCHWRLD_INSTALL/preflight/first-run-mode.sh
run_logged $ARCHWRLD_INSTALL/preflight/disable-mkinitcpio.sh
