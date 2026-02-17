#!/usr/bin/env bash

set -e

# Description: Helper to choose a running Kubernetes pod and display the log
# in a selected container. Uses `dialog` for a curses UI when
# available, falling back to a Bash `select` menu. Strips ANSI escape codes
# from dialog output so selections remain clean.
#
# Usage: ./kki_logs.sh
# Requirements: `kubectl` in PATH; optional `dialog` for GUI-like menus.

# --- Utility: strip ANSI escape codes ---
clean_ansi() {
    printf "%s" "$1" | sed -r $'s/\x1B\\[[0-9;]*[A-Za-z]//g'
}

# --- Check for dialog ---
HAS_DIALOG=false
if command -v dialog >/dev/null 2>&1; then
    HAS_DIALOG=true
fi

# --- Get running pods ---
mapfile -t PODS < <(kubectl get pods --no-headers --field-selector=status.phase=Running | awk '{print $1}')

if [ ${#PODS[@]} -eq 0 ]; then
    echo "No running pods found."
    exit 1
fi

# --- Dialog-based selection ---
choose_with_dialog() {
    local title="$1"
    shift
    local options=("$@")

    local menu_items=()
    local i=1
    for opt in "${options[@]}"; do
        menu_items+=("$i" "$opt")
        ((i++))
    done

    local choice
    choice=$(dialog --clear --stdout --menu "$title" 20 60 15 "${menu_items[@]}")
    clear

    # sanitize
    choice=$(clean_ansi "$choice")

    if [ -z "$choice" ]; then
        echo "Cancelled."
        exit 1
    fi

    echo "${options[$((choice-1))]}"
}

# --- Bash select fallback ---
choose_with_select() {
    local title="$1"
    shift
    local options=("$@")

    echo "$title"
    PS3="Select an option: "
    select opt in "${options[@]}"; do
        if [ -n "$opt" ]; then
            echo "$opt"
            return
        else
            echo "Invalid selection"
        fi
    done
}

# --- Wrapper to choose method ---
choose() {
    local title="$1"
    shift
    local options=("$@")

    if $HAS_DIALOG; then
        choose_with_dialog "$title" "${options[@]}"
    else
        choose_with_select "$title" "${options[@]}"
    fi
}

# --- Step 1: Choose pod ---
POD=$(choose "Select a running pod" "${PODS[@]}")
POD=$(clean_ansi "$POD")

# --- Step 2: Get containers ---
CONTAINERS=($(kubectl get pod "$POD" -o jsonpath='{.spec.containers[*].name}'))

if [ ${#CONTAINERS[@]} -eq 1 ]; then
    CONTAINER="${CONTAINERS[0]}"
else
    CONTAINER=$(choose "Pod has multiple containers. Select one:" "${CONTAINERS[@]}")
fi

CONTAINER=$(clean_ansi "$CONTAINER")

# --- Step 3: Show logs in container ---
echo "Showing logs in pod: $POD, container: $CONTAINER"
kubectl logs "$POD" -c "$CONTAINER"
