import qs.modules.common.components.controls
import qs.modules.common.components
import qs.services
import Quickshell
import Quickshell.Io
import QtQuick

SplitButton {
    id: playerSelector
    property var barWidth: 150
    disabled: !Players.list.length
    active: menuItems.find(m => m.modelData === Players.active) ?? menuItems[0] ?? null
    menu.onItemSelected: item => Players.manualActive = (item as PlayerItem).modelData
    
    menuItems: playerList.instances
    fallbackIcon: "music_off"
    fallbackText: qsTr("No players")

    menuOnTop: true

    Variants {
        id: playerList

        model: Players.list

        PlayerItem {}
    }
}
        // Image {
        //     id: musicIcon
        //     source: Quickshell.env("HOME") + "/.config/quickshell/icons/music.png"
        //     width: 16
        //     height: 16
        //     fillMode: Image.PreserveAspectFit
        //     anchors.verticalCenter: parent.verticalCenter
        // }
// component PlayerItem: MenuItem {
//     required property MprisPlayer modelData

//     icon: modelData === Players.active ? "check" : ""
//     text: Players.getIdentity(modelData)
//     activeIcon: "animated_images"
// }