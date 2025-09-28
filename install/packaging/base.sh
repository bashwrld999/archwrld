# Install all base packages

pkg_installed() {
    local PkgIn=$1

    if pacman -Qi "${PkgIn}" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

pkg_available() {
    local PkgIn=$1

    if pacman -Si "${PkgIn}" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

aur_available() {
    local PkgIn=$1

    if yay -Si "${PkgIn}" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

listPkg="${1:-"$ARCHWRLD_INSTALL/archwrld-base.packages"}"
archPkg=()
aurhPkg=()

while read -r pkg deps; do
    pkg="${pkg// /}"
    if [ -z "${pkg}" ]; then
        continue
    fi

    if [ ! -z "${deps}" ]; then
        deps="${deps%"${deps##*[![:space:]]}"}"
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

        if [[ ${pass} -ne 1 ]]; then
            echo -e "\033[0;33m[skip]\033[0m ${pkg} is missing (${deps}) dependency..."
            continue
        fi
    fi

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

if [[ ${#archPkg[@]} -gt 0 ]]; then
    sudo pacman ${use_default} -S --noconfirm --needed "${archPkg[@]}"
fi

if [[ ${#aurhPkg[@]} -gt 0 ]]; then
    yay ${use_default} -S --noconfirm --needed "${aurhPkg[@]}"
fi