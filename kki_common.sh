#!/usr/bin/env bash

set -e

# Shared helpers for kube-scripts
# - clean_ansi: strip ANSI escape codes
# - choose / choose_with_dialog / choose_with_select: selection UI
# - select_pod: choose a running pod
# - select_container: choose a container from a pod

clean_ansi() {
    printf "%s" "$1" | sed -r $'s/\x1B\\[[0-9;]*[A-Za-z]//g'
}

HAS_DIALOG=false
if command -v dialog >/dev/null 2>&1; then
    HAS_DIALOG=true
fi

choose_with_dialog() {
    local title="$1"; shift
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
    choice=$(clean_ansi "$choice")
    if [ -z "$choice" ]; then
        echo ""
        return 1
    fi
    echo "${options[$((choice-1))]}"
}

choose_with_select() {
    local title="$1"; shift
    local options=("$@")
    # Print the menu UI to stderr so command substitution captures only the selected value on stdout.
    exec 3>&1
    {
        echo "$title" >&2
        PS3="Select an option: "
        select opt in "${options[@]}"; do
            if [ -n "$opt" ]; then
                printf '%s\n' "$opt" >&3
                exec 3>&-
                return 0
            else
                echo "Invalid selection" >&2
            fi
        done
    } 1>&2
}

choose() {
    local title="$1"; shift
    local options=("$@")
    if $HAS_DIALOG; then
        choose_with_dialog "$title" "${options[@]}"
    else
        choose_with_select "$title" "${options[@]}"
    fi
}

select_pod() {
    mapfile -t PODS < <(kubectl get pods --no-headers --field-selector=status.phase=Running | awk '{print $1}')
    if [ ${#PODS[@]} -eq 0 ]; then
        echo ""
        return 1
    fi
    choose "Select a running pod" "${PODS[@]}"
}

select_container() {
    local pod="$1"
    CONTAINERS=($(kubectl get pod "$pod" -o jsonpath='{.spec.containers[*].name}'))
    if [ ${#CONTAINERS[@]} -eq 0 ]; then
        echo ""
        return 1
    fi
    if [ ${#CONTAINERS[@]} -eq 1 ]; then
        echo "${CONTAINERS[0]}"
    else
        choose "Pod has multiple containers. Select one:" "${CONTAINERS[@]}"
    fi
}
