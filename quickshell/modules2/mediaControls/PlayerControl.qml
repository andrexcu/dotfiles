pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.models
import qs.services
import qs
import Qt5Compat.GraphicalEffects as GE
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick.Effects

Item { // Player instance
    id: root
    required property MprisPlayer selectedPlayer
   
    property color artDominantColor: ColorUtils.mix((colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary), Appearance.colors.colPrimaryContainer, 0.8) || Appearance.m3colors.m3secondaryContainer
 

    property list<real> visualizerPoints: []
    property real maxVisualizerValue: 1000 // Max value in the data points
    property int visualizerSmoothing: 2 // Number of points to average for smoothing
    property real radius



    component TrackChangeButton: RippleButton {
        implicitWidth: 24
        implicitHeight: 24

        property var iconName
        colBackground: ColorUtils.transparentize(blendedColors.colSecondaryContainer, 1)
        colBackgroundHover: blendedColors.colSecondaryContainerHover
        colRipple: blendedColors.colSecondaryContainerActive

        contentItem: MaterialSymbol {
            iconSize: Appearance.font.pixelSize.huge
            fill: 1
            horizontalAlignment: Text.AlignHCenter
            color: blendedColors.colOnSecondaryContainer
            text: iconName

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }
    

    ColorQuantizer {
        id: colorQuantizer
        source: Players.displayedArtFilePath
        depth: 0 // 2^0 = 1 color
        rescaleSize: 1 // Rescale to 1x1 pixel for faster processing
    }

    property QtObject blendedColors: AdaptedMaterialScheme {
        color: artDominantColor
    }

    StyledRectangularShadow {
        target: background
    }
    Rectangle { // Background
        id: background
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
        color: ColorUtils.applyAlpha(blendedColors.colLayer0, 1)
        radius: root.radius

        layer.enabled: true
        layer.effect: GE.OpacityMask {
            maskSource: Rectangle {
                width: background.width
                height: background.height
                radius: background.radius
            }
        }

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
                    if (!bgArtContainer.pendingSource) return
                    bgArtCurrent.source = bgArtContainer.pendingSource
                    imgBlurOutTimer.restart()
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
                    bgArtContainer.pendingSource = Players.displayedArtFilePath
                    if (!bgArtContainer.pendingSource) return  // skip if no art yet
                    bgArtContainer.transitioning = true
                    imgBlurInTimer.restart()
                }
            }

        }
                // Gradient overlay for Material
        Rectangle {
            anchors.fill: parent
            visible: true
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.35; color: ColorUtils.transparentize(blendedColors?.colLayer0 ?? Appearance.colors.colLayer0, 0.3) }
                GradientStop { position: 1.0; color: ColorUtils.transparentize(blendedColors?.colLayer0 ?? Appearance.colors.colLayer0, 0.15) }
            }
        }
        WaveVisualizer {
            id: visualizerCanvas
            anchors.fill: parent
            live: Players.effectiveIsPlaying ?? false
            points: root.visualizerPoints
            maxVisualizerValue: root.maxVisualizerValue
            smoothing: root.visualizerSmoothing
            color: blendedColors.colPrimary
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 13
            spacing: 15

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
                Layout.preferredWidth: background.height - 24
                Layout.preferredHeight: background.height - 24
                radius: Appearance.rounding.small
                color: "transparent"
                clip: true
                layer.enabled: true
                layer.effect: GE.OpacityMask {
                    maskSource: Rectangle { width: background.width; height: background.height; radius: background.radius }
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

            ColumnLayout { // Info & controls
                Layout.fillHeight: true
                spacing: 2

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
                Item { Layout.fillHeight: true }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: trackTime.implicitHeight + sliderRow.implicitHeight
                    
                  
                    StyledText {
                        id: trackTime
                        visible: Players.effectiveCanSeek ?? false
                        anchors.bottom: sliderRow.top
                        anchors.bottomMargin: 5
                        anchors.left: parent.left
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: blendedColors.colSubtext
                        elide: Text.ElideRight
                        text: `${StringUtils.friendlyTimeForSeconds(Players.effectivePosition)} / ${StringUtils.friendlyTimeForSeconds(Players.effectiveLength)}`
                    }
                    RowLayout {
                        id: sliderRow
                        visible: Players.effectiveCanSeek ?? false
              
                        anchors {       
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                        }
                        TrackChangeButton {
                            iconName: "skip_previous"
                            downAction: () => {
                                root.selectedPlayer.previous()
                                loadingDots.dotCount = 1

                                // Restart all dot animations so opacity starts from the beginning
                                for (let i = 0; i < loadingDots.children.length; i++) {
                                    let child = loadingDots.children[i]
                                    if (child.dotAnim) {
                                        child.dotAnim.restart()
                                    }
                                }
                            }
                        }
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 16
                            Loader {
                                anchors.fill: parent
                                active: Players.effectiveCanSeek ?? false
                            
                            sourceComponent: StyledSlider {
                                    configuration: StyledSlider.Configuration.Wavy
                                    wavy: Players.effectiveIsPlaying ?? false
                                    animateWave: Players.effectiveIsPlaying ?? false
                                    highlightColor: blendedColors?.colPrimary ?? Appearance.colors.colPrimary
                                    trackColor: blendedColors?.colSecondaryContainer ?? Appearance.colors.colSecondaryContainer
                                    handleColor: blendedColors?.colPrimary ?? Appearance.colors.colPrimary
                                    value: root.selectedPlayer?.length > 0 ? root.selectedPlayer.position / root.selectedPlayer.length : 0
                                    onMoved: root.selectedPlayer.position = value * root.selectedPlayer.length
                                    scrollable: true
                                }
                            }
                        }
                        TrackChangeButton {
                            iconName: "skip_next"
                            downAction: () => {
                                root.selectedPlayer?.next()
                                loadingDots.dotCount = 1

                                // Restart all dot animations so opacity starts from the beginning
                                for (let i = 0; i < loadingDots.children.length; i++) {
                                    let child = loadingDots.children[i]
                                    if (child.dotAnim) {
                                        child.dotAnim.restart()
                                    }
                                }
                            }
                        }
                    }

                    Item {
                    id: loadingDots
                    visible: !Players.effectiveCanSeek
                    Layout.fillWidth: true
                    
                    implicitHeight: 16

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    // Layout.alignment: Qt.AlignBottom
       

                    property int dotCount: 1

                        // Timer to grow dots from 4 → 7 and reset to 4
                        Timer {
                            interval: 600
                            repeat: true
                            running: !Players.effectiveCanSeek
                            onTriggered: {
                                if (loadingDots.dotCount < 4) {
                                    loadingDots.dotCount++
                                } else {
                                    loadingDots.dotCount = 1
                                }
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
                                    color: blendedColors?.colPrimary ?? Appearance.colors.colPrimary
                                    opacity: 0.3

                                    SequentialAnimation on opacity {
                                        id: dotAnim
                                        loops: Animation.Infinite
                                        // PauseAnimation { duration: index * 400 } // stagger start
                                        NumberAnimation { to: 1; duration: 400; easing.type: Easing.InOutQuad }
                                        NumberAnimation { to: 0.3; duration: 400; easing.type: Easing.InOutQuad }
                                    }
                                }
                            }
                        }
                    }

                    RippleButton {
                        id: playPauseButton
                        visible: Players.effectiveCanSeek ?? false
                        
                        anchors.right: parent.right
                        anchors.bottom: sliderRow.top
                        anchors.bottomMargin: 5
                        property real size: 44
                        implicitWidth: size
                        implicitHeight: size
                        downAction: () => root.selectedPlayer.togglePlaying();

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
                }
            }
        }
    }
}