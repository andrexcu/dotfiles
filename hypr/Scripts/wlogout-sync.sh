#!/bin/bash


WALLPAPER=$(awww query | awk -F'image: ' '/image:/ {print $2}')
echo  $WALLPAPER
# SELECTED="$CURRENT_WALLPAPER"
# Remove file:// prefix
WALLPAPER="${WALLPAPER#file://}"
# Get current KDE wallpaper
# WALLPAPER=$(qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
# var d = desktops()[0];
# d.currentConfigGroup = ['Wallpaper','org.kde.image','General'];
# print(d.readConfig('Image'));
# ")
# Paths
WALL_DIR="$HOME/Pictures/Wallpaper"
WALL_NAME="$(basename "$WALLPAPER")"

BLUR_BG="$HOME/.config/wlogout/images/wallpaper_blurred.png"


# WL_TEMPLATE="$HOME/.config/wlogout/style-template.css"
WLCSS="$HOME/.config/wlogout/style.css"

mkdir -p "$(dirname "$BLUR_BG")"

# Generate Blurred Wallpaper (use full path to avoid issues)
magick "$WALLPAPER" \
  -resize 1920x1080^ \
  -gravity center \
  -extent 1920x1080 \
  -blur 0x8 \
  -fill black \
  -colorize 65% \
  "$BLUR_BG"

# === UPDATE STYLE.CSS ===
# cat "$WL_TEMPLATE" > "$WLCSS"