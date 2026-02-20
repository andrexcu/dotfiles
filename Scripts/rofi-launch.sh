#!/bin/bash

LOCKFILE="/tmp/rofi-launch-$UID.lock"
exec 200>"$LOCKFILE"
flock -n 200 || {
    echo "Another instance of wofi-launch is already running."
    exit 0
}

rofi -show drun 2>/dev/null
