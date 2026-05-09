import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Effects
import QtCore
import Quickshell.Wayland
import qs.components
import Quickshell
import Quickshell.Io as Io
import Quickshell.Hyprland
import QtQuick.Window
import Quickshell.Widgets
import qs.colors
import Qt.labs.platform
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import qs.selector
import qs
import qs.services

Scope {
	id: wallpaperController

	// =======================
	// CONFIGURATION
	// =======================
	// property var colors: Colors {}
	
	// property var WallpaperService.wallpapers: WallpaperService.wallpapers   // initially same as full list
	property string selectedWallpaper: ""
	property string lastError: ""
	

	// Boolean
	property bool hasFfmpeg: false
	property bool hasMatugen: false
	property bool settingsOpen: false
	property bool selectorOpen: false
	property bool showDelegateBorder: true
	property bool cardVisible: false
	property bool _previousSelectedHex: false
	property bool framePending: false
	property bool isContentVisible: true
	
	// tracking items
	property Item currentSelected: null

	
	property string homeDir: ""
	property string wallpaperDir: ""
	property string savedWallpaperDir: ""


	property var selectedVisual: wallpaperController.currentSelected
								&& wallpaperController.currentSelected.visualWrapperRef
								? wallpaperController.currentSelected.visualWrapperRef
								: null


	
	

	Timer {
		id: cardShowTimer
		interval: 50
		onTriggered: wallpaperController.cardVisible = true
	}

	Timer {
		id: focusTimer
		interval: 0
		repeat: false
		onTriggered: {
			WallpaperService.homeProcess.exec(["sh","-c","echo $HOME"])
		}
	}


	Component.onCompleted: {  

		cardShowTimer.start()
		

			console.log(
				"columns: ", WatcherService.columns,
				"rows: ", WatcherService.rows,
				// "walldir: ", Config.options.wallpaperDir,
				// "pixel effect:", Config.options.effects.pixel
			)
	}

	property bool blurTransition: false

	Timer {
		id: imgBlurInTimer
		interval: 150
		repeat: false
		onTriggered: {
			imgBlurOutTimer.restart()
		}
	}

	Timer {
		id: imgBlurOutTimer
		interval: 50
		repeat: false
		onTriggered: wallpaperController.blurTransition = false
	
	}

	Timer {
		id: scaleDelayTimer
		interval: 400 
		repeat: false
		onTriggered: {
			if (wallpaperController.currentSelected) {
				wallpaperController.currentSelected.visualWrapperRef.visualScale = 1.15
			} 
		}
	}

	function runFrame() {
		hexListView.updateGridFocusOffset()
	}
	
	function requestFrame() {
		if (framePending) return
		framePending = true

		Qt.callLater(() => {
			framePending = false
			wallpaperController.runFrame()
		})
	}

	function runUpdateShift() {
		var sel = wallpaperController.selectedItem
		if (sel && sel.updateShift)
			sel.updateShift()
	}

	// computed values
	property int currentIndex: 0
	property int previousIndex: 0

	property Item currentItem: null
	property Item previousItem: null
	property real currentTargetX
	property real currentTargetY

	property bool isSelected: false
		


	property real currentItemX
	property real currentItemY

	
	property bool _flipLock: false
	Connections {
    target: wallpaperController
	
    function onCurrentIndexChanged() {
			if(Config.options.effects.blur) {
				wallpaperController.blurTransition = true
				imgBlurInTimer.restart()
			}
			
		}
	}

	property int hexRadius: 105
	Behavior on hexRadius { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }
	property int hexRows: WallpaperService.rows
	Behavior on hexRows { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }
	property int hexCols: WallpaperService.columns
	Behavior on hexCols { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }


	property int cardHeight: hexGridHeight
	property int hexCardWidth: selectorPanel.width
	property int cardWidth: hexCardWidth
	Behavior on cardWidth { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }
	property int hexGridHeight: {
		var rows = hexRows
		var r = hexRadius
		var spacing = 6
		var hexH = Math.ceil(r * 1.73205)
		var stepY = hexH + spacing
		var contentH = (rows - 1) * stepY + hexH + hexH / 2
		return contentH + 90
	}
	
  Behavior on cardHeight { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }
    PanelWindow {
        id: selectorPanel
		objectName: "wallpaper-selector"
        screen: Quickshell.screens[0]
		anchors {
			top: true
			bottom: true
			left: true
			right: true
		}
		margins {
		top: 0
		bottom: 0
		left: 0
		right: 0
		}
		color: "transparent"

		HyprlandFocusGrab {
			windows: [ selectorPanel ]
			active: wallpaperController.cardVisible
		}
		WlrLayershell.namespace: "wallpaper-selector-parallel"
		WlrLayershell.layer: WlrLayer.Overlay
		// visible: wallpaperController.cardVisible
		
		WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
		
		exclusionMode: ExclusionMode.Ignore

		Shortcut {
			sequence: "Escape"
			onActivated: {
				wallpaperController.cardVisible = false
				
				WallpaperService.selectorQuit()
			}
		}
		DimOverlay {
			active: wallpaperController.cardVisible
			// active: false
		}


		MouseArea {
		anchors.fill: parent
		onClicked: {
				wallpaperController.cardVisible = false
				WallpaperService.selectorQuit()
				
		}
		}
	
//   ColumnLayout {
// 	// anchors.fill: parent
// 	anchors.centerIn: parent
// 	anchors.margins: 16
// 	spacing: 16
	
 Item {
	id: cardContainer
	visible: wallpaperController.cardVisible
	width: wallpaperController.cardWidth
	height: wallpaperController.cardHeight
	Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
	anchors.centerIn: parent
	opacity: 0
	// testing
	Rectangle {
        anchors.fill: parent
        color: "transparent" 
        border.color: "red"       
        border.width: 1
    }
	property bool animateIn: wallpaperController.cardVisible

    onAnimateInChanged: {
      if (animateIn) {
        opacity = 1
        focusTimer.restart()
        // wallpaperSelector.uiReady()
      }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }
						
		// opacity: wallpaperController.cardVisible ? 1 : 0

		// Behavior on opacity {
		// 	NumberAnimation {
		// 		duration: 150
		// 		easing.type: Easing.InOutQuad
		// 	}
		// }
		Rectangle {
			id: selectorState
			// visible: wallpaperController.cardVisible
			// STATE
			property bool isLoading: !WatcherService.thumbsGenerated && !WatcherService.pathEmpty
			property bool isEmpty: !WatcherService.thumbsGenerated && WatcherService.pathEmpty
			property bool isDone: WatcherService.thumbsGenerated

			opacity: wallpaperController.cardVisible ? 1 : 0

			Behavior on opacity {
				NumberAnimation {
					duration: 150
					easing.type: Easing.InOutQuad
				}
			}

			anchors.centerIn: parent
			color: "transparent"
			border.color: "red"
			border.width: 1

			ColumnLayout {
				anchors.centerIn: parent
				spacing: 26

				// ICON
				Text {
					id: spinner

					text: selectorState.isLoading ? "ⴵ"
						: selectorState.isEmpty  ? "(⋟﹏⋞)"
						: ""

					font.pixelSize: selectorState.isLoading ? 135 : 30
					color: Colors.primary

					property real rot: 0
					rotation: selectorState.isLoading ? rot : 0

					horizontalAlignment: Text.AlignHCenter
					Layout.alignment: Qt.AlignHCenter

					// IMPORTANT: base opacity for non-loading
					opacity: selectorState.isLoading ? spinnerOpacity : 1
					property real spinnerOpacity: 1

					NumberAnimation on rot {
						from: 0
						to: 360
						duration: 2500
						loops: Animation.Infinite
						running: selectorState.isLoading
					}

					SequentialAnimation on spinnerOpacity {
						loops: Animation.Infinite
						running: selectorState.isLoading
						NumberAnimation { to: 0.3; duration: 1400 }
						NumberAnimation { to: 0.85; duration: 1400 }
					}
				}

				// PROGRESS BAR
				ProgressBar {
					id: bar
					from: 0
					to: WatcherService.total
					value: WatcherService.current

					width: cardContainer.width * 0.25
					height: 6

					visible: selectorState.isLoading

					background: Rectangle {
						color: Colors.background
						radius: 3
						height: 6
					}

					contentItem: Rectangle {
						width: bar.visualPosition * bar.width
						height: 6
						radius: 3
						color: Colors.primary
					}
				}

				// TEXT
				Text {
					text: selectorState.isLoading
							? WatcherService.current + " / " + WatcherService.total
						: selectorState.isEmpty
							? "No Wallpapers Found."
						: ""

					color: Colors.primary
					font.pixelSize: 20

					horizontalAlignment: Text.AlignHCenter
					Layout.alignment: Qt.AlignHCenter
				}
			}
		}
 	}
	
	


    // Item {
    //     id: keyRoot
    //     anchors.fill: parent
    //     focus: true
	// 	clip: false
    	

	// ColumnLayout {
	// 	anchors.fill: parent
	// 	anchors.leftMargin: 16
	// 	anchors.rightMargin: 16
	// 	anchors.margins: 16
	// 	clip: false
	
		// Error message
		// Rectangle {
		// 	visible: isContentVisible && lastError !== ""
		// 	color: colorError
		// 	radius: 4
		// 	height: 40
		// 	Layout.fillWidth: true

		// 	Text {
		// 		text: lastError
		// 		color: colorOnSurface
		// 		font.pixelSize: 12
		// 		anchors.centerIn: parent
		// 	}
		// }

		
			// visible: wallpaperController.cardVisible
			// visible: wallpaperController.rowsChanged || wallpaperController.columnsChanged
			// opacity: WatcherService.thumbsGenerated ? 1 : 0
			// Behavior on opacity { 
			// 	NumberAnimation { 
			// 		duration: 350; 
			// 		easing.type: Easing.InOutQuad 
			// 	} 
			// }
	// 			Rectangle {
    //     anchors.fill: parent
    //     color: "transparent" 
    //     border.color: "red"       
    //     border.width: 1
    // }
		ListView {
			id: hexListView
			visible: wallpaperController.cardVisible
			anchors.top: cardContainer.top
			anchors.topMargin: 35
			anchors.bottom: cardContainer.bottom
			anchors.bottomMargin: 20
			anchors.left: cardContainer.left
			anchors.right: cardContainer.right
			
			boundsBehavior: Flickable.StopAtBounds
			flickDeceleration: 1500
			// cacheBuffer: _stepX * 2
			orientation: ListView.Horizontal
			// flickableDirection: Flickable.HorizontalFlick
			maximumFlickVelocity: 3000
			
			clip: true
			
			focus: true

			property int _rows: wallpaperController.hexRows
			property real _r: wallpaperController.hexRadius
			property real _gridSpacing: 6
			property real _hexW: _r * 2
			property real _hexH: Math.ceil(_r * 1.73205)
			property real _stepX: 1.5 * _r + _gridSpacing
			property real _stepY: _hexH + _gridSpacing
			property real _gridContentH: (_rows - 1) * _stepY + _hexH + _hexH / 2
			property real _yOffset: Math.max(0, (height - _gridContentH) / 2)
			property real _visibleBand: (wallpaperController.hexCols - 1) * _stepX + _hexW
			property real _fadeZone: (width - _visibleBand) / 2

			model: Math.ceil((WallpaperService.wallpapers ? WallpaperService.wallpapers.count : 0) / Math.max(1, _rows))
			
			property int _selectedCol: currentIndex
      		property int _selectedRow: 0
			
			onCountChanged: {
				if (count > 0 && visible) {
				var startCol = Math.min(Math.floor(wallpaperController.hexCols / 2), count - 1)
				if (startCol >= 0) { currentIndex = startCol; _selectedCol = startCol; _selectedRow = 0 }
				}
			}
			spacing: 0

			highlightFollowsCurrentItem: true
			highlightMoveDuration: Style.animExpand
			highlight: Item {}
			preferredHighlightBegin: (width - _hexW) / 2
			preferredHighlightEnd: (width + _hexW) / 2
			highlightRangeMode: ListView.StrictlyEnforceRange

			header: Item { width: (hexListView.width - hexListView._hexW) / 2 }
			footer: Item { width: (hexListView.width - hexListView._hexW) / 2 }

			add: Transition {
				NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Style.animEnter; easing.type: Easing.OutCubic }
				NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: Style.animEnter; easing.type: Easing.OutCubic }
			}
			remove: Transition {
				NumberAnimation { property: "opacity"; to: 0; duration: Style.animNormal; easing.type: Easing.InCubic }
			}
			displaced: Transition {
				NumberAnimation { properties: "x,y"; duration: Style.animMedium; easing.type: Easing.OutCubic }
			}

			MouseArea {
				anchors.fill: parent
				propagateComposedEvents: true
				onWheel: function(wheel) {
				var step = 1
				if (wheel.angleDelta.y > 0 || wheel.angleDelta.x > 0) {
					hexListView.currentIndex = Math.max(0, hexListView.currentIndex - step)
					hexListView._selectedCol = hexListView.currentIndex
				} else if (wheel.angleDelta.y < 0 || wheel.angleDelta.x < 0) {
					hexListView.currentIndex = Math.min(hexListView.count - 1, hexListView.currentIndex + step)
					hexListView._selectedCol = hexListView.currentIndex
				}
				}
				onPressed: function(mouse) { mouse.accepted = false }
				onReleased: function(mouse) { mouse.accepted = false }
				onClicked: function(mouse) { mouse.accepted = false }
			}

			Keys.onEscapePressed: wallpaperSelector.showing = false
			Keys.onReturnPressed: {
				var flatIdx = _selectedCol * _rows + _selectedRow
				if (flatIdx >= 0 && flatIdx < WallpaperService.wallpapers.count) {
				var item = WallpaperService.wallpapers.get(flatIdx)
				WallpaperApplyService.applyWallpaper(item)
				}
			}
			

			Keys.onPressed: function(event) {
				if (event.key === Qt.Key_Left && !(event.modifiers & Qt.ShiftModifier)) {
				if (currentIndex > 0) { currentIndex--; _selectedCol = currentIndex }
				event.accepted = true
				return
				}
				if (event.key === Qt.Key_Right && !(event.modifiers & Qt.ShiftModifier)) {
				if (currentIndex < count - 1) { currentIndex++; _selectedCol = currentIndex }
				event.accepted = true
				return
				}
				if (event.key === Qt.Key_Up && !(event.modifiers & Qt.ShiftModifier)) {
				if (_selectedRow > 0) _selectedRow--
				event.accepted = true
				return
				}
				if (event.key === Qt.Key_Down && !(event.modifiers & Qt.ShiftModifier)) {
				var maxRow = Math.min(_rows, WallpaperService.wallpapers.count - _selectedCol * _rows) - 1
				if (_selectedRow < maxRow) _selectedRow++
				event.accepted = true
				return
				}
			}

					delegate: Item {
						id: hexCol
						width: hexListView.stepX
						height: hexListView.height
						clip: false

						property int colIdx: index

						readonly property real _colCenter: (x - hexListView.contentX) + width * 0.5
						readonly property bool _insideView: _colCenter > -hexListView._hexW && _colCenter < hexListView.width + hexListView._hexW
						readonly property bool _nearEdge: _colCenter < hexListView._fadeZone || _colCenter > (hexListView.width - hexListView._fadeZone)
						readonly property bool _nearLeft: _colCenter < hexListView.width / 2
						readonly property bool _visible: _insideView && !_nearEdge
						property real _colScale: _visible ? 1 : 0
						Behavior on _colScale { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }
						
						Repeater {
							model: Math.max(
								0,
								Math.min(
									hexListView._rows,
									Math.max(0, WallpaperService.wallpapers.count - hexCol.colIdx * hexListView._rows)
								)
							)
						
							HexItem {
								property int rowIdx: index
            					property int flatIdx: hexCol.colIdx * hexListView._rows + rowIdx
								hexRadius: hexListView._r
								isSelected: hexCol.colIdx === hexListView._selectedCol && rowIdx === hexListView._selectedRow
								
								itemData: (flatIdx >= 0 && flatIdx < WallpaperService.wallpapers.count)
								? WallpaperService.wallpapers.get(flatIdx)
								: null
								x: 0
            					y: hexListView._yOffset + rowIdx * hexListView._stepY + (hexCol.colIdx % 2 !== 0 ? hexListView._hexH / 2 : 0)
								parallaxX: {
								var viewCenterX = hexListView.width / 2
								var normalized = (hexCol._colCenter - viewCenterX) / Math.max(1, viewCenterX)
								return -normalized * hexListView._r * 0.6
								}
								parallaxY: {
								var viewCenterY = hexListView.height / 2
								var hexCenterY = y + height / 2
								var normalized = (hexCenterY - viewCenterY) / Math.max(1, viewCenterY)
								return -normalized * hexListView._r * 0.6
								}
								scale: hexCol._colScale
								transformOrigin: hexCol._nearLeft ? Item.Left : Item.Right
								opacity: hexCol._colScale < 0.01 ? 0 : 1
							}
							
						}
					}
			}
	// 	SettingsPanel{}


    // }
}
}