ARCHWRLD_MIGRATIONS_STATE_PATH=~/.local/state/archwrld/migrations
mkdir -p $ARCHWRLD_MIGRATIONS_STATE_PATH

for file in ~/.local/share/archwrld/migrations/*.sh; do
  touch "$ARCHWRLD_MIGRATIONS_STATE_PATH/$(basename "$file")"
done
