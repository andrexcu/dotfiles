#!/usr/bin/env bash
# ~/.config/wofi/update-wofi-style.sh

# Accept wallpaper path as first argument
SELECTED="$1"

# Accept wallpaper path as first argument
SELECTED="$1"
if [[ -z "$SELECTED" ]]; then
    echo "Usage: $0 /path/to/wallpaper.png"
    exit 1
fi

# generate JSON palette
matugen image "$SELECTED" -j hex > /tmp/matugen.json

# extract only the colors we need
BG=$(jq -r '.colors.background.dark' /tmp/matugen.json)
FG=$(jq -r '.colors.on_background.dark' /tmp/matugen.json)
ACC=$(jq -r '.colors.primary.dark' /tmp/matugen.json)
# Convert hex to RGB for rgba()
hex2rgb() {
    local HEX=$1
    echo "$((16#${HEX:1:2})), $((16#${HEX:3:2})), $((16#${HEX:5:2}))"
}

# Convert hex to RGB
hex2rgb() {
    local HEX=$1
    echo "$((16#${HEX:1:2})), $((16#${HEX:3:2})), $((16#${HEX:5:2}))"
}

BG_RGB=$(hex2rgb "$BG")
FG_RGB=$(hex2rgb "$FG")
ACC_RGB=$(hex2rgb "$ACC")

cat > ~/.config/wofi/style.css <<EOF
* {
    all: unset;
    font-family: 'JetBrains Mono', monospace;
    font-size: 18px;
    text-shadow: none;
    background-color: transparent;
}

window {
    padding: 20px;
    border-radius: 12px;

    background:
        radial-gradient(circle at top left,     rgba($ACC_RGB,0.35), transparent 70%),
        radial-gradient(circle at top right,    rgba($ACC_RGB,0.35), transparent 70%),
        radial-gradient(circle at bottom left,  rgba($ACC_RGB,0.35), transparent 70%),
        radial-gradient(circle at bottom right, rgba($ACC_RGB,0.35), transparent 70%),
        rgba($BG_RGB,0.85);
}

/* === Layout === */
#outer-box {
    border: none;
}
#inner-box {
    margin: 2px;
    padding: 5px;
    border: none;
}
#scroll {
    margin: 0px;
    padding: 20px;
    border: none;
}

/* === Input field === */

#input {
    margin: 20px;
    padding: 15px;
    border-radius: 10px;
    color: rgba($FG_RGB,1);
    background-color: rgba($BG_RGB,0.25);
    box-shadow: 1px 1px 5px rgba(0,0,0,0.5);
}

#input image {
    color: rgba($ACC_RGB,1);
    padding-right: 10px;
}

#entry {
    border: none;
    margin: 5px;
    padding: 10px;
    border-radius: 12px;
    transition: background-color 0.2s ease, color 0.2s ease;
}

#entry #text {
    color: rgba($FG_RGB,1);
}

#entry:selected {
    background-color: rgba($ACC_RGB,0.2);
    border: 1px solid rgba($ACC_RGB,1);
    box-shadow: 0 0 8px rgba($ACC_RGB,0.3);
}
#entry:selected #text {
    color: rgba($ACC_RGB,1);
    font-weight: bold;
}

#entry arrow {
    color: rgba($ACC_RGB,1);
}
EOF