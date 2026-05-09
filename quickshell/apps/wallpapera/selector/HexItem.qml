import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Effects
import QtCore
import Quickshell.Wayland
import qs.components
import Quickshell
import Quickshell.Io as Io
import Quickshell.Hyprland
import QtQuick.Window
import Quickshell.Widgets
import qs.colors
import Qt.labs.platform
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import qs
import qs.services

Item {
    id: hexItem

    property var colors
    property var service
    property int hexRadius: 140
    property var itemData
    // property bool isSelected: false
    property bool isSelected: controller.currentIndex === itemIndex
    property var controller
    property int itemIndex
    property var listViewRef
    // property bool isHovered: hexMouse.containsMouse
    property bool pulledOut: false

    property real parallaxX: 0
    property real parallaxY: 0

    signal flipRequested(var data, real gx, real gy, var sourceItem)
    signal hoverSelected()

    // property real targetX:
    //     listViewRef.baseX(itemIndex)

    x: 0
        // + layoutX
        // + (entering ? 0 : (rippleOff ? 0 : ripple.x))

        // property real targetY:
        // flick.baseY(itemIndex)
        // + layoutY
        // + (entering ? 0 : (rippleOff ? 0 : ripple.y))

    // y: targetY


    // Behavior on targetX {
    //     NumberAnimation {
    //             duration: 350
    //             easing.type: Easing.BezierSpline
    //             easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
    //             onRunningChanged: {
    //                 if (!running) {
    //                     // highlightContainer.updateBorder()
    //                     // controller.currentItemX = hexItem.x
    //                     // console.log("final X:", controller.currentItem.x)
    //                 }
    //             }
    //         }
    // }

    // Behavior on targetY {
    //     NumberAnimation {
    //             duration: 350
    //             easing.type: Easing.BezierSpline
    //             easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
    //             // onRunningChanged: {
    //             //     if (!running) {
    //             //         controller.currentItemY = hexItem.y
    //             //         console.log("final Y:", controller.currentItemY)
    //             //     }
    //             // }
    //         }
    //     }

    // Component.onCompleted: {
    //     console.log("data", itemData)
    // }

    width: hexRadius * 2
    height: Math.ceil(hexRadius * 1.73205)

    readonly property real _r: hexRadius
    readonly property real _cx: _r
    readonly property real _cy: height / 2
    readonly property real _cos30: 0.866025
    readonly property real _sin30: 0.5

    Item {
        id: hexMask
        width: hexItem.width; height: hexItem.height
        visible: false
        layer.enabled: true
        Shape {
            anchors.fill: parent
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: "white"
                strokeColor: "transparent"
                startX: hexItem._cx + hexItem._r;                          startY: hexItem._cy
                PathLine { x: hexItem._cx + hexItem._r * hexItem._sin30;  y: hexItem._cy - hexItem._r * hexItem._cos30 }
                PathLine { x: hexItem._cx - hexItem._r * hexItem._sin30;  y: hexItem._cy - hexItem._r * hexItem._cos30 }
                PathLine { x: hexItem._cx - hexItem._r;                   y: hexItem._cy }
                PathLine { x: hexItem._cx - hexItem._r * hexItem._sin30;  y: hexItem._cy + hexItem._r * hexItem._cos30 }
                PathLine { x: hexItem._cx + hexItem._r * hexItem._sin30;  y: hexItem._cy + hexItem._r * hexItem._cos30 }
                PathLine { x: hexItem._cx + hexItem._r;                   y: hexItem._cy }
            }
        }
    }

    Item {
        id: imageContainer
        anchors.fill: parent
        opacity: hexItem.pulledOut ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Style.animFast } }

            Rectangle {
                id: hexPlaceholder
                anchors.centerIn: parent
                width: hexItem.width * 1.3
                height: hexItem.height * 1.3
                color: Style.fallbackAccent
                opacity: (thumbImage.status === Image.Ready && thumbImage.source != "") ? 0 : 0.08
                Behavior on opacity { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
                visible: opacity > 0

                Text {
                    anchors.centerIn: parent
                    text: "\u{f0553}"
                    font.family: Style.fontFamilyNerdIcons; font.pixelSize: 22
                    color: Qt.rgba(1, 1, 1, 0.1)
                    visible: thumbImage.status !== Image.Ready
                }
            }

            Image {
                id: thumbImage
                width: hexItem.width * 1.5
                height: hexItem.height
                x: (hexItem.width - width) / 2 + hexItem.parallaxX
                y: (hexItem.height - height) / 2 + hexItem.parallaxY
                // source: hexItem.itemData && hexItem.itemData.thumb ? ImageService.fileUrl(hexItem.itemData.thumb) : ""
                 property string thumbName: WallpaperCacheService.thumbnailPaths[itemData.filePath] || ""
                  
                    source: WatcherService.thumbsGenerated
                        ? "file://" + Config.cacheDir + "/" + thumbName
                        : ""
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                cache: false
                sourceSize.width: Math.ceil(hexItem.width * 1.3)
                sourceSize.height: Math.ceil(hexItem.height)
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
            }

            layer.enabled: true
            layer.smooth: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: hexMask
                maskThresholdMin: 0.3
                maskSpreadAtMin: 0.3
            }
    }

    

   

    Shape {
        anchors.fill: parent
        visible: hexItem.pulledOut
        opacity: hexItem.pulledOut ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Style.animFast } }
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: hexItem.colors ? Qt.rgba(hexItem.colors.primary.r, hexItem.colors.primary.g, hexItem.colors.primary.b, 0.08) : Qt.rgba(1,1,1,0.05)
            strokeColor: hexItem.colors ? Qt.rgba(hexItem.colors.primary.r, hexItem.colors.primary.g, hexItem.colors.primary.b, 0.4) : Qt.rgba(1,1,1,0.2)
            strokeWidth: 2
            strokeStyle: ShapePath.DashLine
            dashPattern: [4, 4]
            startX: hexItem._cx + hexItem._r;                          startY: hexItem._cy
            PathLine { x: hexItem._cx + hexItem._r * hexItem._sin30;  y: hexItem._cy - hexItem._r * hexItem._cos30 }
            PathLine { x: hexItem._cx - hexItem._r * hexItem._sin30;  y: hexItem._cy - hexItem._r * hexItem._cos30 }
            PathLine { x: hexItem._cx - hexItem._r;                   y: hexItem._cy }
            PathLine { x: hexItem._cx - hexItem._r * hexItem._sin30;  y: hexItem._cy + hexItem._r * hexItem._cos30 }
            PathLine { x: hexItem._cx + hexItem._r * hexItem._sin30;  y: hexItem._cy + hexItem._r * hexItem._cos30 }
            PathLine { x: hexItem._cx + hexItem._r;                   y: hexItem._cy }
        }
    }

    Shape {
        id: hexBorder
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: "transparent"
            strokeColor: hexItem.isSelected
                ? (hexItem.colors ? hexItem.colors.primary : Style.fallbackAccent)
                : Qt.rgba(0, 0, 0, 0.5)
            Behavior on strokeColor { ColorAnimation { duration: Style.animFast } }
            strokeWidth: hexItem.isSelected ? 3 : 1.5
            startX: hexItem._cx + hexItem._r;                          startY: hexItem._cy
            PathLine { x: hexItem._cx + hexItem._r * hexItem._sin30;  y: hexItem._cy - hexItem._r * hexItem._cos30 }
            PathLine { x: hexItem._cx - hexItem._r * hexItem._sin30;  y: hexItem._cy - hexItem._r * hexItem._cos30 }
            PathLine { x: hexItem._cx - hexItem._r;                   y: hexItem._cy }
            PathLine { x: hexItem._cx - hexItem._r * hexItem._sin30;  y: hexItem._cy + hexItem._r * hexItem._cos30 }
            PathLine { x: hexItem._cx + hexItem._r * hexItem._sin30;  y: hexItem._cy + hexItem._r * hexItem._cos30 }
            PathLine { x: hexItem._cx + hexItem._r;                   y: hexItem._cy }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
         
            controller.previousIndex = controller.currentIndex
            controller.currentIndex = itemIndex
            hexListView.forceActiveFocus() 
            // Qt.callLater(() => flickRef.forceActiveFocus())
        }

        onDoubleClicked: {
            WallpaperApplyService.applyWallpaper(itemData)
        }
    }
    
    // MouseArea {
    //     anchors.fill: parent
    //     onClicked: {
    //         hexListView._selectedCol = hexCol.colIdx
    //         hexListView._selectedRow = rowIdx
    //         hexListView.currentIndex = hexCol.colIdx
    //     }
    // }
    // MouseArea {
    //     id: hexMouse
    //     anchors.fill: parent
    //     hoverEnabled: true
    //     acceptedButtons: Qt.LeftButton | Qt.RightButton
    //     cursorShape: Qt.PointingHandCursor
    //     function contains(point) {
    //         var dx = Math.abs(point.x - hexItem._cx)
    //         var dy = Math.abs(point.y - hexItem._cy)
    //         return dy <= hexItem._cos30 * hexItem._r && dx <= hexItem._r - dy * 0.57735
    //     }
    //     onContainsMouseChanged: {
    //         if (containsMouse) hexItem.hoverSelected()
    //     }
    //     onClicked: function(mouse) {
    //         if (mouse.button === Qt.RightButton && hexItem.itemData) {
    //             var gp = hexItem.mapToItem(null, hexItem._cx, hexItem._cy)
    //             hexItem.flipRequested(hexItem.itemData, gp.x, gp.y, hexItem)
    //         } else if (mouse.button === Qt.LeftButton && hexItem.itemData) {
    //             if (hexItem.itemData.type === "we") {
    //                 hexItem.service.applyWE(hexItem.itemData.weId)
    //             } else if (hexItem.itemData.type === "video") {
    //                 hexItem.service.applyVideo(hexItem.itemData.path)
    //             } else {
    //                 hexItem.service.applyStatic(hexItem.itemData.path)
    //             }
    //         }
    //     }
    // }
}