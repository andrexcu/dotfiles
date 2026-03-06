import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.colors

PanelWindow {
  id: bottomBar
  anchors { bottom: true; left: true; right: true }
  implicitHeight: 15 
  color: "transparent"
  
  property bool isLaunching: false
  property bool isShowing: false
  property var colorsPalette: Colors {}

  Rectangle {
    anchors.fill: parent
    antialiasing: true
    layer.enabled: true
    color: colorsPalette.background
    // gradient: Gradient {
    //   orientation: Gradient.Horizontal 
    //   GradientStop { position: 0.0; color: Colors.isDark ? Colors.overPrimaryFixed : Colors.primaryFixed }
    //   GradientStop { position: 0.2; color: Colors.isDark ? Colors.surface : Colors.surface  }
    //   GradientStop { position: 0.3; color: Colors.isDark ? Colors.overSecondaryFixed : Colors.primaryFixed }
    //   GradientStop { position: 0.5; color: Colors.isDark ? Colors.surface : Colors.surface }
    //   GradientStop { position: 0.8; color: Colors.isDark ? Colors.overPrimaryFixed : Colors.primaryFixedDim  }
    //   GradientStop { position: 1.0; color: Colors.isDark ? Colors.overPrimaryFixed : Colors.primaryFixedDim }
    // }
        
    Rectangle {
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: 2             
      border.width: 2 
      border.color: colorsPalette.primary
      anchors.leftMargin: 13 
      anchors.rightMargin: 13
    }
  }
}
