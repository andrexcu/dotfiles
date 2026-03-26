pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects as GE
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.models
import qs.services
import QtQuick.Controls
import qs.colors

import "root:"

Item {
    id: root
    implicitHeight: root.safePlayer !== null ? card.implicitHeight + playerSelector.height + 20 : 0
    visible: root.safePlayer !== null
    // anchors.fill: parent
    anchors.centerIn: parent
    // anchors.margins: 16
    property MprisPlayer player: Players.active
    readonly property bool isYtMusicPlayer: MprisController.isYtMusicActive
    readonly property bool hasPlayer: (player && player.trackTitle) || (isYtMusicPlayer && YtMusic.currentVideoId)
    
    property var colorsPalette: Colors{}
    readonly property string effectiveTitle: isYtMusicPlayer ? YtMusic.currentTitle : (player?.trackTitle ?? "")
    readonly property string effectiveArtist: isYtMusicPlayer ? YtMusic.currentArtist : (player?.trackArtist ?? "")
    readonly property string effectiveArtUrl: isYtMusicPlayer ? YtMusic.currentThumbnail : (player?.trackArtUrl ?? "")
    readonly property real effectivePosition: isYtMusicPlayer ? YtMusic.currentPosition : (player?.position ?? 0)
    readonly property real effectiveLength: isYtMusicPlayer ? YtMusic.currentDuration : (player?.length ?? 0)
    readonly property bool effectiveIsPlaying: isYtMusicPlayer ? YtMusic.isPlaying : (player?.isPlaying ?? false)
    readonly property bool effectiveCanSeek: isYtMusicPlayer ? YtMusic.canSeek : (player?.canSeek ?? false)
    
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: effectiveArtUrl ? Qt.md5(effectiveArtUrl) : ""
    property string artFilePath: artFileName ? `${artDownloadLocation}/${artFileName}` : ""
    property bool downloaded: false
    // property string displayedArtFilePath: downloaded ? Qt.resolvedUrl(artFilePath) : ""
    property int _downloadRetryCount: 0
    readonly property int _maxRetries: 3
    

    // property var safePlayer: player
    property MprisPlayer safePlayer: null

    property string displayedArtFilePath: ""
    property string currentVisibleTitle: Translation.tr("No media playing")
    property string currentVisibleArtist: ""


       // Poll timer
    Timer {
        interval: 100
        repeat: true
        running: true
        onTriggered: {
            const current = Players.active
            if (!current) return

            // Always keep a safePlayer reference
            if (root.safePlayer !== current) {
                root.safePlayer = current
            }

            // Update metadata snapshots
            const newTitle = current.trackTitle || current.metadata?.title
            const newArtist = current.trackArtist || current.metadata?.artist

            if (newTitle) root.currentVisibleTitle = StringUtils.cleanMusicTitle(newTitle)
            if (newArtist) root.currentVisibleArtist = newArtist

            // Update artwork if metadata is ready
            if (newTitle) {
                updateArtAndInfo()
            }
        }
    }
    function updateArtAndInfo() {
        if (!safePlayer) return;

        const newArtUrl = isYtMusicPlayer ? YtMusic.currentThumbnail : safePlayer.trackArtUrl;

        if (newArtUrl) {
            const fileName = Qt.md5(newArtUrl);
            const coverFilePath = `${artDownloadLocation}/${fileName}`;

            artFileName = fileName;
            artFilePath = coverFilePath;   // assign cover art path

            // Cover art downloader
            coverArtDownloader.targetFile = newArtUrl;
            coverArtDownloader.artFilePath = coverFilePath;
            coverArtDownloader.running = true;
        }
    }
 
    function isPlayerReady(player) {
     return player && (player.trackTitle || player.metadata?.title || player.artFilePath)
    }


    onSafePlayerChanged: {
        updateArtAndInfo()
    }

    Connections {
        target: safePlayer
        ignoreUnknownSignals: true

        function onMetadataChanged() { updateArtAndInfo() }
        function onTrackArtUrlChanged() { 
            _downloadRetryCount = 0
            checkAndDownloadArt()
        }
    }
    // Cava visualizer - using shared CavaProcess component
    CavaProcess {
        id: cavaProcess
        active: root.visible && root.hasPlayer && GlobalStates.sidebarLeftOpen && Appearance.effectsEnabled
    }

    property list<real> visualizerPoints: cavaProcess.points

    function checkAndDownloadArt() {
        if (!root.effectiveArtUrl) {
            downloaded = false
            _downloadRetryCount = 0
            return
        }
        artExistsChecker.running = true
    }

    function retryDownload() {
        if (_downloadRetryCount < _maxRetries && root.effectiveArtUrl) {
            _downloadRetryCount++
            retryTimer.start()
        }
    }

    Timer {
        id: retryTimer
        interval: 1000 * root._downloadRetryCount
        repeat: false
        onTriggered: {
            if (root.effectiveArtUrl && !root.downloaded) {
                coverArtDownloader.targetFile = root.effectiveArtUrl
                coverArtDownloader.artFilePath = root.artFilePath
                coverArtDownloader.running = true
            }
        }
    }

    onArtFilePathChanged: {
        _downloadRetryCount = 0
        checkAndDownloadArt()
    }
    
    onEffectiveArtUrlChanged: {
        _downloadRetryCount = 0
        checkAndDownloadArt()
    }
    
    // Re-check cover art when becoming visible
    onVisibleChanged: {
        if (visible && hasPlayer && artFilePath) {
            checkAndDownloadArt()
        }
    }

    Process {
        id: artExistsChecker
        command: ["/usr/bin/test", "-f", root.artFilePath]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.downloaded = true
                root._downloadRetryCount = 0
            } else {
                root.downloaded = false
                coverArtDownloader.targetFile = root.effectiveArtUrl
                coverArtDownloader.artFilePath = root.artFilePath
                coverArtDownloader.running = true
            }
        }
    }

       Process {
        id: coverArtDownloader
        property string targetFile
        property string artFilePath
        command: ["/usr/bin/bash", "-c", `
            target="$1"
            out="$2"
            dir="$3"
            
            if [ -f "$out" ]; then exit 0; fi
            mkdir -p "$dir"
            tmp="$out.tmp"
            /usr/bin/curl -sSL --connect-timeout 10 --max-time 30 "$target" -o "$tmp" && \
            [ -s "$tmp" ] && /usr/bin/mv -f "$tmp" "$out" || { rm -f "$tmp"; exit 1; }
        `, 
        "_", 
        targetFile, 
        artFilePath, 
        root.artDownloadLocation
        ]
        onExited: (exitCode) => {
        if (exitCode === 0) {
            root.downloaded = true
            displayedArtFilePath = Qt.resolvedUrl(root.artFilePath) // update UI here
            _downloadRetryCount = 0
        } else {
            root.downloaded = false
            root.retryDownload()
        }
        }
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0
        rescaleSize: 1
    }

    property color artDominantColor: ColorUtils.mix(
        colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary,
        Appearance.colors.colPrimaryContainer, 0.7
    )

    property QtObject blendedColors: AdaptedMaterialScheme { color: root.artDominantColor }
    
    // Inir uses fixed colors instead of adaptive
    readonly property color jiraColText: Appearance.inir.colText
    readonly property color jiraColTextSecondary: Appearance.inir.colTextSecondary
    readonly property color jiraColPrimary: Appearance.inir.colPrimary
    readonly property color jiraColLayer1: Appearance.inir.colLayer1
    readonly property color jiraColLayer2: Appearance.inir.colLayer2

   
    
   // Full-window click-catcher outside the ColumnLayout
    MouseArea {
        anchors.fill: parent
        visible: playerSelector.menuOpen
        z: 999
        onClicked: playerSelector.menuOpen = false
    }
    ColumnLayout {
    id: playerColumnLayout
    anchors.fill: parent
    spacing: 8
         Item {
            id: playerSelector
            Layout.alignment: Qt.AlignHCenter
            property bool menuOpen: false
            // visible: false
            Timer {
                id: autoCloseTimer
                interval: 3000   // 3 seconds
                repeat: false
                onTriggered: playerSelector.menuOpen = false
            } 
            // Watch for menuOpen changes
            onMenuOpenChanged: {
                if (menuOpen) {
                    autoCloseTimer.restart()  // start countdown when menu opens
                } else {
                    autoCloseTimer.stop()     // stop timer if menu closed manually
                }
            }
            // Filtered list: only players with media
            readonly property var mediaPlayers: Players.list.filter(p =>
                p.trackTitle || p.trackArtist || p.metadata?.title || p.metadata?.artist || p.metadata?.artUrl
            )

            // Base button
           Rectangle {
    id: button
    radius: 8
    color: colorsPalette.surfaceContainer
    implicitWidth: 180
    implicitHeight: 32

    // Chevron V arrow
   Item {
    id: chevron
    width: 12
    height: 6
    anchors.verticalCenter: parent.verticalCenter
    anchors.right: parent.right
    anchors.rightMargin: 8
    rotation: playerSelector.menuOpen ? 180 : 0
    Behavior on rotation { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    Canvas {
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.strokeStyle = colorsPalette.backgroundText;
            ctx.lineWidth = 2;
            ctx.lineCap = "round";  // slightly rounded ends

            // Left line
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(width/2, height);
            ctx.stroke();

            // Right line
            ctx.beginPath();
            ctx.moveTo(width, 0);
            ctx.lineTo(width/2, height);
            ctx.stroke();
        }
    }
}

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: chevron.left
        anchors.leftMargin: 8
        elide: Text.ElideRight
        text: Players.active ? Players.getIdentity(Players.active) : "No players"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: playerSelector.menuOpen = !playerSelector.menuOpen
    }
}

            // Make parent item size match the button
            width: button.implicitWidth
            height: button.implicitHeight

            // Menu container with smooth animation
            Rectangle {
                id: menuContainer
                width: button.width
                color: "transparent"
                radius: 6
                anchors.horizontalCenter: button.horizontalCenter
                anchors.bottom: button.top
                clip: true

                property real itemHeight: 30
                property real targetHeight: playerSelector.mediaPlayers.length * (itemHeight + 4) // 4 = spacing
                height: playerSelector.menuOpen ? targetHeight : 0
                opacity: playerSelector.menuOpen ? 1 : 0

                Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                Column {
                    id: menu
                    spacing: 4
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Repeater {
                        model: playerSelector.mediaPlayers

                        delegate: Rectangle {
                            required property var modelData
                            width: parent.width
                            height: menuContainer.itemHeight
                            radius: 6
                            color: modelData === Players.active ? colorsPalette.primary : colorsPalette.background

                            StyledText {
                                anchors.centerIn: parent
                                text: Players.getIdentity(modelData)
                                elide: Text.ElideRight
                                color: modelData === Players.active ? colorsPalette.primaryText : colorsPalette.backgroundText
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    Players.manualActive = modelData
                                    playerSelector.menuOpen = false
                                }
                            }
                        }
                    }
                }
            }
        }   
    
        Item {
            Layout.fillWidth: true
            implicitHeight: card.implicitHeight
            StyledRectangularShadow {
                target: card
            }
            Rectangle {
                id: card
                Layout.alignment: Qt.AlignVCenter 
                width: parent.width
                implicitHeight: 130
                radius: Appearance.angelEverywhere ? Appearance.angel.roundingNormal
                    : Appearance.inirEverywhere ? Appearance.inir.roundingNormal
                    : Appearance.rounding.normal
                color: Appearance.angelEverywhere ? Appearance.angel.colGlassCard
                    : Appearance.inirEverywhere ? Appearance.inir.colLayer1 
                    : Appearance.auroraEverywhere ? ColorUtils.transparentize(blendedColors?.colLayer0 ?? Appearance.colors.colLayer0, 0.7)
                    : (blendedColors?.colLayer0 ?? Appearance.colors.colLayer0)
                border.width: Appearance.angelEverywhere ? 0 : (Appearance.inirEverywhere ? 1 : 0)
                border.color: Appearance.angelEverywhere ? "transparent"
                    : Appearance.inirEverywhere ? Appearance.inir.colBorder : "transparent"
                clip: true

                AngelPartialBorder { targetRadius: card.radius; coverage: 0.5 }

                layer.enabled: true
                layer.effect: GE.OpacityMask {
                    maskSource: Rectangle { width: card.width; height: card.height; radius: card.radius }
                }

                // Cover art background - subtle for inir, more transparent for aurora
                Item {
                    id: bgArtContainer
                    anchors.fill: parent
                
                
                    property alias blurTimerRef: imgBlurInTimer
                    
                    Image {
                        id: bgArtCurrent
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        source: root.displayedArtFilePath
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
                        target: root
                        function onDisplayedArtFilePathChanged() {
                            if (!root.displayedArtFilePath) return
                            bgArtContainer.pendingSource = root.displayedArtFilePath
                            bgArtContainer.transitioning = true
                            imgBlurInTimer.start()
                        }
                    }

                }

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

                // Visualizer at bottom
                WaveVisualizer {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 30
                    live: root.effectiveIsPlaying
                    points: root.visualizerPoints
                    maxVisualizerValue: 1000
                    smoothing: 2
                    color: ColorUtils.transparentize(
                        Appearance.angelEverywhere ? Appearance.angel.colPrimary
                        : Appearance.inirEverywhere ? root.jiraColPrimary : (blendedColors?.colPrimary ?? Appearance.colors.colPrimary), 
                        0.6
                    )
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    // Cover art thumbnail
                    Rectangle {
                        id: coverArtContainer
                        property string currentSource: ""
                        property string nextSource: ""
                        property bool transitioning: false

                        Layout.preferredWidth: card.height - 24
                        Layout.preferredHeight: card.height - 24
                        radius: Appearance.rounding.small
                        color: "transparent"
                        clip: true
                        layer.enabled: true
                        layer.effect: GE.OpacityMask {
                            maskSource: Rectangle { width: card.width; height: card.height; radius: card.radius }
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
                            target: root
                            function onDisplayedArtFilePathChanged() {
                                if (!root.displayedArtFilePath) return

                                if (!coverArtContainer.currentSource) {
                                    coverArtContainer.currentSource = root.displayedArtFilePath
                                    return
                                }

                                if (root.displayedArtFilePath === coverArtContainer.currentSource) return

                                coverArtContainer.nextSource = root.displayedArtFilePath
                                currentImage.blurLevel = 1  // start blur animation
                                swapTimer.start()            // delay swap so blur animates
                            }
                        }
                    }

                    // Info & controls column
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 2

                        // Title
                        StyledText {
                            Layout.fillWidth: true
                            text: currentVisibleTitle
                            // text: StringUtils.cleanMusicTitle(root.effectiveTitle) || "—"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.angelEverywhere ? Appearance.angel.colText
                                : Appearance.inirEverywhere ? root.jiraColText : (blendedColors?.colOnLayer0 ?? Appearance.colors.colOnLayer0)
                            elide: Text.ElideRight
                            animateChange: true
                            animationDistanceX: 6
                        }

                        // Artist
                        StyledText {
                            Layout.fillWidth: true
                            text: root.currentVisibleArtist
                            // text: root.effectiveArtist || ""
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.angelEverywhere ? Appearance.angel.colTextSecondary
                                : Appearance.inirEverywhere ? root.jiraColTextSecondary : (blendedColors?.colSubtext ?? Appearance.colors.colSubtext)
                            elide: Text.ElideRight
                            visible: text !== ""
                        }

                        Item { Layout.fillHeight: true }

                        // Progress bar
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 16

                            Loader {
                                anchors.fill: parent
                                active: root.effectiveCanSeek
                                sourceComponent: StyledSlider {
                                    configuration: StyledSlider.Configuration.Wavy
                                    wavy: root.effectiveIsPlaying
                                    animateWave: root.effectiveIsPlaying
                                    highlightColor: Appearance.angelEverywhere ? Appearance.angel.colPrimary
                                        : Appearance.inirEverywhere ? root.jiraColPrimary : (blendedColors?.colPrimary ?? Appearance.colors.colPrimary)
                                    trackColor: Appearance.angelEverywhere ? Appearance.angel.colGlassCard
                                        : Appearance.inirEverywhere ? Appearance.inir.colLayer2 : (blendedColors?.colSecondaryContainer ?? Appearance.colors.colSecondaryContainer)
                                    handleColor: Appearance.angelEverywhere ? Appearance.angel.colPrimary
                                        : Appearance.inirEverywhere ? root.jiraColPrimary : (blendedColors?.colPrimary ?? Appearance.colors.colPrimary)
                                    value: root.effectiveLength > 0 ? root.effectivePosition / root.effectiveLength : 0
                                    onMoved: {
                                        if (root.isYtMusicPlayer) {
                                            YtMusic.seek(value * root.effectiveLength)
                                        } else if (root.player) {
                                            root.player.position = value * root.player.length
                                        }
                                    }
                                    scrollable: true
                                }
                            }

                            // Loader {
                            //     anchors.fill: parent
                            //     active: !root.effectiveCanSeek
                            //     sourceComponent: StyledProgressBar {
                            //         wavy: root.effectiveIsPlaying
                            //         animateWave: root.effectiveIsPlaying
                            //         highlightColor: Appearance.angelEverywhere ? Appearance.angel.colPrimary
                            //             : Appearance.inirEverywhere ? root.jiraColPrimary : (blendedColors?.colPrimary ?? Appearance.colors.colPrimary)
                            //         trackColor: Appearance.angelEverywhere ? Appearance.angel.colGlassCard
                            //             : Appearance.inirEverywhere ? Appearance.inir.colLayer2 : (blendedColors?.colSecondaryContainer ?? Appearance.colors.colSecondaryContainer)
                            //         value: root.effectiveLength > 0 ? root.effectivePosition / root.effectiveLength : 0
                            //     }
                            // }
                        }
                        Item {
                        id: loadingDots
                        visible: !root.effectiveCanSeek
                        Layout.fillWidth: true
                        implicitHeight: 16
                        Layout.alignment: Qt.AlignHCenter

                        property int dotCount: 1

                        // Timer to grow dots from 4 → 7 and reset to 4
                        Timer {
                            interval: 600
                            repeat: true
                            running: !root.effectiveCanSeek
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
                        // Time + controls row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            visible: root.safePlayer !== null && root.effectiveCanSeek
                            StyledText {
                                text: StringUtils.friendlyTimeForSeconds(root.effectivePosition)
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                font.family: Appearance.font.family.numbers
                                color: Appearance.angelEverywhere ? Appearance.angel.colText
                                    : Appearance.inirEverywhere ? root.jiraColText : (blendedColors?.colOnLayer0 ?? Appearance.colors.colOnLayer0)
                            }

                            Item { Layout.fillWidth: true }

                            // Controls
                            RippleButton {
                                implicitWidth: 32
                                implicitHeight: 32
                                buttonRadius: Appearance.angelEverywhere ? Appearance.angel.roundingSmall
                                    : Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.full
                                colBackground: "transparent"
                                colBackgroundHover: Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover
                                    : Appearance.inirEverywhere ? Appearance.inir.colLayer2Hover : ColorUtils.transparentize(blendedColors?.colLayer1 ?? Appearance.colors.colLayer1, 0.5)
                                colRipple: Appearance.angelEverywhere ? Appearance.angel.colGlassCardActive
                                    : Appearance.inirEverywhere ? Appearance.inir.colLayer2Active : (blendedColors?.colLayer1Active ?? Appearance.colors.colLayer1Active)
                                // onClicked: player?.previous()
                                onClicked: {
                                    
                                    player?.previous() // play next track
                                    // Players.isLoading = true
                                    // Reset loading dots like in doNext()
                                    loadingDots.dotCount = 1

                                    for (let i = 0; i < loadingDots.children.length; i++) {
                                        let child = loadingDots.children[i]
                                        if (child.dotAnim) child.dotAnim.restart()
                                    }
                                }

                                contentItem: Item {
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "skip_previous"
                                        iconSize: 22
                                        fill: 1
                                        color: Appearance.angelEverywhere ? Appearance.angel.colText
                                            : Appearance.inirEverywhere ? root.jiraColText : (blendedColors?.colOnLayer0 ?? Appearance.colors.colOnLayer0)
                                    }
                                }

                                StyledToolTip { text: qsTr("Previous")}
                  
                            }

                            RippleButton {
                                id: playPauseButton
                                implicitWidth: 40
                                implicitHeight: 40
                                buttonRadius: Appearance.angelEverywhere ? Appearance.angel.roundingSmall
                                    : Appearance.inirEverywhere 
                                    ? Appearance.inir.roundingSmall 
                                    : (root.effectiveIsPlaying ? Appearance.rounding.normal : Appearance.rounding.full)
                                colBackground: Appearance.angelEverywhere
                                    ? "transparent"
                                    : Appearance.inirEverywhere
                                    ? "transparent"
                                    : Appearance.auroraEverywhere
                                        ? "transparent"
                                        : (root.effectiveIsPlaying 
                                            ? (blendedColors?.colPrimary ?? Appearance.colors.colPrimary)
                                            : (blendedColors?.colSecondaryContainer ?? Appearance.colors.colSecondaryContainer))
                                colBackgroundHover: Appearance.angelEverywhere
                                    ? Appearance.angel.colGlassCardHover
                                    : Appearance.inirEverywhere
                                    ? Appearance.inir.colLayer2Hover
                                    : Appearance.auroraEverywhere
                                        ? ColorUtils.transparentize(blendedColors?.colLayer1 ?? Appearance.colors.colLayer1, 0.5)
                                        : (root.effectiveIsPlaying 
                                            ? (blendedColors?.colPrimaryHover ?? Appearance.colors.colPrimaryHover)
                                            : (blendedColors?.colSecondaryContainerHover ?? Appearance.colors.colSecondaryContainerHover))
                                colRipple: Appearance.angelEverywhere
                                    ? Appearance.angel.colGlassCardActive
                                    : Appearance.inirEverywhere
                                    ? Appearance.inir.colLayer2Active
                                    : Appearance.auroraEverywhere
                                        ? (blendedColors?.colLayer1Active ?? Appearance.colors.colLayer1Active)
                                        : (root.effectiveIsPlaying 
                                            ? (blendedColors?.colPrimaryActive ?? Appearance.colors.colPrimaryActive)
                                            : (blendedColors?.colSecondaryContainerActive ?? Appearance.colors.colSecondaryContainerActive))
                                onClicked: player?.togglePlaying()
                                //  onClicked: {
                                //     if (!player) return;

                                //     // capture current state
                                //     const wasPlaying = player.playbackState === MprisPlaybackState.Playing;

                                //     // toggle playback
                                //     player.togglePlaying();

                                //     // store for global tracking
                                //     Players.lastUserPaused = wasPlaying;  // true if user paused, false if user resumed
                                //     Players.lastUserPlayed = !wasPlaying
                                // }

                                Behavior on buttonRadius {
                                    enabled: Appearance.animationsEnabled && !Appearance.inirEverywhere
                                    NumberAnimation { duration: Appearance.animation.elementMoveFast.duration }
                                }

                                contentItem: Item {
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: root.effectiveIsPlaying ? "pause" : "play_arrow"
                                        iconSize: 24
                                        fill: 1
                                        color: Appearance.angelEverywhere
                                            ? Appearance.angel.colPrimary
                                            : Appearance.inirEverywhere
                                            ? root.jiraColPrimary
                                            : Appearance.auroraEverywhere
                                                ? (blendedColors?.colOnLayer0 ?? Appearance.colors.colOnLayer0)
                                                : (root.effectiveIsPlaying 
                                                    ? (blendedColors?.colOnPrimary ?? Appearance.colors.colOnPrimary)
                                                    : (blendedColors?.colOnSecondaryContainer ?? Appearance.colors.colOnSecondaryContainer))

                                        Behavior on color {
                                            enabled: Appearance.animationsEnabled
                                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                        }
                                    }
                                }

                                StyledToolTip { text: root.effectiveIsPlaying ? Translation.tr("Pause") : Translation.tr("Play") }
                                
                            }

                            RippleButton {
                                implicitWidth: 32
                                implicitHeight: 32
                                buttonRadius: Appearance.angelEverywhere ? Appearance.angel.roundingSmall
                                    : Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.full
                                colBackground: "transparent"
                                colBackgroundHover: Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover
                                    : Appearance.inirEverywhere ? Appearance.inir.colLayer2Hover : ColorUtils.transparentize(blendedColors?.colLayer1 ?? Appearance.colors.colLayer1, 0.5)
                                colRipple: Appearance.angelEverywhere ? Appearance.angel.colGlassCardActive
                                    : Appearance.inirEverywhere ? Appearance.inir.colLayer2Active : (blendedColors?.colLayer1Active ?? Appearance.colors.colLayer1Active)
                                // onClicked: MprisController.next()
                                // onClicked: player?.next()
                                onClicked: {
                                    player?.next()  // play next track

                                    // Players.isLoading = true
                                    // Reset loading dots like in doNext()
                                    loadingDots.dotCount = 1

                                    for (let i = 0; i < loadingDots.children.length; i++) {
                                        let child = loadingDots.children[i]
                                        if (child.dotAnim) child.dotAnim.restart()
                                    }
                                }

                                contentItem: Item {
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "skip_next"
                                        iconSize: 22
                                        fill: 1
                                        color: Appearance.angelEverywhere ? Appearance.angel.colText
                                            : Appearance.inirEverywhere ? root.jiraColText : (blendedColors?.colOnLayer0 ?? Appearance.colors.colOnLayer0)
                                    }
                                }

                                StyledToolTip { text: Translation.tr("Next") }
                                // ToolTip.timeout: 3000
                                // ToolTip.delay: 300
                                // ToolTip.visible: hovered
                                // ToolTip.text: qsTr("Next")
                            }

                            Item { Layout.fillWidth: true }

                            StyledText {
                                text: StringUtils.friendlyTimeForSeconds(root.effectiveLength)
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                font.family: Appearance.font.family.numbers
                                color: Appearance.angelEverywhere ? Appearance.angel.colText
                                    : Appearance.inirEverywhere ? root.jiraColText : (blendedColors?.colOnLayer0 ?? Appearance.colors.colOnLayer0)
                            }
                        }
                    }
                }
            }
        }
    }
    Timer {
        running: root.effectiveIsPlaying && GlobalStates.sidebarLeftOpen
        interval: 1000
        repeat: true
        onTriggered: {
            if (!root.isYtMusicPlayer && root.player) {
                root.player.positionChanged()
            }
        }
    }
}
