import qs
import qs.modules.common
import qs.modules.common.components.icon
import qs.modules.common.components
import qs.modules.config
import qs.modules.common.widgets
import qs.modules.bar.islands
import qs.modules.bar.components
import qs.services
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Io
import Quickshell.Wayland
import qs.colors
import Quickshell.Widgets
import qs.modules.bar.components
import QtQuick.Effects
import qs.services
import qs.modules.mediaControls
import Quickshell.Wayland
import Quickshell.Hyprland

Rectangle {
    id: mediaIsland
    
    property real progressTop: 0
    property real progressBottom: 0
    property real maxRadius: Appearance.rounding.full
    readonly property real borderWidth: 2
    property var colorsPalette: Colors {}
    property bool animating: false
    anchors.horizontalCenter: parent.horizontalCenter
    Behavior on width {
        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
    }
    // Top-left growing line
    Item {
        visible: false
        id: borderLayer
        anchors.fill: parent
        z: -1 // explicitly behind
        
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            width: parent.width * progressTop
            height: parent.height * progressTop
            color: "transparent"
            border.width: borderWidth
            border.color: colorsPalette.primary
            radius: Appearance.rounding.full
        }

        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: parent.width * progressBottom
            height: parent.height * progressBottom
            color: "transparent"
            border.width: borderWidth
            border.color: colorsPalette.primary
            radius: Appearance.rounding.full
        }
    }


    // Connections {
    //     target: ActiveWindow
    //     function onCurrentChanged() {
    //         console.log("current active window:")
    //     }
    // }
    ParallelAnimation {
        id: borderAnim
        loops: 1
        running: false

        PropertyAnimation { 
            id: animTop
            target: mediaIsland
            property: "progressTop"
            duration: 600
            easing.type: Easing.OutCubic
        }

        PropertyAnimation { 
            id: animBottom
            target: mediaIsland
            property: "progressBottom"
            duration: 600
            easing.type: Easing.OutCubic
        }

        onStarted: mediaIsland.animating = true
        onFinished: mediaIsland.animating = false
    }

    
    // Watch the playback state
    property bool lastIsPlaying: false
    Timer {
        interval: 100
        repeat: true
        running: true
        onTriggered: {
            const playing = Players.effectiveIsPlaying ?? false

            if (playing !== lastIsPlaying) {
                if (playing) {
                    // Shrink borders: 1 → 0
                    animTop.from = mediaIsland.progressTop
                    animTop.to   = 1
                    animBottom.from = mediaIsland.progressBottom
                    animBottom.to   = 1
                } else {
                    // Grow borders: 0 → 1
                    animTop.from = mediaIsland.progressTop
                    animTop.to   = 0
                    animBottom.from = mediaIsland.progressBottom
                    animBottom.to   = 0
                }
                borderAnim.restart()
            }

            lastIsPlaying = playing
        }
    }
    property MprisPlayer safePlayer: null
    
  
    // console.log("current active window: ", ActiveWindow.current)
    


    // readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || titleText.current
    // readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property var activePlayer: Players.player
    // property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle || activePlayer?.metadata?.title) 
    //                                     || titleText.current
    readonly property string configPath: FileUtils.trimFileProtocol(Directories.cache) + "/cava_config.txt"
    readonly property string popupMode: "dock"
    required property real waveformHeight
   
    property var audioBars: [0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    property var barHeight: 0
    property var barWidth: root.implicitWidth  + 18
    // property var barWidth: clockTimeIsland.width + root.implicitWidth + clockDateIsland.width + 18
    
    property bool volumePopupVisible: false
    readonly property real maxMediaWidth: 400
    // Bar-anchored media popup
    property bool barMediaPopupVisible: false
    property bool borderless: false
    // property list<real> visualizerPoints: []
        // readonly property MprisPlayer activePlayer: MprisController.activePlayer
        // readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || titleText.current
        // readonly property string popupMode: "dock"
    radius: Appearance.rounding.full
    // color: mediaIsland.animating ? colorsPalette.background : colorsPalette.backgroundt70
    // color: mediaIsland.activePlayer?.isPlaying || mediaIsland.animating ? colorsPalette.background: colorsPalette.backgroundt70
    
    // color: Appearance.colors.colLayer1
    // color: colorsPalette.backgroundt30
    color: "transparent"
    Behavior on color {
        ColorAnimation {
            duration: 300      // adjust as needed
            easing.type: Easing.OutCubic
        }
    }
    
    // border.width: mediaIsland.activePlayer?.isPlaying && mediaIsland.animating ? 1 : 0
    border.width:0
    border.color: "#4DFFFFFF"

    clip: true
    property int padding: 10


    width: barWidth > 0 ? barWidth : 0
    // width: 
    height: barHeight > 0 ? barHeight : 0
    Layout.alignment: Qt.AlignHCenter


    
    // height: (barHeight > 0 ? barHeight : 0) + (waveformHeight > 0 ? waveformHeight : 0)
 
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        blurMax: 1
        shadowColor: Qt.alpha(colorsPalette.shadow, 0.6)
    }
    readonly property bool visualizerActive: true
    CavaProcess {
    id: cavaProcess
    active: visualizerActive
    }
    property list<real> visualizerPoints: cavaProcess.points
    // WaveVisualizer {
    //     anchors.left: parent.left
    //     anchors.right: parent.right
    //     anchors.bottom: parent.bottom
    //     anchors.leftMargin: 2  
    //     anchors.rightMargin: 2
    //     anchors.bottomMargin: 2
    //     // z: 1
    //     clip: true  
    //     height: barHeight  // for example 35
    //     live: Players.effectiveIsPlaying ?? false
    //     points: mediaIsland.visualizerPoints
    //     maxVisualizerValue: 1000
    //     smoothing: 2
    //     blurred: false
    //     // color: ColorUtils.transparentize(Appearance.colors.colPrimary,
    //     //     0.6
    //     // )
    //     color: Appearance.colors.colPrimary
    //     z: 10 
    // }

    // active window:
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(mediaIsland.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    property string activeWindowAddress: `0x${activeWindow?.HyprlandToplevel?.address}`
    property bool focusingThisMonitor: HyprlandData.activeWorkspace?.monitor == monitor?.name
    property var biggestWindow: HyprlandData.biggestWindowForWorkspace(HyprlandData.monitors[mediaIsland.monitor?.id]?.activeWorkspace.id)
   
    RowLayout {
    
        spacing: 10
        z: 2
        property real targetWidth: Math.min(rowLayout.implicitWidth + rowLayout.spacing * 2, maxMediaWidth)
        property real animWidth: targetWidth  // This is what we animate
        // anchors.centerIn: parent
        Layout.preferredHeight: barHeight
        Layout.preferredWidth: animWidth
        anchors.top: parent.top // Align to the top of the parent container
        anchors.horizontalCenter: parent.horizontalCenter
        // Layout.alignment: Qt.AlignVTop | Qt.AlignHCenter
        // Layout.fillWidth: true
        // Layout.fillHeight: true  
        Behavior on animWidth {
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }
    

        // Rectangle {
        //     id: clockTimeIsland
        //     radius: Appearance.rounding.full
        //     visible: false
        //     // color: colorsPalette.backgroundt30
        //     color: Appearance.colors.colLayer1
        //     // color: colorsPalette.surfaceContainer
        //     border.width: 0
        //     border.color: "#4DFFFFFF"
        //     property int padding: 10
         
        //     Layout.preferredHeight: barHeight * 0.8
        //     Layout.preferredWidth: clockTime.implicitWidth + padding * 2
        //     ClockTime {
        //         id: clockTime
        //         anchors.centerIn: parent
        //     }
        // }
        Rectangle {
            id: root
    
            Layout.fillHeight: true
   
            Layout.preferredHeight: barHeight * 0.9
            Layout.alignment: Qt.AlignTop
          
            Layout.fillWidth: false
            
            color: "#000000"
            Layout.topMargin: 0
            Layout.bottomMargin: 0
            // radius: 10
            topLeftRadius: 10
            topRightRadius: 10
            bottomLeftRadius: Appearance.rounding.full
            bottomRightRadius: Appearance.rounding.full
            // radius: Appearance.rounding.full
            property real targetWidth: Math.min(rowLayout.implicitWidth + rowLayout.spacing * 2, maxMediaWidth)
            
            Layout.preferredWidth: targetWidth
            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutCubic
                }
            }

            // anchors.bottomMargin: 6
            Rectangle {
                anchors.left: parent.left; 
                anchors.right: parent.right; 
                anchors.top: parent.top
                height: 10
                color: "#000000"
                visible: true
            }

             // Concave Corners
            RoundCorner {
                anchors.right: parent.left; anchors.top: parent.top
                implicitSize: 14; 
                color: "#000000"; 
                corner: RoundCorner.CornerEnum.TopRight
                visible: true; 
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }

            RoundCorner {
                anchors.left: parent.right; anchors.top: parent.top
                implicitSize: 14; 
                color: "#000000"; 
                corner: RoundCorner.CornerEnum.TopLeft
                visible: true 
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }

            Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
            // Clamp width to prevent long song titles from overflowing into Workspaces.
            // The bar's centerSideModuleWidth binding already accounts for this, but
            // an explicit maxWidth keeps the text properly elided inside the group.
            
            implicitWidth: Math.min(rowLayout.implicitWidth + rowLayout.spacing * 2, maxMediaWidth)
            implicitHeight: barHeight - 8
            
            clip: false

        

            RowLayout { // Real content
                id: rowLayout

                spacing: 4
                anchors.fill: parent
                // anchors.leftMargin: 10
                // anchors.rightMargin: 6
              

            
                // property bool trackPaused: titleText.text !== titleText.buildText() &&
                //                             titleText.text !== Translation.tr("Paused")

                // property bool trackPlayed: titleText.text !== titleText.buildText() &&
                //                             titleText.text !== Translation.tr("Now Playing")
                MaterialIcon {
                    id: icon

                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.leftMargin: rowLayout.spacing * 2

                //     property bool trackPaused: titleText.text !== titleText.buildText() &&
                //                             titleText.text !== Translation.tr("Paused")

                // property bool trackPlayed: titleText.text !== titleText.buildText() &&
                //                             titleText.text !== Translation.tr("Now Playing")

                    visible: true
                    animate: true

                    text: Icons.getAppCategoryIcon(HyprlandData.activeToplevel?.lastIpcObject?.class, "desktop_windows")
                    color: Appearance.colors.colOnLayer1
                }
                // Connections {
                //     target: HyprlandData
                //     onActiveToplevelChanged: {
                //         icon.winClass = HyprlandData.activeToplevel?.lastIpcObject?.class ?? ""
                //         icon.winAppId = HyprlandData.activeToplevel?.lastIpcObject?.appId ?? ""
                //         icon.winTitle = HyprlandData.activeToplevel?.lastIpcObject?.title ?? ""
                //     }
                // }

                StyledText {
                    id: titleText

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: rowLayout.spacing
                    Layout.rightMargin: rowLayout.spacing * 2
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    color: Appearance.colors.colOnLayer1
                    

                    // ---------------------------
                    // CROSSFADE SYSTEM
                    // ---------------------------
                    property string current: ""
                    property var currentTextLayer: text1

                    Item {
                        anchors.fill: parent

                        Text {
                            id: text1
                            anchors.fill: parent
                            horizontalAlignment: titleText.horizontalAlignment
                            verticalAlignment: titleText.verticalAlignment
                            font: titleText.font
                            color: titleText.color
                            elide: titleText.elide
                            opacity: 1
                            Behavior on opacity { Anim {} }
                        }

                        Text {
                            id: text2
                            anchors.fill: parent
                            horizontalAlignment: titleText.horizontalAlignment
                            verticalAlignment: titleText.verticalAlignment
                            font: titleText.font
                            color: titleText.color
                            elide: titleText.elide
                            opacity: 0
                            Behavior on opacity { Anim {} }
                        }
                    }

                    // 🔥 Bridge: update crossfade when text changes
                    onTextChanged: current = titleText.text

                    onCurrentChanged: {
                        const next = currentTextLayer === text1 ? text2 : text1
                        const prev = currentTextLayer

                        next.text = current
                        next.opacity = 0

                        currentTextLayer = next

                        Qt.callLater(() => {
                            prev.opacity = 0
                            next.opacity = 1
                        })
                    }

                    // ---------------------------
                    // HELPERS
                    // ---------------------------
                    function computeCurrentWindow() {
                        if (!mediaIsland) return Translation.tr("Desktop")

                        const active = mediaIsland.activeWindow
                        const biggest = mediaIsland.biggestWindow

                        if (mediaIsland.focusingThisMonitor && active?.activated && biggest)
                            return active.title
                        else if (biggest)
                            return `${Translation.tr("Workspace")} ${monitor?.activeWorkspace?.id ?? 1} — ${biggest.title}`
                        else
                            return `${Translation.tr("Workspace")} ${monitor?.activeWorkspace?.id ?? 1} — ${Translation.tr("Desktop")}`
                    }

                    // ---------------------------
                    // REFRESH TIMER
                    // ---------------------------
                    Timer {
                        interval: 200
                        repeat: true
                        running: true
                        onTriggered: {
                            titleText.text = titleText.computeCurrentWindow()
                        }
                    }

                    Component.onCompleted: {
                        titleText.text = titleText.computeCurrentWindow()
                        text1.text = titleText.text
                        text2.text = ""
                        current = text1.text
                    }
                }
            }

        }
         // ---------------------------
                    // Loading dots inside StyledText
                    // ---------------------------
                    // Item {
                    //     id: loadingDots
                    //     anchors.fill: parent
                    //     visible: titleText.isLoading
                    //     property int dotCount: 1

                    //     Timer {
                    //         interval: 400   // faster animation
                    //         repeat: true
                    //         running: loadingDots.visible
                    //         onTriggered: {
                    //             loadingDots.dotCount = loadingDots.dotCount < 4 ? loadingDots.dotCount + 1 : 1
                    //         }
                    //     }

                    //     Row {
                    //         anchors.centerIn: parent
                    //         spacing: 4
                    //         Repeater {
                    //             model: loadingDots.dotCount
                    //             Rectangle {
                    //                 width: 6
                    //                 height: 6
                    //                 radius: 3
                    //                 color: "white"
                    //                 opacity: 0.3

                    //                 SequentialAnimation on opacity {
                    //                     loops: Animation.Infinite
                    //                     NumberAnimation { to: 1; duration: 400; easing.type: Easing.InOutQuad }
                    //                     NumberAnimation { to: 0.3; duration: 400; easing.type: Easing.InOutQuad }
                    //                 }
                    //             }
                    //         }
                    //     }
                    // }
        // Rectangle {
        //     id: clockDateIsland
        //     radius: Appearance.rounding.full
        //     visible: false
        //     // color: colorsPalette.backgroundt30
        //     color: Appearance.colors.colLayer1
            
        //     // color: colorsPalette.surfaceContainer
        //     border.width: 0
        //     border.color: "#4DFFFFFF"
        //     property int padding: 10

        //     Layout.preferredHeight: barHeight * 0.8
        //     Layout.preferredWidth: clockDate.implicitWidth + padding * 2
        //     // Layout.leftMargin: 12
        //     // layer.enabled: true
        //     // layer.effect: MultiEffect {
        //     //     shadowEnabled: true
        //     //     blurMax: 1
        //     //     shadowColor: Qt.alpha(colorsPalette.shadow, 0.6)  // adjust opacity
        //     // }

        //     ClockDate {
        //         id: clockDate
        //         anchors.centerIn: parent
        //     }
            
        // }
    }
}

    // Canvas {
    //     id: audioVisualizer
    //     z: 0
    //     opacity: 0.7
    //     anchors.left: parent.left
    //     anchors.right: parent.right
    //     anchors.bottom: parent.bottom  // attach to bottom of mediaIsland
    //     // anchors.top: parent.top
    //     // visible: activePlayer ? true : false
    //     visible: (activePlayer?.volume ?? 0) !== 0 && activePlayer?.isPlaying ? true : false
    //     height: mediaIsland.barHeight
    //     clip: false
        
    //     property var displayBars: [0,0,0,0,0,0,0,0,0,0,0,0,0,0]

    //     Connections {
    //         target: mediaIsland
    //         function onAudioBarsChanged() {
    //             let newBars = mediaIsland.audioBars
    //             let smoothed = []
    //             let prev = audioVisualizer.displayBars
    //             for (let i = 0; i < newBars.length; i++) {
    //                 let p = i < prev.length ? prev[i] : 0
    //                 smoothed.push(p + (newBars[i] - p) * 0.45)
    //             }
    //             // for (let i = 0; i < prev.length; i++) {
    //             //     let target = newBars[i] ?? 0
    //             //     let p = prev[i] ?? 0
    //             //     smoothed.push(p + (target - p) * 0.35)
    //             // }
    //             audioVisualizer.displayBars = smoothed
    //             audioVisualizer.requestPaint()
    //         }
    //     }


    //     onPaint: {
    //         var ctx = getContext("2d")
    //         ctx.clearRect(0, 0, width, height)

    //         var raw = displayBars
    //         if (!raw || raw.length === 0) return

    //         var first = raw[0] || 0
    //         var last = raw[raw.length - 1] || 0
    //         var vals = [0, first*0.1, first*0.35].concat(raw).concat([last*0.35, last*0.1, 0])

    //         var baseY = height / 2
    //         var topPadding = barHeight * 0.05
    //         var maxAmp = (height / 2) - topPadding
    //         var step = width / (vals.length - 1)
    //         var ampScale = 0.85
    //         var minAmp = maxAmp * 0.05    // 5% minimum

    //         // Clip to canvas
    //         ctx.beginPath()
    //         ctx.rect(0, 0, width, height)
    //         ctx.clip()

    //         // --- Filled waveform ---
    //         ctx.beginPath()
    //         for (var i = 0; i < vals.length; i++) {
    //             var x = i * step
    //             var amp = Math.max(vals[i]/100 * maxAmp * ampScale, minAmp)
    //             var y = baseY - amp
    //             if (i === 0) ctx.moveTo(x, y)
    //             else {
    //                 var prevX = (i-1) * step
    //                 var cpX = (prevX + x)/2
    //                 var prevAmp = Math.max(vals[i-1]/100 * maxAmp * ampScale, minAmp)
    //                 var prevY = baseY - prevAmp
    //                 ctx.quadraticCurveTo(cpX, prevY, x, y)
    //             }
    //         }

    //         // Mirror bottom
    //         for (var i = vals.length -1; i >= 0; i--) {
    //             var x = i * step
    //             var amp = Math.max(vals[i]/100 * maxAmp * ampScale, minAmp)
    //             var y = baseY + amp
    //             ctx.lineTo(x, y)
    //         }

    //         ctx.closePath()
    //         var surf = colorsPalette.surface
    //         ctx.fillStyle = Qt.rgba(surf.r, surf.g, surf.b, 0.88)
    //         ctx.fill()

    //         // --- Stroke ---
    //         ctx.beginPath()
    //         for (var i = 0; i < vals.length; i++) {
    //             var x = i * step
    //             var amp = Math.max(vals[i]/100 * maxAmp * ampScale, minAmp)
    //             var y = baseY - amp
    //             if (i === 0) ctx.moveTo(x, y)
    //             else {
    //                 var prevX = (i-1) * step
    //                 var cpX = (prevX + x)/2
    //                 var prevAmp = Math.max(vals[i-1]/100 * maxAmp * ampScale, minAmp)
    //                 var prevY = baseY - prevAmp
    //                 ctx.quadraticCurveTo(cpX, prevY, x, y)
    //             }
    //         }
    //         for (var i = vals.length -1; i >= 0; i--) {
    //             var x = i * step
    //             var amp = Math.max(vals[i]/100 * maxAmp * ampScale, minAmp)
    //             var y = baseY + amp
    //             ctx.lineTo(x, y)
    //         }

    //         ctx.strokeStyle = Qt.rgba(colorsPalette.primary.r, colorsPalette.primary.g, colorsPalette.primary.b, 0.6)
    //         ctx.lineWidth = 1
    //         ctx.lineJoin = "round"
    //         ctx.lineCap = "round"
    //         ctx.stroke()
    //     }
        
    //     Connections {
    //         target: mediaIsland.colorsPalette
    //         function onSurfaceChanged() { audioVisualizer.requestPaint() }
    //         function onPrimaryChanged() { audioVisualizer.requestPaint() }
    //     }
    // }



    
    // --- Cava process ---
   
   
//    Process {
//         id: cavaProcess
//         command: ["cava", "-p", mediaIsland.configPath]
//         running: true
//         stdout: SplitParser {
//             onRead: data => {
//                 let raw = data.trim()
//                 if (!raw) return
//                 let vals = raw.split(";").filter(s => s !== "").map(s => parseInt(s) || 0)
//                 if (vals.length > 0) mediaIsland.audioBars = vals
//             }
//         }
//         onExited: { cavaRestartTimer.start() }
//     }

//     Timer {
//         id: cavaRestartTimer
//         interval: 2000
//         onTriggered: { if (!cavaProcess.running) cavaProcess.running = true }
//     }
// }
      