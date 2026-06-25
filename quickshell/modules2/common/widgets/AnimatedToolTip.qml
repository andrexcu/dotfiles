import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    property string text: ""
    property bool show: false
    property int delay: 300
    property int timeout: 3000
    property real padding: 8

    Timer {
        id: showTimer
        interval: root.delay
        repeat: false
        onTriggered: tooltip.visible = true
    }

    Timer {
        id: hideTimer
        interval: root.timeout
        repeat: false
        onTriggered: tooltip.visible = false
    }

    Rectangle {
        id: tooltip
        color: "#2b2b2b"
        radius: 6
        opacity: 0
        visible: false
        anchors.top: parent.bottom
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        z: 999

        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        scale: visible ? 1.0 : 0.85

        // Add padding by using anchors + implicitWidth/Height
        width: tooltipText.implicitWidth + 2*root.padding
        height: tooltipText.implicitHeight + 2*root.padding

        Text {
            id: tooltipText
            text: root.text
            color: "white"
            font.pixelSize: 14
            wrapMode: Text.Wrap
            anchors.centerIn: parent
        }
    }

    onShowChanged: {
        showTimer.stop()
        hideTimer.stop()
        tooltip.visible = false
        if (show) showTimer.start()
    }

    Connections {
        target: tooltip
        onVisibleChanged: {
            if (tooltip.visible) hideTimer.start()
            else { showTimer.stop(); hideTimer.stop(); }
        }
    }
}