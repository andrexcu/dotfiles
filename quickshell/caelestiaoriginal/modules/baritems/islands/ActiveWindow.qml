import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.colors

Item {
    id: root
    Layout.preferredWidth: 150
    Layout.preferredHeight: 32

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    property var colorsPalette: Colors {}
    property bool focusingThisMonitor: HyprlandData.activeWorkspace?.monitor == monitor?.name
    property var biggestWindow: HyprlandData.biggestWindowForWorkspace(HyprlandData.monitors[root.monitor?.id]?.activeWorkspace.id)

    Text {
        anchors.fill: parent
        text: "~: " + (
            root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow
                ? root.activeWindow?.appId
                : (root.biggestWindow?.class ?? `${qsTr("Workspace")} ${monitor?.activeWorkspace?.id ?? 1}`)
        )
        font.pixelSize: Appearance.font.pixelSize.small
        color: colorsPalette.inactiveText
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
