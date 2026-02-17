#!/usr/bin/env bash

set -e

# Check if dialog is available
HAS_DIALOG=false
if command -v dialog >/dev/null 2>&1; then
    HAS_DIALOG=true
fi

# Get list of running pods
PODS=($(kubectl get pods --no-headers --field-selector=status.phase=Running | awk '{print $1}'))

if [ ${#PODS[@]} -eq 0 ]; then
    echo "No running pods found."
    exit 1
fi

clean_ansi() {
    printf "%s" "$1" | sed -r 's/\x1B

\[[0-9;]*[A-Za-z]//g'
}

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

    # Strip ANSI escape codes 
    choice=$(printf "%s" "$choice" | sed -r 's/\x1B \[[0-9;]*[A-Za-z]//g')

    if [ -z "$choice" ]; then
        echo "Cancelled."
        exit 1
    fi

    echo "${options[$((choice-1))]}"
}

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

# Step 1: Choose pod
POD=$(choose "Select a running pod" "${PODS[@]}")

# Step 2: Get containers for that pod
CONTAINERS=($(kubectl get pod "$POD" -o jsonpath='{.spec.containers[*].name}'))

POD=$(clean_ansi "$POD")
CONTAINER=$(clean_ansi "$CONTAINER")

if [ ${#CONTAINERS[@]} -eq 1 ]; then
    CONTAINER="${CONTAINERS[0]}"
else
    CONTAINER=$(choose "Pod has multiple containers. Select one:" "${CONTAINERS[@]}")
fi

# Step 3: Exec into the container
echo "Opening shell in pod: $pod, container: $container"
echo

kubectl exec -it "$pod" -c "$container" -- /bin/bash
