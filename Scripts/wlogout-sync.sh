# #!/bin/bash

# # Get current KDE wallpaper
# WALLPAPER=$(qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
# var d = desktops()[0];
# d.currentConfigGroup = ['Wallpaper','org.kde.image','General'];
# print(d.readConfig('Image'));
# ")

# # Remove file:// prefix
# WALLPAPER=$(qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
# var d = desktops()[0];
# d.currentConfigGroup = ['Wallpaper','org.kde.image','General'];
# print(d.readConfig('Image'));
# ")
# WALLPAPER="${WALLPAPER#file://}"

# # Paths
# WALL_DIR="$HOME/Pictures/Wallpaper"
# WALL_NAME="$(basename "$WALLPAPER")"

# BLUR_BG="$HOME/.config/wlogout/images/wallpaper_blurred.png"
# WL_TEMPLATE="$HOME/.config/wlogout/style-template.css"
# WLCSS="$HOME/.config/wlogout/style.css"

# mkdir -p "$(dirname "$BLUR_BG")"
# # Create black placeholder immediately
# magick -size 1920x1080 xc:black "$BLUR_BG"
# # Generate Blurred Wallpaper (use full path to avoid issues)
# magick "$WALLPAPER" \
#   -resize 1920x1080^ \
#   -gravity center \
#   -extent 1920x1080 \
#   -blur 0x8 \
#   -fill black \
#   -colorize 65% \
#   "$BLUR_BG"


# pkill -HUP wlogout 2>/dev/null
# # === UPDATE STYLE.CSS ===
# cat "$WL_TEMPLATE" > "$WLCSS"

#!/bin/bash

# Get current KDE wallpaper
WALLPAPER=$(qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
var d = desktops()[0];
d.currentConfigGroup = ['Wallpaper','org.kde.image','General'];
print(d.readConfig('Image'));
")

# Remove file:// prefix
WALLPAPER="${WALLPAPER#file://}"

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