import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.modules.bar
import qs.colors
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects
import qs.modules.bar.islands
import qs.modules.common
import qs.modules.bar.components
import qs.modules.common.widgets
import qs
import qs.modules.sidebarLeft
import qs.modules.common.functions
import Quickshell.Services.UPower
import qs.services

Item {
    
    id: root

    property var screen: root.QsWindow.window?.screen
    // property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    readonly property var brightnessMonitor: screen ? Brightness.getMonitorForScreen(screen) : null
    property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width) ? 2 : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width) ? 1 : 0
    readonly property int centerSideModuleWidth: (useShortenedForm == 2) ? Appearance.sizes.barCenterSideModuleWidthHellaShortened : (useShortenedForm == 1) ? Appearance.sizes.barCenterSideModuleWidthShortened : Appearance.sizes.barCenterSideModuleWidth
    property var colorsPalette: Colors {}
    property real waveformHeight: 14
    component VerticalBarSeparator: Rectangle {
        Layout.topMargin: Appearance.sizes.baseBarHeight / 3
        Layout.bottomMargin: Appearance.sizes.baseBarHeight / 3
        Layout.fillHeight: true
        implicitWidth: 1
        color: Appearance.colors.colOutlineVariant
    }

    // Background shadow
    Loader {
        // active: Config.options.bar.showBackground && Config.options.bar.cornerStyle === 1
        active: true
        anchors.fill: barBackground
        sourceComponent: StyledRectangularShadow {
            anchors.fill: undefined
            target: barBackground
        }
    }

    // Background
    Rectangle {
        id: barBackground
        anchors {
            fill: parent
            margins: Config.options.bar.cornerStyle === 1 ? (Appearance.sizes.hyprlandGapsOut) : 0
        }
        color: colorsPalette.backgroundt70
        // color: "#4D000000"
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
        border.color: "#494949"
    }

    Item { // Left side | scroll to change brightness
        id: barLeftSideMouseArea

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: middleSection.left
        }
        implicitWidth: leftSectionRowLayout.implicitWidth
        implicitHeight: Appearance.sizes.baseBarHeight

        // onScrollDown: root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness - 0.05)
        // onScrollUp: root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness + 0.05)
        // onMovedAway: GlobalStates.osdBrightnessOpen = false
        // onPressed: event => {
        //     if (event.button === Qt.LeftButton)
        //         GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
        // }

     

        RowLayout {
            id: leftSectionRowLayout
            anchors.fill: parent
            z: 0
            spacing: 10

            LeftSidebarButton {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 8 
                colBackground: barLeftSideMouseArea.hovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
            }
            Rectangle {
                id: workspaceIsland
                radius: 14
                color: colorsPalette.backgroundt70
                // color: Appearance.colors.colLayer1
                clip: false
                // color: colorsPalette.surfaceContainer      // same as leftIsland or different if you want
                border.width: 0
                border.color: "#4DFFFFFF"                  // subtle off-white
                property int padding: 6
                Layout.preferredHeight: Appearance.sizes.baseBarHeight * 0.8                  // rectangle height
                Layout.preferredWidth: workspacesLayout.implicitWidth + padding * 1
               
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    blurMax: 1
                    shadowColor: Qt.alpha(colorsPalette.shadow, 0.6)  // adjust opacity
                }
                
                RowLayout {
                    id: workspacesLayout
                    spacing:0
                    Layout.leftMargin: 0
                    anchors.centerIn: parent
                    // anchors.verticalCenter: parent.verticalCenter
                
                    
                    BarWorkspaces {
                        id: workspacesWidget
                        parentBarHeight: Appearance.sizes.baseBarHeight * 0.8
                    
                    }
                }  
            }
            
            Rectangle {
                id: scrollIsland
                radius: 14
                color: colorsPalette.backgroundt70
                clip: false
                border.width: 0
                border.color: "#4DFFFFFF"
                property int padding: 6
                Layout.preferredHeight: Appearance.sizes.baseBarHeight * 0.8
                Layout.preferredWidth: scrollLayout.implicitWidth

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    blurMax: 1
                    shadowColor: Qt.alpha(colorsPalette.shadow, 0.6)
                }

                RowLayout {
                    id: scrollLayout
                    spacing: 0      // <-- reduce space between scrolls
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    // anchors.margins: padding

                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignVCenter  // centers children vertically

                    // Brightness scroll
                    FocusedScrollMouseArea {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: scrollHint.implicitWidth
                        implicitHeight: scrollHint.implicitHeight

                        onScrollDown: root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness - 0.05)
                        onScrollUp: root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness + 0.05)
                        onMovedAway: GlobalStates.osdBrightnessOpen = false
                        onPressed: mouse => {
                            if (mouse.button === Qt.LeftButton)
                                GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen
                        }

                        ScrollHint {
                            id: scrollHint
                            icon: "light_mode"
                            tooltipText: Translation.tr("Scroll to change brightness")
                        }
                    }

                    // Volume scroll
                    FocusedScrollMouseArea {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: scrollHintVolume.implicitWidth
                        implicitHeight: scrollHintVolume.implicitHeight

                        onScrollDown: {
                            const step = Audio.value < 0.1 ? 0.01 : 0.02
                            Audio.sink.audio.volume -= step
                        }
                        onScrollUp: {
                            const step = Audio.value < 0.1 ? 0.01 : 0.02
                            Audio.sink.audio.volume = Math.min(1, Audio.sink.audio.volume + step)
                        }
                        onMovedAway: GlobalStates.osdVolumeOpen = false
                        onPressed: mouse => {
                            if (mouse.button === Qt.LeftButton)
                                GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen
                        }

                        ScrollHint {
                            id: scrollHintVolume
                            icon: "volume_up"
                            tooltipText: Translation.tr("Scroll to change volume")
                        }
                    }
                }
            }        
        }
             // ActiveWindow {
            //     visible: root.useShortenedForm === 0
            //     Layout.rightMargin: Appearance.rounding.screenRounding
            //     Layout.fillWidth: true
            //     Layout.fillHeight: true
            // }
    }

   
            
    //    RowLayout {
    
    //     id: leftCenterGroup
    //     anchors {
    //             top: parent.top
    //             bottom: parent.bottom
    //             // verticalCenter: parent.verticalCenter
    //             centerIn: parent
    //         }
        // Rectangle {
        //     id: workspaceIsland
        //     radius: 10
        //     color: colorsPalette.backgroundt70
        //     clip: false
        //     // color: colorsPalette.surfaceContainer      // same as leftIsland or different if you want
        //     border.width: 1
        //     border.color: "#4DFFFFFF"                  // subtle off-white
        //     property int padding: 6
        //     Layout.preferredHeight: Appearance.sizes.baseBarHeight * 0.8                  // rectangle height
        //     Layout.preferredWidth: workspacesLayout.implicitWidth + padding * 1.5
        //     Layout.alignment: Qt.AlignVCenter
        //     // Layout.leftMargin: 14
        //     layer.enabled: true
        //     layer.effect: MultiEffect {
        //         shadowEnabled: true
        //         blurMax: 1
        //         shadowColor: Qt.alpha(colorsPalette.shadow, 0.6)  // adjust opacity
        //     }
            
        //     RowLayout {
        //         id: workspacesLayout
        //         spacing:0
        //         // anchors.verticalCenter: parent.verticalCenter
            
                
        //         BarWorkspaces {
        //             id: workspacesWidget
        //             parentBarHeight: Appearance.sizes.baseBarHeight * 0.8
                
        //         }
        //     }  
        // }
        // }  
    RowLayout {
        id: centerGroup
        anchors {
            top: parent.top
            bottom: parent.bottom
            // horizontalCenter: parent.horizontalCenter
            centerIn: parent
        }
        spacing: 12   // space between media and player selector

        anchors.margins: 8

        // BarWorkspaces {
        //     id: workspacesWidget
        //     parentBarHeight: Appearance.sizes.baseBarHeight * 0.8
        // }

        Loader {
            id: mediaLoader
            active: true
            visible: active
            sourceComponent: Media {
                waveformHeight: 30
            }
            onLoaded: {
                // mediaLoader.item.barWidth = 300
                // mediaLoader.item.barHeight = root.implicitHeight 
                mediaLoader.item.barHeight = Appearance.sizes.baseBarHeight * 0.8
            }
        }
    
    }

    RowLayout {
        id: rightGroup
        spacing: 12
        //  anchors.verticalCenter: parent.verticalCenter
        // anchors.horizontalCenter: parent.horizontalCenter
        anchors.right: parent.right
        anchors.rightMargin: 0

        Rectangle {
            id: weatherIsland
            radius: 10
            color: colorsPalette.backgroundt70
            border.width: 1
            border.color: "#4DFFFFFF"
        
            property int padding: 10

            Layout.preferredHeight: Appearance.sizes.baseBarHeight * 0.8
            Layout.preferredWidth: weatherLoader.implicitWidth
            layer.enabled: true
            
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 1
                shadowColor: Qt.alpha(colorsPalette.shadow, 0.6)
            }

            RowLayout {

                spacing: 8
            
                anchors.centerIn: parent

                Loader {
                    id: weatherLoader
                    active: true
                    visible: active
                    sourceComponent: WeatherBar {}
                }


            }
        }
        Rectangle {
            id: resourcesIsland
            radius: 10
            color: colorsPalette.backgroundt70
            border.width: 1
            border.color: "#4DFFFFFF"

            property int padding: 10

            Layout.preferredHeight: Appearance.sizes.baseBarHeight * 0.8
            // Layout.preferredWidth: resourceLoader.implicitWidth
            //                     + mediaLoader.implicitWidth
            //                     + padding * 2
            Layout.preferredWidth: resourceLoader.implicitWidth + padding * 2
            layer.enabled: true
            Layout.rightMargin: 120
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 1
                shadowColor: Qt.alpha(colorsPalette.shadow, 0.6)
            }

            RowLayout {

                spacing: 8
            
                anchors.centerIn: parent

                Loader {
                    id: resourceLoader
                    active: true
                    visible: active
                    sourceComponent: Resources {}
                }


            }
        }

    Rectangle {
            id: optionsIsland
            radius: 18
            visible: true
            color: "transparent"
            border.width: 0
            border.color: "#4DFFFFFF"
            property int padding: 0
            
        
            Layout.preferredHeight: root.implicitHeight      
            Layout.preferredWidth: optionsIslandLayout.implicitWidth + padding * 2
            
            Layout.alignment: Qt.AlignVCenter 
            

            // Shadow
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 1
                shadowColor: Qt.alpha(colorsPalette.shadow, 0.6)  
            }
            RowLayout {
                id: optionsIslandLayout
                spacing: 0
                anchors.verticalCenter: parent.verticalCenter

                RightSidebarButton {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    Layout.leftMargin:2
                    Layout.rightMargin:2
                }
                
            }
        }    

    }

}