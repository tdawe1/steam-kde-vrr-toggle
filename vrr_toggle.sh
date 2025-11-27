#!/bin/bash

KS_CMD="/usr/bin/kscreen-doctor"
JQ_CMD="/usr/bin/jq"

STATE_FILE="/tmp/vrr_original_states.json"


case "$1" in
    off)
        echo "[VRR_TOGGLE] Disabling VRR..."

        # Capture current state to a temp file first
        TEMP_STATE=$(mktemp)
        if ! $KS_CMD -j > "$TEMP_STATE"; then
            echo "[VRR_TOGGLE] Error: Failed to query kscreen-doctor state."
            rm -f "$TEMP_STATE"
            exit 1
        fi

        # Validate JSON content
        if ! $JQ_CMD . "$TEMP_STATE" >/dev/null 2>&1; then
            echo "[VRR_TOGGLE] Error: Invalid JSON output from kscreen-doctor."
            rm -f "$TEMP_STATE"
            exit 1
        fi

        # Move valid state to persistent location
        mv "$TEMP_STATE" "$STATE_FILE"

        while read -r output_name; do
            echo "[VRR_TOGGLE] EXECUTING: $KS_CMD output.${output_name}.vrrpolicy.never"
            if ! $KS_CMD "output.${output_name}.vrrpolicy.never"; then
                echo "[VRR_TOGGLE] Error: Failed to disable VRR for $output_name"
                # We continue to try other outputs, but exit with error at the end?
                # Or exit immediately? The comment says "abort with a clear error".
                # But we might have partially applied changes.
                # For now, let's just log it. The wrapper calls this asynchronously anyway.
                exit 1
            fi
        done < <($JQ_CMD -r '.outputs[] | select(.enabled==true) | .name' < "$STATE_FILE")
        ;;

    restore)
        if [[ -f "$STATE_FILE" ]]; then
            echo "[VRR_TOGGLE] Restoring VRR..."
            RESTORE_SUCCESS=true

            while read -r output_name original_vrr_policy; do
                if [[ "$original_vrr_policy" != "null" ]]; then
                    # Map integer values to strings if necessary
                    case "$original_vrr_policy" in
                        0) policy_str="never" ;;
                        1) policy_str="always" ;;
                        2) policy_str="automatic" ;;
                        *) policy_str="$original_vrr_policy" ;; # Fallback for existing string values
                    esac

                    echo "[VRR_TOGGLE] RESTORING: $KS_CMD output.${output_name}.vrrpolicy.${policy_str}"
                    if ! $KS_CMD "output.${output_name}.vrrpolicy.${policy_str}"; then
                        echo "[VRR_TOGGLE] Error: Failed to restore VRR for $output_name"
                        RESTORE_SUCCESS=false
                    fi
                fi
            done < <($JQ_CMD -r '.outputs[] | select(.enabled==true) | "\(.name) \(.vrrpolicy)"' < "$STATE_FILE")

            if [ "$RESTORE_SUCCESS" = true ]; then
                rm "$STATE_FILE"
                echo "[VRR_TOGGLE] Restoration complete."
            else
                echo "[VRR_TOGGLE] Warning: Restoration failed for some outputs. State file preserved."
                exit 1
            fi
        else
            echo "[VRR_TOGGLE] No state file found. Nothing to restore."
        fi
        ;;
esac
