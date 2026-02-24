#!/usr/bin/env bash

CURRENT_WALLPAPER=$(awww query | awk -F'image: ' '/image:/ {print $2}')

SELECTED="$CURRENT_WALLPAPER"

[[ -z "$SELECTED" ]] && { echo "Usage: $0 /path/to/wallpaper.png"; exit 1; }

CACHE="$HOME/.cache/matugen"
mkdir -p "$CACHE"

# Generate JSON palette
matugen image "$SELECTED" -j hex > "$CACHE/colors.json"

# Extract colors from JSON
BG=$(jq -r '.colors.background.dark' "$CACHE/colors.json")
FG=$(jq -r '.colors.on_background.dark' "$CACHE/colors.json")
ACC=$(jq -r '.colors.primary.dark' "$CACHE/colors.json")

# Convert hex to RGB
hex2rgb() {
    local HEX=$1
    echo "$((16#${HEX:1:2})), $((16#${HEX:3:2})), $((16#${HEX:5:2}))"
}

# Convert RGB to rgba() string
rgba() {
    local RGB=$1
    local ALPHA=$2
    echo "rgba($RGB, $ALPHA)"
}

BG_RGB=$(hex2rgb "$BG")
FG_RGB=$(hex2rgb "$FG")
ACC_RGB=$(hex2rgb "$ACC")

# Launcher colors
BG_LAUNCHER=$(rgba "$BG_RGB" 0.85)
FG_LAUNCHER=$(rgba "$FG_RGB" 1)
ACC_LAUNCHER=$(rgba "$ACC_RGB" 0.1)

# Wallpaper picker colors
BG_T90=$(rgba "$BG_RGB" 0.9)
BG_T40=$(rgba "$BG_RGB" 0.4)
FG_T70=$(rgba "$FG_RGB" 0.7)
ACC_T100=$(rgba "$ACC_RGB" 1)


cat > "$CACHE/rofi-colors.rasi" <<EOF
* {
    /* App launcher */
    bg: rgba($BG_RGB, 0.85);
    bg-opaque: rgba($BG_RGB, 1);
    fg: rgba($FG_RGB, 1);
    acc: rgba($ACC_RGB, 0.1);

    /* Wallpaper picker */
    background-t90: rgba($BG_RGB, 0.9);
    background-t80: rgba($BG_RGB, 0.8);
    background-t75: rgba($BG_RGB, 0.75);
    background-t70: rgba($BG_RGB, 0.7);
    background-t60: rgba($BG_RGB, 0.6);
    background-t40: rgba($BG_RGB, 0.4);
    foreground-t70: rgba($FG_RGB, 0.7);
    active: rgba($ACC_RGB, 1);
}
EOF



