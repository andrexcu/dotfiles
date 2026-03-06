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
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    property string activeWindowAddress: `0x${activeWindow?.HyprlandToplevel?.address}`
    property bool focusingThisMonitor: HyprlandData.activeWorkspace?.monitor == monitor?.name
    property var biggestWindow: HyprlandData.biggestWindowForWorkspace(HyprlandData.monitors[root.monitor?.id]?.activeWorkspace.id)
    property var colorsPalette: Colors {}
    implicitWidth: colLayout.implicitWidth

    ColumnLayout {
        id: colLayout

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: -4

        // StyledText {
        //     Layout.fillWidth: true
        //     font.pixelSize: Appearance.font.pixelSize.smaller
        //     color: Appearance.colors.colSubtext
        //     elide: Text.ElideRight
        //     text: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ? 
        //         root.activeWindow?.appId :
        //         (root.biggestWindow?.class) ?? qsTr("Desktop")

        // }

        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.small
            // color: Appearance.colors.colOnLayer0
            color: colorsPalette.inactiveText
            // color: colorsPalette.secondaryText
            elide: Text.ElideRight
            text: "~: " + (
            root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow
                ? root.activeWindow?.appId
                : (root.biggestWindow?.class ?? `${qsTr("Workspace")} ${monitor?.activeWorkspace?.id ?? 1}`)
        )
            // width: 150                 // adjust as needed
    // elide: Text.ElideRight
            
    // text: {
    //     var title = root.biggestWindow
    //         ? (root.activeWindow?.title?.split(" - ")[0] ?? root.activeWindow?.appId)
    //         : `${qsTr("Workspace")} ${monitor?.activeWorkspace?.id ?? 1}`;
    //     return title.length > 15 ? title.slice(0, 15) + "…" : title; // limit to 15 chars
    // // }
    //          text: root.biggestWindow ? 
    //             root.activeWindow?.title :
    //             (root.biggestWindow?.title) ?? `${qsTr("Workspace")} ${monitor?.activeWorkspace?.id ?? 1}`
        //    text: `${qsTr("Workspace")} ${monitor?.activeWorkspace?.id ?? 1}`
        }

    }

}
