#!/bin/bash

exec 200>/tmp/wlogout.lock
flock -n 200 || exit 0

TXT_DIR="$HOME/.config/wlogout/images"

# Get current wallpaper
WALLPAPER=$(qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
var d = desktops()[0];
d.currentConfigGroup = ['Wallpaper','org.kde.image','General'];
print(d.readConfig('Image'));
")
WALLPAPER="${WALLPAPER#file://}"
WAL_NAME="$(basename "$WALLPAPER")"
WAL_BASE="${WAL_NAME%.*}"

# Wait for blur TXT file
MAX_ITER=50
SLEEP_INTERVAL=0.1
ITER=0
while [[ ! -f "$TXT_DIR/$WAL_BASE.txt" && $ITER -lt $MAX_ITER ]]; do
    sleep $SLEEP_INTERVAL
    ((ITER++))
done

# Launch wlogout only if file exists
if [[ -f "$TXT_DIR/$WAL_BASE.txt" ]]; then
    /usr/bin/wlogout
else
    notify-send "wlogout" "Blurred wallpaper not ready"
fi