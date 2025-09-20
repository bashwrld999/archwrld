echo "Add UWSM env"

export ARCHWRLD_PATH="$HOME/.local/share/archwrld"
export PATH="$ARCHWRLD_PATH/bin:$PATH"

mkdir -p "$HOME/.config/uwsm/"
archwrld-refresh-config uwsm/env

echo -e "\n\e[31mArchWRLD bins have been added to PATH (and ARCHWRLD_PATH is now system-wide).\nYou must immediately relaunch Hyprland or most ArchWRLD cmds won't work.\nPlease run ArchWRLD > Update again after the quick relaunch is complete.\e[0m"
echo

mkdir -p ~/.local/state/archwrld/migrations
gum confirm "Ready to relaunch Hyprland? (All applications will be closed)" &&
  touch ~/.local/state/archwrld/migrations/1751134560.sh &&
  uwsm stop
