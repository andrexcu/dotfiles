#!/bin/bash

# Ensure only one instance runs
exec 200>/tmp/wlogout.lock
flock -n 200 || exit 0

# Minimal environment for hotkeys/panel
export DISPLAY=:0
export XAUTHORITY=/run/user/1000/xauth_ZfjUVo   # adjust to your session
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
export WAYLAND_DISPLAY=wayland-0

# Path to single TXT file
TXT_FILE="$HOME/.config/wlogout/images/current_image.txt"

# Get current wallpaper
WALLPAPER=$(qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
var d = desktops()[0];
d.currentConfigGroup = ['Wallpaper','org.kde.image','General'];
print(d.readConfig('Image'));
")
WALLPAPER="${WALLPAPER#file://}"
WAL_NAME="$(basename "$WALLPAPER")"

# Wait for TXT file's first line to match current wallpaper
MAX_ITER=50
SLEEP_INTERVAL=0.1
ITER=0
wait_for_blur() {
    local iter=0
    while (( iter < MAX_ITER )); do
        if [[ -f "$TXT_FILE" ]]; then
            FIRST_LINE=$(head -n1 "$TXT_FILE" | tr -d '\r\n' | xargs)
            [[ "$FIRST_LINE" == "$WAL_NAME" ]] && return 0
        fi
        ((iter++))
        sleep "$SLEEP_INTERVAL"
    done
    return 1
}

if wait_for_blur; then
    wlogout
fi
# while (( ITER < MAX_ITER )); do
#     if [[ -f "$TXT_FILE" ]]; then
#         FIRST_LINE=$(head -n1 "$TXT_FILE" | tr -d '\r\n')  # remove newline
#         if [[ "$FIRST_LINE" == "$WAL_NAME" ]]; then
#             /usr/bin/wlogout
#             exit 0
#         fi
#     fi
#     ((ITER++))
#     sleep "$SLEEP_INTERVAL"
# done