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
    
    readonly property int maxWidth: {
        const otherModules = bar.children.filter(c => c.id && c.item !== this && c.id !== "spacer");
        const otherHeight = otherModules.reduce((acc, curr) => acc + (curr.item.nonAnimHeight ?? curr.height), 0);
        // Length - 2 cause repeater counts as a child
        // return bar.height - otherHeight - bar.spacing * (bar.children.length - 1) - bar.vPadding * 2;
        return bar.width - otherHeight - bar.spacing * (bar.children.length - 1) - bar.hPadding * 2;
    }
    property Title current: text1

    clip: true
    // implicitWidth: Math.max(icon.implicitWidth, current.implicitHeight)
    // implicitHeight: icon.implicitHeight + current.implicitWidth + current.anchors.topMargin
    implicitWidth: icon.implicitWidth + current.implicitWidth + Appearance.spacing.small
    implicitHeight: Math.max(icon.implicitHeight, current.implicitHeight)
    MaterialIcon {
        id: icon

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        animate: true
        text: Icons.getAppCategoryIcon(Hypr.activeToplevel?.lastIpcObject.class, "desktop_windows")
        color: root.colour
    }

    Title {
        id: text1
    }

    Title {
        id: text2
    }

    TextMetrics {
        id: metrics

        text: Hypr.activeToplevel?.title ?? qsTr("Desktop")
        font.pointSize: Appearance.font.size.smaller
        font.family: Appearance.font.family.mono
        elide: Qt.ElideRight
        // elideWidth: root.maxHeight - icon.height
        elideWidth: root.maxWidth - icon.width

        onTextChanged: {
            const next = root.current === text1 ? text2 : text1;
            next.text = elidedText;
            root.current = next;
        }
        onElideWidthChanged: root.current.text = elidedText
    }

    Behavior on implicitHeight {
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    component Title: StyledText {
        id: text

        anchors.horizontalCenter: icon.horizontalCenter
        // anchors.top: icon.bottom
        // anchors.topMargin: Appearance.spacing.small
        anchors.left: icon.right
        anchors.leftMargin: Appearance.spacing.small
        anchors.verticalCenter: icon.verticalCenter
        font.pointSize: metrics.font.pointSize
        font.family: metrics.font.family
        color: root.colour
        opacity: root.current === this ? 1 : 0

        // transform: [
        //     Translate {
        //         x: Config.bar.activeWindow.inverted ? -implicitWidth + text.implicitHeight : 0
        //     },
        //     Rotation {
        //         angle: Config.bar.activeWindow.inverted ? 270 : 90
        //         origin.x: text.implicitHeight / 2
        //         origin.y: text.implicitHeight / 2
        //     }
        // ]

        // width: implicitHeight
        // height: implicitWidth
        width: implicitWidth
        height: implicitHeight
        Behavior on opacity {
            Anim {}
        }
    }
}
