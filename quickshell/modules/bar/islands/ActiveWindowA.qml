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
    property var colorsPalette: Colors{}
    implicitWidth: colLayout.implicitWidth

  
    ColumnLayout {
    id: colLayout
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: -4
    StyledText {
        Layout.fillWidth: true
        font.pixelSize: Appearance.font.pixelSize.smaller
        // horizontalAlignment: Text.AlignHCenter
        // verticalAlignment: Text.AlignVCenter
        color: colorsPalette.inactiveText
        elide: Text.ElideRight
        text: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ? 
            root.activeWindow?.appId :
            (root.biggestWindow?.class) ?? `${qsTr("Desktop")}`

    }
    StyledText {
        id: typingText
        Layout.fillWidth: true
        font.pixelSize: Appearance.font.pixelSize.small
        // horizontalAlignment: Text.AlignHCenter
        // verticalAlignment: Text.AlignVCenter
        color: colorsPalette.backgroundText
        elide: Text.ElideRight

        property string fullText: ""
        property real charIndex: 0

        text: fullText.substring(0, Math.floor(charIndex))

        PropertyAnimation {
            id: typingAnim
            target: typingText
            property: "charIndex"
            duration: 180
            easing.type: Easing.Linear
        }

        function startTyping() {
            Qt.callLater(function() {

                var workspaceId = monitor?.activeWorkspace?.id ?? 1

                var newText = root.biggestWindow
                    ? (root.activeWindow?.title ?? root.biggestWindow?.title)
                    : `${qsTr("Workspace")} ${workspaceId}`

                fullText = newText
                charIndex = 0

                typingAnim.from = 0
                typingAnim.to = fullText.length
                typingAnim.restart()
            })
        }

        Component.onCompleted: startTyping()

        Connections {
            target: root

            function onActiveWindowChanged(arg) {
                typingText.startTyping()
            }
        }

        Connections {
            target: monitor

            // ✅ Modern, warning-free
            function onActiveWorkspaceChanged(arg) {
                typingText.startTyping()
            }
        }
        Connections {
            target: root.activeWindow
            ignoreUnknownSignals: true

            function onTitleChanged(arg) {
                typingText.startTyping()
            }
        }
    }
}

}
