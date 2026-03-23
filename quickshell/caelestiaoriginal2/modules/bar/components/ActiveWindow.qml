pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.utils
import qs.config
import QtQuick

Item {
    id: root

    required property var bar
    required property Brightness.Monitor monitor
    property color colour: Colours.palette.m3primary

    readonly property int maxWidth: root.implicitWidth * 0.8
    property Title current: text1

    clip: true

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight


    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.small

        MaterialIcon {
            id: icon
            animate: true
            text: Icons.getAppCategoryIcon(Hypr.activeToplevel?.lastIpcObject.class, "desktop_windows")
            color: root.colour
        }

        Item {
            id: textContainer
            height: icon.height
            implicitWidth: current.implicitWidth

            Title { id: text1 }
            Title { id: text2 }
        }
    }


    TextMetrics {
        id: metrics

        text: Hypr.activeToplevel?.title ?? qsTr("Desktop")
        font.pointSize: Appearance.font.size.smaller
        font.family: Appearance.font.family.mono
        elide: Qt.ElideRight
        elideWidth: root.maxWidth

        onTextChanged: {
            const next = root.current === text1 ? text2 : text1
            next.text = elidedText
            root.current = next
        }

        onElideWidthChanged: root.current.text = elidedText
    }


    Behavior on implicitWidth {
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }


    component Title: StyledText {
        anchors.verticalCenter: parent.verticalCenter

        font.pointSize: metrics.font.pointSize
        font.family: metrics.font.family
        color: root.colour

        opacity: root.current === this ? 1 : 0

        width: implicitWidth
        height: implicitHeight

        Behavior on opacity {
            Anim {}
        }
    }
}
