#!/usr/bin/env bash

set -e

# Description: Choose a running Kubernetes pod and show `kubectl describe`
# output for that pod. Uses `dialog` for a curses UI when available and
# falls back to a Bash `select` menu. Strips ANSI escape codes from menu
# output so selections remain clean.
#
# Usage: ./kki_describe.sh
# Requirements: `kubectl` in PATH; optional `dialog` for GUI-like menus.

# source shared helpers
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$DIR/kki_common.sh"

# --- Step 1: Choose pod ---
POD=$(select_pod) || { echo "No running pods found."; exit 1; }
POD=$(clean_ansi "$POD")

# --- Step 2: Describe pod ---
kubectl describe pod "$POD"
