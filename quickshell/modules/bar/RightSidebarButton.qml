            
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.colors
import QtQuick.Layouts
            
RippleButton { // Right sidebar button
    id: rightSidebarButton
    visible: Config.options?.bar?.modules?.rightSidebarButton ?? true

    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
    Layout.fillWidth: false

    implicitWidth: indicatorsRowLayout.implicitWidth + 10 * 2
    implicitHeight: indicatorsRowLayout.implicitHeight + 5 * 2

    buttonRadius: Appearance.rounding.full
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.colors.colSecondaryContainerActive

    toggled: GlobalStates.sidebarRightOpen
    property color colText: toggled ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0

    Behavior on colText {
        animation: ColorAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
    }

    onPressed: {
        GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
    }

    RowLayout {
        id: indicatorsRowLayout
        anchors.centerIn: parent
        property real realSpacing: 15
        spacing: 0

        // Revealer {
        //     reveal: Audio.sink?.audio?.muted ?? false
        //     Layout.fillHeight: true
        //     Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
        //     Behavior on Layout.rightMargin {
        //         animation: NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
        //     }
        //     MaterialSymbol {
        //         text: "volume_off"
        //         iconSize: Appearance.font.pixelSize.larger
        //         color: rightSidebarButton.colText
        //     }
        // }
        // Revealer {
        //     reveal: Audio.source?.audio?.muted ?? false
        //     Layout.fillHeight: true
        //     Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
        //     Behavior on Layout.rightMargin {
        //         animation: NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
        //     }
        //     MaterialSymbol {
        //         text: "mic_off"
        //         iconSize: Appearance.font.pixelSize.larger
        //         color: rightSidebarButton.colText
        //     }
        // }
        // HyprlandXkbIndicator {
        //     Layout.alignment: Qt.AlignVCenter
        //     Layout.rightMargin: indicatorsRowLayout.realSpacing
        //     color: rightSidebarButton.colText
        // }
        // Revealer {
        //     reveal: Notifications.silent || Notifications.unread > 0
        //     Layout.fillHeight: true
        //     Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
        //     implicitHeight: reveal ? notificationUnreadCount.implicitHeight : 0
        //     implicitWidth: reveal ? notificationUnreadCount.implicitWidth : 0
        //     Behavior on Layout.rightMargin {
        //         animation: NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
        //     }
        //     NotificationUnreadCount {
        //         id: notificationUnreadCount
        //     }
        // }
        MaterialSymbol {
            text: Network.materialSymbol
            iconSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colOnLayer0
            // color: rightSidebarButton.colText
        }
        // MaterialSymbol {
        //     Layout.leftMargin: indicatorsRowLayout.realSpacing
        //     visible: BluetoothStatus.available
        //     text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
        //     iconSize: Appearance.font.pixelSize.larger
        //     color: rightSidebarButton.colText
        // }
    }
}