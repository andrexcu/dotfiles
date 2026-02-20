#!/usr/bin/env bash

# Accept wallpaper path as first argument
SELECTED="$1"
if [[ -z "$SELECTED" ]]; then
    echo "Usage: $0 /path/to/wallpaper.png"
    exit 1
fi

# Generate JSON palette
matugen image "$SELECTED" -j hex > /tmp/matugen.json

# Extract colors from JSON
BG=$(jq -r '.colors.background.dark' /tmp/matugen.json)
FG=$(jq -r '.colors.on_background.dark' /tmp/matugen.json)
ACC=$(jq -r '.colors.primary.dark' /tmp/matugen.json)

# Convert hex to RGB for rgba()
hex2rgb() {
    local HEX=$1
    echo "$((16#${HEX:1:2})), $((16#${HEX:3:2})), $((16#${HEX:5:2}))"
}

BG_RGB=$(hex2rgb "$BG")
FG_RGB=$(hex2rgb "$FG")
ACC_RGB=$(hex2rgb "$ACC")

# Write dynamic config.rasi
cat > ~/.config/rofi/config.rasi <<EOF
entry {
    placeholder: "";
    text-color: rgba($FG_RGB, 1);
    padding: 8px 0 8px 8px;
}

configuration {
    font: "JetBrainsMono Nerd Font Mono 12";
    lines: 10;
    fixed-num-lines: true;
    padding: 10px;
}

inputbar {
    children: [entry];
}

* {
    separatorcolor: transparent;
    selected-normal-background: rgba($ACC_RGB, 10%);
    normal-background: rgba($BG_RGB, 0%);
    alternate-normal-background: rgba($BG_RGB, 0%);
}

mainbox {
    border: 2px;
    border-color: rgba($FG_RGB, 20%);
    border-radius: 10px;
    padding: 10px;
}

window {
    border-radius: 11px;
    border: 1px solid;
    border-color: rgba($FG_RGB, 20%);
    background-color: rgba($BG_RGB, 85%);
    padding: 0px;
    width: 30%;
}

listview {
    lines: 10;
}

element {
    padding: 10px 10px;
    height: 50px;
    border-radius: 5px;
    children: [ element-text, element-icon ];
}

element-text {
    text-color: rgba($FG_RGB, 1);
}

#scrollbar {
    handle-color: rgba($FG_RGB, 40%);
    handle-width: 4px ;
    padding: 0;
}
EOF