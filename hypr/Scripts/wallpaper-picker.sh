#!/bin/bash

exec 200>"/tmp/wallpaper-picker-$UID.lock"
flock -n 200 || exit 0

WALLPAPERS="$HOME/Pictures/Wallpaper"
CACHE_DIR="$HOME/.cache/wallpaper-picker"
THUMB_WIDTH="250"
THUMB_HEIGHT="141"

mkdir -p "$CACHE_DIR"
generate_thumbnail(){
    local input="$1"
    local output="$2"
    magick "$input" -thumbnail "${THUMB_WIDTH}x${THUMB_HEIGHT}^" \
        -gravity center -extent "${THUMB_WIDTH}x${THUMB_HEIGHT}" "$output"
}

# Generate menu with thumbnails randomly
generate_menu() {
    # Get all wallpaper files safely
    mapfile -t wallpapers_list < <(find "$WALLPAPERS" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | sort -V)

    # Shuffle the array randomly
    wallpapers_list=($(printf "%s\n" "${wallpapers_list[@]}" | shuf))

    for img in "${wallpapers_list[@]}"; do
        [[ -f "$img" ]] || continue
        ext="${img##*.}"
        thumb="$CACHE_DIR/$(basename "${img%.*}").$ext"

        # Generate thumbnail
        if [[ ! -f "$thumb" ]] || [[ "$img" -nt "$thumb" ]]; then
            generate_thumbnail "$img" "$thumb"
        fi

        # Output menu line for Wofi
        echo -en "img:$thumb\x00info:$(basename "$img")\x1f$img\n"
    done
}

CHOICE=$(generate_menu | wofi --show dmenu \
    --cache-file /dev/null \
    --define "image-size=${THUMB_WIDTH}x${THUMB_HEIGHT}" \
    --columns 3 \
    --allow-images \
    --insensitive \
    --sort-order=default \
    --prompt "Select Wallpaper" \
    --conf ~/.config/wofi/wallpaper
)

[ -z "$CHOICE" ] && exit 0
WAL_NAME=$(basename "$CHOICE")
SELECTED="$WALLPAPERS/$WAL_NAME"

# Show the chosen file on the console
echo "$WAL_NAME"

[[ -f "$SELECTED" ]] || { echo "Error: file does not exist: $SELECTED"; exit 1; }
plasmashell-apply-wallpaperimage() {
    if command -v plasma-apply-wallpaperimage &>/dev/null; then
        plasma-apply-wallpaperimage "$1"
    else
        echo "Error: plasma-apply-wallpaperimage not found"
        exit 1
    fi
}


plasmashell-apply-wallpaperimage "$SELECTED"


/home/andrexcu/Scripts/wlogout-sync.sh

~/.config/wofi/wofi-matugen.sh "$SELECTED"
~/.config/rofi/rofi-matugen.sh "$SELECTED"


# Path to the txt file
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



