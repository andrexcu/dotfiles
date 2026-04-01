import QtQuick
import QtQuick.Effects
import qs.modules.common
import qs.modules.common.functions

Item {
    id: root
    required property var target
    property bool hovered: false
    property real radius: (target && target.radius !== undefined) ? Number(target.radius) : 0
    // Passthrough properties for backward compat (some sites override these)
    // property real blur: 0.9 * Appearance.sizes.elevationMargin
    property real blur:  0.9 * 5
    property real spread: 1
    property color color: Appearance.colors.colShadow
    property vector2d offset: Qt.vector2d(0.0, 1.0)

    visible: true
    anchors.fill: target

    // ─── MATERIAL MODE: standard blur shadow ───
    RectangularShadow {
        visible: true
        anchors.fill: parent
        radius: root.radius
        blur: root.blur
        offset: root.offset
        spread: root.spread
        color: root.color
        cached: true
    }
}
