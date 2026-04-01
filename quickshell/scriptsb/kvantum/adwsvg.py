import re
import os

def read_scss(file_path):
    """Reads an SCSS file and returns a dictionary of color variables."""
    colors = {}
    with open(file_path, 'r') as file:
        for line in file:
            match = re.match(r'\$(\w+):\s*(#[0-9A-Fa-f]{3,8});', line.strip())
            if match:
                variable_name, color = match.groups()
                colors[variable_name] = color
    return colors

def is_valid_color(color):
    """Validate hex color formats (#RGB, #RRGGBB, #RRGGBBAA)."""
    return bool(re.match(r'^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$', color))

def get_color(color_data, key, fallback="#ffffff"):
    """Safely get color from SCSS data."""
    value = color_data.get(key, fallback)
    value = value.strip().rstrip(';:')
    if not is_valid_color(value):
        print(f"[WARN] Invalid color for '{key}': {value} → using fallback {fallback}")
        return fallback
    return value

def update_svg_colors(svg_path, old_to_new_colors, output_path):
    """Replace colors in SVG safely."""
    with open(svg_path, 'r') as file:
        svg_content = file.read()

    for old_color, new_color in old_to_new_colors.items():
        if not is_valid_color(new_color):
            print(f"[WARN] Skipping invalid color: {new_color}")
            continue

        svg_content = re.sub(
            re.escape(old_color),
            new_color,
            svg_content,
            flags=re.IGNORECASE
        )

    with open(output_path, 'w') as file:
        file.write(svg_content)

    print(f"[OK] SVG colors updated → {output_path}")

def main():
    xdg_config_home = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    xdg_state_home = os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))

    scss_file = os.path.join(xdg_state_home, "quickshell", "user", "generated", "material_colors.scss")
    svg_path = os.path.join(xdg_config_home, "Kvantum", "Colloid", "Colloid.svg")
    output_path = os.path.join(xdg_config_home, "Kvantum", "MaterialAdw", "MaterialAdw.svg")

    color_data = read_scss(scss_file)

    old_to_new_colors = {
        '#3c84f7': get_color(color_data, 'primary'),
        '#000000': get_color(color_data, 'shadow'),
        '#f04a50': get_color(color_data, 'error'),
        '#4285f4': get_color(color_data, 'primaryFixedDim'),
        '#f2f2f2': get_color(color_data, 'background'),
        '#ffffff': get_color(color_data, 'background'),
        '#1e1e1e': get_color(color_data, 'onPrimaryFixed'),
        '#333': get_color(color_data, 'inverseSurface'),
        '#212121': get_color(color_data, 'onSecondaryFixed'),
        '#5b9bf8': get_color(color_data, 'secondaryContainer'),
        '#26272a': get_color(color_data, 'term7'),
        '#444444': get_color(color_data, 'onBackground'),
        '#333333': get_color(color_data, 'onPrimaryFixed'),
    }

    update_svg_colors(svg_path, old_to_new_colors, output_path)

if __name__ == "__main__":
    main()