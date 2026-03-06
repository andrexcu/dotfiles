import QtQuick
import QtQuick.Layouts
import qs.colors

Rectangle {
  id: notifItem
  
  required property var notification
  property var colorsPalette: Colors{}
  
  signal dismissClicked()
  
  height: contentLayout.height + 20
  
  color: colorsPalette.backgroundt70
  
  radius: 8
  border.width: 0
  
  ColumnLayout {
    id: contentLayout
    anchors {
      left: parent.left
      right: parent.right
      top: parent.top
      margins: 10
    }
    spacing: 5
    RowLayout {
      Layout.fillWidth: true
      
      Text {
        text: notification.appName || "Notification"
        color: colorsPalette.primary
        font.pixelSize: 12
        Layout.fillWidth: true
      }
      
      // Close button
      // Rectangle {
      //   width: 20
      //   height: 20
      //   color: closeArea.containsMouse ? Colors.errorContainer : Colors.surfaceContainerHigh
      //   color: colorsPalette.primary
      //   radius: 3
        
      //   Text {
      //     anchors.centerIn: parent
      //     text: "×"
      //     color: "white"
      //     font.pixelSize: 16
      //     font.bold: true
      //   }
        
      //   MouseArea {
      //     id: closeArea
      //     anchors.fill: parent
      //     hoverEnabled: true
      //     onClicked: notifItem.dismissClicked()
      //   }
      // }
    }
    
    Text {
      text: notification.summary || ""
      color: colorsPalette.primary
      font.pixelSize: 14
      font.bold: true
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }
    
    Text {
      text: notification.body || ""
      color: colorsPalette.primary
      font.pixelSize: 12
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
      visible: notification.body !== ""
    }
  }
}
