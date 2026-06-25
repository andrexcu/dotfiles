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

Item {
    id: root
    // property bool borderless: Config.options.bar.borderless
    readonly property MprisPlayer activePlayer: Players.player
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media")

    Layout.fillHeight: true
    // implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitWidth: root.implicitWidth  + 18
    implicitHeight: Appearance.sizes.barHeight

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        onPressed: (event) => {
            if (event.button === Qt.MiddleButton) {
                activePlayer.togglePlaying();
            } else if (event.button === Qt.BackButton) {
                activePlayer.previous();
            } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                activePlayer.next();
            } else if (event.button === Qt.LeftButton) {
                GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen
            }
        }
    }
    readonly property bool visualizerActive: true
    CavaProcess {
        id: cavaProcess
        active: visualizerActive
    }

    WaveVisualizer {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 0 
        anchors.rightMargin: 0
        anchors.bottomMargin: 2
        // z: 1
        clip: true  
        height: barHeight  // for example 35
        live: titleText.showVisualizer && Players.effectiveIsPlaying
        
        points: root.visualizerPoints
        maxVisualizerValue: 1000
        smoothing: 2
        blurred: false
        centered: true
        color: ColorUtils.transparentize(Appearance.colors.colPrimary,
            0.6
        )
        // color: Appearance.colors.colPrimary
        z: 10 
    }
    property list<real> visualizerPoints: cavaProcess.points
    
    RowLayout { // Real content
        id: rowLayout

        spacing: 4
        anchors.fill: parent

        ClippedFilledCircularProgress {
            id: mediaCircProg
            Layout.alignment: Qt.AlignVCenter
            lineWidth: Appearance.rounding.unsharpen
            value: activePlayer?.position / activePlayer?.length
            implicitSize: 20
            colPrimary: Appearance.colors.colOnSecondaryContainer
            enableAnimation: false

            Item {
                anchors.centerIn: parent
                width: mediaCircProg.implicitSize
                height: mediaCircProg.implicitSize
                
                MaterialSymbol {
                    anchors.centerIn: parent
                    fill: 1
                    text: activePlayer?.isPlaying ? "pause" : "music_note"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.m3colors.m3onSecondaryContainer
                }
            }
        }


        Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Item {
            id: centerGroup
            anchors.centerIn: parent
            width: Math.min(parent.width, titleText.implicitWidth + 60)
            Layout.fillHeight: true
            Layout.fillWidth: true

            StyledText {
                id: titleText

                Layout.fillHeight: true
                Layout.fillWidth: true
                width: centerGroup.width
                elide: Text.ElideRight

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                
                color: Appearance.colors.colOnLayer1
                animateChange: true

                // 🔥 THIS is the key: only vertical center
                y: (parent.height - height) / 2

                // ---------------------------
                // STATE
                // ---------------------------
                property bool lastIsPlaying: false
                property bool pauseLock: false
                property bool playLock: false
                property bool showCurrentAfterPause: false
                property string queuedMessage: ""
                property bool showVisualizer: false
                

                function buildText() {
                    if (!activePlayer) return "No Media"
                    const title = activePlayer.trackTitle || activePlayer.metadata?.title || ""
                    const artist = activePlayer.trackArtist ? " • " + activePlayer.trackArtist : ""
                    return title ? StringUtils.cleanMusicTitle(title) + artist : ""
                }

                // ---------------------------
                // TIMERS
                // ---------------------------
                Timer {
                    id: pauseTimer
                    interval: 1000
                    onTriggered: {
                        
                        titleText.pauseLock = false
                        titleText.showVisualizer = false
                        if (!activePlayer || activePlayer.playbackState !== MprisPlaybackState.Playing) {
                            titleText.showCurrentAfterPause = true
                            titleText.text = Translation.tr("Paused")
                        }
                    }
                }

                Timer {
                    id: playTimer
                    interval: 1000
                    onTriggered: {
                        titleText.playLock = false
                        titleText.showVisualizer = true
                        titleText.text = titleText.queuedMessage.length > 0
                            ? titleText.queuedMessage
                            : titleText.buildText()
                        titleText.queuedMessage = ""
                    }
                }

                Timer {
                    interval: 200
                    repeat: true
                    running: true

                    onTriggered: {
                        const playing = activePlayer?.playbackState === MprisPlaybackState.Playing
                        const currentTrack = titleText.buildText()
                        const hasTrack = currentTrack.length > 0
                        
                        if (!playing && titleText.lastIsPlaying) {
                            pauseTimer.stop()
                            playTimer.stop()
                            
                            loadingDots.dotCount = 1
                            titleText.pauseLock = true
                            titleText.playLock = false
                            titleText.queuedMessage = ""
                            titleText.showCurrentAfterPause = true

                            titleText.text = Translation.tr("Paused")
                            pauseTimer.start()
                            
                        }
                        else if (playing && !titleText.lastIsPlaying) {
                            pauseTimer.stop()
                            playTimer.stop()
                            

                            loadingDots.dotCount = 1
                            titleText.pauseLock = false
                            titleText.playLock = true
                            titleText.showCurrentAfterPause = false

                            titleText.queuedMessage = currentTrack
                            titleText.text = Translation.tr("Now Playing")
                            playTimer.start()
                            
                        }
                        else {
                            if (titleText.pauseLock) {
                                titleText.text = Translation.tr("Paused")
                            }
                            else if (titleText.playLock) {
                                titleText.text = Translation.tr("Now Playing")
                            }
                            else if (!playing && titleText.showCurrentAfterPause) {
                                titleText.text = currentTrack
                            }
                            else {
                                titleText.text = hasTrack
                                    ? currentTrack
                                    : Translation.tr("No media")
                            }
                        }

                        titleText.lastIsPlaying = playing
                    }
                }

                Component.onCompleted: {
                    const playing = activePlayer?.playbackState === MprisPlaybackState.Playing

                    if (playing) {
                        titleText.text = titleText.buildText()
                    } else {
                        titleText.showCurrentAfterPause = true
                        titleText.text = Translation.tr("No media")
                    }
                }
            }

            // ---------------------------
            // RIGHT DOTS (anchored to text)
            // ---------------------------
                Item {
                    id: loadingDots
                    // anchors.fill: titleText
                    anchors.left: titleText.right
                    anchors.verticalCenter: titleText.verticalCenter
                    // anchors.leftMargin: 10   // spacing from text
                    visible: titleText.text === "Now Playing" || 
                    titleText.text === "Paused"
                    property int dotCount: 1

                    Timer {
                        id: loadingDotsTimer
                        interval: 333
                        repeat: true
                        running: loadingDots.visible
                        onTriggered: {
                            if (loadingDots.dotCount < 3) {
                                loadingDots.dotCount++
                            } else {
                                stop()   // ✅ STOP after reaching 3
                            }
                        }
                        // onTriggered: {
                        //     loadingDots.dotCount = loadingDots.dotCount < 3 ? loadingDots.dotCount + 1 : 1
                        // }
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Repeater {
                            model: loadingDots.dotCount
                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: Appearance.colors.colOnLayer1
                                opacity: 0.3

                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutQuad }
                                    NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutQuad }
                                }
                            }
                        }
                    }
                }

                Item {
                    id: loadingDotsLeft
                    anchors.right: titleText.left
                    anchors.verticalCenter: titleText.verticalCenter
                    // anchors.rightMargin: 10
                    visible: titleText.text === "Now Playing" || 
                    titleText.text === "Paused"

                    property int dotCount: loadingDots.dotCount  // sync with right side

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        layoutDirection: Qt.RightToLeft   // 🔥 this reverses direction

                        Repeater {
                            model: loadingDotsLeft.dotCount
                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: Appearance.colors.colOnLayer1
                                opacity: 0.3

                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutQuad }
                                    NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutQuad }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
      