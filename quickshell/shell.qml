import Quickshell
import QtQuick
import qs.modules.bar
import qs.modules.mediaControls
import qs.services
import qs.modules.sidebarLeft

ShellRoot {
    id: root
    // Bar {}
    // MediaControls {}
    

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
    }
    LazyLoader {

        active: true

        component: ShellPanels {}
    } 
}
