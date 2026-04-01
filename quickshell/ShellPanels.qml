import qs.modules.sidebarLeft

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.screenCorners
import qs.modules.onScreenDisplay
import qs.modules.bar
import qs.modules.mediaControls
import "."

Item {
    id: panelsRoot
    component PanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready && (Config.options?.enabledPanels ?? []).includes(identifier) && extraCondition
    }

    // ii style (Material)
   
    // PanelLoader { identifier: "iiScreenCorners"; component: ScreenCorners {} }
    // PanelLoader { identifier: "iiSessionScreen"; component: SessionScreen {} }
    PanelLoader { identifier: "iiBar"; component: Bar {} }
    PanelLoader { identifier: "iiMediaControls"; component: MediaControls {} }
    PanelLoader { identifier: "iiSidebarLeft"; component: SidebarLeft {} }
    PanelLoader { identifier: "iiScreenCorners"; component: ScreenCorners {} }
    PanelLoader { identifier: "iiOnScreenDisplay"; component: OnScreenDisplay {} }
    

    // PanelLoader { identifier: "iiSidebarRight"; component: SidebarRight {} }

    
}
