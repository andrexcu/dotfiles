import QtQuick
import QtQuick.Shapes

Shape {
    id: root
    anchors.fill: parent
    layer.enabled: true
    layer.smooth: true
    antialiasing: true

    property color bgColor: "#222222"
    property color borderColor: "#ff5555"
    property int borderHeight: 2
    property real rounding: 12

    ShapePath {
        strokeWidth: root.borderHeight
        strokeColor: root.borderColor
        fillColor: root.bgColor

        startX: 0
        startY: root.height

        PathLine { relativeX: 0; relativeY: -root.height + rounding }
        PathArc { relativeX: rounding; relativeY: -rounding; radiusX: rounding; radiusY: rounding }
        PathLine { relativeX: root.width - rounding*2; relativeY: 0 }
        PathArc { relativeX: rounding; relativeY: rounding; radiusX: rounding; radiusY: rounding }
        PathLine { relativeX: 0; relativeY: root.height - rounding }
        PathLine { relativeX: -root.width; relativeY: 0 }
    }
}