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
        Layout.topMargin: Appearance.sizes.baseBarHeight / 4
        Layout.bottomMargin: Appearance.sizes.baseBarHeight / 4
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
        color: "#4D000000"
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
        border.color: "#494949"
    }

    FocusedScrollMouseArea { // Left side | scroll to change brightness
        id: barLeftSideMouseArea
        
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            // right: parent.right
            // right: middleSection.left
        }

        implicitWidth: leftSectionRowLayout.implicitWidth
        implicitHeight: Appearance.sizes.baseBarHeight
        // implicitWidth: scrollHintBrightness.implicitWidth
        // implicitHeight: scrollHintBrightness.implicitHeight

        onScrollDown: root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness - 0.05)
        onScrollUp: root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness + 0.05)
        onMovedAway: GlobalStates.osdBrightnessOpen = false
        onPressed: mouse => {
            if (mouse.button === Qt.LeftButton)
                GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen
        }
        ScrollHint {
            id: scrollHintBrightness
            z: 999
            reveal: barLeftSideMouseArea.hovered
            icon: "light_mode"
            tooltipText: Translation.tr("Scroll to change brightness")
            side: "left"
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
        }
        
    }

        Item { // Left side | scroll to change brightness
            id: barLeftSideSection
            
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                // right: parent.right
                // right: middleSection.left
            }

            implicitWidth: leftSectionRowLayout.implicitWidth
            implicitHeight: Appearance.sizes.baseBarHeight
            RowLayout {
                    id: leftSectionRowLayout
                    anchors.fill: parent
                    z: 0
                    spacing: 10

                    property int padding: 6
                    LeftSidebarButton {
                        id: leftSidebarButton
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 8 
                        colBackground: barLeftSideSection.hovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
                    }

                    // Rectangle {
                    // id: workspaceIsland
                    // radius: Appearance.rounding.full
                    // // color: colorsPalette.backgroundt30
                    // // color: Appearance.colors.colLayer1
                    // color: "red"
                    // clip: false
                    // // color: colorsPalette.surfaceContainer      // same as leftIsland or different if you want
                    // border.width: 0
                    // border.color: "#4DFFFFFF"                  // subtle off-white
                    // property int padding: 6
                    // Layout.preferredHeight: Appearance.sizes.baseBarHeight * 0.8                  // rectangle height
                    // Layout.preferredWidth: workspacesLayout.implicitWidth + padding * 1
                    
                    
                    // // layer.enabled: true
                    // // layer.effect: MultiEffect {
                    // //     shadowEnabled: true
                    // //     blurMax: 1
                    // //     shadowColor: Qt.alpha(colorsPalette.shadow, 0.6)  // adjust opacity
                    // // }
                    
                     BarGroup {
                        id: workspacesGroup
                        Layout.preferredWidth: workspacesWidget.implicitWidth + padding
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignVCenter
                        implicitHeight: Appearance.sizes.baseBarHeight * 0.8
                    
                            
                        BarWorkspaces {
                            id: workspacesWidget
                            Layout.fillHeight: true
                    
                        }
                     }  

                     
                
                VerticalBarSeparator {
                    // visible: Config.options?.bar.borderless
                    // visible: false
                }
            
               BarGroup {
                    id: leftCenterGroup
                    Layout.preferredWidth: root.centerSideModuleWidth
                    Layout.fillHeight: false

                    Media {
                        visible: root.useShortenedForm < 2
                        Layout.fillWidth: true
                    }
                }
            }
               
            }      
            // Rectangle {
            //     id: scrollIsland
            //     radius: Appearance.rounding.full
            //     // color: colorsPalette.backgroundt30
            //     color: Appearance.colors.colLayer1
                
            //     clip: false
            //     border.width: 0
            //     border.color: "#4DFFFFFF"
            //     property int padding: 6
            //     Layout.preferredHeight: Appearance.sizes.baseBarHeight * 0.8
            //     Layout.preferredWidth: scrollLayout.implicitWidth
            //     visible: false
            //     layer.enabled: true
            //     layer.effect: MultiEffect {
            //         shadowEnabled: true
            //         blurMax: 1
            //         shadowColor: Qt.alpha(colorsPalette.shadow, 0.6)
            //     }
             
            //     RowLayout {
            //         id: scrollLayout
            //         spacing: 0      // <-- reduce space between scrolls
            //         anchors.top: parent.top
            //         anchors.bottom: parent.bottom
            //         anchors.left: parent.left
            //         anchors.right: parent.right
                    
            //         // anchors.margins: padding

            //         Layout.fillHeight: false
            //         Layout.alignment: Qt.AlignVCenter  // centers children vertically
                    
                  
            //         FocusedScrollMouseArea {
            //             id: brightnessScrollArea
            //             property string tooltipText: Translation.tr("Scroll to change brightness")  // new property

            //             Layout.alignment: Qt.AlignVCenter
            //             implicitWidth: scrollHintBrightness.implicitWidth
            //             implicitHeight: scrollHintBrightness.implicitHeight

            //             onScrollDown: root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness - 0.05)
            //             onScrollUp: root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness + 0.05)
            //             onMovedAway: GlobalStates.osdBrightnessOpen = false
            //             onPressed: mouse => {
            //                 if (mouse.button === Qt.LeftButton)
            //                     GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen
            //             }
         
            //             StyledToolTip {
            //                 id: brightnessTooltip
            //                 text: Translation.tr("Scroll to change brightness")
            //                 visible: brightnessScrollArea.hovered // initially hidden
            //                 focus: false           // never receive keyboard focus
            //                 enabled: false
            //             }  

            //             ScrollHint {
            //                 id: scrollHintBrightness
            //                 icon: "light_mode"
            //             }

            //             // Tooltip for the entire scroll area
                       
                      
            //         }   

                      
            //         // Volume scroll
            //         FocusedScrollMouseArea {
            //             id: volumeScrollArea
            //             Layout.alignment: Qt.AlignVCenter
            //             implicitWidth: scrollHintVolume.implicitWidth
            //             implicitHeight: scrollHintVolume.implicitHeight

            //             onScrollDown: {
            //                 const step = Audio.value < 0.1 ? 0.01 : 0.02
            //                 Audio.sink.audio.volume -= step
            //             }
            //             onScrollUp: {
            //                 const step = Audio.value < 0.1 ? 0.01 : 0.02
            //                 Audio.sink.audio.volume = Math.min(1, Audio.sink.audio.volume + step)
            //             }
            //             onMovedAway: GlobalStates.osdVolumeOpen = false
            //             // onPressed: mouse => {
            //             //     if (mouse.button === Qt.LeftButton)
            //             //         GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen
            //             // }
            //             StyledToolTip {
            //                 id: volumeTooltip
            //                 text: Translation.tr("Scroll to change volume")
            //                 visible: volumeScrollArea.hovered // initially hidden
            //                 focus: false           // never receive keyboard focus
            //                 enabled: false
            //             }  
            //             ScrollHint {
            //                 id: scrollHintVolume
            //                 icon: "volume_up"
            //             }
            //         }
            //     }
                  
            // }   
               
        
            
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
            id: activeWindowLoader
            active: true
            visible: active
            sourceComponent: ActiveWindow {
                waveformHeight: 30
            }
            onLoaded: {
                // mediaLoader.item.barWidth = 300
                // mediaLoader.item.barHeight = root.implicitHeight 
                activeWindowLoader.item.barHeight = Appearance.sizes.baseBarHeight
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
            radius: Appearance.rounding.full
            // color: colorsPalette.backgroundt30
            color: Appearance.colors.colLayer1
            border.width: 0
            border.color: "#4DFFFFFF"
        
            property int padding: 10

            Layout.preferredHeight: Appearance.sizes.baseBarHeight * 0.8
            Layout.preferredWidth: weatherLoader.implicitWidth
            // layer.enabled: true
            
            // layer.effect: MultiEffect {
            //     shadowEnabled: true
            //     blurMax: 1
            //     shadowColor: Qt.alpha(colorsPalette.shadow, 0.6)
            // }

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
            radius: Appearance.rounding.full
            // color: colorsPalette.backgroundt30
            color: Appearance.colors.colLayer1
            border.width: 0
            border.color: "#4DFFFFFF"

            property int padding: 10

            Layout.preferredHeight: Appearance.sizes.baseBarHeight * 0.8
            // Layout.preferredWidth: resourceLoader.implicitWidth
            //                     + mediaLoader.implicitWidth
            //                     + padding * 2
            Layout.preferredWidth: resourceLoader.implicitWidth + padding * 2
            Layout.rightMargin: 120
            // layer.enabled: true
            // layer.effect: MultiEffect {
            //     shadowEnabled: true
            //     blurMax: 1
            //     shadowColor: Qt.alpha(colorsPalette.shadow, 0.6)
            // }

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
            radius: Appearance.rounding.full
            visible: true
            color: "transparent"
            border.width: 0
            border.color: "#4DFFFFFF"
            property int padding: 0
            
        
            Layout.preferredHeight: root.implicitHeight      
            Layout.preferredWidth: optionsIslandLayout.implicitWidth + padding * 2
            
            Layout.alignment: Qt.AlignVCenter 
            

            // Shadow
            // layer.enabled: true
            // layer.effect: MultiEffect {
            //     shadowEnabled: true
            //     blurMax: 1
            //     shadowColor: Qt.alpha(colorsPalette.shadow, 0.6)  
            // }
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