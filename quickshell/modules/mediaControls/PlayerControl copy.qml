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
import qs
import QtQuick.Controls

Item {
    id: root
    required property MprisPlayer player
    required property list<real> visualizerPoints
    property real radius: Appearance.rounding.large
    
    // Keep last known active player with metadata
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

        // const newArtUrl = isYtMusicPlayer ? YtMusic.currentThumbnail : safePlayer.trackArtUrl;
        const newArtUrl = isYtMusicPlayer ? YtMusic.currentThumbnail : safePlayer.displayArtUrl;

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
            checkAndDownloadArt(root.safePlayer.displayArtUrl)
        }
    }

    // Use centralized YtMusic detection from MprisController
    readonly property bool isYtMusicPlayer: {
        if (!player) return false
        // Direct match with YtMusic.mpvPlayer
        if (YtMusic.mpvPlayer && player === YtMusic.mpvPlayer) return true
        // Use MprisController's detection for consistency
        return MprisController._isYtMusicMpv(player)
    }
    

    function doTogglePlaying(): void {
        if (isYtMusicPlayer) {
            YtMusic.togglePlaying()
            // console.log("[PlayerControl] YouTube Music toggle clicked")
        } else {
            player?.togglePlaying()
            // const wasPlaying = player?.playbackState === MprisPlaybackState.Playing
            // Players.lastUserPaused = wasPlaying  // true if user paused, false if user resumed
            // Players.lastUserPlayed = !wasPlaying
            // console.log(`[PlayerControl] User ${wasPlaying ? "paused" : "resumed"} playback. lastUserPaused=${Players.lastUserPaused}`)
        }
    }
    // function doTogglePlaying(): void {
    //     if (isYtMusicPlayer) {
    //         YtMusic.togglePlaying()
    //     } else {
    //         player?.togglePlaying()
    //     }
    // }
    
    function doPrevious(): void {
        if (isYtMusicPlayer) {
            YtMusic.playPrevious()
        } else {
            player?.previous()
        }
        // Players.isLoading = true
        
              // Reset the dot count so the Repeater starts fresh
        loadingDots.dotCount = 1

        // Restart all dot animations so opacity starts from the beginning
        for (let i = 0; i < loadingDots.children.length; i++) {
            let child = loadingDots.children[i]
            if (child.dotAnim) {
                child.dotAnim.restart()
            }
        }
    }
    function doNext(): void {
        if (isYtMusicPlayer) {
            YtMusic.playNext()
        } else {
            player?.next()
        }

        // Players.isLoading = true
        // console.log(`Player Control loading: ${Players.isLoading}`)
        // Reset the dot count so the Repeater starts fresh
        loadingDots.dotCount = 1

        // Restart all dot animations so opacity starts from the beginning
        for (let i = 0; i < loadingDots.children.length; i++) {
            let child = loadingDots.children[i]
            if (child.dotAnim) {
                child.dotAnim.restart()
            }
        }
    }

    
    // Screen position for aurora glass effect
    property real screenX: 0
    property real screenY: 0

    readonly property string effectiveArtUrl: isYtMusicPlayer ? YtMusic.currentThumbnail : (player?.trackArtUrl ?? "")
    // readonly property string effectiveArtUrl: isYtMusicPlayer ? YtMusic.currentThumbnail : (player?.displayArtUrl ?? "")
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: effectiveArtUrl ? Qt.md5(effectiveArtUrl) : ""
    property string artFilePath: artFileName ? `${artDownloadLocation}/${artFileName}` : ""
    property bool downloaded: false
    property int _downloadRetryCount: 0
    readonly property int _maxRetries: 3

    function checkAndDownloadArt() {
        if (!effectiveArtUrl) {
            downloaded = false
            _downloadRetryCount = 0
            return
        }
        artExistsChecker.running = true
    }

    function retryDownload() {
        if (_downloadRetryCount < _maxRetries && effectiveArtUrl) {
            _downloadRetryCount++
            retryTimer.start()
        }
    }

    Timer {
        id: retryTimer
        interval: 1000 * root._downloadRetryCount
        repeat: false
        onTriggered: {
            if (root.effectiveArtUrl  && !root.downloaded) {
                mainImageDownloader.targetFile = root.effectiveArtUrl
                mainImageDownloader.artFilePath = root.artFilePath
                mainImageDownloader.running = true
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

    Connections {
        target: root.player
        function onTrackArtUrlChanged() {
            if (!root.isYtMusicPlayer) {
                root._downloadRetryCount = 0
                root.checkAndDownloadArt()
            }
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

    Timer {
        running: root.player?.playbackState === MprisPlaybackState.Playing
        interval: 1000
        repeat: true
        onTriggered: root.player?.positionChanged()
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

    StyledRectangularShadow 
    { target: card; visible: true }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: parent.width - Appearance.sizes.elevationMargin
        height: parent.height - Appearance.sizes.elevationMargin
        radius: root.radius
        color: blendedColors?.colLayer0 ?? Appearance.colors.colLayer0
        border.width: 0
        // border.color: Appearance.colors.colPrimary
        clip: true

        layer.enabled: true
        layer.effect: GE.OpacityMask {
            maskSource: Rectangle { width: card.width; height: card.height; radius: card.radius }
        }


        // Aurora tint overlay
        Rectangle {
            anchors.fill: parent
            visible: true
            color: ColorUtils.transparentize(blendedColors?.colLayer0 ?? Appearance.colors.colLayer0Base)
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

        // Visualizer at bottom
        WaveVisualizer {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 35
            live: root.player?.isPlaying ?? false
            points: root.visualizerPoints
            maxVisualizerValue: 1000
            smoothing: 2
            color: ColorUtils.transparentize(blendedColors?.colPrimary ?? Appearance.colors.colPrimary,
                0.6
            )
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

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
            // Info & controls
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                StyledText {
                    Layout.fillWidth: true
                    text: root.currentVisibleTitle
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.currentVisibleArtist
                    font.pixelSize: Appearance.font.pixelSize.small
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
                        active: root.player?.canSeek ?? false
                        sourceComponent: StyledSlider {
                            configuration: StyledSlider.Configuration.Wavy
                            wavy: root.player?.isPlaying ?? false
                            animateWave: root.player?.isPlaying ?? false
                            highlightColor: Appearance.inirEverywhere ? root.inirPrimary
                                : Appearance.auroraEverywhere ? Appearance.colors.colPrimary
                                : (blendedColors?.colPrimary ?? Appearance.colors.colPrimary)
                            trackColor: Appearance.inirEverywhere ? root.inirLayer2
                                : Appearance.auroraEverywhere ? Appearance.aurora.colElevatedSurface
                                : (blendedColors?.colSecondaryContainer ?? Appearance.colors.colSecondaryContainer)
                            handleColor: Appearance.inirEverywhere ? root.inirPrimary
                                : Appearance.auroraEverywhere ? Appearance.colors.colPrimary
                                : (blendedColors?.colPrimary ?? Appearance.colors.colPrimary)
                            value: root.player?.length > 0 ? root.player.position / root.player.length : 0
                            onMoved: root.player.position = value * root.player.length
                            scrollable: true
                        }
                    }


                }
                // // Progress bar
                // Item {
                //     Layout.fillWidth: true
                //     implicitHeight: 16
                //     // property bool waiting: root.player ? root.player.length === 0 : true

                //     // hide the whole progress bar when waiting
                //     visible: root.safePlayer !== null && root.player?.canSeek
                //     Loader {

                //         anchors.fill: parent
                //         active: root.player?.canSeek ?? false
                //         sourceComponent: StyledSlider {
                //             configuration: StyledSlider.Configuration.Wavy
                //             wavy: root.player?.isPlaying ?? false
                //             animateWave: root.player?.isPlaying ?? false
                //             highlightColor: blendedColors?.colPrimary ?? Appearance.colors.colPrimary
                //             trackColor: blendedColors?.colSecondaryContainer ?? Appearance.colors.colSecondaryContainer
                //             handleColor: blendedColors?.colPrimary ?? Appearance.colors.colPrimary
                //             value: root.player?.length > 0 ? root.player.position / root.player.length : 0
                //             onMoved: root.player.position = value * root.player.length
                //             scrollable: true
                //         }
                //     }
                // }
                Item {
                id: loadingDots
                visible: !root.player?.canSeek
                Layout.fillWidth: true
                implicitHeight: 16
                Layout.alignment: Qt.AlignHCenter

                property int dotCount: 1

                    // Timer to grow dots from 4 → 7 and reset to 4
                    Timer {
                        interval: 600
                        repeat: true
                        running: !root.player?.canSeek
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
                // Time + controls
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: root.safePlayer !== null && root.player?.canSeek
                    StyledText {
                        text: StringUtils.friendlyTimeForSeconds(root.player?.position ?? 0)
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.family: Appearance.font.family.numbers
                        color: blendedColors?.colOnLayer0 ?? Appearance.colors.colOnLayer0
                    }

                    Item { Layout.fillWidth: true }

                    RippleButton {
                        implicitWidth: 32; implicitHeight: 32
                        buttonRadius: Appearance.rounding.full
                        colBackground: "transparent"
                        colBackgroundHover: ColorUtils.transparentize(blendedColors?.colLayer1 ?? Appearance.colors.colLayer1, 0.5)
                        colRipple: blendedColors?.colLayer1Active ?? Appearance.colors.colLayer1Active
                        onClicked: root.doPrevious()
                        contentItem: Item {
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "skip_previous"; iconSize: 22; fill: 1
                                color: blendedColors?.colOnLayer0 ?? Appearance.colors.colOnLayer0
                            }
                        }

                        StyledToolTip { text: Translation.tr("Previous") }
                    }

                    RippleButton {
                        id: playPauseButton
                        implicitWidth: 40
                        implicitHeight: 40
                        buttonRadius: root.player?.isPlaying ? Appearance.rounding.normal : Appearance.rounding.full
                        colBackground: root.player?.isPlaying
                                    ? (blendedColors?.colPrimary ?? Appearance.colors.colPrimary)
                                    : (blendedColors?.colSecondaryContainer ?? Appearance.colors.colSecondaryContainer)
                        colBackgroundHover: root.player?.isPlaying 
                                    ? (blendedColors?.colPrimaryHover ?? Appearance.colors.colPrimaryHover)
                                    : (blendedColors?.colSecondaryContainerHover ?? Appearance.colors.colSecondaryContainerHover)
                        colRipple: root.player?.isPlaying
                                    ? (blendedColors?.colPrimaryActive ?? Appearance.colors.colPrimaryActive)
                                    : (blendedColors?.colSecondaryContainerActive ?? Appearance.colors.colSecondaryContainerActive)
                        onClicked: root.doTogglePlaying()
                       

                        Behavior on buttonRadius {
                            enabled: true
                            NumberAnimation { duration: Appearance.animation.elementMoveFast.duration }
                        }
                        contentItem: Item {
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: root.player?.isPlaying ? "pause" : "play_arrow"
                                    iconSize: 24
                                    fill: 1
                                    color: root.player?.isPlaying
                                                ? (blendedColors?.colOnPrimary ?? Appearance.colors.colOnPrimary)
                                                : (blendedColors?.colOnSecondaryContainer ?? Appearance.colors.colOnSecondaryContainer)

                                    Behavior on color {
                                        enabled: Appearance.animationsEnabled
                                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                    }
                                }
                            }
                        StyledToolTip { text: root.player?.isPlaying ? Translation.tr("Pause") : Translation.tr("Play") }
                    }

                    RippleButton {
                        implicitWidth: 32; implicitHeight: 32
                        buttonRadius: Appearance.rounding.full
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer1Active
                        onClicked: root.doNext()
                        contentItem: Item {
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "skip_next"; iconSize: 22; fill: 1
                                color:  Appearance.colors.colOnLayer0
                            }
                        }
                        
                        StyledToolTip { text: Translation.tr("Next") } 
        
                    }
                    
                    Item { Layout.fillWidth: true }

                    StyledText {
                        text: StringUtils.friendlyTimeForSeconds(root.player?.length ?? 0)
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.family: Appearance.font.family.numbers
                        color: Appearance.colors.colOnLayer0
                    }
                }
            }
        }
    }
}
