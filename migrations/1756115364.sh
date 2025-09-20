echo "Replace buggy native Zoom client with webapp"

if archwrld-pkg-present zoom; then
  archwrld-pkg-drop zoom
  archwrld-webapp-install "Zoom" https://app.zoom.us/wc/home https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/zoom.png
fi
