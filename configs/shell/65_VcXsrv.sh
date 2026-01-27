# Use WSLg (built-in X server for WSL2) instead of VcXsrv
# WSLg uses Unix sockets, avoiding network/firewall issues
export DISPLAY=:0
unset WAYLAND_DISPLAY

# Update systemd environment for GUI apps started via systemd
dbus-update-activation-environment --systemd DISPLAY

