import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.colors
import qs.config
import qs.components
import qs.utils

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

            StyledText {
            id: typingText
            // font.pixelSize: Appearance.font.pixelSize.normal
            color: colorsPalette.inactiveText
            elide: Text.ElideRight

            property string fullText: ""
            property real charIndex: 0

            text: "~: " + fullText.substring(0, Math.floor(charIndex))

            PropertyAnimation {
                id: typingAnim
                target: typingText
                property: "charIndex"
                duration: 180
                easing.type: Easing.Linear
            }
            function startTyping() {
                Qt.callLater(function() {
                    var currentWorkspace = monitor?.activeWorkspace?.id ?? 1
                    var activeWindow = root.activeWindow

                    var newText = (activeWindow && activeWindow.activated)
                                ? activeWindow.appId
                                : `${qsTr("Workspace")} ${currentWorkspace}`

                    // Always update, even if fullText is same mid-animation
                    fullText = newText
                    charIndex = 0

                    typingAnim.from = 0
                    typingAnim.to = fullText.length
                    typingAnim.restart()
                })
            }

            Component.onCompleted: startTyping()

            // Update whenever active window changes
            Connections {
                target: root
                onActiveWindowChanged: typingText.startTyping()
            }

            // Update whenever workspace changes (for empty workspaces)
            Connections {
                target: monitor
                onActiveWorkspaceChanged: typingText.startTyping()
            }
        }
    }
    // ColumnLayout {
    //     id: colLayout

    //     anchors.verticalCenter: parent.verticalCenter
    //     anchors.left: parent.left
    //     anchors.right: parent.right
    //     spacing: -4

    //     StyledText {
    //         Layout.fillWidth: true
    //         font.pixelSize: Appearance.font.pixelSize.small

    //         color: colorsPalette.inactiveText
     
    //         elide: Text.ElideRight
    //         text: "~: " + (
    //         root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow
    //             ? root.activeWindow?.appId
    //             : (root.biggestWindow?.class ?? `${qsTr("Workspace")} ${monitor?.activeWorkspace?.id ?? 1}`)
    //     )
    //     }
    // }

}
