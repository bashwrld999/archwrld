#!/bin/bash
CURRENT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
for f in $(find "${CURRENT_DIR}/" -type f ! -name "mainmenu.sh" ! -name "menu.sh"); do source $f; done

# return types:
# 0 - success
# 1 - error
# 2 - exit
# 3 - show menu again
menu() {
  $@
  local exitcode="$?"
  if [ "$exitcode" = "3" ]; then
    menu $@
    exitcode="$?"
  fi
  return "$exitcode"
}

# return types:
# 0 - next menu
# 1 - one menu back
# 2 - exit
menuFlow() {
  local i=1
  while [ "$i" -le "$#" ]; do
    eval "\${$i}"
    local exitcode="$?"
    if [ "$exitcode" = "0" ]; then
      if [ "$i" -eq "$#" ]; then
        return 0
      fi
      i=$((i + 1))
    elif [ "$exitcode" = "2" ]; then
      return 0
    else
      if [ "$i" -eq "1" ]; then
        return 1
      fi
      i=$((i - 1))
    fi
  done
}
