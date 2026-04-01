import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects
import qs.colors
import QtQuick.Effects

Item {
    id: root
    property bool vertical: false
    property bool borderless: Config.options.bar.borderless
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property var wsConfig: Config.options?.bar?.workspaces ?? {}
    // readonly property int workspacesShown: Config.options.bar.workspaces.shown
    readonly property int workspacesShown: 5
    readonly property int workspaceGroup: Math.floor((monitor?.activeWorkspace?.id - 1) / root.workspacesShown)
    property list<bool> workspaceOccupied: []
    property int widgetPadding: 4
    property int workspaceButtonWidth: 46
    property int smallButtonWidth: 26
    property real activeWorkspaceMargin: 2
    property real workspaceIconSize: 26 * 0.69
    property real workspaceIconSizeShrinked: 26 * 0.55
    property real workspaceIconOpacityShrinked: 1
    property real workspaceIconMarginShrinked: -4
    property int workspaceIndexInGroup: (monitor?.activeWorkspace?.id - 1) % root.workspacesShown
   
    property var colorsPalette: Colors{}
    property bool showNumbers: false
    
    property real dynamicWidth: {
        let total = 0;
        const start = root.workspaceGroup * root.workspacesShown; // e.g., group 1: 0*5=0, group2: 1*5=5
        const end = start + root.workspacesShown;

        for (let i = start; i < end; i++) {
            const biggest = HyprlandData.biggestWindowForWorkspace(i + 1);
            const second = HyprlandData.secondBiggestWindowForWorkspace(i + 1);
            const btnWidth = second ? root.workspaceButtonWidth : root.smallButtonWidth;
            total += btnWidth;
        }
        return total;
    }

    Behavior on implicitWidth{
        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
    }
    implicitWidth: root.dynamicWidth
    implicitHeight: root.vertical ? (root.workspaceButtonWidth * root.workspacesShown) : Appearance.sizes.barHeight
    // Connections {
    // target: HyprlandData
    // onWindowListChanged: root.dynamicWidth = root.dynamicWidth // triggers recalculation
    // }
    Timer {
        id: showNumbersTimer
        interval: (Config?.options.bar.autoHide.showWhenPressingSuper.delay ?? 100)
        repeat: false
        onTriggered: {
            root.showNumbers = true
        }
    }
    Connections {
        target: GlobalStates
        function onSuperDownChanged() {
            if (!Config?.options.bar.autoHide.showWhenPressingSuper.enable) return;
            if (GlobalStates.superDown) showNumbersTimer.restart();
            else {
                showNumbersTimer.stop();
                root.showNumbers = false;
            }
        }
        function onSuperReleaseMightTriggerChanged() { 
            showNumbersTimer.stop()
        }
    }


    // Function to update workspaceOccupied
    function updateWorkspaceOccupied() {
        workspaceOccupied = Array.from({ length: root.workspacesShown }, (_, i) => {
            return Hyprland.workspaces.values.some(ws => ws.id === workspaceGroup * root.workspacesShown + i + 1);
        })
    }

    // Occupied workspace updates
    Component.onCompleted: {
        updateWorkspaceOccupied()
      
    }
    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() {
            updateWorkspaceOccupied();
        }
    }
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            updateWorkspaceOccupied();
        }
    }
    onWorkspaceGroupChanged: {
        updateWorkspaceOccupied();
    }

  

    // implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : (root.workspaceButtonWidth * root.workspacesShown)
    

    // Scroll to switch workspaces
   
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

        onWheel: (event) => {
            const current = monitor?.activeWorkspace?.id ?? 1;
            const maxWorkspace = 10;   // set this to your actual max, e.g., 10 or 20
            const minWorkspace = 1;

            if (event.angleDelta.y < 0 && current < maxWorkspace) {
                Hyprland.dispatch(`workspace r+1`);
            } else if (event.angleDelta.y > 0 && current > minWorkspace) {
                Hyprland.dispatch(`workspace r-1`);
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton
        onPressed: (event) => {
            if (event.button === Qt.BackButton) {
                Hyprland.dispatch(`togglespecialworkspace`);
            } 
        }
    }

    // Workspaces - background
    Grid {
        z: 1
        anchors.centerIn: parent

        rowSpacing: 0
        columnSpacing: 0
        columns: root.vertical ? 1 : root.workspacesShown
        rows: root.vertical ? root.workspacesShown : 1

        Repeater {
            model: root.workspacesShown

            Rectangle { // Occupied workspace highlight
                id: wsHighlight

                z: 1

                property int workspaceValue: root.workspaceGroup * root.workspacesShown + index + 1

                property var biggest: HyprlandData.biggestWindowForWorkspace(workspaceValue)
                property var second: HyprlandData.secondBiggestWindowForWorkspace(workspaceValue)

                implicitWidth: second ? root.workspaceButtonWidth : root.smallButtonWidth
                implicitHeight: 26

                // property bool isActiveWorkspace: monitor?.activeWorkspace?.id === workspaceValue
                // Occupancy & corner logic
                // property bool currentOccupied: Boolean(workspaceOccupied[index]) && !(Boolean(activeWindow?.activated) === false && monitor?.activeWorkspace?.id === workspaceValue)
                // property bool previousOccupied: Boolean(workspaceOccupied[index-1]) && !(Boolean(activeWindow?.activated) === false && monitor?.activeWorkspace?.id === workspaceValue-1)
                // property bool nextOccupied: Boolean(workspaceOccupied[index+1]) && !(Boolean(activeWindow?.activated) === false && monitor?.activeWorkspace?.id === workspaceValue+1)
                
                
                // property bool currentOccupied:  ( monitor?.activeWorkspace?.windows?.length ?? 0) > 0

                property bool previousOccupied:
                    Boolean(workspaceOccupied[index - 1] ?? false) &&
                    (Boolean(activeWindow?.activated) || monitor?.activeWorkspace?.id !== workspaceValue - 1)

                property bool nextOccupied:
                    Boolean(workspaceOccupied[index + 1] ?? false) &&
                    (Boolean(activeWindow?.activated) || monitor?.activeWorkspace?.id !== workspaceValue + 1)
            
                
                property real leftRadius: previousOccupied ? 0 : Appearance.rounding.full
                property real rightRadius: nextOccupied ? 0 : Appearance.rounding.full

                topLeftRadius: root.vertical ? leftRadius : leftRadius
                bottomLeftRadius: root.vertical ? leftRadius : leftRadius
                topRightRadius: root.vertical ? rightRadius : rightRadius
                bottomRightRadius: root.vertical ? rightRadius : rightRadius

                // color: ColorUtils.transparentize(colorsPalette.secondaryContainer, 0.4)
                // color: ColorUtils.transparentize(Appearance.m3colors.m3secondaryContainer, 0.4)
                color: (workspaceOccupied[index] && !(!activeWindow?.activated && monitor?.activeWorkspace?.id === workspaceValue)) 
                ? ColorUtils.transparentize(Appearance.m3colors.m3secondaryContainer, 0.4) 
                : "transparent"
                // opacity: (workspaceOccupied[index] && !(!activeWindow?.activated && monitor?.activeWorkspace?.id === workspaceValue)) ? 1 : 0
                // color: "#4D000000"
                enabled: false

                Behavior on topLeftRadius { animation: Appearance.animation.elementMove.numberAnimation.createObject(this) }
                Behavior on bottomLeftRadius { animation: Appearance.animation.elementMove.numberAnimation.createObject(this) }
                Behavior on topRightRadius { animation: Appearance.animation.elementMove.numberAnimation.createObject(this) }
                Behavior on bottomRightRadius { animation: Appearance.animation.elementMove.numberAnimation.createObject(this) }
                Behavior on opacity { animation: Appearance.animation.elementMove.numberAnimation.createObject(this) }
            }
        }
    }




// Rectangle {
//     id: activeIndicator
//     z: 2
//     radius: 8
//     color: colorsPalette.primary

//     anchors.verticalCenter: parent.verticalCenter
//     // if vertical bar, use horizontalCenter: parent.horizontalCenter

//     property real indicatorWidth: {
//         const ws = monitor?.activeWorkspace?.id
//         const second = HyprlandData.secondBiggestWindowForWorkspace(ws)
//         return second ? root.workspaceButtonWidth : root.smallButtonWidth
//     }

//     property real indicatorX: {
//         let pos = 0  // start at 0, parent anchors will handle vertical centering
//         const startWorkspace = root.workspaceGroup * root.workspacesShown
//         for (let i = startWorkspace; i < startWorkspace + root.workspaceIndexInGroup; i++) {
//             const second = HyprlandData.secondBiggestWindowForWorkspace(i + 1)
//             pos += second ? root.workspaceButtonWidth : root.smallButtonWidth
//         }
//         return pos
//     }

//     Behavior on indicatorX { NumberAnimation { duration: 320; easing.type: Easing.InOutQuad } }
//     Behavior on indicatorWidth { NumberAnimation { duration: 320; easing.type: Easing.InOutQuad } }

//     x: indicatorX  // animate horizontally from left edge of the parent
//     implicitWidth: indicatorWidth
//     implicitHeight: 26 - root.activeWorkspaceMargin * 2
// }
// Active workspace indicator
Rectangle {
    id: activeIndicator
    z: 2
    radius: Appearance.rounding.full
    color: colorsPalette.primary

    anchors.verticalCenter: parent.verticalCenter

    // --- Calculated properties ---
    property real indicatorWidth: {
        const ws = monitor?.activeWorkspace?.id
        const second = HyprlandData.secondBiggestWindowForWorkspace(ws)
        return second ? root.workspaceButtonWidth : root.smallButtonWidth
    }

    property real indicatorX: {
        let pos = 0
        const startWorkspace = root.workspaceGroup * root.workspacesShown
        for (let i = startWorkspace; i < startWorkspace + root.workspaceIndexInGroup; i++) {
            const second = HyprlandData.secondBiggestWindowForWorkspace(i + 1)
            pos += second ? root.workspaceButtonWidth : root.smallButtonWidth
        }
        return pos
    }

    // --- Smooth animation like AnimatedTabIndexPair ---
    Behavior on indicatorX { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
    Behavior on indicatorWidth { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }

    x: indicatorX
    implicitWidth: indicatorWidth
    implicitHeight: 26 - root.activeWorkspaceMargin * 2
}

// Trail rectangle (visual effect)
Rectangle {
    id: trailIndicator
    z: 1
    radius: Appearance.rounding.full
    color: colorsPalette.primary
    anchors.verticalCenter: parent.verticalCenter

    // Keep trail's own edges and target
    property real leftEdge: activeIndicator.x
    property real rightEdge: activeIndicator.x + activeIndicator.implicitWidth
    property real targetX: activeIndicator.x
    property real targetWidth: activeIndicator.implicitWidth

    x: leftEdge
    implicitWidth: rightEdge - leftEdge
    implicitHeight: 26 - root.activeWorkspaceMargin * 2

    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            // Always refer to trailIndicator explicitly
            trailIndicator.targetX = activeIndicator.x
            trailIndicator.targetWidth = activeIndicator.implicitWidth

           if (trailIndicator.targetX > trailIndicator.leftEdge) {
                // moving right → stretch left edge slowly
                trailIndicator.leftEdge = Math.min(trailIndicator.targetX,
                    trailIndicator.leftEdge + (trailIndicator.targetX - trailIndicator.leftEdge) * 0.2)
                trailIndicator.rightEdge = trailIndicator.targetX + trailIndicator.targetWidth
            } else if (trailIndicator.targetX < trailIndicator.leftEdge) {
                // moving left → stretch right edge slowly
                trailIndicator.rightEdge = Math.max(trailIndicator.targetX + trailIndicator.targetWidth,
                    trailIndicator.rightEdge - (trailIndicator.rightEdge - (trailIndicator.targetX + trailIndicator.targetWidth)) * 0.2)
                trailIndicator.leftEdge = trailIndicator.targetX
            } else {
                // exact position
                trailIndicator.leftEdge = trailIndicator.targetX
                trailIndicator.rightEdge = trailIndicator.targetX + trailIndicator.targetWidth
            }
        }
    }
}

    // Workspaces - numbers
    Grid {
        z: 3
        // anchors.centerIn: parent
        columns: root.vertical ? 1 : root.workspacesShown
        rows: root.vertical ? root.workspacesShown : 1
        columnSpacing: 0
        rowSpacing: 0
        
        anchors.fill: parent

        Repeater {
            model: root.workspacesShown
            
           Button {
            id: button
            
            property int workspaceValue: workspaceGroup * root.workspacesShown + index + 1
            property bool isActiveWorkspace: monitor?.activeWorkspace?.id === workspaceValue
            property bool currentOccupied:
                    Boolean(workspaceOccupied[index]) &&
                    (Boolean(activeWindow?.activated) || monitor?.activeWorkspace?.id !== workspaceValue)
            // Compute dynamic width
            // property var biggestWindow: HyprlandData.biggestWindowForWorkspace(workspaceValue)
            // property var secondBiggestWindow: HyprlandData.secondBiggestWindowForWorkspace(workspaceValue)
            
            width: workspaceButtonBackground.secondBiggestWindow ? root.workspaceButtonWidth : root.smallButtonWidth
            
            implicitHeight: Appearance.sizes.barHeight
            implicitWidth: Appearance.sizes.verticalBarWidth
            
            onPressed: {
                if (monitor?.activeWorkspace?.id !== workspaceValue) {
                    Hyprland.dispatch(`workspace ${workspaceValue}`)
                }
            }                
                background: Item {
                    id: workspaceButtonBackground
                    implicitWidth: workspaceButtonWidth
                    implicitHeight: workspaceButtonWidth
                    anchors.centerIn: parent
                    // implicitWidth: workspaceButtonWidth
                    // implicitHeight: 26
                    property var biggestWindow: HyprlandData.biggestWindowForWorkspace(button.workspaceValue)
                    property var secondBiggestWindow: HyprlandData.secondBiggestWindowForWorkspace(button.workspaceValue)
                    property var mainAppIconSource: biggestWindow
                    ? Quickshell.iconPath(AppSearch.guessIcon(biggestWindow?.class), "image-missing")
                    : ""
                   
                    property var secondAppIconSource: secondBiggestWindow
                    ? Quickshell.iconPath(AppSearch.guessIcon(secondBiggestWindow.class), "image-missing")
                    : ""   // empty string = no icon
                    
                    StyledText { // Workspace number text
                        opacity: root.showNumbers
                            || ((Config.options?.bar.workspaces.alwaysShowNumbers && (!Config.options?.bar.workspaces.showAppIcons || !workspaceButtonBackground.biggestWindow || root.showNumbers))
                            || (root.showNumbers && !Config.options?.bar.workspaces.showAppIcons)
                            )  || (button.isActiveWorkspace && !button.currentOccupied) ? 1 : 0
                        //  opacity: (
                        //         button.isActiveWorkspace &&
                        //         !button.currentOccupied
                        //     )
                        //  ? 1 : 0
                        
                        z: 3
                        property bool shouldBeVisible: !button.isActiveWorkspace && !activeIndicator.moving            
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font {
                            pixelSize: Appearance.font.pixelSize.small - ((text.length - 1) * (text !== "10") * 2)
                            family: Config.options?.bar.workspaces.useNerdFont ? Appearance.font.family.iconNerd : defaultFont
                        }
                        property list<string> numberMap: ["一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十"]
                        text: Config.options?.bar.workspaces.numberMap[button.workspaceValue - 1] || button.workspaceValue
                        elide: Text.ElideRight
                        // color: (monitor?.activeWorkspace?.id == button.workspaceValue) ? 
                        //     Appearance.m3colors.m3onPrimary : 
                        //     (workspaceOccupied[index] ? Appearance.m3colors.m3onSecondaryContainer : 
                        //         colorsPalette.inactiveText)
                        // Appearance.colors.colOnLayer1Inactive
                        color: Appearance.m3colors.m3onPrimary
                        // Behavior on color {
                        //     ColorAnimation {
                        //         duration: 250        // animation duration in ms
                        //         easing.type: Easing.InOutQuad  // smooth easing
                        //     }
                        // }

                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                    }
                    Rectangle { // Dot instead of ws number
                        id: wsDot
                        opacity: (Config.options?.bar.workspaces.alwaysShowNumbers
                            || root.showNumbers
                            || (Config.options?.bar.workspaces.showAppIcons && workspaceButtonBackground.biggestWindow)
                            ) ? 0 : 1
                        visible: !button.isActiveWorkspace
                        anchors.centerIn: parent
                        width: workspaceButtonWidth * 0.18
                        height: width
                        radius: width / 2
                        color: Appearance.colors.colOnLayer1Inactive
                        // color: (monitor?.activeWorkspace?.id == button.workspaceValue) ? 
                        //     Appearance.m3colors.m3onPrimary : 
                        //     (workspaceOccupied[index] ? Appearance.m3colors.m3onSecondaryContainer : 
                        //         Appearance.colors.colOnLayer1Inactive)

                        // Behavior on opacity {
                        //     animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        // }
                    }

                        Item { // Main app icon container
                        anchors.centerIn: parent
                        width: workspaceButtonWidth
                        height: workspaceButtonWidth
                        // implicitWidth: mainAppIcon.implicitWidth
                        

                        opacity: !Config.options?.bar.workspaces.showAppIcons ? 0 :
                            (workspaceButtonBackground.biggestWindow && !root.showNumbers) ? 
                            1 : workspaceButtonBackground.biggestWindow ? workspaceIconOpacityShrinked : 0

                        visible: opacity > 0

                        Row {
                            anchors.centerIn: parent
                            spacing: 4
                            

                            // --- Main icon ---
                            Item {
                                width: workspaceIconSize
                                height: workspaceIconSize
                                visible: workspaceButtonBackground.mainAppIconSource !== ""
                                // && !button.isActiveWorkspace
                                
                                IconImage {
                                    id: mainAppIcon
                                    anchors.fill: parent
                                    // anchors.centerIn: parent
                                    source: workspaceButtonBackground.mainAppIconSource
                                    smooth: true
                                    // opacity: activeIndicator.moving ?  0 : 1
                                    // Behavior on opacity {
                                    //     NumberAnimation {
                                    //         duration: 180        // fade duration in ms
                                    //         easing.type: Easing.InOutQuad
                                    //     }
                                    // }
                                }
                                
                                Loader {
                                    active: wsConfig.monochromeIcons
                                    opacity: 1
                                    // opacity: !button.isActiveWorkspace ?  1 :  0
                                    anchors.fill: mainAppIcon
                                    visible: true
                                    sourceComponent: Item {
                                        Desaturate {
                                            id: desaturatedMain
                                            visible: false // already have overlay
                                            anchors.fill: parent
                                            source: mainAppIcon
                                            desaturation: 0.8
                                        }
                                        ColorOverlay {
                                            anchors.fill: desaturatedMain
                                            source: desaturatedMain
                                            color: ColorUtils.transparentize(wsDot.color, 0.9)
                                        }
                                    }
                                    // Behavior on opacity {
                                    //     NumberAnimation {
                                    //         duration: 180        // fade duration in ms
                                    //         easing.type: Easing.InOutQuad
                                    //     }
                                    // }
                                }
                            }

                            // --- Second icon ---
                            Item {
                                width: workspaceIconSize
                                height: workspaceIconSize
                                visible: workspaceButtonBackground.secondAppIconSource !== ""
                                
                                // && !button.isActiveWorkspace

                                IconImage {
                                    id: secondAppIcon
                                    anchors.fill: parent
                                    source: workspaceButtonBackground.secondAppIconSource
                                    smooth: true
                                    // opacity: activeIndicator.moving ?  0 : 1
                                    // Behavior on opacity {
                                    //     NumberAnimation {
                                    //         duration: 180        // fade duration in ms
                                    //         easing.type: Easing.InOutQuad
                                    //     }
                                    // }
                                }

                                Loader {
                                    active: wsConfig.monochromeIcons
                                    opacity: 1
                                    // opacity: !button.isActiveWorkspace ?  1 :  0
                                    anchors.fill: secondAppIcon
                                    visible: true
                                    sourceComponent: Item {
                                        Desaturate {
                                            id: desaturatedSecond
                                            visible: false
                                            anchors.fill: parent
                                            source: secondAppIcon
                                            desaturation: 0.8
                                        }
                                        ColorOverlay {
                                            anchors.fill: desaturatedSecond
                                            source: desaturatedSecond
                                            color: ColorUtils.transparentize(wsDot.color, 0.9)
                                        }
                                    }
                                    // Behavior on opacity {
                                    //     NumberAnimation {
                                    //         duration: 180        // fade duration in ms
                                    //         easing.type: Easing.InOutQuad
                                    //     }
                                    // }
                                }
                            }
                        }
                    }
                }
                

            }
        
        }

    }

}
