#!/usr/bin/env bash

QUICKSHELL_CONFIG_NAME="ii"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$QUICKSHELL_CONFIG_NAME"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_CONFIG_FILE="$XDG_CONFIG_HOME/illogical-impulse/config.json"
MATUGEN_DIR="$XDG_CONFIG_HOME/matugen"
terminalscheme="$SCRIPT_DIR/terminal/scheme-base.json"

# Validate critical runtime dependencies early
if ! command -v jq &>/dev/null; then
    echo "[switchwall.sh] Missing required dependency: jq"
    echo "  Arch: sudo pacman -S jq"
    exit 1
fi
if ! command -v matugen &>/dev/null; then
    echo "[switchwall.sh] Missing required dependency: matugen"
    echo "  Install from: https://github.com/InioX/matugen"
    exit 1
fi

repair_matugen_colors_template() {
    local user_template="$MATUGEN_DIR/templates/colors.json"
    local default_template="$CONFIG_DIR/defaults/matugen/templates/colors.json"

    # If user template is missing, restore from project defaults.
    if [[ ! -f "$user_template" && -f "$default_template" ]]; then
        mkdir -p "$MATUGEN_DIR/templates"
        cp "$default_template" "$user_template"
        return
    fi

    # Some broken installs ended up with commented tertiary lines in this template.
    # Matugen then writes invalid JSON (comments included), breaking shell theming.
    if [[ -f "$user_template" ]] && grep -qE '^\s*//\s*"tertiary"' "$user_template"; then
        if [[ -f "$default_template" ]]; then
            cp "$default_template" "$user_template"
            echo "[switchwall.sh] Repaired invalid matugen colors template from defaults"
        fi
    fi
}

# handle_kde_material_you_colors() {
#     # Check if Qt app theming is enabled in config
#     if [ -f "$SHELL_CONFIG_FILE" ]; then
#         enable_qt_apps=$(jq -r '.appearance.wallpaperTheming.enableQtApps' "$SHELL_CONFIG_FILE")
#         if [ "$enable_qt_apps" == "false" ]; then
#             return
#         fi
#     fi

#     # Map $type_flag to allowed scheme variants for kde-material-you-colors-wrapper.sh
#     local kde_scheme_variant=""
#     case "$type_flag" in
#         scheme-content|scheme-expressive|scheme-fidelity|scheme-fruit-salad|scheme-monochrome|scheme-neutral|scheme-rainbow|scheme-tonal-spot)
#             kde_scheme_variant="$type_flag"
#             ;;
#         *)
#             kde_scheme_variant="scheme-tonal-spot" # default
#             ;;
#     esac
#     "$XDG_CONFIG_HOME"/matugen/templates/kde/kde-material-you-colors-wrapper.sh --scheme-variant "$kde_scheme_variant"
# }

pre_process() {
    local mode_flag="$1"
    repair_matugen_colors_template

    # Set GNOME color-scheme if mode_flag is dark or light
    if [[ "$mode_flag" == "dark" ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    elif [[ "$mode_flag" == "light" ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
    fi

    if [ ! -d "$CACHE_DIR"/user/generated ]; then
        mkdir -p "$CACHE_DIR"/user/generated
    fi
    if [ ! -d "$STATE_DIR"/user/generated ]; then
        mkdir -p "$STATE_DIR"/user/generated
    fi
}

post_process() {
    local screen_width="$1"
    local screen_height="$2"
    local wallpaper_path="$3"

    # handle_kde_material_you_colors &
    "$SCRIPT_DIR/code/material-code-set-color.sh" &
    # Note: GTK4/libadwaita apps don't reload ~/.config/gtk-4.0/gtk.css in real-time
    # Apps need to be restarted to pick up new colors from matugen
}

write_generated_wallpaper_path() {
    local wallpaper_path="$1"
    local wallpaper_state_path="$STATE_DIR/user/generated/wallpaper/path.txt"

    mkdir -p "$(dirname "$wallpaper_state_path")"
    printf '%s\n' "$wallpaper_path" > "$wallpaper_state_path"
}

get_max_monitor_resolution() {
    local width=1920
    local height=1080
    # Try Niri first
    if command -v niri >/dev/null 2>&1 && niri msg outputs >/dev/null 2>&1; then
        # Parse niri msg outputs for resolution (e.g., "  Current mode: 1920x1080@60.000")
        local res=$(niri msg outputs 2>/dev/null | grep -oP 'Current mode: \K\d+x\d+' | sort -t'x' -k1 -nr | head -1)
        if [[ -n "$res" ]]; then
            width=$(echo "$res" | cut -d'x' -f1)
            height=$(echo "$res" | cut -d'x' -f2)
        fi
    # Fallback to Hyprland
    elif command -v hyprctl >/dev/null 2>&1; then
        width="$(hyprctl monitors -j 2>/dev/null | jq '([.[].width] | max)' | xargs)"
        height="$(hyprctl monitors -j 2>/dev/null | jq '([.[].height] | max)' | xargs)"
    fi
    echo "$width $height"
}



CUSTOM_DIR="$XDG_CACHE_HOME/quickshell"
RESTORE_SCRIPT_DIR="$CUSTOM_DIR/scripts"
RESTORE_SCRIPT="$RESTORE_SCRIPT_DIR/__restore_video_wallpaper.sh"
THUMBNAIL_DIR="$CUSTOM_DIR/video_thumbnails"
VIDEO_OPTS="no-audio loop hwdec=auto scale=bilinear interpolation=no video-sync=display-resample panscan=1.0 video-scale-x=1.0 video-scale-y=1.0 video-align-x=0.5 video-align-y=0.5 load-scripts=no"

is_video() {
    local extension="${1##*.}"
    [[ "$extension" == "mp4" || "$extension" == "webm" || "$extension" == "mkv" || "$extension" == "avi" || "$extension" == "mov" ]] && return 0 || return 1
}

is_gif() {
    local extension="${1##*.}"
    [[ "${extension,,}" == "gif" ]] && return 0 || return 1
}

has_valid_file() {
    local path="$1"
    [[ -n "$path" && -f "$path" && -s "$path" ]]
}




set_wallpaper_path() {
    local path="$1"
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        jq --arg path "$path" '.background.wallpaperPath = $path' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    fi
}

set_wallpaper_path_per_monitor() {
    local path="$1"
    local monitor="$2"
    local startWs="${3:-1}"
    local endWs="${4:-10}"

    if [ -f "$SHELL_CONFIG_FILE" ]; then
        # Use jq to update wallpapersByMonitor array
        # Remove existing entry for this monitor, then add new entry
        jq --arg monitor "$monitor" \
           --arg path "$path" \
           --argjson startWs "${startWs:-1}" \
           --argjson endWs "${endWs:-10}" \
           '.background.wallpapersByMonitor = (
               (.background.wallpapersByMonitor // []) |
               map(select(.monitor != $monitor)) +
               [{
                   "monitor": $monitor,
                   "path": $path,
                   "workspaceFirst": $startWs,
                   "workspaceLast": $endWs
               }]
           )' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    fi
}

set_thumbnail_path() {
    local path="$1"
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        jq --arg path "$path" '.background.thumbnailPath = $path' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    fi
}

set_backdrop_thumbnail_path() {
    local path="$1"
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        jq --arg path "$path" '.background.backdrop.thumbnailPath = $path' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    fi
}

get_focused_monitor_name() {
    if command -v niri >/dev/null 2>&1 && niri msg -j focused-output >/dev/null 2>&1; then
        niri msg -j focused-output 2>/dev/null | jq -r '.name // ""'
        return
    fi
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' | head -1
        return
    fi
    echo ""
 }

 resolve_effective_theming_wallpaper() {
    jq -r --arg focused_monitor "$(get_focused_monitor_name)" '
        def monitor_entry: if ((.background.multiMonitor.enable // false) and ($focused_monitor != ""))
            then ((.background.wallpapersByMonitor // []) | map(select(.monitor == $focused_monitor)) | .[0])
            else null end;
        def main_path: (monitor_entry.path // .background.wallpaperPath // "");
        def monitor_backdrop: (monitor_entry.backdropPath // "");
        def waffle_main: (if (.waffles.background.useMainWallpaper // true) then main_path else (.waffles.background.wallpaperPath // main_path) end);
        if (.appearance.wallpaperTheming.useBackdropForColors // false) then
            if (.panelFamily // "ii") == "waffle" then
                (if (.waffles.background.backdrop.useMainWallpaper // true) then waffle_main else (.waffles.background.backdrop.wallpaperPath // waffle_main) end)
            else
                (if monitor_backdrop != "" then monitor_backdrop else (if (.background.backdrop.useMainWallpaper // true) then main_path else (.background.backdrop.wallpaperPath // main_path) end) end)
            end
        else
            if (.panelFamily // "ii") == "waffle" then waffle_main else main_path end
        end // ""
    ' "$SHELL_CONFIG_FILE" 2>/dev/null || echo ""
 }

 ensure_color_preview_for_media() {
    local media_path="$1"
    local out_path="$2"
    mkdir -p "$(dirname "$out_path")"

    if is_video "$media_path"; then
        if ! command -v ffmpeg >/dev/null 2>&1; then
            echo "[switchwall.sh] Missing ffmpeg for video color preview generation" >&2
            return 1
        fi
        ffmpeg -y -i "$media_path" -vframes 1 "$out_path" >/dev/null 2>&1
        return $?
    fi

    if is_gif "$media_path"; then
        if command -v magick >/dev/null 2>&1; then
            magick "$media_path[0]" "$out_path" >/dev/null 2>&1
            return $?
        fi
        if command -v ffmpeg >/dev/null 2>&1; then
            ffmpeg -y -i "$media_path" -vframes 1 "$out_path" >/dev/null 2>&1
            return $?
        fi
        echo "[switchwall.sh] Missing magick/ffmpeg for gif color preview generation" >&2
        return 1
    fi

    return 1
 }

switch() {
    imgpath="$1"
    mode_flag="$2"
    type_flag="$3"
    color_flag="$4"
    color="$5"
    skip_config_write="$6"

    # Per-monitor wallpaper changes: only update config, skip color generation
    # Global theme colors should only change from global wallpaper changes
    if [[ -n "$monitor_name" && -n "$imgpath" ]]; then
        set_wallpaper_path_per_monitor "$imgpath" "$monitor_name" "$start_workspace" "$end_workspace"
        echo "[switchwall.sh] Per-monitor wallpaper set for $monitor_name, skipping global color generation"
        return
    fi

    # Start Gemini auto-categorization if enabled
    aiStylingEnabled=$(jq -r '.background.clock.cookie.aiStyling' "$SHELL_CONFIG_FILE")
    if [[ "$aiStylingEnabled" == "true" ]]; then
        "$SCRIPT_DIR/../ai/gemini-categorize-wallpaper.sh" "$imgpath" > "$STATE_DIR/user/generated/wallpaper/category.txt" &
    fi

    # Hyprland-specific cursor/monitor math: only run if hyprctl is available.
    # On Niri or other compositors we fall back to centered defaults to avoid
    # spamming errors while still producing valid colors.
    if command -v hyprctl >/dev/null 2>&1; then
        focused_monitor_info=$(hyprctl monitors -j 2>/dev/null | jq -r '[.[] | select(.focused == true)] | first | if . == null then "" else "\(.scale) \(.x) \(.y) \(.height)" end' 2>/dev/null)
        if [[ -n "$focused_monitor_info" ]]; then
            read scale screenx screeny screensizey <<< "$focused_monitor_info"
            cursor_json=$(hyprctl cursorpos -j 2>/dev/null)
            cursorposx=$(printf '%s' "$cursor_json" | jq -r '.x // empty' 2>/dev/null)
            cursorposy=$(printf '%s' "$cursor_json" | jq -r '.y // empty' 2>/dev/null)
            if [[ -n "$cursorposx" && -n "$cursorposy" ]]; then
                cursorposx=$(bc <<< "scale=0; ($cursorposx - $screenx) * $scale / 1")
                cursorposy=$(bc <<< "scale=0; ($cursorposy - $screeny) * $scale / 1")
            else
                cursorposx=960
                cursorposy=540
            fi
            cursorposy_inverted=$((screensizey - cursorposy))
        else
            scale=1
            screenx=0
            screeny=0
            screensizey=1080
            cursorposx=960
            cursorposy=540
            cursorposy_inverted=$((screensizey - cursorposy))
        fi
    else
        scale=1
        screenx=0
        screeny=0
        screensizey=1080
        cursorposx=960
        cursorposy=540
        cursorposy_inverted=$((screensizey - cursorposy))
    fi

    if [[ "$color_flag" == "1" ]]; then
        matugen_args=(color hex "$color")
        generate_colors_material_args=(--color "$color")
    else
        if [[ -z "$imgpath" ]]; then
            if [[ -n "$noswitch_flag" ]]; then
                # --noswitch without --image: read current wallpaper from config for color regeneration
                imgpath=$(resolve_effective_theming_wallpaper)
                if [[ -z "$imgpath" || ! -f "$imgpath" ]]; then
                    echo "[switchwall.sh] --noswitch: No valid wallpaper path in config"
                    exit 0
                fi
                echo "[switchwall.sh] --noswitch: Using current wallpaper for color regeneration: $imgpath"
            else
                echo 'Aborted'
                exit 0
            fi
        fi
        
            mkdir -p "$THUMBNAIL_DIR"
        
            color_source="$imgpath"
            matugen_args=(image "$color_source")
            generate_colors_material_args=(--path "$color_source")
            # Update wallpaper path in config
            if [[ "$skip_config_write" != "1" ]]; then
                set_wallpaper_path "$imgpath"
            fi
            # Clear video thumbnail path (prevents stale video colors)
            if [[ "$skip_config_write" != "1" ]]; then
                set_thumbnail_path ""
            fi

    fi

    # Determine mode if not set
    if [[ -z "$mode_flag" ]]; then
        current_mode=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'")
        if [[ "$current_mode" == "prefer-dark" ]]; then
            mode_flag="dark"
        else
            mode_flag="light"
        fi
    fi

    # enforce dark mode for terminal
    if [[ -n "$mode_flag" ]]; then
        matugen_args+=(--mode "$mode_flag")
        if [[ $(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode' "$SHELL_CONFIG_FILE") == "true" ]]; then
            generate_colors_material_args+=(--mode "dark")
        else
            generate_colors_material_args+=(--mode "$mode_flag")
        fi
    fi
    # If useBackdropForColors is enabled, override color source to use backdrop wallpaper
    # Respects active panel family: ii reads from background.backdrop, waffle from waffles.background.backdrop

    [[ -n "$type_flag" ]] && matugen_args+=(--type "$type_flag") && generate_colors_material_args+=(--scheme "$type_flag")
    generate_colors_material_args+=(--termscheme "$terminalscheme" --blend_bg_fg)
    generate_colors_material_args+=(--cache "$STATE_DIR/user/generated/color.txt")

    pre_process "$mode_flag"
    write_generated_wallpaper_path "$imgpath"

    # Check if app and shell theming is enabled in config
    local enable_apps_shell="true"
    local enable_terminal="true"
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        enable_apps_shell=$(jq -r '.appearance.wallpaperTheming.enableAppsAndShell // true' "$SHELL_CONFIG_FILE")
        enable_terminal=$(jq -r '.appearance.wallpaperTheming.enableTerminal // true' "$SHELL_CONFIG_FILE")
    fi

    # Skip entirely only if BOTH app theming AND terminal theming are disabled
    if [ "$enable_apps_shell" == "false" ] && [ "$enable_terminal" == "false" ]; then
        echo "Both app/shell and terminal theming disabled, skipping color generation"
        return
    fi

    # Set harmony and related properties from terminalColorAdjustments
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        # Read from terminalColorAdjustments (the unified config)
        term_saturation=$(jq -r '.appearance.wallpaperTheming.terminalColorAdjustments.saturation // 0.65' "$SHELL_CONFIG_FILE")
        term_brightness=$(jq -r '.appearance.wallpaperTheming.terminalColorAdjustments.brightness // 0.60' "$SHELL_CONFIG_FILE")
        term_harmony=$(jq -r '.appearance.wallpaperTheming.terminalColorAdjustments.harmony // 0.40' "$SHELL_CONFIG_FILE")
        term_bg_brightness=$(jq -r '.appearance.wallpaperTheming.terminalColorAdjustments.backgroundBrightness // 0.50' "$SHELL_CONFIG_FILE")
        
        # Legacy props for backwards compatibility
        harmonize_threshold=$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold // 100' "$SHELL_CONFIG_FILE")
        soften_colors=$(jq -r '.appearance.softenColors' "$SHELL_CONFIG_FILE")
        
        # Pass new parameters to Python script
        [[ "$term_saturation" != "null" && -n "$term_saturation" ]] && generate_colors_material_args+=(--term_saturation "$term_saturation")
        [[ "$term_brightness" != "null" && -n "$term_brightness" ]] && generate_colors_material_args+=(--term_brightness "$term_brightness")
        [[ "$term_harmony" != "null" && -n "$term_harmony" ]] && generate_colors_material_args+=(--harmony "$term_harmony")
        [[ "$term_bg_brightness" != "null" && -n "$term_bg_brightness" ]] && generate_colors_material_args+=(--term_bg_brightness "$term_bg_brightness")
        [[ "$harmonize_threshold" != "null" && -n "$harmonize_threshold" ]] && generate_colors_material_args+=(--harmonize_threshold "$harmonize_threshold")
        [[ "$soften_colors" == "true" ]] && generate_colors_material_args+=(--soften)
    fi

    # Use user's matugen config (installed to ~/.config/matugen/ during setup)
    matugen --config "$MATUGEN_DIR/config.toml" "${matugen_args[@]}"
    if [[ -n "${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-}" ]]; then
        _ii_venv="$(eval echo "$ILLOGICAL_IMPULSE_VIRTUAL_ENV")"
    else
        _ii_venv="$HOME/.local/state/quickshell/.venv"
    fi
    source "$_ii_venv/bin/activate" 2>/dev/null || true
    _ii_python="$_ii_venv/bin/python3"
    [[ ! -x "$_ii_python" ]] && _ii_python="python3"

    _scss_tmp="$STATE_DIR/user/generated/material_colors.scss.tmp"
    _json_tmp="$STATE_DIR/user/generated/colors.json.tmp"
    _json_out="$STATE_DIR/user/generated/colors.json"
    if "$_ii_python" "$SCRIPT_DIR/generate_colors_material.py" "${generate_colors_material_args[@]}" \
        --json-output "$_json_tmp" \
        > "$_scss_tmp" 2>/dev/null && [[ -s "$_scss_tmp" ]]; then
        mv "$_scss_tmp" "$STATE_DIR/user/generated/material_colors.scss"
        if [[ -s "$_json_tmp" ]]; then
            mv "$_json_tmp" "$_json_out"
        else
            rm -f "$_json_tmp"
            echo "[switchwall] Warning: colors.json generation failed, keeping previous JSON" >&2
        fi
    else
        echo "[switchwall] Warning: generate_colors_material.py failed, keeping previous SCSS" >&2
        rm -f "$_scss_tmp"
        rm -f "$_json_tmp"
    fi

    # Generate Vesktop theme if enabled (only when app theming is on)
    # if [ "$enable_apps_shell" != "false" ]; then
    #     enable_vesktop=$(jq -r '.appearance.wallpaperTheming.enableVesktop // true' "$SHELL_CONFIG_FILE" 2>/dev/null || echo "true")
    #     if [[ "$enable_vesktop" != "false" ]]; then
    #         "$_ii_python" "$SCRIPT_DIR/system24_palette.py"
    #     fi
    # fi

    # Always run applycolor.sh - it has its own checks for enableTerminal and enableAppsAndShell
    # "$SCRIPT_DIR"/applycolor.sh
    # deactivate 2>/dev/null || true

    # Pass screen width, height, and wallpaper path to post_process (only when app theming is on)
    if [ "$enable_apps_shell" != "false" ]; then
        read max_width_desired max_height_desired <<< "$(get_max_monitor_resolution)"
        post_process "$max_width_desired" "$max_height_desired" "$imgpath"
    fi
}

main() {
    imgpath=""
    mode_flag=""
    type_flag=""
    color_flag=""
    color=""
    noswitch_flag=""
    skip_config_write=""

    get_type_from_config() {
        jq -r '.appearance.palette.type' "$SHELL_CONFIG_FILE" 2>/dev/null || echo "auto"
    }

    get_accent_color_from_config() {
        jq -r '.appearance.palette.accentColor' "$SHELL_CONFIG_FILE" 2>/dev/null || echo ""
    }

    set_accent_color() {
        local color="$1"
        jq --arg color "$color" '.appearance.palette.accentColor = $color' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    }

    detect_scheme_type_from_image() {
        local img="$1"
        local _det_venv
        if [[ -n "${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-}" ]]; then
            _det_venv="$(eval echo "$ILLOGICAL_IMPULSE_VIRTUAL_ENV")"
        else
            _det_venv="$HOME/.local/state/quickshell/.venv"
        fi
        source "$_det_venv/bin/activate" 2>/dev/null || true
        "$SCRIPT_DIR"/scheme_for_image.py "$img" 2>/dev/null | tr -d '\n'
        deactivate 2>/dev/null || true
    }

    # while [[ $# -gt 0 ]]; do
    #     case "$1" in
    #         --mode)
    #             mode_flag="$2"
    #             shift 2
    #             ;;
    #         --type)
    #             type_flag="$2"
    #             shift 2
    #             ;;
    #         --color)
    #             if [[ "$2" =~ ^#?[A-Fa-f0-9]{6}$ ]]; then
    #                 set_accent_color "$2"
    #                 shift 2
    #             elif [[ "$2" == "clear" ]]; then
    #                 set_accent_color ""
    #                 shift 2
    #             else
    #                 set_accent_color $(hyprpicker --no-fancy)
    #                 shift
    #             fi
    #             ;;
    #         --image)
    #             imgpath="$2"
    #             shift 2
    #             ;;
    #         --noswitch)
    #             noswitch_flag="1"
    #             imgpath=$(jq -r '.background.wallpaperPath' "$SHELL_CONFIG_FILE" 2>/dev/null || echo "")
    #             shift
    #             ;;
    #         --skip-config-write)
    #             skip_config_write="1"
    #             shift
    #             ;;
    #         --monitor)
    #             monitor_name="$2"
    #             shift 2
    #             ;;
    #         --start-workspace)
    #             start_workspace="$2"
    #             shift 2
    #             ;;
    #         --end-workspace)
    #             end_workspace="$2"
    #             shift 2
    #             ;;
    #         *)
    #             if [[ -z "$imgpath" ]]; then
    #                 imgpath="$1"
    #             fi
    #             shift
    #             ;;
    #     esac
    # done

    # ARGS=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --color)
                if [[ "$2" =~ ^#?[A-Fa-f0-9]{6}$ ]]; then
                    set_accent_color "$2"
                elif [[ "$2" == "clear" ]]; then
                    set_accent_color ""
                else
                    set_accent_color $(hyprpicker --no-fancy)
                fi
                # Apply immediately
                "$SCRIPT_DIR"/applycolor.sh
                deactivate 2>/dev/null || true
                color_flag="1"
                color="$2"
                shift 2
                ;;
            --mode) mode_flag="$2"; shift 2 ;;
            --type) type_flag="$2"; shift 2 ;;
            --image) imgpath="$2"; shift 2 ;;
            --noswitch) noswitch_flag="1"; imgpath=$(jq -r '.background.wallpaperPath' "$SHELL_CONFIG_FILE" 2>/dev/null || echo ""); shift ;;
            --skip-config-write) skip_config_write="1"; shift ;;
            --monitor) monitor_name="$2"; shift 2 ;;
            --start-workspace) start_workspace="$2"; shift 2 ;;
            --end-workspace) end_workspace="$2"; shift 2 ;;
            *) [[ -z "$imgpath" ]] && imgpath="$1"; shift ;;
        esac
    done
    


    # If type_flag is not set, get it from config
    if [[ -z "$type_flag" ]]; then
        type_flag="$(get_type_from_config)"
    fi

    # If accentColor is set in config, use it
    config_color="$(get_accent_color_from_config)"
    if [[ "$config_color" =~ ^#?[A-Fa-f0-9]{6}$ ]]; then
        color_flag="1"
        color="$config_color"
    fi

    # Validate type_flag (allow 'auto' as well)
    allowed_types=(scheme-content scheme-expressive scheme-fidelity scheme-fruit-salad scheme-monochrome scheme-neutral scheme-rainbow scheme-tonal-spot auto)
    valid_type=0
    for t in "${allowed_types[@]}"; do
        if [[ "$type_flag" == "$t" ]]; then
            valid_type=1
            break
        fi
    done
    if [[ $valid_type -eq 0 ]]; then
        echo "[switchwall.sh] Warning: Invalid type '$type_flag', defaulting to 'auto'" >&2
        type_flag="auto"
    fi

    # Only prompt for wallpaper if not using --color and not using --noswitch and no imgpath set
    if [[ -z "$imgpath" && -z "$color_flag" && -z "$noswitch_flag" ]]; then
        cd "$(xdg-user-dir PICTURES)/Wallpapers/showcase" 2>/dev/null || cd "$(xdg-user-dir PICTURES)/Wallpapers" 2>/dev/null || cd "$(xdg-user-dir PICTURES)" || return 1
        imgpath="$(kdialog --getopenfilename . --title 'Choose wallpaper')"
    fi


    
    # If type_flag is 'auto', detect scheme type from image (after imgpath is set)
    if [[ "$type_flag" == "auto" ]]; then
        if [[ -n "$imgpath" && -f "$imgpath" ]]; then
            detected_type="$(detect_scheme_type_from_image "$imgpath")"
            # Only use detected_type if it's valid
            valid_detected=0
            for t in "${allowed_types[@]}"; do
                if [[ "$detected_type" == "$t" && "$detected_type" != "auto" ]]; then
                    valid_detected=1
                    break
                fi
            done
            if [[ $valid_detected -eq 1 ]]; then
                type_flag="$detected_type"
            else
                echo "[switchwall] Warning: Could not auto-detect a valid scheme, defaulting to 'scheme-tonal-spot'" >&2
                type_flag="scheme-tonal-spot"
            fi
        else
            echo "[switchwall] Warning: No image to auto-detect scheme from, defaulting to 'scheme-tonal-spot'" >&2
            type_flag="scheme-tonal-spot"
        fi
    fi

    switch "$imgpath" "$mode_flag" "$type_flag" "$color_flag" "$color" "$skip_config_write"
}

main "$@"

