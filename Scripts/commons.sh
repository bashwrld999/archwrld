ARCHWRLD_CONF_FILE="archwrld.conf"
ARCHWRLD_LOG_FILE="archwrld.log"

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
