import QtQuick
import Quickshell
import QtQuick.Controls
import qs
import QtQuick.Layouts
import QtQuick.Shapes
import qs.services
import qs.components
import qs.colors

ColumnLayout {
    id: settingsPanel
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignHCenter
    

    RowLayout {
        id: textContainer
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        visible: wallpaperController.cardVisible
        
        z: 9999
        

        // visible: wallpaperController.cardVisible
        // && wallpaperRepeater.count > 0
        // && wallpaperRepeater.itemAt(wallpaperController.currentIndex).imageReady
        Rectangle {
            anchors.fill: parent
            
            color: "transparent" 
            border.color: "red"       
            border.width: 1
        }

  
        Item {
            id: skewField
            Layout.alignment: Qt.AlignHCenter
            layer.enabled: true
            layer.smooth: true
              
            width: 260
            height: 36

            SkewShape {
                width: 260
                height: 36
                fill: Colors.background
            }
                    
            Item {
                anchors.fill: parent
                clip: false

                TextField {
                    id: searchBox
                    anchors.fill: parent

                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    
                    background: null
                    
                    placeholderText: "Filter Images..."
                    placeholderTextColor: Colors.backgroundText70

                    font.pixelSize: 16
                    font.family: "JetBrainsMono Nerd Font"
                    color: Colors.backgroundText70

                    focus: true
                    cursorVisible: false
                    selectionColor: "transparent"

                    focusPolicy: Qt.StrongFocus
                    activeFocusOnPress: true

                    MouseArea {
                        anchors.fill: parent
                        onPressed: Qt.callLater(() => searchBox.forceActiveFocus())
                    }

                   onTextChanged: {
                    if (!WallpaperService || !WallpaperService.wallpapers)
                        return

                    let list = WallpaperService.wallpapers

                    if (!text || text.length === 0) {
                        filteredWallpapers = list
                    } else {

                        let query = text.toLowerCase()

                        filteredWallpapers = list.filter(function(filePath) {

                            let fileName = filePath.split("/").pop()

                            // remove extension
                            fileName = fileName.replace(/\.[^/.]+$/, "")

                            return fileName.toLowerCase().indexOf(query) !== -1
                        })
                    }

                    if (!wallpaperController)
                        return

                    wallpaperController.currentIndex = 0

                    if (filteredWallpapers.length > 0)
                        selectedWallpaper = filteredWallpapers[0]

                    wallpaperController.requestFrame()
                }
                }
            }
        }

       

        // Button {
        // 	id: rescanBtn
        // 	text: "Rescan"
        // 	onClicked: {
        // 		startListing()
        // 		initTimer.start()
        // 	}
        // 	background: Rectangle {
        // 		radius: 8
        // 		color: rescanBtn.down ? Qt.darker(ColorsurfaceContainer, 1.3) : (rescanBtn.hovered ? Qt.lighter(ColorsurfaceContainer, 1.2) : ColorsurfaceContainer)
        // 		border.color: colorOutline
        // 		border.width: 1
        // 	}
        // 	contentItem: Text {
        // 		text: rescanBtn.text
        // 		color: colorOnSurface
        // 		font.pixelSize: 14
        // 		horizontalAlignment: Text.AlignHCenter
        // 		verticalAlignment: Text.AlignVCenter
        // 		elide: Text.ElideRight
        // 	}
        // }
        // Button {
        // 	id: randomBtn
        // 	text: "Random"
        // 	onClicked: utils.randomWallpaperFisherYates(filteredWallpapers, filteredWallpapers[wallpaperController.currentIndex]);
        // 	background: Rectangle {
        // 		radius: 8
        // 		color: randomBtn.down ? Qt.darker(ColorsurfaceContainer, 1.3) : (randomBtn.hovered ? Qt.lighter(ColorsurfaceContainer, 1.2) : ColorsurfaceContainer)
        // 		border.color: colorOutline
        // 		border.width: 1
        // 	}
        // 	contentItem: Text {
        // 		text: randomBtn.text
        // 		color: colorOnSurface
        // 		font.pixelSize: 14
        // 		horizontalAlignment: Text.AlignHCenter
        // 		verticalAlignment: Text.AlignVCenter
        // 		elide: Text.ElideRight
        // 	}
        // }
        // Button {
        // 	id: settingsBtn
        // 	text: "Settings"
        // 	onClicked: settingsOpen = true
        // 	background: Rectangle {
        // 		radius: 8
        // 		color: settingsBtn.down ? Qt.darker(ColorsurfaceContainer, 1.3) : (settingsBtn.hovered ? Qt.lighter(ColorsurfaceContainer, 1.2) : ColorsurfaceContainer)
        // 		border.color: colorOutline
        // 		border.width: 1
        // 	}
        // 	contentItem: Text {
        // 		text: settingsBtn.text
        // 		color: colorOnSurface
        // 		font.pixelSize: 14
        // 		horizontalAlignment: Text.AlignHCenter
        // 		verticalAlignment: Text.AlignVCenter
        // 		elide: Text.ElideRight
        // 	}
        // }
    }

    RowLayout {
            id: pathTextContainer
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            visible: wallpaperController.cardVisible
            
            z: 9999
            

            // visible: wallpaperController.cardVisible
            // && wallpaperRepeater.count > 0
            // && wallpaperRepeater.itemAt(wallpaperController.currentIndex).imageReady
            Rectangle {
                anchors.fill: parent
                color: "transparent" 
                border.color: "red"       
                border.width: 1
            }

          
            Item {
                id: pathSkewField
                Layout.alignment: Qt.AlignHCenter
                layer.enabled: true
                layer.smooth: true
                
                
                width: 350
                height: 36

                SkewShape {
                    width: 350
                    height: 36
                    fill: Colors.background
                }
                  
            
                Item {
                    anchors.fill: parent
                    clip: false

                    TextField {
                        id: pathTextBox
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10

                        background: null

                        placeholderText: Config.options.wallpaperDir
                        text: Config.options.wallpaperDir
                        placeholderTextColor: Colors.backgroundText70
                        font.pixelSize: 16
                        font.family: "JetBrainsMono Nerd Font"
                        color: Colors.backgroundText70
                        
                        focus: true
                        cursorVisible: false
                        selectionColor: "transparent"

                        focusPolicy: Qt.StrongFocus
                        activeFocusOnPress: true

                        MouseArea {
                            anchors.fill: parent
                            onPressed: Qt.callLater(() => pathTextBox.forceActiveFocus())
                        }
                        
                        onAccepted: {
                             if (!wallpaperController)
                                return       
                            WallpaperService.killAll()
                            wallpaperController.currentIndex = 0
                            let newPath = InputHandler.normalizePath(text)

                            if (newPath && newPath !== Config.options.wallpaperDir) {
                                Config.options.wallpaperDir = newPath
                                WatcherService.wallpaperModel.folder = 
                                "file://" + Config.options.wallpaperDir
                            }
                            
                            
                            
                        }
                            // Qt.callLater(() => {
                            // })
                    }
                }
            }

          

        
        }
    }