#!/bin/bash

LOCKFILE="/tmp/wofi-launch-$UID.lock"
exec 200>"$LOCKFILE"
flock -n 200 || {
    echo "Another instance of wofi-launch is already running."
    exit 0
}

wofi