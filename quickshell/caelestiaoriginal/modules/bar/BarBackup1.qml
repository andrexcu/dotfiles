pragma ComponentBehavior: Bound

import qs.services
import qs.config
import "popouts" as BarPopouts
import "components"
// import "components/workspaces"
import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.baritems
import qs.modules.baritems.islands
import qs.modules.common
import qs.colors
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

RowLayout {
    
    id: root
    spacing: 0
    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property BarPopouts.Wrapper popouts
   
    Layout.leftMargin: 28
    implicitHeight: 40   // bar height
    property var colorsPalette: Colors{}
   
    // GROUPED ISLAND
    Rectangle {
        id: leftIsland
        radius: 14
        color: "transparent"
        border.width: 0
        border.color: "#33FFFFFF"
        property int padding: 8

        Layout.preferredHeight: 32            // rectangle height
        Layout.preferredWidth: leftIslandLayout.implicitWidth + padding * 2

        // anchors.verticalCenter: parent.verticalCenter  // vertically center in the bar
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 24

        
        RowLayout {
            id: leftIslandLayout
             z: 999
            spacing: 6
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: leftIsland.padding

            LeftSidebarButton {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
            }

            Item {
                Layout.preferredWidth: 130
                Layout.preferredHeight: 32
                ActiveWindow {
                    anchors.fill: parent
                }
            }
        }
    }
   
    Rectangle {
        id: workspaceIsland
        radius: 14
        color: colorsPalette.surfaceContainer      // same as leftIsland or different if you want
         MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
    }
        border.width: 1
        border.color: "#33FFFFFF"                  // subtle off-white
        property int padding: 8

        Layout.preferredHeight: 32                  // rectangle height
        Layout.preferredWidth: workspacesLayout.implicitWidth + padding
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 0
        
        RowLayout {
            id: workspacesLayout
            spacing:0
            anchors.verticalCenter: parent.verticalCenter
            // anchors.left: parent.left
            // anchors.right: parent.right
            // anchors.margins: workspaceIsland.padding
            // anchors.centerIn: parent
            Layout.fillWidth: true
            BarWorkspaces {
                id: workspacesWidget
                parentBarHeight: root.implicitHeight
            }
      
        }
    }    
}
   
    // TIME ISLAND
    // Rectangle {
    //     id: timeIsland
    //     radius: 14
    //     color: colorsPalette.surfaceContainer         // background color
    //     border.width: 1
    //     border.color: "#33FFFFFF"                     // subtle off-white border
    //     property int padding: 8

    //     Layout.preferredHeight: 32                     // rectangle height
    //     Layout.preferredWidth: timeLayout.implicitWidth + padding * 2
    //     anchors.verticalCenter: parent.verticalCenter
    //     Layout.leftMargin: 12

    //     RowLayout {
    //         id: timeLayout
    //         spacing: 4
    //         anchors.verticalCenter: parent.verticalCenter
    //         anchors.left: parent.left
    //         anchors.right: parent.right
    //         anchors.margins: timeIsland.padding

    //         Text {
    //             id: clockTime
    //             font.pixelSize: 16
    //             color: colorsPalette.backgroundText
    //             text: Qt.formatTime(new Date(), "h:mm AP")
    //         }

    //         Text {
    //             id: separator
    //             font.pixelSize: 14
    //             color: colorsPalette.backgroundText
    //             text: "•"
    //         }

    //         Text {
    //             id: clockDate
    //             font.pixelSize: 14
    //             color: colorsPalette.backgroundText
    //             text: Qt.formatDate(new Date(), "ddd, dd/MM")
    //         }

    //         Timer {
    //             interval: 1000
    //             running: true
    //             repeat: true
    //             onTriggered: {
    //                 clockTime.text = Qt.formatTime(new Date(), "h:mm AP")
    //                 clockDate.text = Qt.formatDate(new Date(), "ddd, dd/MM")
    //             }
    //         }
    //     }
    // }
    

 
    // BarGroup {
    //     id: workspacesGroup
    //     padding: 4
    //     Layout.alignment: Qt.AlignVCenter
    //     Layout.preferredWidth: workspacesWidget.implicitWidth
    //     Layout.preferredHeight: workspacesWidget.implicitHeight

    //     Workspaces {
    //         id: workspacesWidget
    //         parentBarHeight: root.implicitHeight
    //     }
    // }

