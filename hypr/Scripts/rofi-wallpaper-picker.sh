#!/usr/bin/env bash

exec 200>"/tmp/rofi-wallpaper-picker-$UID.lock"
flock -n 200 || exit 0
WALLPAPERS="$HOME/Pictures/Wallpaper"
CACHE_DIR="$HOME/.cache/wallpaper-picker"
PLACEHOLDER="$HOME/.config/rofi/placeholder.png"
THUMB_WIDTH="250"
THUMB_HEIGHT="250"

mkdir -p "$CACHE_DIR"

# Generate thumbnail
generate_thumbnail() {
    local input="$1"
    local output="$2"
    magick "$input" -thumbnail "${THUMB_WIDTH}x${THUMB_HEIGHT}^" \
        -gravity center -extent "${THUMB_WIDTH}x${THUMB_HEIGHT}" "$output"
}

generate_menu() {
    mapfile -t wallpapers_list < <(
        find "$WALLPAPERS" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | shuf
    )

    for img in "${wallpapers_list[@]}"; do
        fname=$(basename "$img")
        thumb="$CACHE_DIR/${fname%.*}.png"

        [[ -f "$thumb" ]] || generate_thumbnail "$img" "$thumb"
        # generate_thumbnail "$img" "$thumb"3
        # Use full path as the label so Rofi returns it directly
        printf '%s\0icon\x1f%s\n' "$img" "$thumb"
    done
}

CONFIG2="$HOME/.config/rofi/wallpaper-config2.rasi"
CONFIG1="$HOME/.config/rofi/wallpaper-config.rasi"

SELECTED=$(generate_menu | rofi -dmenu \
    -no-layers \
    -no-lazy-grab \
    -i -p "Search" \
    -config "$HOME/.config/rofi/wallpaper-config2.rasi")
# rofi -show drun -config "$HOME/.config/rofi/wallpaper-config2.rasi"
WAL_NAME=$(basename "$SELECTED")


[[ -f "$SELECTED" ]] || { echo "Invalid wallpaper: $SELECTED"; exit 1; }


~/Scripts/matugen.sh "$SELECTED"
img=("$SELECTED")  # store as array
# apply wallpaper
FPS=60
TYPE="any"
DURATION=1.4
BEZIER="0,0,1,1"
# BEZIER="0,0,1.19,.2"
# BEZIER=".6,0,.4,1"
# BEZIER=".43,1.19,1,.4"

AWWW_PARAMS=(
  --transition-fps "$FPS"
  --transition-type "$TYPE"
  --transition-duration "$DURATION"
  --transition-bezier "$BEZIER"
)

awww img "${img[@]}" "${AWWW_PARAMS[@]}"

# awww img "${img[@]}" --transition-type any --transition-duration 1.75
# --transition-type grow --transition-pos top-right
~/Scripts/wlogout-sync.sh




# # Path to the txt file
TXT_FILE="$HOME/.config/wlogout/images/current_image.txt"

# Ensure the directory exists
mkdir -p "$(dirname "$TXT_FILE")"

# If the file doesn't exist, create it
touch "$TXT_FILE"

# Replace the first line with WAL_NAME
if [[ -s "$TXT_FILE" ]]; then
    # File has content → replace first line
    { echo "$WAL_NAME"; tail -n +2 "$TXT_FILE"; } > "${TXT_FILE}.tmp" && mv "${TXT_FILE}.tmp" "$TXT_FILE"
else
    # File empty → just write the line
    echo "$WAL_NAME" > "$TXT_FILE"
fi
