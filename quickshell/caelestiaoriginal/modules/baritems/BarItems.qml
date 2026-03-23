import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.modules.baritems
import qs.colors
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects
import QtQuick.Controls
import qs.modules.baritems.islands
import qs.modules.common
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
    implicitHeight: 36
    anchors { top: true; left: true; right: true }
    // Create the "floating" effect
    margins {
        top: 12
        left: 14
        right: 14
    }
    

    property int activeWsId: 1
    property int targetWsId: 1
    
    property string mediaText: ""
    property string mediaClass: "stopped"
    property real mediaPosition: 0
    property real mediaLength: 0
    property string volumeStr: "󰕾 0%"
    property int volumePercent: 50
    property bool volumeMuted: false
    property var cavaValues: [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1]
    property var stableWorkspaces: [1,2,3,4,5,6,7,8,9,10]
    
 readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property int workspacesShown: 5
    readonly property int workspaceGroup: Math.floor((monitor?.activeWorkspace?.id - 1) / root.workspacesShown)
    property list<bool> workspaceOccupied: []
    property int widgetPadding: 4
    property int workspaceButtonWidth: 26
    property real activeWorkspaceMargin: 2
    property real workspaceIconSize: workspaceButtonWidth * 0.69
    property real workspaceIconSizeShrinked: workspaceButtonWidth * 0.55
    property real workspaceIconOpacityShrinked: 1
    property real workspaceIconMarginShrinked: -4
    property int workspaceIndexInGroup: (monitor?.activeWorkspace?.id - 1) % root.workspacesShown
    // Connections {
    //     target: Hyprland
    //     function onRawEvent(event) {
    //         if (event.name === "workspace") {
    //             var wsId = parseInt(event.data.trim())
    //             if (!isNaN(wsId)) {
    //                 bar.targetWsId = wsId
    //                 wsTransition.restart()
    //             }
    //         } else if (event.name === "focusedmon") {
    //             var parts = event.data.split(",")
    //             if (parts.length >= 2) {
    //                 var wsId = parseInt(parts[1])
    //                 if (!isNaN(wsId)) {
    //                     bar.targetWsId = wsId
    //                     wsTransition.restart()
    //                 }
    //             }
    //         }
    //     }
    // }


    


 

    // Rectangle {
    //     id: mainIsland

    //     color: colorsPalette.backgroundt70
    //     radius: 14
    //     border.width: 2
    //     border.color: "#CCFFFFFF"

    //     anchors.top: parent.top
    //     anchors.left: parent.left

    //     property int padding: 14
    //     property int spacing: 18

    //     implicitWidth: contentRow.childrenRect.width + padding * 2
    //     implicitHeight: bar.implicitHeight

    //     Row {
    //         id: contentRow
    //         anchors.fill: parent
    //         anchors.margins: mainIsland.padding
    //         spacing: mainIsland.spacing
    //         anchors

    
    //     verticalAlignment: Qt.AlignVCenter
    //             // ===== MENU =====
    //             ActiveWindow {
    //                 id: activeWindowItem
                    
    //             }


    //         // ===== WORKSPACES =====
    //         Row {
    //             id: workspacesRow
    //             Workspaces {}
    //         }

    //         // ===== TIME =====
    //         Row {
    //             id: timeRow

    //             Text {
    //                 id: clockText
    //                 text: Qt.formatTime(new Date(), "h:mm AP")
    //                 color: "#ffffff"
    //                 font.pixelSize: 15
    //                 font.family: "JetBrainsMono Nerd Font Mono"
    //             }
    //         }
    //     }

    //     Timer {
    //         interval: 1000
    //         running: true
    //         repeat: true
    //         onTriggered:
    //             clockText.text = Qt.formatTime(new Date(), "h:mm AP")
    //     }

    //     Behavior on implicitWidth {
    //         NumberAnimation {
    //             duration: 300
    //             easing.type: Easing.OutCubic
    //         }
    //     }
    // }
//     Rectangle {
//     id: menuIsland
//     // color: "transparent"
//     color: colorsPalette.backgroundt70
//     // color: ""
//     radius: 14
//     border.width: 0

//     anchors.top: parent.top
//     anchors.left: parent.left

//     property int padding: 0

//     height: parent.height
//     // width: bar
//     width: leftSectionRowLayout.implicitWidth + padding * 2


//     RowLayout {
//         id: leftSectionRowLayout
//         anchors.fill: parent
//         anchors.margins: padding
//         anchors.leftMargin: 0
//         spacing: 1

//         LeftSidebarButton {
//             Layout.alignment: Qt.AlignVCenter
//             Layout.leftMargin: 8
//             // Layout.leftMargin: Appearance.rounding.screenRounding

//             // colBackground: barLeftSideMouseArea.hovered
//             //     ? Appearance.colors.colLayer1Hover
//             //     : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
//         }


//     }
// }
    


    // Rectangle {
    // id: workspacesIsland
    // color: colorsPalette.backgroundt70 // semi-transparent background
    // radius: 14           // rounded corners
    // border.width: 2
    // border.color: "#FFFFFF"
    // anchors.verticalCenter: parent.verticalCenter
    // anchors.left: menuIsland.right
    // anchors.leftMargin: 12
   
    // // padding inside the island
    // property int padding: 8
    // // width: parent.width
    // implicitWidth: workspacesRow.childrenRect.width + padding * 2

    // implicitHeight: workspacesRow.childrenRect.height + padding * 2
    // Behavior on width {
    //     NumberAnimation {
    //         duration: 300
    //         easing.type: Easing.OutCubic
    //     }
    // }
   
    //   Item {
    // anchors.fill: parent

    //     Row {   
    //         id: workspacesRow
    //         anchors.centerIn: parent
    //         Workspaces{}
    //         }   
    //   }}

    // Rectangle {
    //     id: timeIsland

    //     color: colorsPalette.backgroundt70
    //     radius: 14
    //     border.width: 2
    //     border.color: "#CCFFFFFF"
        
    //     anchors.verticalCenter: parent.verticalCenter
    //     anchors.left: workspacesIsland.right
    //     anchors.leftMargin: 12   // spacing between islands

    //     property int padding: 12
    //     width: timeRow.childrenRect.width + padding * 2
    //     height: bar.implicitHeight   // <- ensures perfect match

    //     Row {
    //         id: timeRow
    //         anchors.centerIn: parent
    //         anchors.margins: timeIsland.padding

    //         Text {
    //             id: clockText
    //             text: Qt.formatTime(new Date(), "h:mm AP")
    //             color: "#ffffff"
    //             font.pixelSize: 15
    //             font.family: "JetBrainsMono Nerd Font Mono"
    //            // <-- key line
    //         }
    //     }

    //     Timer {
    //         interval: 1000
    //         running: true
    //         repeat: true
    //         onTriggered: clockText.text = Qt.formatTime(new Date(), "h:mm AP")
    //     }
    // }
// Parent Island containing Workspaces and Time
Rectangle {
    id: mainIsland
    color: colorsPalette.backgroundt70
    radius: 14
    border.width: 0
    border.color: "#CCFFFFFF"
    // border.color:
    // border.color: "transparent" // 40% opacity border

    anchors.verticalCenter: parent.verticalCenter
    // anchors.left: menuIsland.right
    anchors.leftMargin: 12   // spacing between islands
    property int padding: 2
    implicitWidth: leftSidebarButton.width + activeWindowIsland.width + workspacesRow.width + timeRow.width + padding * 2 // spacing between children
    implicitHeight: parent.height

    Behavior on width {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    Row {
        id: contentRow
        anchors.fill: parent
        anchors.margins: padding
        spacing: 0  // spacing between workspaces and clock
        // color: colorsPalette.backgroundt70
        // Workspaces Section
        LeftSidebarButton {
            id: leftSidebarButton 
            width: 32        // set fixed width
            height: 32       // set fixed height
            anchors.verticalCenter: parent.verticalCenter
            // anchors.verticalLeft: parent.verticalLeft
            // Optional background
            // colBackground: Appearance.colors.colLayer1
        }
            // Active Window Island
        Rectangle {
            id: activeWindowIsland
            color: "transparent"
            radius: 14
            anchors.verticalCenter: parent.verticalCenter
            property int padding: 8
            // width: activeWindowItem.implicitWidth + padding * 2
            width: 150
            height: parent.height  // match row height

            ActiveWindow {
                id: activeWindowItem
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: activeWindowIsland.padding  // add some space from rectangle border
            }
        }
        Row {
            id: workspacesRow
            anchors.verticalCenter: parent.verticalCenter
            padding: 8
            // BarGroup{
            //     Workspaces{}
            // }
            BarGroup {
            id: workspacesGroup
            padding: 0
             Layout.fillHeight: false
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            // Layout.fillHeight: true
             anchors.margins: 0
            // Layout.fillWidth: false
            // Layout.alignment: Qt.AlignVCenter
            // implicitHeight: Appearance.sizes.baseBarHeight * 0.8
            width: workspacesWidget.implicitWidth + padding
            implicitHeight: mainIsland.implicitHeight

                BarWorkspaces {
                    id: workspacesWidget
                    parentBarHeight: mainIsland.implicitHeight
                }
            }
            // Workspaces{}
            
        }

        // Time Section
        Row {
            id: timeRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

             // Time BarGroup
            BarGroup {
                id: timeGroup
                padding: 8
                
                Layout.fillHeight: false
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                
                // width: timeRowContent.implicitWidth + 14
                
                implicitHeight: mainIsland.implicitHeight

                Row {
                    id: timeRowContent
                    spacing: 4

                    Text {
                        id: clockTime
                        font.pixelSize: 16
                        // color: Appearance.colors.colOnLayer1
                        color: colorsPalette.backgroundText
                        text: Qt.formatTime(new Date(), "h:mm AP")
                    }

                    Text {
                        id: separator
                        // visible: true
                        font.pixelSize: 14
                        color: colorsPalette.backgroundText
                        text: "•"
                    }

                    Text {
                        id: clockDate
                        // visible: true
                        font.pixelSize: 14
                        color: colorsPalette.backgroundText
                        text: Qt.formatDate(new Date(), "ddd, dd/MM")
                    }

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: {
                            clockTime.text = Qt.formatTime(new Date(), "h:mm AP")
                            clockDate.text = Qt.formatDate(new Date(), "ddd, dd/MM")
                        }
                    }
                }
            }
        }
        // ActiveWindow {
        //     id: activeWindowItem
        //     Layout.fillWidth: true
        //     Layout.fillHeight: false
        //     Layout.alignment: Qt.AlignVCenter
        //     Layout.rightMargin: Appearance.rounding.screenRounding
        // }
    }
}


// Rectangle {
//     id: activeWindowIsland
//     color: "transparent"
//     radius: 14
//     // border.width: 2
//     // border.color: "#CCFFFFFF"

//     // Anchor to the right of mainIsland
//     anchors.top: mainIsland.top
//     anchors.left: mainIsland.right
//     anchors.leftMargin: 12    // spacing between mainIsland and menuIsland

//     property int padding: 14
//     width: activeWindowItem.implicitWidth + padding * 2
//     height: mainIsland.height    // match mainIsland height

//     ActiveWindow {
//         id: activeWindowItem
//         anchors.centerIn: parent
//     }
// }

Rectangle {
    id: mediaIsland
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    radius: 14
    color: colorsPalette.backgroundt80
    border.width: 0
    // border.color: "transparent" // 20% opacity border
    border.color: "#CCFFFFFF"
    // border.color: colorsPalette.primary
    clip: true
    property int padding: 10
    height: parent.height
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
                color: colorsPalette.backgroundText
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