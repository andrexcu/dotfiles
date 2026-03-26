pragma ComponentBehavior: Bound
// CompactMediaPlayer.qml
// Enhanced media player widget for the compact sidebar Controls section
// Shows current track with album art, playback controls, and progress
// Supports native players, YtMusic, and browser media (via MPRIS/plasma-browser-integration)
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.models

import qs.modules.mediaControls.components
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects as GE
import qs.colors
import Quickshell.Io
import Quickshell

Item {
    id: root
    

    implicitHeight: Players.player !== null ? playerCard.implicitHeight : 0
    // property MprisPlayer player: Players.readyActive
    property MprisPlayer selectedPlayer: Players.player
    visible: Players.player !== null
    property var colorsPalette: Colors{}
      // used by Image
    
    ColorQuantizer {
        id: colorQuantizer
        source: Players.displayedArtFilePath
        depth: 0
        rescaleSize: 1
    }
    property color artDominantColor: ColorUtils.mix(
        colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary,
        Appearance.colors.colPrimaryContainer, 0.7
    )

    
    // Blended colors from dominant album art color
    property QtObject blendedColors: AdaptedMaterialScheme { color: root.artDominantColor }
    
    readonly property color colText: Appearance.colors.colOnLayer1
    readonly property color colTextSecondary: Appearance.colors.colSubtext
    readonly property color colCard: Appearance.colors.colLayer1 
    readonly property color colBorder: Appearance.colors.colLayer0Border
    readonly property int borderWidth: 1
    readonly property real radius: Appearance.rounding.normal
    readonly property color colPrimary: Appearance.colors.colPrimary
    readonly property color colAuxButtonHover: ColorUtils.transparentize(root.colText, 0.82)
    readonly property color colAuxButtonActive: ColorUtils.transparentize(root.colText, 0.72)
    // Dynamic accent from album art
    readonly property color accentColor: blendedColors?.colPrimary ?? colPrimary


    CavaProcess {
        id: cavaProcess
        active: root.visible && Players.hasPlayer && GlobalStates.sidebarLeftOpen && Appearance.effectsEnabled
    }

    property list<real> visualizerPoints: cavaProcess.points

    StyledRectangularShadow { visible: false; target: playerCard }

    Rectangle {
        id: playerCard
        anchors.fill: parent
        implicitHeight: contentColumn.implicitHeight + 16
        radius: root.radius
        color: "transparent"
        border.width: 0
        border.color: "transparent"
        clip: true

        layer.enabled: true
        layer.effect: GE.OpacityMask {
            maskSource: Rectangle { width: playerCard.width; height: playerCard.height; radius: playerCard.radius }
        }

        // Blurred album art background
        Item {
            id: bgArtContainer
            anchors.fill: parent
        
        
            property alias blurTimerRef: imgBlurInTimer
            
            Image {
                id: bgArtCurrent
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                source: Players.displayedArtFilePath
                opacity: 0.5
                layer.enabled: Appearance.effectsEnabled
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: bgArtContainer.transitioning ? 1 : 0
                    blurMax: 32
                    Behavior on blur {
                        enabled: Appearance.animationsEnabled
                        NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
                    }
                }
            }

            property string pendingSource: ""
            property bool transitioning: false
            Timer {
                id: imgBlurInTimer
                interval: 150
                repeat: false
                onTriggered: {
                        bgArtCurrent.source = bgArtContainer.pendingSource
                    
                    imgBlurOutTimer.start()
                }
            }

            Timer {
                id: imgBlurOutTimer
                interval: 50
                repeat: false
                onTriggered: bgArtContainer.transitioning = false
            
            }
            Connections {
                target: Players
                function onDisplayedArtFilePathChanged() {
                    if (!Players.displayedArtFilePath) return
                    bgArtContainer.pendingSource = Players.displayedArtFilePath
                    bgArtContainer.transitioning = true
                    imgBlurInTimer.start()
                }
            }

        }
      
        // Gradient overlay for depth and text readability
         // Dark overlay for controls visibility - only for Material
        Rectangle {
            anchors.fill: parent
            visible: !Appearance.inirEverywhere && !Appearance.auroraEverywhere
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.35; color: ColorUtils.transparentize(blendedColors?.colLayer0 ?? Appearance.colors.colLayer0, 0.3) }
                GradientStop { position: 1.0; color: ColorUtils.transparentize(blendedColors?.colLayer0 ?? Appearance.colors.colLayer0, 0.15) }
            }
        }
        WaveVisualizer {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 30
            live: Players.effectiveIsPlaying
            points: root.visualizerPoints
            maxVisualizerValue: 1000
            smoothing: 2
            color: ColorUtils.transparentize(
                Appearance.angelEverywhere ? Appearance.angel.colPrimary
                : Appearance.inirEverywhere ? root.jiraColPrimary : (blendedColors?.colPrimary ?? Appearance.colors.colPrimary), 
                0.6
            )
        }
        ColumnLayout {
            id: contentColumn
            anchors {
                fill: parent
                margins: 10
            }
            spacing: 6

            // // Player switcher header (when multiple players)
            // RowLayout {
            //     Layout.fillWidth: true
            //     visible: true
            //     // visible: (MprisController.displayPlayers?.length ?? 0) > 1
            //     spacing: 6

            //     MaterialSymbol {
            //         text: _playerIcon()
            //         iconSize: 14
            //         color: root.colTextSecondary
            //     }

            //     StyledText {
            //         Layout.fillWidth: true
            //         text: Players.player?.identity ?? ""
            //         font.pixelSize: Appearance.font.pixelSize.smallest
            //         // color: root.colTextSecondary
            //         color: blendedColors?.colSubtext ?? Appearance.colors.colSubtext
            //         elide: Text.ElideRight
            //     }

            //     RippleButton {
            //         implicitWidth: 20
            //         implicitHeight: 20
            //         buttonRadius: 10
            //         colBackground: "transparent"
            //         colBackgroundHover: Appearance.colors.colLayer1Hover
            //         onClicked: {
            //             playerSwitcherMenu.anchorItem = this
            //             playerSwitcherMenu.active = true
            //         }

            //         contentItem: MaterialSymbol {
            //             anchors.centerIn: parent
            //             text: "swap_horiz"
            //             iconSize: 14
            //             color: root.colTextSecondary
            //         }

            //         StyledToolTip {
            //             text: Translation.tr("Switch player")
            //         }
            //     }
            // }

            
            // Main content: Album art + Track info + time
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Album art with hover play/pause overlay
                Rectangle {
                        id: coverArtContainer
                        property string currentSource: ""
                        property string nextSource: ""
                        property bool transitioning: false
                        Component.onCompleted: {
                            if (Players.displayedArtFilePath) {
                                coverArtContainer.currentSource = Players.displayedArtFilePath
                            }
                        }
                        Layout.preferredWidth: 56
                        Layout.preferredHeight: 56
                        radius: Appearance.rounding.small
                        color: "transparent"
                        clip: true
                        layer.enabled: true
                        layer.effect: GE.OpacityMask {
                            maskSource: Rectangle { width: playerCard.width; height: playerCard.height; radius: playerCard.radius }
                        }

                        // CURRENT IMAGE
                        Image {
                            id: currentImage
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            source: coverArtContainer.currentSource
                            opacity: 1

                            property real blurLevel: 0
                            layer.enabled: Appearance.effectsEnabled
                            layer.effect: MultiEffect {
                                blurEnabled: true
                                blur: currentImage.blurLevel
                                blurMax: 32
                                Behavior on blur { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
                            }
                        }

                        // NEXT IMAGE
                        Image {
                            id: nextImage
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            source: coverArtContainer.nextSource
                            opacity: 0
                            layer.enabled: Appearance.effectsEnabled
                            layer.effect: MultiEffect {
                                blurEnabled: true
                                blur: 0.15
                                blurMax: 16
                                saturation: 0.3
                            }
                            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                        }

                        // TIMER TO CONTROL BLUR + FADE
                        Timer {
                            id: swapTimer
                            interval: 150
                            repeat: false
                            onTriggered: {
                                // fade in nextImage
                                nextImage.opacity = 1
                                currentImage.opacity = 0

                                // swap sources after fade
                                Qt.callLater(() => {
                                    coverArtContainer.currentSource = coverArtContainer.nextSource
                                    coverArtContainer.nextSource = ""
                                    currentImage.blurLevel = 0
                                    nextImage.opacity = 0
                                    currentImage.opacity = 1
                                })
                            }
                        }

                        Connections {
                            target: Players
                            function onDisplayedArtFilePathChanged() {
                                if (!Players.displayedArtFilePath) return

                                if (!coverArtContainer.currentSource) {
                                    coverArtContainer.currentSource = Players.displayedArtFilePath
                                    return
                                }

                                if (Players.displayedArtFilePath === coverArtContainer.currentSource) return

                                coverArtContainer.nextSource = Players.displayedArtFilePath
                                currentImage.blurLevel = 1  // start blur animation
                                swapTimer.start()            // delay swap so blur animates
                            }
                        }
                    }

                // Track info
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        StyledText {
                            id: trackTitle
                            Layout.fillWidth: true
                            font.pixelSize: Appearance.font.pixelSize.large
                            color: Appearance.angelEverywhere ? Appearance.angel.colText
                                    : Appearance.inirEverywhere ? root.jiraColText : (blendedColors?.colOnLayer0 ?? Appearance.colors.colOnLayer0)
                            elide: Text.ElideRight
                            text: Players.currentVisibleTitle
                            animateChange: true
                            animationDistanceX: 6
                            animationDistanceY: 0
                        }

                        RippleButton {
                            implicitWidth: 20
                            implicitHeight: 20
                            buttonRadius: 10
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer1Hover
                            onClicked: {
                                playerSwitcherMenu.anchorItem = this
                                playerSwitcherMenu.active = true
                            }

                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "swap_horiz"
                                iconSize: 14
                                color: root.colTextSecondary
                            }

                            StyledToolTip {
                                text: Translation.tr("Switch player")
                            }
                        }
                    }

                    StyledText {
                        id: trackArtist
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.angelEverywhere ? Appearance.angel.colTextSecondary
                                : Appearance.inirEverywhere ? root.jiraColTextSecondary : (blendedColors?.colSubtext ?? Appearance.colors.colSubtext)
                        elide: Text.ElideRight
                        text: Players.currentVisibleArtist
                        animateChange: true
                        animationDistanceX: 6
                        animationDistanceY: 0
                    }
                    // PlayerInfo {
                    //     Layout.fillWidth: true
                    //     title: Players.currentVisibleTitle
                    //     artist: Players.currentVisibleArtist
                    //     titleSize: Appearance.font.pixelSize.normal
                    //     artistSize: Appearance.font.pixelSize.smaller
                    //     titleColor: blendedColors?.colOnLayer0 ?? Appearance.colors.colOnLayer0
                    //     artistColor: blendedColors?.colSubtext ?? Appearance.colors.colSubtext
                    //     animateTitle: true
                    //     animateArtist: true
                    // }
                    

                    // Time display
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: Players.effectiveLength > 0

                        StyledText {
                            text: formatTime(root.selectedPlayer?.position ?? 0)
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.family: Appearance.font.family.numbers
                            color: root.accentColor
                            font.weight: Font.Medium
                        }

                        StyledText {
                            text: "/"
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: root.colTextSecondary
                            opacity: 0.5
                        }

                        StyledText {
                            text: formatTime(root.selectedPlayer?.length ?? 0)
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.family: Appearance.font.family.numbers
                            color: root.colTextSecondary
                        }

                        Item { Layout.fillWidth: true }
                        
                        // Open full player button
                        RippleButton {
                            implicitWidth: 22
                            implicitHeight: 22
                            buttonRadius: 11
                            colBackground: "transparent"
                            colBackgroundHover: root.angelStyle ? Appearance.angel.colGlassCardHover
                                : root.inirStyle ? Appearance.inir.colLayer2Hover
                                : Appearance.colors.colLayer1Hover
                            onClicked: GlobalStates.mediaControlsOpen = true

                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "open_in_full"
                                iconSize: 14
                                color: root.colTextSecondary
                            }

                            StyledToolTip {
                                text: Translation.tr("Open full player")
                            }
                        }
                    }
                }

                
            }

            // Progress bar with dynamic accent color
            Item {
                Layout.fillWidth: true
                implicitHeight: 16
                Loader {
                    anchors.fill: parent
                    active: Players.effectiveCanSeek
                    sourceComponent: StyledSlider {
                        configuration: StyledSlider.Configuration.Wavy
                        wavy: Players.effectiveIsPlaying
                        animateWave: Players.effectiveIsPlaying
                        highlightColor: blendedColors?.colPrimary ?? Appearance.colors.colPrimary
                        trackColor: blendedColors?.colSecondaryContainer ?? Appearance.colors.colSecondaryContainer
                        handleColor: blendedColors?.colPrimary ?? Appearance.colors.colPrimary
                        value: Players.effectiveLength > 0 ? Players.effectivePosition / Players.effectiveLength : 0
                        onMoved: {
                            if (Players.isYtMusicPlayer) {
                                YtMusic.seek(value * Players.effectiveLength)
                            } else if (root.selectedPlayer) {
                                root.selectedPlayer.position = value * root.selectedPlayer.length
                            }
                        }
                        scrollable: true
                    }
                }
            }
            // Transport controls row — clean, no wrapper surface
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                spacing: 2

                Item {
                    width: 32; height: 32
                    visible: false
                    Rectangle {
                        anchors.fill: parent
                        radius: width/2
                        color: MprisController.hasShuffle ? blendedColors.colPrimary : "transparent"
                        opacity: 0.1
                    }

                    MediaControlBtn {
                        anchors.fill: parent
                        icon: "shuffle"
                        toggled: MprisController.hasShuffle
                        onClicked: MprisController.setShuffle(!MprisController.hasShuffle)
                    }

                    Connections {
                        target: MprisController
                        onHasShuffleChanged: {
                            // forces QML to update the rectangle color and toggled state
                            // sometimes just referencing it is enough
                            _dummy = MprisController.hasShuffle
                        }
                    }
                    property bool _dummy
                }

                Item { Layout.fillWidth: true }

                // Previous
                MediaControlBtn {
                    icon: "skip_previous"
                    visible: Players.effectiveCanSeek
                    iconFill: true
                    onClicked: selectedPlayer.previous()
                    tooltipText: Translation.tr("Previous")
                }

                // Play/Pause — prominent center button
                RippleButton {
                        id: playPauseButton
                        visible: Players?.effectiveCanSeek ?? false
                        
                        // anchors.right: parent.right
                        // anchors.bottom: sliderRow.top
                        anchors.bottomMargin: 5
                        property real size: 44
                        implicitWidth: size
                        implicitHeight: size
                        downAction: () => selectedPlayer.togglePlaying();

                        buttonRadius: Players.effectiveIsPlaying ? Appearance?.rounding.normal : size / 2
                        colBackground: Players.effectiveIsPlaying ? blendedColors.colPrimary : blendedColors.colSecondaryContainer
                        colBackgroundHover: Players.effectiveIsPlaying ? blendedColors.colPrimaryHover : blendedColors.colSecondaryContainerHover
                        colRipple: Players.effectiveIsPlaying ? blendedColors.colPrimaryActive : blendedColors.colSecondaryContainerActive

                        contentItem: MaterialSymbol {
                            iconSize: Appearance.font.pixelSize.huge
                            fill: 1
                            horizontalAlignment: Text.AlignHCenter
                            color: Players.effectiveIsPlaying ? blendedColors.colOnPrimary : blendedColors.colOnSecondaryContainer
                            text: Players.effectiveIsPlaying ? "pause" : "play_arrow"

                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }
                        }
                    }

                // Next
                MediaControlBtn {
                    icon: "skip_next"
                    visible: Players.effectiveCanSeek
                    iconFill: true
                    onClicked: selectedPlayer.next()
                    tooltipText: Translation.tr("Next")
                }

                Item { Layout.fillWidth: true }

                // Loop button (right auxiliary)
            Item {
                width: 32
                height: 32
                visible: Players.effectiveCanSeek
                // Rounded background
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: MprisController.loopState !== 0
                        ? blendedColors.colPrimary
                        : "transparent"
                    opacity: 0.1
                    z: 0
                }

                MediaControlBtn {
                    anchors.fill: parent
                    z: 1  // Ensure button is on top
                    icon: MprisController.loopState === 2 ? "repeat_one" : "repeat"
                    toggled: MprisController.loopState !== 0
                    onClicked: {
                        const next = (MprisController.loopState + 1) % 3
                        MprisController.setLoopState(next)
                    }
                    tooltipText: Translation.tr("Loop")
                    small: true
                }
            }
            }
        }

        // Angel partial border
        AngelPartialBorder {
            targetRadius: playerCard.radius
            visible: true
        }
    }
    
    // Player switcher context menu (styled)
    // property var mediaPlayers: Players.list.filter(p => p && p.trackTitle) // loose filter for menu
    ContextMenu {
        id: playerSwitcherMenu
        property var mediaPlayers: Players.list.filter(p => Players.hasMedia(p))

        model: mediaPlayers.map(player => ({
            type: "item",
            text: player.identity ?? "",
            checkable: true,
            checked: Players.readyActive === player,
            action: () => { 
                Players.readyActive = player 
            }
        }))
    }

    // Resolve a Material Symbol icon name for the active player identity
    function _playerIcon(): string {
        const player = root.selectedPlayer
        if (!player) return "music_note"
        const name = (player.dbusName ?? "").toLowerCase()
        const identity = (player.identity ?? "").toLowerCase()
        if (name.includes("firefox") || identity.includes("firefox")) return "open_in_browser"
        if (name.includes("chrome") || identity.includes("chrome")) return "open_in_browser"
        if (name.includes("brave") || identity.includes("brave")) return "open_in_browser"
        if (name.includes("vivaldi") || identity.includes("vivaldi")) return "open_in_browser"
        if (name.includes("opera") || identity.includes("opera")) return "open_in_browser"
        if (name.includes("plasma-browser") || identity.includes("plasma-browser")) return "open_in_browser"
        if (name.includes("spotify") || identity.includes("spotify")) return "library_music"
        if (name.includes("mpv") || identity.includes("mpv")) return "smart_display"
        if (name.includes("vlc") || identity.includes("vlc")) return "smart_display"
        return "music_note"
    }

    function formatTime(seconds) {
        if (!seconds || seconds <= 0) return "0:00"
        const mins = Math.floor(seconds / 60)
        const secs = Math.floor(seconds % 60)
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    // Media control button component — simplified, no wrapper surface
    component MediaControlBtn: Item {
        id: mcBtn
        required property string icon
        property string tooltipText: ""
        property bool highlighted: false
        property bool toggled: false
        property bool small: false
        property bool iconFill: false
        
        signal clicked()
        
        implicitWidth: small ? 30 : 34
        implicitHeight: small ? 30 : 34
        
        Rectangle {
            anchors.fill: parent
            radius: root.angelStyle ? Appearance.angel.roundingSmall
                : root.inirStyle ? Appearance.inir.roundingSmall : Appearance.rounding.full
            border.width: 0
            border.color: "transparent"
            
            color: {
                if (mcBtnMA.containsPress)
                    return root.colAuxButtonActive
                if (mcBtnMA.containsMouse)
                    return root.colAuxButtonHover
                if (mcBtn.toggled)
                    return root.angelStyle ? ColorUtils.transparentize(root.accentColor, 0.64)
                        : root.inirStyle ? Appearance.inir.colSecondaryContainer
                        : ColorUtils.transparentize(root.accentColor, 0.78)
                return "transparent"
            }
            
            Behavior on color { 
                ColorAnimation { 
                    duration: Appearance.animation.elementMoveFast.duration 
                } 
            }
            
            MaterialSymbol {
                anchors.centerIn: parent
                text: mcBtn.icon
                iconSize: mcBtn.small ? 18 : 22
                fill: mcBtn.iconFill || mcBtn.highlighted || mcBtn.toggled ? 1 : 0
                color: mcBtn.highlighted
                    ? "white"
                    : mcBtn.toggled
                    ? (root.inirStyle ? Appearance.inir.colOnSecondaryContainer : root.accentColor)
                    : root.colText
                
                Behavior on color {
                    ColorAnimation { 
                        duration: Appearance.animation.elementMoveFast.duration 
                    }
                }
            }
            
            scale: mcBtnMA.containsPress ? 0.88 : 1.0
            
            Behavior on scale {
                NumberAnimation { 
                    duration: 150
                    easing.type: Easing.OutCubic 
                }
            }
            
            MouseArea {
                id: mcBtnMA
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: mcBtn.clicked()
            }
            
            StyledToolTip {
                visible: mcBtnMA.containsMouse && mcBtn.tooltipText !== ""
                text: mcBtn.tooltipText
            }
        }
    }
}
