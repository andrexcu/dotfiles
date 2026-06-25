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

Scope {
    
id: barScope

    readonly property int osdHideMouseMoveThreshold: 20
    property bool showBarBackground: Config.options.bar.showBackground

    Variants {
        model: {
            const screens = Quickshell.screens;
            const list = Config.options.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }
    
        LazyLoader {
                id: barLoader
                active: GlobalStates.barOpen && !GlobalStates.screenLocked
                required property ShellScreen modelData
                component: PanelWindow {
                id: bar
                
                property var colorsPalette: Colors {}
                property real waveformHeight: 14
                color: "transparent"

                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "quickshell"
                implicitHeight: 36
                anchors { top: true; left: true; right: true }
                // Create the "floating" effect
                
                margins {
                    top: 10
                    left: 12
                    right: 12
                }
                // radius: 18
                //  property var screen: root.QsWindow.window?.screen
                // property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
                
                // MouseArea {
                //     anchors.fill: parent
                //     onClicked: {
                //         GlobalStates.sidebarLeftOpen = false
                //     }
                // }
                component VerticalBarSeparator: Rectangle {
                    // Layout.topMargin: bar.implicitHeight / 4
                    // Layout.bottomMargin: bar.implicitHeight / 4
                    Layout.margins: bar.implicitHeight / 4  
                    Layout.fillHeight: true
                    implicitWidth: 1      // 1 or 2 px for a line
                    color: colorsPalette.outline
                }
                // VerticalBarSeparator {
                //     Layout.alignment: Qt.AlignVCenter
                //     visible: true
                // }
                RowLayout {
                
                    id: leftGroup
                    spacing: 12
                    // Layout.leftMargin: 28
                    // implicitHeight: 40 
                    
                    // LEFT ICON AND ACTIVE WINDOW
                    Rectangle {
                        id: windowIsland
                        radius: 18
                        visible: true
                        color: "transparent"
                        border.width: 0
                        border.color: "#4DFFFFFF"
                        property int padding: 0
                        
                        
                        Layout.preferredHeight: bar.implicitHeight      
                        Layout.preferredWidth: windowIslandLayout.implicitWidth + padding * 2
                        
                        Layout.alignment: Qt.AlignVCenter 
                        

                        // Shadow
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            blurMax: 1
                            shadowColor: Qt.alpha(colorsPalette.shadow, 0.6)  
                        }
                        RowLayout {
                            id: windowIslandLayout
                            spacing: 0
                            anchors.verticalCenter: parent.verticalCenter

                            LeftSidebarButton {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                Layout.leftMargin:2
                                Layout.rightMargin:2
                                sidebarRoot: SidebarLeft.sidebarRoot
                            }
                            
                            // Item {
                            //     Layout.preferredWidth: 300
                            //     Layout.preferredHeight: 32
                            //     Layout.leftMargin: 8
                            //     Layout.rightMargin: 8
                            //     // anchors.centerIn: parent
                            //     clip: true 
                            //     ActiveWindow {
                            //         id: activeWindow
                            //         anchors.fill: parent
                            //     }
                            // }

                        }
                    }    

                    // WORKSPACE ISLAND

                    Rectangle {
                        id: workspaceIsland
                        radius: 10
                        color: colorsPalette.backgroundt70
                        clip: false
                        // color: colorsPalette.surfaceContainer      // same as leftIsland or different if you want
                        border.width: 1
                        border.color: "#4DFFFFFF"                  // subtle off-white
                        property int padding: 6
                        Layout.preferredHeight: bar.implicitHeight                   // rectangle height
                        Layout.preferredWidth: workspacesLayout.implicitWidth + padding * 1.5
                        Layout.alignment: Qt.AlignVCenter
                        // Layout.leftMargin: 14
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            blurMax: 1
                            shadowColor: Qt.alpha(colorsPalette.shadow, 0.6)  // adjust opacity
                        }
                        
                        RowLayout {
                            id: workspacesLayout
                            spacing:0
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.centerIn: parent
                            
                            BarWorkspaces {
                                id: workspacesWidget
                                parentBarHeight: bar.implicitHeight
                            
                            }
                        }  
                    }


            
                    
                    
                }
                        
                    
                RowLayout {
                    id: centerGroup
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12   // space between media and player selector

                    
                    Loader {
                        id: mediaLoader
                        active: true
                        visible: active
                        sourceComponent: Media {
                            waveformHeight: 30
                        }
                        onLoaded: {
                            // mediaLoader.item.barWidth = 300
                            mediaLoader.item.barHeight = bar.implicitHeight
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

                        Layout.preferredHeight: bar.implicitHeight
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

                        Layout.preferredHeight: bar.implicitHeight
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
                        
                    
                        Layout.preferredHeight: bar.implicitHeight      
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
        }
    }
}

