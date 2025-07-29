# KDE Plasma Per-Game VRR Toggle

[![AUR version](https://img.shields.io/aur/version/steam-kde-vrr-toggle)](https://aur.archlinux.org/packages/steam-kde-vrr-toggle)
[![License: 0BSD](https://img.shields.io/badge/License-0BSD-blue.svg)](https://opensource.org/licenses/0BSD)

Automatically toggles VRR / Adaptive-Sync on a per-game basis in KDE Plasma (Wayland). Solves game flickering issues by disabling VRR for specific Steam games.

---

## The Problem

Some games, particularly those running through Proton on Linux, can experience issues like flickering, stuttering, or incorrect frame pacing when Variable Refresh Rate (VRR) is enabled. Manually toggling this setting in System Settings before and after playing is tedious. This project automates that process.

## The Solution

This solution uses a two-script system to reliably manage display settings without being affected by the Steam runtime sandbox:

1.  **`steam-vrr-wrapper.sh`**: A minimal wrapper script placed in the Steam game's launch options. Its only job is to use `systemd-run` to call the main worker script, ensuring it executes in a clean, non-sandboxed user session with the correct environment.

2.  **`vrr-toggle.sh`**: The main worker script that does all the heavy lifting. It communicates directly with the KDE KScreen daemon using the `kscreen-doctor` utility and the correct `vrrpolicy` command to turn VRR off and on.

> **Important Disclaimer:** This script controls the VRR setting *at the Operating System level*. It will not work if your monitor's internal firmware (the On-Screen Display, or OSD) is set to override the OS preference. If your monitor's "Adaptive-Sync" or "FreeSync" setting is permanently enabled via its physical buttons, this script cannot change that.

## Prerequisites

Your system needs the following command-line tools.
-   `bash`
-   `kscreen-doctor` (Part of KDE Plasma)
-   `jq` (A lightweight JSON processor)
-   `systemd`

## Installation

### Method 1: Arch User Repository (AUR) - Recommended

This is the easiest and recommended method for users on Arch Linux and its derivatives (like CachyOS, Manjaro, etc.). The AUR package handles all file placement and configuration automatically.

1.  Make sure you have an AUR helper like `yay` or `paru` installed.
2.  Install the package from the AUR:
    ```bash
    yay -S steam-kde-vrr-toggle
    ```
3.  Skip to the [Usage](#usage) section.

### Method 2: Manual Installation

<details>
<summary>Click here for manual installation instructions</summary>

If you are not on an Arch-based distro or prefer a manual setup, follow these steps.

**1. Create the Scripts**

First, create a directory for your scripts if you don't have one:
```bash
mkdir -p ~/scripts
```

Now, create the two script files below.

**File 1: Main Worker Script: `vrr-toggle.sh`**

Save this code as `~/scripts/vrr-toggle.sh`. This script contains the core logic.

```bash
#!/bin/bash
#
# VRR Toggle Script 
# Toggles VRR between OFF and a sensible default (Automatic).

# --- Configuration: Set the full path to your executables ---
KS_CMD="/usr/bin/kscreen-doctor"
JQ_CMD="/usr/bin/jq"

# --- Main Logic ---
case "$1" in
    off)
        while read -r output_name; do
            $KS_CMD "output.${output_name}.vrrpolicy.off"
        done < <($KS_CMD -j | $JQ_CMD -r '.outputs[] | select(.enabled==true) | .name')
        ;;

    restore)
        while read -r output_name; do
            $KS_CMD "output.${output_name}.vrrpolicy.auto"
        done < <($KS_CMD -j | $JQ_CMD -r '.outputs[] | select(.enabled==true) | .name')
        ;;
esac
```

**File 2: Steam Wrapper Script: `steam_vrr_wrapper.sh`**

Save this code as `~/scripts/steam_vrr_wrapper.sh`. This is the script Steam calls.

```bash
#!/bin/bash
#
# Steam Wrapper Script

# --- USER CONFIGURATION ---
MAIN_SCRIPT_PATH="/home/YOUR_USER/scripts/vrr_toggle.sh"

systemd-run \
    --user --no-block \
    --setenv=WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
    --setenv=XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
    --setenv=DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
    "$MAIN_SCRIPT_PATH" off

"$@"

systemd-run \
    --user --no-block \
    --setenv=WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
    --setenv=XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
    --setenv=DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
    "$MAIN_SCRIPT_PATH" restore
```

**2. Make Scripts Executable**

```bash
chmod +x ~/scripts/vrr_toggle.sh && chmod +x ~/scripts/steam-vrr-wrapper.sh
```

**3. Configure the Wrapper**

Open the `steam_vrr_wrapper.sh` file with a text editor and **replace `YOUR_USER`** with your actual Linux username.
```bash
kate ~/scripts/steam-vrr-wrapper.sh
```

</details>

## Usage

1.  In your Steam Library, right-click the game you want to manage.
2.  Select **Properties...**.
3.  In the **GENERAL** tab, find the **LAUNCH OPTIONS** text box.
4.  Enter the command based on your installation method:

    #### If installed from the AUR:
    The scripts are in your system's PATH, so no full path is needed.
    ```
    steam-vrr-wrapper.sh %command%
    ```

    #### If installed manually:
    You must provide the full path to the wrapper script. Remember to replace `YOUR_USER`.
    ```
    /home/YOUR_USER/scripts/steam-vrr-wrapper.sh %command%
    ```

5.  Close the Properties window. That's it! If your monitor respects OS-level VRR commands, your screen should flicker as the mode is turned off and on.

## Troubleshooting

### Checking the Log

The script's actions are logged to the systemd journal. If you suspect an issue, you can check its log. Open a terminal and run this command to see recent logs from the script:

```bash
journalctl --user -u "vrr-toggle.sh" --since "5 minutes ago"
```
If the log shows the `EXECUTING` and `RESTORING` messages without any errors, the script is working correctly from a software perspective.

### No Screen Flicker / Setting Doesn't Change

If the journal shows the script is working but you see no physical change on your screen, it is almost certain that your **monitor's internal firmware is overriding the command from the OS.**

*   **The Cause:** Many monitors have a primary "Adaptive-Sync" or "FreeSync" setting in their On-Screen Display (OSD) menu (the menu you access with the physical buttons on the monitor). If this is set to "On", it may ignore any requests from the operating system to turn it off.
*   **The Solution:** Use the physical buttons on your monitor to open its OSD menu, navigate to the "Gaming" or "System" section, and ensure the master Adaptive-Sync setting is set to a state that allows OS control, which may be labeled "Off" or "Standard". The ideal scenario is when toggling the setting in KDE's System Settings causes a screen flicker, which confirms the OS has control.
