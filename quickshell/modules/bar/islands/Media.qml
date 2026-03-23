import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.mediaControls
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



Rectangle {
    id: mediaIsland
    
    property real progressTop: 0
    property real progressBottom: 0
    property real maxRadius: 10
    readonly property real borderWidth: 2
    property var colorsPalette: Colors {}
    property bool animating: false
    anchors.horizontalCenter: parent.horizontalCenter
    Behavior on width {
        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
    }
    // Top-left growing line
    Item {
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
            radius: 10
        }

        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: parent.width * progressBottom
            height: parent.height * progressBottom
            color: "transparent"
            border.width: borderWidth
            border.color: colorsPalette.primary
            radius: 10
        }
    }

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
            const playing = mediaIsland.activePlayer?.isPlaying ?? false

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
    property string cleanedTitle: Translation.tr("No media playing")
    // Timer {
    //     id: updatedTimer
    //     interval: 200
    //     repeat: true
    //     running: true
    //     onTriggered: {
    //         const playing = activePlayer?.playbackState === MprisPlaybackState.Playing
    //         const currentTrack = titleText.buildText()  // fully qualified

    //         // Update lastTrack before showing paused
    //         titleText.lastTrack = currentTrack

    //         // Show "Paused" only if user paused
    //         if (!playing && titleText.lastIsPlaying && Players.lastUserPaused
    //             && currentTrack !== Translation.tr("No media playing")) {
                
    //             if (!titleText.pauseShown) {
    //                 titleText.pauseShown = true
    //                 titleText.text = Translation.tr("Paused")
    //                 pauseTimer.restart()  // restart in case another pause happens
    //             }
    //         }
    //         else if (playing && !titleText.lastIsPlaying && Players.lastUserPlayed
    //             && currentTrack !== Translation.tr("No media playing")) {
                
    //             if (!titleText.playShown) {
    //                 titleText.playShown = true
    //                 titleText.text = Translation.tr("Now Playing")
    //                 playTimer.restart()  // restart in case another pause happens
    //             }   
    //         } 
    //         // Update normally when playing or after pause
    //         else if (!titleText.pauseShown && !titleText.playShown && titleText.text !== currentTrack) {
    //             titleText.text = currentTrack
    //         }

    //         titleText.lastIsPlaying = playing
    //     }
    // }
    
   
    // Timer {
    //     interval: 100
    //     repeat: true
    //     running: true
    //     onTriggered: {
    //         const active = Players.active

    //         if (active && (active.trackTitle || active.metadata?.title)) {
    //             // Only update if safePlayer changed
    //             if (safePlayer !== active) {
    //                 safePlayer = active
    //                 cleanedTitle = StringUtils.cleanMusicTitle(safePlayer.trackTitle || safePlayer.metadata?.title)
    //                                 || Translation.tr("No media playing")
    //             }
    //         } else if (!active) {
    //             // No player at all → reset
    //             safePlayer = null
    //             cleanedTitle = Translation.tr("No media playing")
    //         }
    //         // else: active exists but metadata not ready → retain old safePlayer/title
    //     }
    // }

    // Timer {
    //     interval: 100
    //     repeat: true
    //     running: true
    //     onTriggered: {
    //         const active = Players.active

    //         let title = ""
    //         let artist = ""

    //         if (active) {
    //             title = active.trackTitle || active.metadata?.title || ""
    //             artist = active.trackArtist || active.metadata?.artist || ""
    //         }

    //         let newText = Translation.tr("No media playing")

    //         if (title !== "") {
    //             newText = StringUtils.cleanMusicTitle(title)

    //             if (artist !== "") {
    //                 newText += " • " + artist
    //             }
    //         }

    //         if (cleanedTitle !== newText) {
    //             cleanedTitle = newText
    //         }
    //     }
    // }

    


    // readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media playing")
    // readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property var activePlayer: Players.active
    // property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle || activePlayer?.metadata?.title) 
    //                                     || Translation.tr("No media playing")
    readonly property string configPath: FileUtils.trimFileProtocol(Directories.cache) + "/cava_config.txt"
    readonly property string popupMode: "dock"
    required property real waveformHeight
    readonly property bool visualizerActive: true
    property var audioBars: [0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    property var barHeight: 0
    property var barWidth: clockTimeIsland.width + root.implicitWidth + clockDateIsland.width + 26
    // property var barWidth: clockTimeIsland.implicitWidth + root.implicitWidth + clockDateIsland.implicitWidth
// Volume popup
    property bool volumePopupVisible: false
    readonly property real maxMediaWidth: 280
    // Bar-anchored media popup
    property bool barMediaPopupVisible: false
    property bool borderless: false
    // property list<real> visualizerPoints: []
        // readonly property MprisPlayer activePlayer: MprisController.activePlayer
        // readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media playing")
        // readonly property string popupMode: "dock"
    radius: 10
    // color: mediaIsland.animating ? colorsPalette.background : colorsPalette.backgroundt70
    color: mediaIsland.activePlayer?.isPlaying || mediaIsland.animating ? colorsPalette.background: colorsPalette.backgroundt70
    // color: "transparent"
    Behavior on color {
        ColorAnimation {
            duration: 300      // adjust as needed
            easing.type: Easing.OutCubic
        }
    }
    border.width: 1
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

    CavaProcess {
    id: cavaProcess
    active: visualizerActive
    }
    property list<real> visualizerPoints: cavaProcess.points
    WaveVisualizer {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 2  
        height: barHeight  // for example 35
        live: mediaIsland.activePlayer?.isPlaying ?? false
        points: mediaIsland.visualizerPoints
        maxVisualizerValue: 1000
        smoothing: 2
        blurred: false
        // color: ColorUtils.transparentize(Appearance.colors.colPrimary,
        //     0.6
        // )
        color: Appearance.colors.colPrimary
        z: 10 // Make sure it's behind other content
    }

    RowLayout {

        spacing: 8
        z: 1
        anchors.centerIn: parent
        property real targetWidth: Math.min(rowLayout.implicitWidth + rowLayout.spacing * 2, maxMediaWidth)
        property real animWidth: targetWidth  // This is what we animate

        Layout.preferredHeight: barHeight
        Layout.preferredWidth: animWidth
        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        Layout.fillWidth: true  
        Behavior on animWidth {
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }
        Rectangle {
            id: clockTimeIsland
            radius: 8
            // visible: false
            color: colorsPalette.backgroundt70
            // color: colorsPalette.surfaceContainer
            border.width: 1
            border.color: "#4DFFFFFF"
            property int padding: 10
         
            Layout.preferredHeight: barHeight - 8
            Layout.preferredWidth: clockTime.implicitWidth + padding * 2
            // Layout.leftMargin: 12
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 1
                shadowColor: Qt.alpha(colorsPalette.shadow, 0.6)  // adjust opacity
            }

            ClockTime {
                id: clockTime
                anchors.centerIn: parent
            }
            
        }
        Rectangle {
            id: root
            // color: "transparent"
            Layout.fillHeight: false
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            color: "#000000"
            Layout.bottomMargin: 4
            radius: 10
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
                visible: isWaterdrop
            }

             // Concave Corners
            RoundCorner {
                anchors.right: parent.left; anchors.top: parent.top
                implicitSize: 12; 
                color: "black"; 
                corner: RoundCorner.CornerEnum.TopRight
                visible: true; 
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }

            RoundCorner {
                anchors.left: parent.right; anchors.top: parent.top
                implicitSize: 12; 
                color: "black"; 
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

            Timer {
                running: activePlayer?.playbackState == MprisPlaybackState.Playing
                interval: Config.options?.resources?.updateInterval ?? 3000
                repeat: true
                onTriggered: activePlayer?.positionChanged()
            }

        
            
            Timer {
                id: hideTimer
                interval: 1000
                onTriggered: volumePopupVisible = false
            }

            Loader {
                id: volumePopupLoader
                active: volumePopupVisible
                sourceComponent: PopupWindow {
                    visible: true
                    color: "transparent"
                    anchor {
                        window: root.QsWindow.window
                        item: root
                        edges: (Config.options?.bar?.bottom ?? false) ? Edges.Top : Edges.Bottom
                        gravity: (Config.options?.bar?.bottom ?? false) ? Edges.Top : Edges.Bottom
                    }
                    implicitWidth: popupContent.width + 16
                    implicitHeight: popupContent.height + 16

                    Rectangle {
                        id: popupContent
                        anchors.centerIn: parent
                        width: volumeRow.width + 12
                        height: volumeRow.height + 8
                        radius: Appearance.angelEverywhere ? Appearance.angel.roundingSmall
                            : Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.verysmall
                        color: Appearance.angelEverywhere ? Appearance.angel.colGlassPopup
                            : Appearance.inirEverywhere ? Appearance.inir.colLayer2
                            : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface
                            : Appearance.colors.colLayer3
                        border.width: Appearance.angelEverywhere ? Appearance.angel.cardBorderWidth
                                    : (Appearance.inirEverywhere || Appearance.auroraEverywhere) ? 1 : 0
                        border.color: Appearance.angelEverywhere ? Appearance.angel.colCardBorder
                                    : Appearance.inirEverywhere ? Appearance.inir.colBorder
                                    : Appearance.auroraEverywhere ? Appearance.aurora.colPopupBorder
                                    : Appearance.colors.colLayer3Hover

                        Row {
                            id: volumeRow
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol {
                                anchors.verticalCenter: parent.verticalCenter
                                text: (activePlayer?.volume ?? 0) === 0 ? "volume_off" : "volume_up"
                                iconSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer3
                            }
                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Math.round((activePlayer?.volume ?? 0) * 100) + "%"
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnLayer3
                            }
                        }
                    }
                }
            }

            // Backdrop for click-outside-to-close (Niri)
            Loader {
                active: barMediaPopupVisible && popupMode === "bar" && CompositorService.isNiri
                sourceComponent: PanelWindow {
                    anchors { top: true; bottom: true; left: true; right: true }
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "quickshell:mediaBackdrop"
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: barMediaPopupVisible = false
                    }
                }
            }

            // Bar-anchored media controls popup (when popupMode === "bar")
            Loader {
                id: barMediaPopupLoader
                active: (barMediaPopupVisible || _barMediaClosing) && popupMode === "bar"

                property bool _barMediaClosing: false

                // Connections {
                //     target: root
                //     function onBarMediaPopupVisibleChanged() {
                //         if (!barMediaPopupVisible) {
                //             barMediaPopupLoader._barMediaClosing = true
                //             _barMediaCloseTimer.restart()
                //         }
                //     }
                // }
                // Connections {
                //     target: root
                //     onBarMediaPopupVisibleChanged: {
                //         if (!barMediaPopupVisible) {
                //             barMediaPopupLoader._barMediaClosing = true
                //             _barMediaCloseTimer.restart()
                //         }
                //     }
                // }
                Timer {
                    id: _barMediaCloseTimer
                    interval: 200
                    onTriggered: barMediaPopupLoader._barMediaClosing = false
                }

                sourceComponent: PopupWindow {
                    id: barMediaPopup
                    visible: true
                    color: "transparent"
                    anchor {
                        window: QsWindow.window
                        item: root
                        edges: Config.options.bar.bottom ? Edges.Top : Edges.Bottom
                        gravity: Config.options.bar.bottom ? Edges.Top : Edges.Bottom
                    }
                    implicitWidth: mediaPopupContent.width + Appearance.sizes.elevationMargin * 2
                    implicitHeight: mediaPopupContent.height + Appearance.sizes.elevationMargin * 2

                    // Click outside to close
                    MouseArea {
                        anchors.fill: parent
                        onClicked: barMediaPopupVisible = false
                        z: -1
                    }

                    BarMediaPopup {
                        id: mediaPopupContent
                        anchors.centerIn: parent
                        onCloseRequested: barMediaPopupVisible = false
                        
                        // Entry/exit animation
                        opacity: barMediaPopupVisible ? 1 : 0
                        scale: barMediaPopupVisible ? 1 : 0.9
                        transformOrigin: Config.options.bar.bottom ? Item.Bottom : Item.Top

                        Behavior on opacity {
                            enabled: Appearance.animationsEnabled
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }
                        Behavior on scale {
                            enabled: Appearance.animationsEnabled
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
                onPressed: (event) => {
                    if (event.button === Qt.MiddleButton) {
                        activePlayer?.togglePlaying();
                    } else if (event.button === Qt.BackButton) {
                        activePlayer?.previous();
                    } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                        activePlayer?.next();
                    } else if (event.button === Qt.LeftButton) {
                        if (popupMode === "bar") {
                            barMediaPopupVisible = !barMediaPopupVisible
                        } else {
                            GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen
                        }
                    }
                }
                onWheel: (event) => {
                    if (!activePlayer?.volumeSupported) return
                    const step = 0.05
                    if (event.angleDelta.y > 0) activePlayer.volume = Math.min(1, activePlayer?.volume + step)
                    else if (event.angleDelta.y < 0) activePlayer.volume = Math.max(0, activePlayer?.volume - step)
                    volumePopupVisible = true
                    hideTimer.restart()
                }
            }

            RowLayout { // Real content
                id: rowLayout

                spacing: 4
                anchors.fill: parent
                // anchors.leftMargin: 10
                // anchors.rightMargin: 6
                ClippedFilledCircularProgress {
                    id: mediaCircProg
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: rowLayout.spacing * 2
                    lineWidth: Appearance.rounding.unsharpen
                    value: (activePlayer && activePlayer.length > 0) ? (activePlayer.position / activePlayer.length) : 0
                    implicitSize: 22
                    colPrimary: Appearance.inirEverywhere ? Appearance.inir.colPrimary
                        : Appearance.auroraEverywhere ? Appearance.colors.colPrimary
                        : Appearance.colors.colOnSecondaryContainer
                    enableAnimation: activePlayer?.playbackState === MprisPlaybackState.Playing

                    Item {
                        anchors.centerIn: parent
                        width: mediaCircProg.implicitSize
                        height: mediaCircProg.implicitSize

                        MaterialSymbol {
                            anchors.centerIn: parent
                            fill: 1
                            text: activePlayer?.isPlaying ? "pause" : "music_note"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.inirEverywhere ? Appearance.inir.colOnPrimary
                                : Appearance.auroraEverywhere ? Appearance.colors.colOnLayer0
                                : Appearance.m3colors.m3onSecondaryContainer
                        }
                    }
                }

            //    Item {
            //     id: mediaBar
            //     width: titleText.width
            //     height: 24

            //     ---------------------------
            //     Track title display
            //     ---------------------------
            //      width: rowLayout.width - (CircularProgress.size + rowLayout.spacing * 2)
            //         width: !titleText.pauseShown && !titleText.playShown && titleText.isLoading ? 80 : rowLayout.width - (CircularProgress.size + rowLayout.spacing * 2)
                // StyledText {
                //     id: titleText
                //     width: 80
                //     Layout.alignment: Qt.AlignVCenter
                //     Layout.fillWidth: true
                //     Layout.rightMargin: rowLayout.spacing
                //     Layout.topMargin: 4
                //     horizontalAlignment: Text.AlignHCenter
                //     verticalAlignment: Text.AlignVCenter
                //     text: ""
                

                // Item {
                //     id: loadingDots
                //     anchors.fill: titleText
                //     visible: titleText.isLoading
                //     property int dotCount: 1

                //     Timer {
                //         interval: 600
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
                //                 color: "white"  // or whatever color
                //                 opacity: 0.3

                //                 SequentialAnimation on opacity {
                //                     loops: Animation.Infinite
                //                     NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutQuad }
                //                     NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutQuad }
                //                 }
                //             }
                //         }
                //     }
                // }
                // }
                

                StyledText {
                    id: titleText
                    width: rowLayout.width - (CircularProgress.size + rowLayout.spacing * 2)
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    Layout.rightMargin: rowLayout.spacing
                    Layout.topMargin: 0
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    color: Appearance.inirEverywhere ? Appearance.inir.colText
                        : Appearance.auroraEverywhere ? Appearance.colors.colOnLayer0
                        : Appearance.colors.colOnLayer1
                    animateChange: true

                    // ---------------------------
                    // State properties
                    // ---------------------------
                    property string lastTrack: ""
                    property bool lastIsPlaying: false
                    property bool pauseShown: false
                    property bool playShown: false
                    property string queuedMessage: ""
                    property bool isLoading: false

                    // ---------------------------
                    // Build text function
                    // ---------------------------
                    function buildText() {
                        if (!activePlayer) return ""
                        const title = activePlayer.trackTitle || activePlayer.metadata?.title || ""
                        const artist = activePlayer.trackArtist ? " • " + activePlayer.trackArtist : ""
                        return title ? StringUtils.cleanMusicTitle(title) + artist : ""
                    }

                    // ---------------------------
                    // Pause Timer
                    // ---------------------------
                    Timer {
                        id: pauseTimer
                        interval: 1000
                        repeat: false
                        running: false
                        onTriggered: {
                            titleText.pauseShown = false
                            titleText.text = titleText.queuedMessage.length > 0 ? titleText.queuedMessage :
                                            (titleText.isLoading ? Translation.tr("Loading...").replace(/./g, " ") :
                                            (titleText.lastTrack.length > 0 ? titleText.lastTrack :
                                            Translation.tr("No media playing")))
                            titleText.queuedMessage = ""
                        }
                    }

                    // ---------------------------
                    // Play Timer
                    // ---------------------------
                    Timer {
                        id: playTimer
                        interval: 1000
                        repeat: false
                        running: false
                        onTriggered: {
                            titleText.playShown = false
                            titleText.text = titleText.queuedMessage.length > 0 ? titleText.queuedMessage :
                                            (titleText.isLoading ? Translation.tr("Loading...").replace(/./g, " ") :
                                            (titleText.lastTrack.length > 0 ? titleText.lastTrack :
                                            Translation.tr("No media playing")))
                            titleText.queuedMessage = ""
                        }
                    }

                    // ---------------------------
                    // Update Timer
                    // ---------------------------
                    Timer {
                        id: updateTimer
                        interval: 200
                        repeat: true
                        running: true
                        onTriggered: {
                            const playing = activePlayer?.playbackState === MprisPlaybackState.Playing
                            const prevPlaying = titleText.lastIsPlaying
                            const currentTrack = titleText.buildText()
                            const hasTrack = currentTrack.length > 0

                            // ---------------------------
                            // Detect external play/pause
                            // ---------------------------
                            if (prevPlaying && !playing) {
                                Players.lastUserPaused = true
                                Players.lastUserPlayed = false
                            } else if (!prevPlaying && playing) {
                                Players.lastUserPaused = false
                                Players.lastUserPlayed = true
                            }

                            // ---------------------------
                            // Loading state
                            // ---------------------------
                            const wasLoading = titleText.isLoading
                            titleText.isLoading = !!activePlayer && !hasTrack

                            // Reset loading dots when loading starts
                            if (titleText.isLoading && !wasLoading) {
                                loadingDots.dotCount = 1
                            }

                            // ---------------------------
                            // Track change
                            // ---------------------------
                            if (currentTrack !== titleText.lastTrack) {
                                if (titleText.pauseShown || titleText.playShown) {
                                    titleText.queuedMessage = hasTrack ? currentTrack :
                                                            (titleText.isLoading ? Translation.tr("Loading...").replace(/./g, " ") :
                                                            Translation.tr("No media playing"))
                                } else {
                                    titleText.lastTrack = currentTrack
                                    titleText.text = hasTrack ? currentTrack :
                                                    (titleText.isLoading ? Translation.tr("Loading...").replace(/./g, " ") :
                                                    Translation.tr("No media playing"))
                                }
                            }

                            // ---------------------------
                            // Pause detected
                            // ---------------------------
                            if (!playing && Players.lastUserPaused && prevPlaying && hasTrack) {
                                if (playTimer.running) playTimer.stop()
                                titleText.text = Translation.tr("Paused")
                                titleText.pauseShown = true
                                pauseTimer.restart()
                            }
                            // ---------------------------
                            // Play detected
                            // ---------------------------
                            else if (playing && !prevPlaying && Players.lastUserPlayed && hasTrack) {
                                if (pauseTimer.running) {
                                    titleText.queuedMessage = Translation.tr("Now Playing")
                                } else {
                                    titleText.text = Translation.tr("Now Playing")
                                }
                                titleText.playShown = true
                                playTimer.restart()
                            }
                            // ---------------------------
                            // Normal display
                            // ---------------------------
                            else if (!titleText.pauseShown && !titleText.playShown) {
                                titleText.text = titleText.isLoading ?
                                                Translation.tr("Loading...").replace(/./g, " ") :
                                                hasTrack ? currentTrack : Translation.tr("No media playing")
                            }

                            titleText.lastIsPlaying = playing
                        }
                    }

                    Component.onCompleted: {
                        titleText.text = Translation.tr("No media playing")
                    }

                    // ---------------------------
                    // Loading dots inside StyledText
                    // ---------------------------
                    Item {
                        id: loadingDots
                        anchors.fill: parent
                        visible: titleText.isLoading
                        property int dotCount: 1

                        Timer {
                            interval: 400   // faster animation
                            repeat: true
                            running: loadingDots.visible
                            onTriggered: {
                                loadingDots.dotCount = loadingDots.dotCount < 4 ? loadingDots.dotCount + 1 : 1
                            }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 4
                            Repeater {
                                model: loadingDots.dotCount
                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: "white"
                                    opacity: 0.3

                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 1; duration: 400; easing.type: Easing.InOutQuad }
                                        NumberAnimation { to: 0.3; duration: 400; easing.type: Easing.InOutQuad }
                                    }
                                }
                            }
                        }
                    }
                }
                
                }
            

        }
        Rectangle {
            id: clockDateIsland
            radius: 8
            // visible: false
            color: colorsPalette.backgroundt70
            // color: colorsPalette.surfaceContainer
            border.width: 1
            border.color: "#4DFFFFFF"
            property int padding: 10

            Layout.preferredHeight: barHeight - 8
            Layout.preferredWidth: clockDate.implicitWidth + padding * 2
            // Layout.leftMargin: 12
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 1
                shadowColor: Qt.alpha(colorsPalette.shadow, 0.6)  // adjust opacity
            }

            ClockDate {
                id: clockDate
                anchors.centerIn: parent
            }
            
        }
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
      