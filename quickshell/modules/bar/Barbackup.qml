import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.colors
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
    id: bar
    property var colorsPalette: Colors{}
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell"
    implicitHeight: 35
    anchors { top: true; left: true; right: true }
    // Create the "floating" effect
    margins {
        top: 14
        left: 14
        right: 8
    }
    
    property int activeWsId: 1
    property int targetWsId: 1
    
    property string mediaText: ""
    property string mediaClass: "stopped"
    property real mediaPosition: 0
    property real mediaLength: 0

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "workspace") {
                var wsId = parseInt(event.data.trim())
                if (!isNaN(wsId)) {
                    bar.targetWsId = wsId
                    wsTransition.restart()
                }
            } else if (event.name === "focusedmon") {
                var parts = event.data.split(",")
                if (parts.length >= 2) {
                    var wsId = parseInt(parts[1])
                    if (!isNaN(wsId)) {
                        bar.targetWsId = wsId
                        wsTransition.restart()
                    }
                }
            }
        }
    }


    
    SequentialAnimation {
        id: wsTransition
        PropertyAnimation {
            target: wsHighlight
            property: "highlightOpacity"
            to: 0.4
            duration: 50
            easing.type: Easing.OutQuad
        }
        ScriptAction {
            script: bar.activeWsId = bar.targetWsId
        }
        ParallelAnimation {
            PropertyAnimation {
                target: wsHighlight
                property: "highlightOpacity"
                to: 1
                duration: 300
                easing.type: Easing.OutCubic
            }
            PropertyAnimation {
                target: wsHighlight
                property: "highlightScale"
                from: 0.9
                to: 1.0
                duration: 300
                easing.type: Easing.OutBack
                easing.overshoot: 1.5
            }
        }
    }
   Rectangle {
    id: menuIsland
    
    color: colorsPalette.backgroundt70
    radius: 14
    border.width: 2
    border.color: "#CCFFFFFF"

    anchors.top: parent.top
    anchors.left: parent.left
    // anchors.topMargin: 0
    // anchors.leftMargin: 0

    property int padding: 14

    width: menuText.implicitWidth + padding * 2
    height: workspacesIsland.height

    Text {
        id: menuText
        anchors.centerIn: parent
        text: "󰣇"
        color: "#ffffff"
        font.pixelSize: 12
        font.family: "JetBrainsMono Nerd Font"
        font.bold: true
    }
}

    Rectangle {
    id: workspacesIsland
    color: colorsPalette.backgroundt70 // semi-transparent background
    radius: 14           // rounded corners
    border.width: 2
    border.color: "#FFFFFF"
    anchors.verticalCenter: menuIsland.verticalCenter
    anchors.left: menuIsland.right
    anchors.leftMargin: 12
   
    // padding inside the island
    property int padding: 8
    // width: parent.width
    implicitWidth: workspacesRow.childrenRect.width + padding * 2
    // implicitWidth: wsRepeater.count > 0
    // ? wsRepeater.count * 26 + (wsRepeater.count - 1) * workspacesRow.spacing + workspacesIsland.padding * 2
    // : 0
    implicitHeight: workspacesRow.childrenRect.height + padding * 2
    Behavior on width {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
   
      Item {
                    anchors.fill: parent

                    Item {
                        id: wsContainer
                        anchors.centerIn: parent
                       width: workspacesRow.width
                        height: 18

                        Rectangle {
                            id: wsHighlight
                            height: 18
                            radius: 9

                            property real targetX: 0
                            property real targetWidth: 26
                            property real highlightOpacity: 1.0
                            property real highlightScale: 1.0

                            x: targetX
                            width: targetWidth
                            opacity: highlightOpacity
                            scale: highlightScale
                            transformOrigin: Item.Center
                            color: colorsPalette.primaryContainer
                            antialiasing: true

                            Behavior on x {
                                NumberAnimation {
                                    duration: 300
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on width {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

    Row {   
        id: workspacesRow
        anchors.centerIn: parent

        
        spacing: 8
    
            Repeater {
                id: wsRepeater
                model: Hyprland.workspaces

                delegate: Item {
                    id: wsDelegate
                    required property var modelData
                    property bool isActive: bar.activeWsId === modelData.id
                    property bool isHovered: wsMA.containsMouse

                    width: Math.max(wsText.implicitWidth + 14, 26)
                    height: 18

                    onIsActiveChanged: updateHighlight()
                    onXChanged: if (isActive) updateHighlight()
                    onWidthChanged: if (isActive) updateHighlight()
                   
                    // Component.onCompleted: {
                    //     Qt.callLater(function() {
                    //         if (isActive)
                    //             updateHighlight()
                    //     })
                    // }
                    // Component.onCompleted: if (isActive) updateHighlight()

                    function updateHighlight() {
                        if (isActive) {
                            var pos = mapToItem(wsContainer, 0, 0)
                            wsHighlight.targetX = pos.x
                            wsHighlight.targetWidth = width
                        }
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: isActive ? colorsPalette.primaryContainer : "transparent"
                        antialiasing: true
                        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }

                    Text {
                        id: wsText
                        anchors.centerIn: parent
                        text: modelData.name || modelData.id.toString()
                        color: "#ffffff"
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"

                        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        id: wsMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hyprland.dispatch("workspace " + modelData.id)
                    }
                }
                Component.onCompleted: {
                    Qt.callLater(function() {
                        for (var i = 0; i < wsRepeater.count; i++) {
                            var item = wsRepeater.itemAt(i)
                            if (item && item.isActive) {
                                item.updateHighlight()
                                break
                            }
                        }
                    })
                }
            }

            Connections {
                target: bar
                function onActiveWsIdChanged() {
                    for (var i = 0; i < wsRepeater.count; i++) {
                        var item = wsRepeater.itemAt(i)
                        if (item && item.isActive) {
                            item.updateHighlight()
                            break
                        }
                    }
                }
            }
        }
    }
      }}

    Rectangle {
        id: timeIsland

        color: colorsPalette.backgroundt70
        radius: 14
        border.width: 2
        border.color: "#CCFFFFFF"
        
        anchors.verticalCenter: workspacesIsland.verticalCenter
        anchors.left: workspacesIsland.right
        anchors.leftMargin: 12   // spacing between islands

        property int padding: 12
        width: timeRow.childrenRect.width + padding * 2
        height: workspacesIsland.height   // <- ensures perfect match

        Row {
            id: timeRow
            anchors.centerIn: parent
            anchors.margins: timeIsland.padding

            Text {
                id: clockText
                text: Qt.formatTime(new Date(), "h:mm AP")
                color: "#ffffff"
                font.pixelSize: 13
                font.family: "JetBrainsMono Nerd Font Mono"
               // <-- key line
            }
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clockText.text = Qt.formatTime(new Date(), "h:mm AP")
        }
    }

    Rectangle {
    id: mediaIsland

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter

    radius: 14
    color: colorsPalette.backgroundt80
    border.width: 2
    border.color: "#CCFFFFFF"

    property int padding: 16
    height: 34
    width: mediaText.implicitWidth + padding * 2

    Text {
        id: mediaText
        anchors.centerIn: parent
        text: "No media playing"
        color: "white"
        font.pixelSize: 13
    }
}
}