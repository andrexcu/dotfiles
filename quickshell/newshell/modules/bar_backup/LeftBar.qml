import QtQuick
import Quickshell
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import qs.colors

PanelWindow {
  id: leftBar
  anchors { top: true; bottom: true; left: true }
  implicitWidth: 15
  color: colorsPalette.background
  property var colorsPalette: Colors {}

  property bool isShowing: false
  property bool menuVisible: false
  property bool launcherVisible: false


  Rectangle {
    anchors.fill: parent
    antialiasing: true
    layer.enabled: true
    color: "transparent"
   

    Rectangle {
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: 2
      border.width: 2 
      border.color: colorsPalette.primary
      
      anchors.topMargin: 13
      anchors.bottomMargin: 12
    }
  }
}
  