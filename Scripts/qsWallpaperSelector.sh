#!/bin/bash

exec 200>"/tmp/quickshell-wallpaper-selector-$UID.lock" 
flock -n 200 || exit 0

QT_QPA_PLATFORMTHEME=qt6ct qs -c ~/.config/quickshell/apps/wallpaper/ &

