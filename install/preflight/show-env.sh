# Show installation environment variables
gum log --level info "Installation Environment:"

env | grep -E "^(ARCHWRLD_CHROOT_INSTALL|ARCHWRLD_ONLINE_INSTALL|ARCHWRLD_USER_NAME|ARCHWRLD_USER_EMAIL|USER|HOME|ARCHWRLD_REPO|ARCHWRLD_REF|ARCHWRLD_PATH)=" | sort | while IFS= read -r var; do
  gum log --level info "  $var"
done
