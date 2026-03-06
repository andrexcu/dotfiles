import QtQuick
import Quickshell.Io
import QtQuick.Layouts 
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import qs.colors
// | Opacity % | Alpha Hex | Color Code  | Transparency %   |
// | --------- | --------- | ----------- | ---------------- |
// | 100%      | FF        | `#FF000000` | 0% transparent   |
// | 90%       | E6        | `#E6000000` | 10% transparent  |
// | 80%       | CC        | `#CC000000` | 20% transparent  |
// | 70%       | B3        | `#B3000000` | 30% transparent  |
// | 60%       | 99        | `#99000000` | 40% transparent  |
// | 50%       | 80        | `#80000000` | 50% transparent  |
// | 40%       | 66        | `#66000000` | 60% transparent  |
// | 30%       | 4D        | `#4D000000` | 70% transparent  |
// | 20%       | 33        | `#33000000` | 80% transparent  |
// | 10%       | 1A        | `#1A000000` | 90% transparent  |
// | 0%        | 00        | `#00000000` | 100% transparent |
PanelWindow {
  id: topBar
//   signal toggleClicked()
//   signal menuClicked()
//   signal panelClicked()
//   signal weatherHovered()
//   signal weatherUnhovered()
//   signal clipboardClicked()

  property bool isOpen: false
  property bool isMenuOpen: false
  property bool anyPanelOpen: false
  anchors { top: true; left: true; right: true }
  implicitHeight: 30
  color: "transparent"
  property var colorsPalette: Colors{}
 
  property int borderHeight: 2

//   Timer {
//     id: batteryHideTimer
//     interval: 200
//     onTriggered: batteryPopup.visible = false
//   }

//   Timer {
//     id: btHideTimer
//     interval: 200
//     onTriggered: btPopup.visible = false
//   }


//   Timer {
//     id: weatherHideTimer
//     interval: 200
//     onTriggered: weatherPopup.visible = false
//   }

//   Timer {
//     id: wifiHideTimer
//     interval: 200
//     onTriggered: wifiPopup.visible = false
//   }

  // Background 
  Rectangle {
    id: topPanel
    anchors.fill: parent
    antialiasing: true
    layer.enabled: true
    color: colorsPalette.backgroundt70
    
    // opacity: 0.7
    
    // gradient: Gradient {
    //   orientation: Gradient.Horizontal 
    //   GradientStop { position: 0.0; color: Colors.isDark ? Colors.surface : Colors.surface }
    //   GradientStop { position: 0.2; color: Colors.isDark ? Colors.overSecondaryFixed : Colors.primaryFixed   }
    //   GradientStop { position: 0.4; color: Colors.isDark ? Colors.surfaceContainerLow : Colors.surface  }
    //   GradientStop { position: 0.6; color: Colors.isDark ? Colors.overPrimaryFixed : Colors.primaryFixed  }
    //   GradientStop { position: 0.8; color: Colors.isDark ? Colors.surface : Colors.surface  }
    //   GradientStop { position: 1.0; color: Colors.isDark ? Colors.overSecondaryFixed : Colors.secondaryFixedDim  }
    // }
        
    Rectangle {
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      height: topBar.borderHeight            
      border.width: 2 
      border.color: colorsPalette.primary

      anchors.leftMargin: 28 
      anchors.rightMargin: 28
    }

    // RowLayout {
    //   anchors.fill: parent
    //   anchors.leftMargin: 15 
    //   anchors.rightMargin: 15
    //   spacing: 11
    //   transform: Translate { y: -1 }

    //   RowLayout {
    //     id: weatherRow
    //     spacing: 4
    //     Layout.alignment: Qt.AlignVCenter
    //     property string wIcon: ""
    //     property string wText: "Loading..."
    //     property string wColor: Colors.overSurfaceVariant

    //   } 
    //   }
  }

  
}
