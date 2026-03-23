import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.colors
import qs.modules.sidebarLeft

RippleButton {
    id: root

    property bool showPing: false
    property var colorsPalette: Colors{}

    property real buttonPadding: 5

    property PanelWindow sidebarRoot

    implicitWidth: distroIcon.width + buttonPadding * 2
    implicitHeight: distroIcon.height + buttonPadding * 2
    buttonRadius: Appearance.rounding.full
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.colors.colSecondaryContainerActive
    toggled: GlobalStates.sidebarLeftOpen

    onPressed: {
        GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen
        // console.log("clicked, sidebar open:", GlobalStates.sidebarLeftOpen)
    }
    focus: GlobalStates.sidebarLeftOpen
    // Keys.onPressed: (event) => {
    //     if (event.key === Qt.Key_Escape) {
    //         sidebarRoot.hide();
    //     }
    // }
 
    // onPressed: {
    //     GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen
    //     if (!GlobalStates.sidebarLeftOpen && sidebarRoot) {
    //         sidebarRoot.hide()   // now safe
    //     }
    //     console.log("clicked, sidebar open:", GlobalStates.sidebarLeftOpen)
    // }
    // Connections {
    //     target: Ai
    //     function onResponseFinished() {
    //         if (GlobalStates.sidebarLeftOpen) return;
    //         root.showPing = true;
    //     }
    // }

    // Connections {
    //     target: Booru
    //     function onResponseFinished() {
    //         if (GlobalStates.sidebarLeftOpen) return;
    //         root.showPing = true;
    //     }
    // }

    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() {
            root.showPing = false;
        }
    }

    CustomIcon {
        id: distroIcon
        anchors.centerIn: parent
        // width: 19.5
        // height: 19.5
       
        width: 22.5
        height: 22.5
        // source: Config.options.bar.topLeftIcon == 'distro' ? SystemInfo.distroIcon : `${Config.options.bar.topLeftIcon}-symbolic`
        source: `${Config.options.bar.topLeftIcon}-symbolic`
        colorize: true
        // color:  "red"
        color: Appearance.colors.colOnLayer0
        // color: colorsPalette.primary
        // opacity: 0.9
        // color: "#1A000000"
        
        Rectangle {
            opacity: root.showPing ? 1 : 0
            visible: opacity > 0
            anchors {
                bottom: parent.bottom
                right: parent.right
                bottomMargin: -2
                rightMargin: -2
            }
            implicitWidth: 8
            implicitHeight: 8
            radius: Appearance.rounding.full
            color: Appearance.colors.colTertiary

            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }
}
