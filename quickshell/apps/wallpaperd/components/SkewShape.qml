
import QtQuick
import Quickshell
import QtQuick.Shapes

Item {
    id: root

    property color fill: "red"
    property real cut: width * 0.04

    Shape {
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.fill
            strokeColor: "transparent"

            startX: root.cut
            startY: 0

            PathLine { x: root.width; y: 0 }
            PathLine { x: root.width - root.cut; y: root.height }
            PathLine { x: 0; y: root.height }
            PathLine { x: root.cut; y: 0 }
        }
    }
}