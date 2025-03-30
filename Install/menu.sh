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
