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

    property var controller
    property var container
    property var flickRef
    property real _animY: 0
    readonly property int sel: controller.currentIndex

    property real baseX: container.itemX(index)
    property real baseY: container.itemY(index)

    property alias visualWrapperRef: visualWrapper

    // grid
    function pos(i) {
        var c = container.columns
        return { x: i % c, y: Math.floor(i / c) }
    }

    function dist(a, b) {
        return Math.max(Math.abs(a.x - b.x), Math.abs(a.y - b.y))
    }

    property int gen: dist(pos(index), pos(sel))

    // shift (geometry only)
    function computeShiftX() {
        if (index === sel) return 0
        return pos(index).x < pos(sel).x ? -20 : 20
    }

    function computeShiftY() {
        if (index === sel) return 0
        return pos(index).y < pos(sel).y ? -10 : 10
    }

    property real shiftX: computeShiftX()
    property real shiftY: computeShiftY()

    x: baseX + shiftX
    y: baseY + shiftY

    Behavior on x {
        enabled: flickRef.firstUpdateDone
        NumberAnimation { duration: 400; easing.type: Easing.BezierSpline }
    }

    Behavior on y {
        enabled: flickRef.firstUpdateDone
        NumberAnimation { duration: 400; easing.type: Easing.BezierSpline }
    }

    // ================= ENGINE (REQUIRED) =================
    property real _colScale: 1
    property bool _visibleState: true
    property real _enterDir: 1   // -1 = from top, +1 = from bottom
    transform: Translate {
        y: _visibleState ? 0 : _startY
    }
    property real _startY: 0
    property real _targetY: 0
    scale: _colScale
    opacity: _colScale

    Behavior on _colScale {
        NumberAnimation {
            duration: 500
            easing.type: Easing.OutBack
            easing.overshoot: 1.5
        }
    }
        // Behavior on scale {
        //     enabled: flickRef.firstUpdateDone
        //     NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        // }

        // Behavior on opacity {
        //     enabled: flickRef.firstUpdateDone
        //     NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        // }


//     Behavior on visualScale {
//     NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
// }

// Behavior on visualOpacity {
//     NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
// }
    // ================= VISUAL =================
    Item {
        id: visualWrapper

        width: container.cellWidth - 10
        height: container.cellHeight - 10

        scale: _colScale
        opacity: _colScale

        Behavior on scale {
            enabled: flickRef.firstUpdateDone
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
            enabled: flickRef.firstUpdateDone
            NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
        }

        Image {
            id: thumbImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false

            sourceSize.width: width
            sourceSize.height: height

            source:
                (WallpaperCacheService.thumbData &&
                 WallpaperCacheService.thumbData[WallpaperCacheService.thumbnailPaths[modelData]])
                ? ("file://" + Config.cacheDir + "/" +
                   WallpaperCacheService.thumbnailPaths[modelData])
                : ""

            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: wallpaperController.currentIndex === index &&
                      wallpaperController.blurTransition ? 1 : 0
                blurMax: 32
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: controller.currentIndex === index ? 0.6 : 0

            Behavior on opacity {
                NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
            }
        }

        layer.enabled: true
        layer.smooth: true

        layer.effect: OpacityMask {
            maskSource: Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: "white"
                    strokeWidth: 0

                    PathMove { x: width * 0.5; y: 0 }
                    PathLine { x: width; y: height * 0.25 }
                    PathLine { x: width; y: height * 0.75 }
                    PathLine { x: width * 0.5; y: height }
                    PathLine { x: 0; y: height * 0.75 }
                    PathLine { x: 0; y: height * 0.25 }
                    PathLine { x: width * 0.5; y: 0 }
                }
            }
        }
    }
}