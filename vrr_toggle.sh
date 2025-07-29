#!/bin/bash

KS_CMD="/usr/bin/kscreen-doctor"
JQ_CMD="/usr/bin/jq"

STATE_FILE="/tmp/vrr_original_states.json"


case "$1" in
    off)
        echo "[VRR_TOGGLE] Disabling VRR..."
        $KS_CMD -j > "$STATE_FILE"

        while read -r output_name; do
            echo "[VRR_TOGGLE] EXECUTING: $KS_CMD output.${output_name}.vrrpolicy.off"
            $KS_CMD "output.${output_name}.vrrpolicy.off"
        done < <($JQ_CMD -r '.outputs[] | select(.enabled==true) | .name' < "$STATE_FILE")
        ;;

    restore)
        if [[ -f "$STATE_FILE" ]]; then
            echo "[VRR_TOGGLE] Restoring VRR..."
            while read -r output_name original_vrr_policy; do
                if [[ "$original_vrr_policy" != "null" ]]; then
                    echo "[VRR_TOGGLE] RESTORING: $KS_CMD output.${output_name}.vrrpolicy.${original_vrr_policy}"
                    $KS_CMD "output.${output_name}.vrrpolicy.${original_vrr_policy}"
                fi
            done < <($JQ_CMD -r '.outputs[] | select(.enabled==true) | "\(.name) \(.vrrpolicy)"' < "$STATE_FILE")

            rm "$STATE_FILE"
        fi
        ;;
esac
