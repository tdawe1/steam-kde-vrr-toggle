#!/bin/bash

set -u

MAIN_SCRIPT_PATH="${MAIN_SCRIPT_PATH:-/usr/lib/steam-kde-vrr-toggle/vrr_toggle.sh}"
SESSION_ID="steam-vrr-$$-${RANDOM}"
RESTORE_NEEDED=0

log() {
	printf '[STEAM_VRR_WRAPPER] %s\n' "$1" >&2
}

run_toggle() {
	local action="$1"

	systemd-run \
		--user \
		--wait \
		--collect \
		--quiet \
		--setenv=STEAM_VRR_WRAPPER_PID="$$" \
		--setenv=WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}" \
		--setenv=XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-}" \
		--setenv=DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-}" \
		"$MAIN_SCRIPT_PATH" "$action" "$SESSION_ID"
}

cleanup() {
	local exit_status=$?

	trap - EXIT INT TERM

	if ((RESTORE_NEEDED)); then
		if ! run_toggle restore; then
			log "Failed to restore VRR state"
		fi
	fi

	exit "$exit_status"
}

main() {
	if [[ $# -eq 0 ]]; then
		log "No game command was provided"
		exit 64
	fi

	if [[ ! -x "$MAIN_SCRIPT_PATH" ]]; then
		log "Main script not found or not executable: $MAIN_SCRIPT_PATH"
		exec "$@"
	fi

	if run_toggle off; then
		RESTORE_NEEDED=1
	else
		log "Failed to disable VRR before launch; continuing without changes"
	fi

	trap cleanup EXIT INT TERM
	"$@"
}

main "$@"
