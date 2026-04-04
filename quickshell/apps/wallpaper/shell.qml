// @ pragma UseQApplication

import Quickshell
import QtQuick
import qs.selector
import qs.colors
import qs.components
import Quickshell.Wayland

ShellRoot {
    id: root  
    Loader {
        id: wallpaperSelectorLoader
        active: true
        source: "selector/Selector.qml"
   }  
}