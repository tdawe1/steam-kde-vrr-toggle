# KDE Plasma Per-Game VRR Toggle

[![AUR version](https://img.shields.io/aur/version/steam-kde-vrr-toggle)](https://aur.archlinux.org/packages/steam-kde-vrr-toggle)
[![License: 0BSD](https://img.shields.io/badge/License-0BSD-blue.svg)](https://opensource.org/licenses/0BSD)

Automatically disables VRR / Adaptive Sync for selected Steam games on KDE Plasma Wayland, then restores the previous display policy when the game exits.

## What It Does

Some games behave poorly with VRR enabled. This project adds a Steam launch wrapper that:

1. Captures the current VRR policy for each enabled display.
2. Disables VRR before the game starts.
3. Restores the original VRR policy after the game exits.

The wrapper runs the worker script through `systemd-run --user` so the display change happens outside the Steam runtime sandbox.

> Important: This only changes the OS-level VRR policy. If your monitor firmware forces Adaptive-Sync on, the scripts cannot override that setting.

## Improvements In v1.0.2

- Waits for VRR to be disabled before launching the game.
- Supports overlapping wrapped game sessions without restoring VRR too early.
- Cleans up stale session markers after interrupted launches.
- Keeps the AUR and manual-install behavior aligned with the same script paths.

## Requirements

- `bash`
- `jq`
- `kscreen-doctor`
- `systemd-run`
- `flock` from `util-linux`

## Installation

### Method 1: Arch User Repository (AUR)

Install the package with your preferred AUR helper:

```bash
yay -S steam-kde-vrr-toggle
```

The package installs:

- `steam_vrr_wrapper.sh` to `/usr/bin/steam_vrr_wrapper.sh`
- `vrr_toggle.sh` to `/usr/lib/steam-kde-vrr-toggle/vrr_toggle.sh`

### Method 2: Manual Installation

Place both scripts somewhere permanent, then make them executable:

```bash
chmod +x /absolute/path/to/vrr_toggle.sh /absolute/path/to/steam_vrr_wrapper.sh
```

If you are not using the packaged path, point the wrapper at the worker script with `MAIN_SCRIPT_PATH`.

## Usage

In the Steam game's launch options, use one of these commands.

### If installed from the AUR

```bash
steam_vrr_wrapper.sh %command%
```

### If installed manually

```bash
MAIN_SCRIPT_PATH="/absolute/path/to/vrr_toggle.sh" /absolute/path/to/steam_vrr_wrapper.sh %command%
```

## Troubleshooting

If the wrapper cannot toggle VRR, it logs a warning and still launches the game.

To inspect recent worker logs:

```bash
journalctl --user --since "10 minutes ago" | grep "VRR_TOGGLE"
```

If the scripts log successful changes but the monitor never flickers or updates, check the monitor OSD and make sure its Adaptive-Sync setting allows OS control.
