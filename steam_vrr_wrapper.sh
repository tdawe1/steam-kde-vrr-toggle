#!/bin/bash

MAIN_SCRIPT_PATH="/home/thomas/scripts/vrr_toggle.sh"

if [ ! -f "$MAIN_SCRIPT_PATH" ]; then
    exit 1
fi

systemd-run \
    --user \
    --no-block \
    --setenv=WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
    --setenv=XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
    --setenv=DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
    "$MAIN_SCRIPT_PATH" off

"$@"

systemd-run \
    --user \
    --no-block \
    --setenv=WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
    --setenv=XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
    --setenv=DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
    "$MAIN_SCRIPT_PATH" restore
