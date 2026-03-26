import QtQuick

Item {
    id: root

    // 👇 forward size from child
    property real padding: 6
    implicitWidth: contentItem.implicitWidth + padding * 2
    implicitHeight: contentItem.implicitHeight + padding * 2
    signal pressed(var mouse)
    // 👇 allow putting content inside
    default property alias content: contentItem.data

    // === signals ===
    signal scrollUp(delta: int)
    signal scrollDown(delta: int)
    signal movedAway()
    signal rightClicked(point: point)

    // === logic state ===
    property bool hovered: false
    property real lastScrollX: 0
    property real lastScrollY: 0
    property bool trackingScroll: false
    property real moveThreshold: 20

    // 👇 visual/content container
    Item {
        id: contentItem
        anchors.fill: parent
    }

    // 👇 interaction layer
    MouseArea {
        anchors.fill: parent

        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true

        onEntered: root.hovered = true
        onExited: {
            root.hovered = false
            root.trackingScroll = false
        }
        onPressed: {
            root.pressed(mouse)   // emit the pressed signal
        }
        onWheel: event => {
            if (event.angleDelta.y < 0)
                root.scrollDown(event.angleDelta.y)
            else if (event.angleDelta.y > 0)
                root.scrollUp(event.angleDelta.y)

            root.lastScrollX = event.x
            root.lastScrollY = event.y
            root.trackingScroll = true
        }

        onPositionChanged: mouse => {
            if (root.trackingScroll) {
                const dx = mouse.x - root.lastScrollX
                const dy = mouse.y - root.lastScrollY
                if (Math.sqrt(dx * dx + dy * dy) > root.moveThreshold) {
                    root.movedAway()
                    root.trackingScroll = false
                }
            }
        }

        onContainsMouseChanged: {
            if (!containsMouse && root.trackingScroll) {
                root.movedAway()
                root.trackingScroll = false
            }
        }
    }
}