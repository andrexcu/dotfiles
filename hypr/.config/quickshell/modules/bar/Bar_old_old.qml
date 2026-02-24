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


PanelWindow {
    id: panel
    property var colorsPalette
    color: "transparent"
    implicitHeight: 35
    anchors { top: true; left: true; right: true }

    Rectangle {
        id: bar
        anchors.fill: parent
        color: "#33000000"
        radius: 0
        
        border.width: 0
        layer.enabled: true

        Rectangle {
        id: bottomBorder
        width: parent.width
        height: 3// The desired thickness of the border
        border.color: colorsPalette ? colorsPalette.primary: "#090606"
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        }

        Row {
            id: workspacesRow
            anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 16 }
            spacing: 8

            Repeater {
                model: Hyprland.workspaces

                Rectangle {
                    width: 32
                    height: 24
                    radius: 0
                    color: modelData.active ? "#4a9eff" : "#333333"
                    border.color: "#555555"
                    border.width: 2

                    MouseArea { anchors.fill: parent; onClicked: Hyprland.dispatch("workspace " + modelData.id) }

                    Text {
                        text: modelData.id
                        anchors.centerIn: parent
                        color: modelData.active ? "#ffffff" : "#cccccc"
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font Mono"
                    }
                }
            }

            Text { visible: Hyprland.workspaces.length === 0; text: "No workspaces"; color: "#ffffff"; font.pixelSize: 12 }
        }
    }
}