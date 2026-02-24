import QtQuick
import Quickshell
import Quickshell.Hyprland

// | Opacity % | Alpha Hex | Color Code  | Transparency %   |
// | --------- | --------- | ----------- | ---------------- |
// | 100%      | FF        | `#FF000000` | 0% transparent   |
// | 90%       | E6        | `#E6000000` | 10% transparent  |
// | 80%       | CC        | `#CC000000` | 20% transparent  |
// | 70%       | B3        | `#B3000000` | 30% transparent  |
// | 60%       | 99        | `#99000000` | 40% transparent  |
// | 50%       | 80        | `#80000000` | 50% transparent  |
// | 40%       | 66        | `#66000000` | 60% transparent  |
// | 30%       | 4D        | `#4D000000` | 70% transparent  |
// | 20%       | 33        | `#33000000` | 80% transparent  |
// | 10%       | 1A        | `#1A000000` | 90% transparent  |
// | 0%        | 00        | `#00000000` | 100% transparent |


FloatingWindow {
    id: selector

    width: 900
    height: 300

    screen: Quickshell.screens[0]
    color: "transparent"

    // This makes it behave like rofi (overlay layer)
    layer: Layer.Top

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: "#1e1e2e"

        Text {
            anchors.centerIn: parent
            text: "Wallpaper Selector"
            color: "white"
            font.pixelSize: 26
        }
    }
}