import Quickshell
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    spacing: 4

    Text {
        id: clockTime
        font.pixelSize: 16
        color: colorsPalette.backgroundText
        text: Qt.formatTime(new Date(), "h:mm AP")
    }

    Text {
        font.pixelSize: 14
        color: colorsPalette.backgroundText
        text: "•"
    }

    Text {
        id: clockDate
        font.pixelSize: 14
        color: colorsPalette.backgroundText
        text: Qt.formatDate(new Date(), "ddd, dd/MM")
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            clockTime.text = Qt.formatTime(new Date(), "h:mm AP")
            clockDate.text = Qt.formatDate(new Date(), "ddd, dd/MM")
        }
    }
}