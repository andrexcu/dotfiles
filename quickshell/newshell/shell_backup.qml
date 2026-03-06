// @ pragma UseQApplication

import Quickshell
import QtQuick
import qs.modules.bar
import qs.modules.notification
import qs.colors
import Quickshell.Io
import Quickshell.Wayland 
import Quickshell.Hyprland
// import QtQuick


ShellRoot {
    id: root

    

    property bool isMenuVisible: false
    property bool isPanelVisible: false
          // define notification
    property bool isNotificationPopupVisible: false
    property bool isNotificationPanelVisible: false

    // // Notification Server - Singleton instance
    NotificationServer {
        id: notificationServer
        
        property var notificationsMonitor: notificationServer.notifications
        onNotificationsMonitorChanged: {
        if (notificationServer.notifications.length > 0) {
            if (!isNotificationPopupVisible && !isPanelVisible && !isNotificationPanelVisible) {
            isNotificationPopupVisible = true
            }
        } 
        else {
            if (isNotificationPopupVisible) {
            notificationPopup.shouldAnimate = false
            notifCloseTimer.start()
            }
        }
        }
    }

    // // handlers
    IpcHandler {
        target: "notifications"
        
        function clearAll() {
        notificationServer.clearAll()
        }
    } 


    function closeSecondaryPanels() {
        if (isNotificationPanelVisible) {
        notificationPanel.isShowing = false
        notificationPanelCloseTimer.start()
        } else {
        isNotificationPanelVisible = false
        }
    }
        // auto close notification
        Timer {
        id: notifCloseTimer
        interval: 300
        onTriggered: isNotificationPopupVisible = false
        }
        
    

    Timer {
        id: panelCloseTimer
        interval: 300
        onTriggered: isPanelVisible = false
    }

    // PanelSettings {
    //     id: panelSettings
    //     visible: isPanelVisible

    //     onOpenNotifications: {
    //     isPanelVisible = false
    //     isNotificationPanelVisible = true
    //     }
    //     notifHistory: notificationServer.history
    // }
    Timer {
        id: notificationPanelCloseTimer
        interval: 300
        onTriggered: isNotificationPanelVisible = false
    }
       NotificationPanel {
            id: notificationPanel
            visible: isNotificationPanelVisible
            notifServer: notificationServer
            onRequestClose: {
            notificationPanel.isShowing = false
            notificationPanelCloseTimer.start()
            }
        }

        NotificationPopup {
            id: notificationPopup
            notificationServer: notificationServer
            panelVisible: isPanelVisible || isNotificationPanelVisible
            // dndActive: dndEnabled
        }






    TopBar {
            // id: topBar
            // isOpen: isDashboardVisible
            // isMenuOpen: isMenuVisible
            // anyPanelOpen: isPanelVisible || isWifiPanelVisible || isBluetoothPanelVisible || isAudioPanelVisible || isNotificationPanelVisible || isClipboardPanelVisible

            // closeAllPanels()
            // isMenuVisible: true
            
        }
    CornerConnector{}
    LeftBar{}
    RightBar{}
    BottomBar{}


    
    // // Loader {
    // //     id: barLoader  
    // //     active: true
    // //     sourceComponent: TopBar {}
    // // }
    // // Loader {
    // //     id: cornerConnectorLoader
    // //     active: true
    // //     sourceComponent: CornerConnector {}
    // // }

    // Loader {
    //     id: shellUiLoader
    //     active: true
    //     sourceComponent: Component {
    //         Item {
    //             TopBar { colorsPalette: colors }
    //             CornerConnector { colorsPalette: colors }
    //             // RightBar { colorsPalette: colors }
    //         }
    //     }
    // }
    // Component.onCompleted: {
    //     console.log("Color JSON text:", colors.colorFile.text())
    //     console.log("Parsed colorData:", colors.colorData)
        
    //     if (barLoader.item) {
    //         barLoader.item.colorsPalette = colors
    //     }
    // }
    
     
}

