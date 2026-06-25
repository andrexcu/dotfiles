import QtQuick
import qs.modules.common.components.controls
import qs.services
import Quickshell.Services.Mpris

MenuItem {
    id: root
    required property MprisPlayer modelData

    icon: modelData === Players.active ? "check" : ""
    text: Players.getIdentity(modelData)
    activeIcon: "animated_images"
}