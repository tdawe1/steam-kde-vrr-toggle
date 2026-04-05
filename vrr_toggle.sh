#!/bin/bash

set -euo pipefail

KS_CMD="/usr/bin/kscreen-doctor"
JQ_CMD="/usr/bin/jq"
FLOCK_CMD="/usr/bin/flock"

STATE_ROOT="${XDG_RUNTIME_DIR:-/tmp}/steam-kde-vrr-toggle"
LOCK_FILE="$STATE_ROOT/lock"
SESSIONS_DIR="$STATE_ROOT/sessions"
ORIGINAL_STATE_FILE="$STATE_ROOT/original-state.json"

usage() {
	printf 'Usage: %s {off|restore} SESSION_ID\n' "$0" >&2
	exit 64
}

require_command() {
	if [[ ! -x "$1" ]]; then
		printf '[VRR_TOGGLE] Missing required executable: %s\n' "$1" >&2
		exit 69
	fi
}

session_file() {
	printf '%s/%s.state' "$SESSIONS_DIR" "$1"
}

prune_stale_sessions() {
	shopt -s nullglob
	local session_files=("$SESSIONS_DIR"/*.state)
	shopt -u nullglob
	local session_file owner_pid

	for session_file in "${session_files[@]}"; do
		owner_pid="$(<"$session_file")"

		if [[ ! "$owner_pid" =~ ^[0-9]+$ ]] || ! kill -0 "$owner_pid" 2>/dev/null; then
			rm -f "$session_file"
		fi
	done
}

disable_vrr() {
	local state_file="$1"

	while IFS= read -r output_name; do
		[[ -n "$output_name" ]] || continue
		printf '[VRR_TOGGLE] Disabling VRR on %s\n' "$output_name"
		"$KS_CMD" "output.${output_name}.vrrpolicy.off"
	done < <("$JQ_CMD" -r '.outputs[] | select(.enabled == true) | .name' <"$state_file")
}

restore_vrr() {
	local state_file="$1"

	while IFS= read -r output_name original_vrr_policy; do
		[[ "$original_vrr_policy" != "null" ]] || continue
		printf '[VRR_TOGGLE] Restoring %s to %s\n' "$output_name" "$original_vrr_policy"
		"$KS_CMD" "output.${output_name}.vrrpolicy.${original_vrr_policy}"
	done < <("$JQ_CMD" -r '.outputs[] | select(.enabled == true) | "\(.name) \(.vrrpolicy)"' <"$state_file")
}

has_active_sessions() {
	shopt -s nullglob
	local session_files=("$SESSIONS_DIR"/*.state)
	shopt -u nullglob
	((${#session_files[@]} > 0))
}

main() {
	local action="${1:-}"
	local session_id="${2:-}"

	[[ -n "$action" && -n "$session_id" ]] || usage
	[[ "$session_id" =~ ^[A-Za-z0-9._-]+$ ]] || {
		printf '[VRR_TOGGLE] Invalid session id: %s\n' "$session_id" >&2
		exit 64
	}

	require_command "$KS_CMD"
	require_command "$JQ_CMD"
	require_command "$FLOCK_CMD"

	mkdir -p "$SESSIONS_DIR"
	exec 9>"$LOCK_FILE"
	"$FLOCK_CMD" 9
	prune_stale_sessions

	local current_session_file
	current_session_file="$(session_file "$session_id")"

	case "$action" in
	off)
		if [[ ! -f "$ORIGINAL_STATE_FILE" ]]; then
			local pending_state_file
			pending_state_file="$STATE_ROOT/original-state.json.$$.tmp"

			printf '[VRR_TOGGLE] Capturing current VRR state\n'
			"$KS_CMD" -j >"$pending_state_file"
			disable_vrr "$pending_state_file"
			mv "$pending_state_file" "$ORIGINAL_STATE_FILE"
		fi

		printf '%s\n' "${STEAM_VRR_WRAPPER_PID:-}" >"$current_session_file"
		;;
	restore)
		rm -f "$current_session_file"

		if [[ -f "$ORIGINAL_STATE_FILE" ]] && ! has_active_sessions; then
			restore_vrr "$ORIGINAL_STATE_FILE"
			rm -f "$ORIGINAL_STATE_FILE"
		fi
		;;
	*)
		usage
		;;
	esac
}

main "$@"
