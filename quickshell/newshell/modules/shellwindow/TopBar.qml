import QtQuick

Item {
    id: root
    width: 800
    height: 30

    // Just include Background as a child
    Background {
        anchors.fill: parent
        bgColor: "#222222"
        borderColor: "#ff5555"
        borderHeight: 2
        rounding: 12
    }
}