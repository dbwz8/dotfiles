# Use WSLg (built-in X server for WSL2) instead of VcXsrv.
if [ -d /mnt/wslg/runtime-dir ]; then
    export DISPLAY=:0
    unset WAYLAND_DISPLAY

    if command -v dbus-update-activation-environment >/dev/null 2>&1; then
        dbus-update-activation-environment --systemd DISPLAY
    fi
fi

