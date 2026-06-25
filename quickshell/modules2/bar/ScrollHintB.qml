import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import QtQuick
import QtQuick.Controls
import qs.colors
import qs.modules.common.functions
import qs.modules.common
// --- ScrollHint as a bar island ---

Item {
    id: root
    property string icon: ""
    property string tooltipText: ""
    property real padding: 6
    property var colorsPalette: Colors{}

    implicitWidth: contentRow.implicitWidth + padding * 2
    implicitHeight: contentRow.implicitHeight + padding * 2

    Row {
        id: contentRow
        spacing: 5
        anchors.centerIn: parent

        MaterialSymbol { text: "keyboard_arrow_left"; iconSize: 14; color: colorsPalette.inactiveText }
        MaterialSymbol { text: root.icon; iconSize: 14; color: colorsPalette.inactiveText }
        MaterialSymbol { text: "keyboard_arrow_right"; iconSize: 14; color: colorsPalette.inactiveText }
    }
}