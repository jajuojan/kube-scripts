#!/usr/bin/env bash

set -e

# Description: Helper to choose a running Kubernetes pod and display the log
# in a selected container. Uses `dialog` for a curses UI when
# available, falling back to a Bash `select` menu. Strips ANSI escape codes
# from dialog output so selections remain clean.
#
# Usage: ./kki_logs.sh
# Requirements: `kubectl` in PATH; optional `dialog` for GUI-like menus.

# source shared helpers
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$DIR/kki_common.sh"

# --- Step 1: Choose pod ---
POD=$(select_pod) || { echo "No running pods found."; exit 1; }
POD=$(clean_ansi "$POD")

# --- Step 2: Get containers ---
CONTAINER=$(select_container "$POD") || { echo "No containers found in pod $POD."; exit 1; }
CONTAINER=$(clean_ansi "$CONTAINER")

# --- Step 3: Show logs in container ---
echo "Showing logs in pod: $POD, container: $CONTAINER"
kubectl logs "$POD" -c "$CONTAINER"
