import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.modules.bar
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
    property var colorsPalette: Colors {}
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
    property string volumeStr: "󰕾 0%"
    property int volumePercent: 50
    property bool volumeMuted: fals
    property var cavaValues: [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1]
    property var stableWorkspaces: [1,2,3,4,5,6,7,8,9,10]
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
                     property bool isNumeric: /^\d+$/.test(modelData.name)

                        visible: isNumeric
  
                    property bool isActive: bar.activeWsId === modelData.id
                    property bool isHovered: wsMA.containsMouse

                    width: isNumeric ? Math.max(wsText.implicitWidth + 14, 26) : 0
                    height: isNumeric ? 18 : 0

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
                font.pixelSize: 15
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
    clip: true
    property int padding: 10
    height: workspacesIsland.height
    width: 270  // can adjust for icons

    Row {
        id: mediaRow
        anchors.fill: parent
        anchors.margins: mediaIsland.padding
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter

        // --- Music Icon on the left ---
        Image {
            id: musicIcon
            source: Quickshell.env("HOME") + "/.config/quickshell/icons/music.png"
            width: 16
            height: 16
            fillMode: Image.PreserveAspectFit
            anchors.verticalCenter: parent.verticalCenter
        }

        // --- Scrolling Text Container ---
        Item {
            id: textContainer
            anchors.verticalCenter: parent.verticalCenter
            width: mediaIsland.width 
                   - musicIcon.width 
                   - mediaIsland.padding * 2 
                   - mediaRow.spacing * 2  // spacing for text
                   - backIcon.width - pauseIcon.width - forwardIcon.width - 12 // reserve space for right icons
            height: parent.height
            clip: true

            Text {
                id: mediaTextItem
                text: bar.mediaClass === "playing" || bar.mediaClass === "paused"
                    ? bar.mediaText
                    : "No media playing"
                color: "#ffffff"
                font.pixelSize: 13
                font.family: "JetBrainsMono Nerd Font Mono"
                font.bold: true
                y: (parent.height - implicitHeight)/2
                x: textContainer.width   // start at right edge

                onImplicitWidthChanged: startScroll() // <-- ensure text width is ready

                function startScroll() {
                    scrollAnim.stop()
                    x = textContainer.width
                    scrollAnim.from = x
                    scrollAnim.to = -implicitWidth
                    scrollAnim.duration = (textContainer.width + implicitWidth) * 15
                    scrollAnim.start()
                }

                // --- Scrolling Animation ---
                PropertyAnimation {
                    id: scrollAnim
                    target: mediaTextItem
                    property: "x"
                    easing.type: Easing.Linear
                    loops: Animation.Infinite
                }
            }
        }

        // --- Media Control Icons on the right ---
Image {
    id: backIcon
    source: Quickshell.env("HOME") + "/.config/quickshell/icons/back.png"
    width: 16
    height: 16
    fillMode: Image.PreserveAspectFit
    anchors.verticalCenter: parent.verticalCenter

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            backProc.running = true
        }
    }
}

Image {
    id: pauseIcon
    // Dynamically change icon depending on media state
    source: bar.mediaClass === "playing"
            ? Quickshell.env("HOME") + "/.config/quickshell/icons/pause.png"
            : Quickshell.env("HOME") + "/.config/quickshell/icons/play.png"

    width: 20
    height: 20
    fillMode: Image.PreserveAspectFit
    anchors.verticalCenter: parent.verticalCenter

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            pauseProc.running = true
        }
    }
}

Image {
    id: forwardIcon
    source: Quickshell.env("HOME") + "/.config/quickshell/icons/forward.png"
    width: 16
    height: 16
    fillMode: Image.PreserveAspectFit
    anchors.verticalCenter: parent.verticalCenter

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: forwardProc.running = true
    }
}

// --- Processes to trigger playerctl ---
Process {
    id: backProc
    command: ["playerctl", "previous"]
}

Process {
    id: pauseProc
    command: ["playerctl", "play-pause", "--player=%any"]
    onExited: {
        // Immediately refresh mediaClass after toggling
        mediaProc.running = true
    }
}

Process {
    id: forwardProc
    command: ["playerctl", "next"]
}
    }

    Component.onCompleted: {2
        mediaTextItem.startScroll()
    }
}
    // --- Media Process ---
//  Timer {
//         interval: 50
//         running: bar.mediaClass === "playing"
//         repeat: true
//         onTriggered: {
//             var newVals = []
//             for (var i = 0; i < 12; i++) {
//                 var current = bar.cavaValues[i]
//                 var target = Math.random() * 0.75 + 0.15
//                 newVals.push(current * 0.35 + target * 0.65)
//             }
//             bar.cavaValues = newVals
//         }
//     }

//     Timer {
//         interval: 60
//         running: bar.mediaClass !== "playing"
//         repeat: true
//         onTriggered: {
//             var newVals = []
//             for (var i = 0; i < 12; i++) {
//                 newVals.push(bar.cavaValues[i] * 0.85)
//             }
//             bar.cavaValues = newVals
//         }
//     }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!mediaProc.running) mediaProc.running = true }
    }

    Process {
        id: mediaProc
        // Use playerctl --follow to get live updates
        command: ["playerctl", "--player=%any", "metadata", "--format", "{{status}}|{{artist}} - {{title}}|{{position}}|{{mpris:length}}", "--follow"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                // split the streamed output
                var parts = data.trim().split("|")
                if (parts.length >= 4) {
                    var status = parts[0].toLowerCase()
                    bar.mediaClass = status === "playing" ? "playing" : (status === "paused" ? "paused" : "stopped")
                    bar.mediaText = parts[1] ? parts[1] : "No media playing"
                    bar.mediaPosition = parseInt(parts[2]) || 0
                    bar.mediaLength = parseInt(parts[3]) || 0
                }
            }
        }
    }
    // Process {
    //     id: mediaProc
    //     command: ["bash", "-c", "status=$(playerctl --player=%any status 2>/dev/null); pos=$(playerctl --player=%any position 2>/dev/null | cut -d. -f1); len=$(playerctl --player=%any metadata mpris:length 2>/dev/null); len=$((len / 1000000)); if [ \"$status\" = \"Playing\" ] || [ \"$status\" = \"Paused\" ]; then artist=$(playerctl --player=%any metadata artist 2>/dev/null); title=$(playerctl --player=%any metadata title 2>/dev/null); if [ -n \"$title\" ]; then text=\"$title\"; [ -n \"$artist\" ] && text=\"$artist - $title\"; if [ ${#text} -gt 35 ]; then text=\"${text:0:32}...\"; fi; echo \"$status|$text|$pos|$len\"; else echo 'stopped||0|0'; fi; else echo 'stopped||0|0'; fi"]
    //     stdout: SplitParser {
    //         onRead: data => {
    //             var parts = data.trim().split("|")
    //             if (parts.length >= 4) {
    //                 bar.mediaClass = parts[0].toLowerCase()
    //                 bar.mediaText = parts[1]
    //                 bar.mediaPosition = parseInt(parts[2]) || 0
    //                 bar.mediaLength = parseInt(parts[3]) || 0
    //             }
    //         }
    //     }
    // }

    Timer {
        interval: 1000
        running: bar.mediaClass === "playing"
        repeat: true
        onTriggered: {
            if (bar.mediaPosition < bar.mediaLength) {
                bar.mediaPosition += 1
            }
        }
    }

    Timer {
        interval: 800
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!volumeProc.running) volumeProc.running = true }
    }

    Process {
        id: volumeProc
        command: ["bash", "-c", "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null); muted=$(echo \"$vol\" | grep -q MUTED && echo 1 || echo 0); pct=$(echo \"$vol\" | awk '{printf \"%.0f\", $2 * 100}'); echo \"$pct|$muted\""]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split("|")
                bar.volumePercent = parseInt(parts[0]) || 0
                bar.volumeMuted = parts[1] === "1"
                if (bar.volumeMuted) {
                    bar.volumeStr = "󰝟 mute"
                } else {
                    var icon = bar.volumePercent > 50 ? "󰕾" : (bar.volumePercent > 0 ? "󰖀" : "󰕿")
                    bar.volumeStr = icon + " " + bar.volumePercent + "%"
                }
            }
        }
    }

    Timer {
        id: volumeDebounce
        interval: 150
        repeat: false
        onTriggered: {
            volumeSetProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", bar.pendingVolume + "%"]
            volumeSetProc.running = true
        }
    }

    Process {
        id: volumeSetProc
        onExited: {
            bar.volumeAdjusting = false
            if (!volumeProc.running) volumeProc.running = true
        }
    }

    function adjustVolume(delta) {
        bar.volumeAdjusting = true
        bar.pendingVolume = Math.max(0, Math.min(100, bar.volumePercent + delta))
        bar.volumePercent = bar.pendingVolume
        var icon = bar.volumePercent > 50 ? "󰕾" : (bar.volumePercent > 0 ? "󰖀" : "󰕿")
        bar.volumeStr = icon + " " + bar.volumePercent + "%"
        volumeDebounce.restart()
    }
}