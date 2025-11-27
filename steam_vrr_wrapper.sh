#!/bin/bash

# Default path if installed via AUR/package
MAIN_SCRIPT_PATH="/usr/bin/vrr_toggle.sh"

# If not found, try to look for it in local scripts or current path
if [ ! -f "$MAIN_SCRIPT_PATH" ]; then
    # Fallback/User Configuration: Set the full path to your script if it's not in /usr/bin
    # MAIN_SCRIPT_PATH="/home/YOUR_USER/scripts/vrr_toggle.sh"

    # Check if we can find it in the same directory as this wrapper?
    # Or just fail if not configured.
    if [ -f "$HOME/scripts/vrr_toggle.sh" ]; then
        MAIN_SCRIPT_PATH="$HOME/scripts/vrr_toggle.sh"
    fi
fi

if [ ! -f "$MAIN_SCRIPT_PATH" ]; then
    echo "Error: vrr_toggle.sh not found at $MAIN_SCRIPT_PATH"
    echo "Please configure MAIN_SCRIPT_PATH in steam_vrr_wrapper.sh"
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
