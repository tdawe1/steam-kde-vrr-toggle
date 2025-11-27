#!/bin/bash

KS_CMD="/usr/bin/kscreen-doctor"
JQ_CMD="/usr/bin/jq"

STATE_FILE="/tmp/vrr_original_states.json"


case "$1" in
    off)
        echo "[VRR_TOGGLE] Disabling VRR..."
        $KS_CMD -j > "$STATE_FILE"

        while read -r output_name; do
            echo "[VRR_TOGGLE] EXECUTING: $KS_CMD output.${output_name}.vrrpolicy.never"
            $KS_CMD "output.${output_name}.vrrpolicy.never"
        done < <($JQ_CMD -r '.outputs[] | select(.enabled==true) | .name' < "$STATE_FILE")
        ;;

    restore)
        if [[ -f "$STATE_FILE" ]]; then
            echo "[VRR_TOGGLE] Restoring VRR..."
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
                    $KS_CMD "output.${output_name}.vrrpolicy.${policy_str}"
                fi
            done < <($JQ_CMD -r '.outputs[] | select(.enabled==true) | "\(.name) \(.vrrpolicy)"' < "$STATE_FILE")

            rm "$STATE_FILE"
        fi
        ;;
esac
