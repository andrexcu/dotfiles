pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.colors
import QtQuick.Controls

Scope {
    id: root
    property bool visible: true
    // readonly property MprisPlayer activePlayer: MprisController.activePlayer
     readonly property MprisPlayer activePlayer: Players.active
    // Use displayPlayers - includes title/position dedup to prevent duplicates (e.g. plasma-browser-integration)
    readonly property var allPlayers: Players.list
    readonly property real osdWidth: Appearance.sizes.osdWidth
    readonly property real widgetWidth: Appearance.sizes.mediaControlsWidth
    readonly property real widgetHeight: Appearance.sizes.mediaControlsHeight
    readonly property real dockHeight: Config.options?.dock?.height ?? 60
    readonly property real dockMargin: Appearance.sizes.elevationMargin + Appearance.sizes.hyprlandGapsOut
    property var colorsPalette: Colors {}
   
    property real popupRounding: Appearance.inirEverywhere ? Appearance.inir.roundingLarge : Appearance.rounding.large
    readonly property bool visualizerActive: true
 
    property MprisPlayer safePlayer: null
    // property var lastKnownMetadata: ({}) // key = player name, value = metadata

    // property var filteredPlayers: {
    //     var players = root.allPlayers || []
    //     if (players.length === 0) return []

    //     var result = []

    //     players.forEach(p => {
    //         var name = p.name
    //         if (p.metadata?.artUrl || p.metadata?.title) {
    //             lastKnownMetadata[name] = p.metadata
    //             result.push(p)
    //         } else if (lastKnownMetadata[name]) {
    //             p.metadata = lastKnownMetadata[name]
    //             result.push(p)
    //         }
    //     })
    //     var withMetadata = result.filter(p => p.metadata?.artUrl || p.metadata?.title)
    //     // return withMetadata.length > 0 ? withMetadata : []
    //     return withMetadata.length > 0 ? withMetadata : (Players.active ? [Players.active] : []);
    // }

    Timer {
        interval: 100
        repeat: true
        running: true
        onTriggered: {
            const active = Players.active
            if (active && (active.trackTitle || active.metadata?.title)) {
                if (safePlayer !== active) {
                    safePlayer = active
                }
            } else if (!active) {
                safePlayer = null
            }
            // If active exists but metadata not ready → keep old safePlayer
        }
    }

    CavaProcess {
        id: cavaProcess
        active: root.visualizerActive
    }

    property list<real> visualizerPoints: cavaProcess.points
    
    Loader {
        id: mediaControlsLoader
        active: GlobalStates.mediaControlsOpen || closingTimer.running

        Timer {
            id: closingTimer
            interval: Appearance.animationsEnabled ? 350 : 0
        }

        Connections {
            target: GlobalStates
            function onMediaControlsOpenChanged() {
                if (!GlobalStates.mediaControlsOpen) {
                    closingTimer.restart()
                } else {
                    closingTimer.stop()
                }
            }
        }

        sourceComponent: PanelWindow {
            id: mediaControlsRoot
            visible: true

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            color: "transparent"
            WlrLayershell.namespace: "quickshell:mediaControls"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: GlobalStates.mediaControlsOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            // Click outside to close - covers entire screen
            FocusScope {
                id: inputScope
                anchors.fill: parent
                focus: true

                Component.onCompleted: focusTimer.start()

                Timer {
                    id: focusTimer
                    interval: 100
                    repeat: false
                    onTriggered: {
                        // console.log("MediaControls: Forcing focus")
                        inputScope.forceActiveFocus()
                    }
                }

                Keys.onSpacePressed: {
                    console.log("MediaControls: Space pressed")
                    if (root.activePlayer?.canTogglePlaying) {
                        root.activePlayer.togglePlaying();
                    }
                }

                Keys.onEscapePressed: {
                    GlobalStates.mediaControlsOpen = false;
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: GlobalStates.mediaControlsOpen = false
                }

                Item {
                id: cardArea
                width: root.widgetWidth
                height: playerColumnLayout.implicitHeight
                anchors.horizontalCenter: parent.horizontalCenter

                // Use screen height for reliable off-screen position
                readonly property real screenH: mediaControlsRoot.screen?.height ?? 1080
                readonly property real targetY: screenH - height - root.dockHeight - root.dockMargin - 5

                y: screenH + 50
                opacity: 0
                scale: 0.9
                transformOrigin: Item.Bottom

                states: State {
                    name: "visible"
                    when: GlobalStates.mediaControlsOpen
                    PropertyChanges {
                        target: cardArea
                        y: cardArea.targetY
                        opacity: 1
                        scale: 1
                    }
                }

                transitions: [
                    Transition {
                        to: "visible"
                        enabled: Appearance.animationsEnabled
                        NumberAnimation { properties: "y"; duration: 350; easing.type: Easing.OutQuint }
                        NumberAnimation { properties: "opacity"; duration: 250; easing.type: Easing.OutCubic }
                        NumberAnimation { properties: "scale"; duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                    },
                    Transition {
                        from: "visible"
                        enabled: Appearance.animationsEnabled
                        NumberAnimation { properties: "y"; duration: 250; easing.type: Easing.InQuint }
                        NumberAnimation { properties: "opacity"; duration: 200; easing.type: Easing.InCubic }
                        NumberAnimation { properties: "scale"; duration: 250; easing.type: Easing.InBack; easing.overshoot: 1.0 }
                    }
                ]

                ColumnLayout {
                    id: playerColumnLayout
                    // anchors.fill: parent
                    anchors.centerIn: parent
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
                        Players.hasMedia(p)
                        // p.trackTitle || p.trackArtist || p.metadata?.title || p.metadata?.artist || p.metadata?.artUrl
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
                    PlayerControl {
                        id: playerDelegate
                        visible: root.safePlayer !== null

                        player: root.activePlayer
                        visualizerPoints: root.visualizerPoints
                        implicitWidth: root.widgetWidth
                        implicitHeight: root.widgetHeight
                        radius: root.popupRounding

                        screenX: cardArea.x + (mediaControlsRoot.width - cardArea.width) / 2
                        screenY: cardArea.y
                    }

                    Item { // No player placeholder
                        Layout.fillWidth: true
                        visible: safePlayer === null
                        // visible: (root.activePlayer?.length ?? 0) === 0
                        // visible: root.activePlayer.length === 0
                        implicitWidth: placeholderBackground.implicitWidth + Appearance.sizes.elevationMargin
                        implicitHeight: placeholderBackground.implicitHeight + Appearance.sizes.elevationMargin

                        StyledRectangularShadow {
                            target: placeholderBackground
                            visible: Appearance.angelEverywhere || (!Appearance.inirEverywhere && !Appearance.auroraEverywhere)
                        }

                        Rectangle {
                            id: placeholderBackground
                            anchors.centerIn: parent
                            color: Appearance.inirEverywhere ? Appearance.inir.colLayer1
                                 : Appearance.auroraEverywhere ? Appearance.aurora.colPopupSurface
                                 : Appearance.colors.colLayer0
                            radius: Appearance.inirEverywhere ? Appearance.inir.roundingLarge : root.popupRounding
                            border.width: Appearance.inirEverywhere || Appearance.auroraEverywhere ? 1 : 0
                            border.color: Appearance.inirEverywhere ? Appearance.inir.colBorder
                                        : Appearance.auroraEverywhere ? Appearance.aurora.colTooltipBorder
                                        : "transparent"
                            property real padding: 20
                            implicitWidth: placeholderLayout.implicitWidth + padding * 2
                            implicitHeight: placeholderLayout.implicitHeight + padding * 2

                            ColumnLayout {
                                id: placeholderLayout
                                anchors.centerIn: parent

                                StyledText {
                                    text: Translation.tr("No active player")
                                    font.pixelSize: Appearance.font.pixelSize.large
                                    color: Appearance.inirEverywhere ? Appearance.inir.colText : Appearance.colors.colOnLayer0
                                }
                                StyledText {
                                    color: Appearance.inirEverywhere ? Appearance.inir.colTextSecondary : Appearance.colors.colSubtext
                                    text: Translation.tr("Make sure your player has MPRIS support\\nor try turning off duplicate player filtering")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    }

    IpcHandler {
        target: "mediaControls"

        function toggle(): void {
            GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen;
            if (GlobalStates.mediaControlsOpen)
                Notifications.timeoutAll();
        }

        function close(): void {
            GlobalStates.mediaControlsOpen = false;
        }

        function open(): void {
            GlobalStates.mediaControlsOpen = true;
            Notifications.timeoutAll();
        }
    }
    Loader {
        active: CompositorService.isHyprland
        sourceComponent: Item {
            GlobalShortcut {
                name: "mediaControlsToggle"
                description: "Toggles media controls on press"

                onPressed: {
                    GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen;
                }
            }
            GlobalShortcut {
                name: "mediaControlsOpen"
                description: "Opens media controls on press"

                onPressed: {
                    GlobalStates.mediaControlsOpen = true;
                    
                }
            }
            GlobalShortcut {
                name: "mediaControlsClose"
                description: "Closes media controls on press"

                onPressed: {
                    GlobalStates.mediaControlsOpen = false;
                }
            }
            GlobalShortcut {
                name: "mediaControlsPlayPause"
                description: "Toggles play/pause when media controls are open"

                onPressed: {
                    if (GlobalStates.mediaControlsOpen && activePlayer?.canTogglePlaying) {
                        activePlayer.togglePlaying();
                    }
                }
            }
        }
    }

    
}
