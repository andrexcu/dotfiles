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

	QtObject {
		id: processManager
	}

	// property QtObject listProcess: Io.Process {
	// 	command: []
	// 	stdout: Io.StdioCollector {
	// 		id: listCollector
	// 	}

	// 	onExited: function(exitCode, exitStatus) {
	// 		if (exitCode !== 0) {
	// 			lastError = "Failed to scan wallpaper directory"
	// 			showNotification("Error", lastError, "dialog-error")
	// 			return
	// 		}

	// 		// Parse output
	// 		let output = listCollector.text.trim()
	// 		if (output.length === 0) {
	// 			lastError = "No wallpapers found in " + wallpaperDir
	// 			showNotification("Error", lastError, "dialog-error")
	// 			return
	// 		}

	// 		let files = output.split("\n").filter(f => f.length > 0)

	// 		// Build wallpaper list + thumbnail paths
	// 		let processed = []
	// 		let paths = {}

	// 		for (let i = 0; i < files.length; i++) {
	// 			let filename = files[i].split("/").pop()
	// 			if (filename.length > 0) {
	// 				processed.push(filename)

	// 				let parts = filename.split(".")
	// 				let baseName = parts.length > 1
	// 					? parts.slice(0, -1).join(".")
	// 					: filename

	// 				paths[filename] = baseName + ".png"
	// 			}
	// 		}

	// 		wallpapers = WallpaperService.shuffleArray(processed)
	// 		thumbnailPaths = paths

	// 		if (wallpapers.length > 0) {
	// 			wallpaperController.currentIndex = 0
	// 			selectedWallpaper = wallpapers[0]
	// 		}

	// 		// ONLY trigger thumbnail scan (non-blocking)
	// 		WallpaperCacheService.updateThumbs()
	// 	}
	// }

	// =======================
	// CONFIGURATION
	// =======================
	property var colorsPalette: Colors {}
	
	property var filteredWallpapers: WallpaperService.wallpapers   // initially same as full list
	property string selectedWallpaper: ""
	property string lastError: ""
	property int currentIndex: 0

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
	// property Item selectedItem: wallpaperRepeater.itemAt(wallpaperController.currentIndex)
	// property Item previousItem: (wallpaperController.previousIndex >= 0 &&
	// 					wallpaperController.previousIndex < wallpaperRepeater.count)
	// 					? wallpaperRepeater.itemAt(wallpaperController.previousIndex)
	// 					: null

	// Path
	
	property string homeDir: ""
	property string wallpaperDir: ""
	property string savedWallpaperDir: ""

	

	// Computed property for convenience
	// property Item currentItem: (wallpaperController.currentIndex >= 0 && wallpaperController.currentIndex < wallpaperRepeater.count)
	// 	? wallpaperRepeater.itemAt(wallpaperController.currentIndex)
	// 	: null

	property var selectedVisual: wallpaperController.currentSelected
								&& wallpaperController.currentSelected.visualWrapperRef
								? wallpaperController.currentSelected.visualWrapperRef
								: null

	property int previousIndex: 0

	
	
	// Path Listeners
	// onWallpaperDirChanged: {
	// 	if (wallpaperDir && wallpaperDir !== wallpaperController.savedWallpaperDir) {
	// 		wallpaperController.savedWallpaperDir = wallpaperDir
	// 	}
	// }

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
		// scaleDelayTimer.start()
		// selectedItem.visualWrapperRef.width = flick.cellWidth - 10
		// selectedItem.visualWrapperRef.height = flick.cellHeight - 10
		console.log("path: " + Config.options.wallpaperDir)
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

	function flipHex() {
		var wSelected = wallpaperController.selectedItem
		var wPrevious = wallpaperController.previousItem

		if (!wSelected) return

		var direction = 1
		if (wPrevious && wPrevious !== wSelected) {
			direction = (wPrevious.x < wSelected.x) ? 1 : -1
		}

		if (wPrevious && wPrevious !== wSelected) {
			var vwPrev = wPrevious.visualWrapperRef
			vwPrev.flipAnim.stop()
			vwPrev.flipAnim.from = vwPrev.flipAngle
			vwPrev.flipAnim.to = 0
			vwPrev.flipAnim.start()
		}

		var vw = wSelected.visualWrapperRef
		vw.flipAnim.stop()
		vw.flipAnim.from = 0
		vw.flipAnim.to = 180 * direction
		vw.flipAnim.start()
	}

	function updateVisual() {
		// flick.applyVisual(selectedItem, 1, 1)
		wallpaperController.currentSelected = selectedItem
	
		wallpaperController.previousIndex = wallpaperController.currentIndex

	}

	function runFrame() {
		flick.updateGridFocusOffset()
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
			// var row = Math.floor(wallpaperController.currentIndex / flick.cols)

			// if (row < flick.startRow || row >= flick.startRow + flick.visibleRows) {
			// 	flick.contentY = row * flick.rowStep
			// }
	// NumberAnimation {
	// 	id: scaleAnim
	// 	target: visualWrapperRef
	// 	property: "visualScale"
	// 	duration: 180
	// 	easing.type: Easing.OutQuad
	// }
	// effects on change
	Connections {
    target: wallpaperController

    function onCurrentIndexChanged() {

        // var wPrev = wallpaperController.previousItem
        // if (wPrev && wPrev !== wallpaperController.currentSelected) {
        //     var vwPrev = wPrev.visualWrapperRef
        //     vwPrev.scaleAnim.stop()
        //     vwPrev.scaleAnim.from = vwPrev.visualScale
        //     vwPrev.scaleAnim.to = 1
        //     vwPrev.scaleAnim.start()
        // }

        // scaleDelayTimer.start()
        // flipHex()
		// updateVisual()
        runUpdateShift()
        flick.updateGridFocusOffset()

        wallpaperController.blurTransition = true
        imgBlurInTimer.restart()
    }
}


// property bool visibleModel: filteredWallpapers.slice(startIndex, endIndex)
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
				Qt.quit()
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
				Qt.quit()
		}
		
		}
	
  ColumnLayout {
	// anchors.fill: parent
	anchors.centerIn: parent
	anchors.margins: 16
	spacing: 16
	
 Item {
	id: cardContainer
	property real paddingY: flick.cellHeight * 0.4
	property real paddingX: Math.max(flick.cellWidth, flick.width * 0.05)
	width: flick.width + paddingX * 2
	height: flick.height * 1.1 + paddingY * 2
	Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
	
	clip: true
	// testing
	Rectangle {
        anchors.fill: parent
        color: "transparent" 
        border.color: "red"       
        border.width: 1
    }
	
	// anchors {
	// 	top: parent.top
	// 	bottom: parent.bottom
	// 	horizontalCenter: parent.horizontalCenter
	// }
	visible: wallpaperController.isContentVisible
	// visible: wallpaperController.cardVisible
	
 	opacity: 0
	
    property bool animateIn: wallpaperController.cardVisible
	onAnimateInChanged: {
		fadeInAnim.stop()

		if (animateIn) {
			opacity = 0
			fadeInAnim.start()

			if (!focusTimer.running)
				focusTimer.start()
		}
	}
    // onAnimateInChanged: {
    //   fadeInAnim.stop()
    //   if (animateIn) {
    //     opacity = 0
    //     fadeInAnim.start()
    //     focusTimer.restart()
    //   }
    // }

    NumberAnimation {
      id: fadeInAnim
      target: cardContainer
      property: "opacity"
      from: 0; to: 1
      duration: 400
      easing.type: Easing.OutCubic
    }

	// prevent clicks from closing when clicking inside
	MouseArea {
		anchors.fill: parent
		onClicked: {}
	}

	
    Item {
        id: keyRoot
        anchors.fill: parent
        focus: true
		clip: false
        // Keys.enabled: isContentVisible
		// function getRow(index) {
		// return Math.floor(index / flick.columns)
		// }

		// function getCol(index) {
		// 	return index % flick.columns
		// }

		// function toIndex(row, col) {
		// 	return row * flick.columns + col
		// }

		// function isValidIndex(i) {
		// 	return i >= 0 && i < filteredWallpapers.length
		// }

		// Keys.onPressed: function(event) {

		// 	InputHandler.navigate(event, {
		// 		size: filteredWallpapers.length,
		// 		columns: flick.columns,
		// 		currentIndex: wallpaperController.currentIndex,

		// 		onApply: (i) => WallpaperApplyService.applyWallpaper(filteredWallpapers[i]),

		// 		onMove: (t) => {
		// 			flick.cancelFlick()
		// 			wallpaperController.currentIndex = t

		// 			const item = wallpaperRepeater.itemAt(t)
		// 			if (!item) return

		// 			const margin = 4
		// 			const fadeZone = flick.height * 0.1

		// 			let top = item.y - margin
		// 			let bottom = item.y + item.height + margin

		// 			if (top < flick.contentY - fadeZone)
		// 				flick.contentY = top
		// 			else if (bottom > flick.contentY + flick.height + fadeZone)
		// 				flick.contentY = bottom - flick.height
		// 		}
		// 	})

		// 	event.accepted = true
		// }
	


	ColumnLayout {
		anchors.fill: parent
		anchors.leftMargin: 16
		anchors.rightMargin: 16
		anchors.margins: 16
		clip: false
	
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
		Item {
			Layout.fillHeight: true
		}
			
	

		ListView {
			id: flick

			boundsBehavior: Flickable.StopAtBounds
			flickDeceleration: 1800
			maximumFlickVelocity: 2900
			orientation: ListView.Vertical
			property int verticalMargin: 15
			property real maxItemScale: 1
			property real itemOverflow: flick.cellHeight * (maxItemScale - 1)
			property int extraPadding: 25
			property int topMargin: 40
			property int bottomMargin: itemOverflow + extraPadding

			Layout.fillHeight: false
			Layout.fillWidth: false

			focus: true

			interactive: true
			
			clip: false // important to make selector overflow

			property bool firstUpdateDone: false

	
			property bool selectedHexSettled: false

			property real topFactor: (5 * verticalMargin) / rowStep
			property real bottomFactor: (1.2 * verticalMargin) / rowStep

			property real viewportTop: contentY - (rowStep * topFactor)
			property real viewportBottom: contentY + height - (rowStep * bottomFactor)
			property bool layoutLock: false

			
			function applyVisual(item, scale, opacity) {
				item.visualWrapperRef.visualScale = scale
				item.visualWrapperRef.fadeOpacity = opacity
			}

		
			property real rowStep: flick.cellHeight * 0.75
			property int cols: flick.columns
		

			property int startRow:
				Math.floor((contentY + rowStep * 0.5) / rowStep)

			property int startIndex:
				startRow * cols

			property int endIndex:
				startIndex + flick.visibleRows * cols

			onMovementEnded: {
				contentY = Math.round(contentY / rowStep) * rowStep
				Qt.callLater(() => {
					requestFrame()
				})
			}
			Behavior on contentY {
				NumberAnimation {
					duration: 150
					easing.type: Easing.BezierSpline
					easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
				}
			}
	
			// Component.onCompleted: {
			// 	flick.updateSlice()
			// }
			Connections {
				target: flick
				function onContentYChanged() {
					wallpaperController.requestFrame()
					// wallpaperController.runUpdateShift()
					flick.forceActiveFocus()
				
				}
			}

				// MouseArea {
				// 	anchors.fill: parent
				// 	focus: true
				// 	onWheel: (wheel) => {
				// 		flick.flick(0, wheel.angleDelta.y * 12) // vertical
				// 		wheel.accepted = true
				// 	}

				// 	onPressed: {
				// 		flick.forceActiveFocus()
				// 	}
					
				// }
				


				
					property real cellWidthFactor: 0.95
					property real spacingXFactor: 0.8
					// Derived value (important!)
    				property real effectiveCellStepX: cellWidth * cellWidthFactor + spacingX * spacingXFactor
					// width: gridWidth()
					width: columns * effectiveCellStepX
					function ripple(index) {
						var sel = wallpaperController.currentIndex
						if (sel < 0) return Qt.point(0, 0)

						if (!wallpaperController.selectedVisual
							|| wallpaperController.selectedVisual.visualScale === 0)
							return Qt.point(0, 0)

						var cols = columns

						var sx = sel % cols
						var sy = Math.floor(sel / cols)

						var x = index % cols
						var y = Math.floor(index / cols)

						var dx = x - sx
						var dy = y - sy

						var selParity = sy % 2

						var shiftX = 0
						var shiftY = 0

						// HARD LEFT / RIGHT SPLIT (this is your original power)
						var leftSide =
							dx < 0 ||
							(y < sy && x <= sx - (selParity === 0 ? 1 : 0)) ||
							(y > sy && x <= sx - (selParity === 0 ? 1 : 0))

						var rightSide =
							dx > 0 ||
							(y < sy && x >= sx + (selParity === 0 ? 0 : 1)) ||
							(y > sy && x >= sx + (selParity === 0 ? 0 : 1))

						if (leftSide) shiftX = -15
						else if (rightSide) shiftX = 15

						// Y original distance
						if (dy < 0) shiftY = -10
						else if (dy > 0) shiftY = 10

						return Qt.point(shiftX, shiftY)
					}
					
					property real baseOffsetX: Math.max((flick.width - gridWidth()) / 2, 0)
					property real globalShiftX: 0
					property real baseBiasX: flick.width * 0.20 + 20

					x: (flick.width - gridWidth()) / 2 + globalShiftX
					y: 0

					function updateGridFocusOffset() {

						var selIndex = wallpaperController.currentIndex
						
						var cols = flick.columns

						var col = selIndex % cols
						var centerCol = Math.floor(cols / 2)

						var offset = col - centerCol

						//  KEY CHANGE HERE
						if (!wallpaperController.selectedVisual || wallpaperController.selectedVisual.opacity === 0) {
							globalShiftX = 0
							return
						}

						var newShift = (offset !== 0) ? -offset * 25 : 0

						if (Math.abs(newShift - globalShiftX) < 0.01)
							return

						globalShiftX = newShift
					}

				
					Behavior on globalShiftX {
						NumberAnimation {
							duration: 500
							easing.type: Easing.BezierSpline
							easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
						}
					}
					

			
					function baseX(index) {
						var col = index % columns;
						var row = Math.floor(index / columns);
						var step = effectiveCellStepX;

						var x = col * step;

						if (row % 2 === 1)
							x += step / 2;

						return x;
					}
					// onGlobalShiftXChanged: console.log("SHIFT =", globalShiftX)
					function itemX(index) {
						return gridOffsetX() + baseX(index) + baseBiasX;
					}

					function gridOffsetX() {
						return (flick.width - gridWidth()) / 2;
					}



					function gridWidth() {
						var step = effectiveCellStepX;

						// worst-case width includes stagger
						var base = (columns - 1) * step + cellWidth;

						// add stagger allowance (critical fix)
						return base + step / 2;
					}


					function itemY(index) {
						// var columns = flick.columns;
						// var row = Math.floor(index / columns);

						// var totalRows = Math.ceil(wallpaperRepeater.count / columns);

						// var stepY = flick.cellHeight * 0.75;

						// // include full visual footprint of last row (important fix)
						// var totalHeight = (totalRows - 1) * stepY
						// 				+ flick.cellHeight;

						// // optional safety margin for visual overflow (recommended)
						// var visualPadding = flick.cellHeight * 0.1;

						// var viewportHeight= flick.height

						
						// var verticalOffset =
						// 	Math.max((viewportHeight - totalHeight) / 2 + visualPadding / 2, 0);

						// return verticalOffset + row * stepY;
					}
			
					
					property real hexRadius: 90
					property int cellWidth: hexRadius * 2
					property int cellHeight: Math.round(cellWidth * Math.sqrt(3)/2 * 1.2) 
					property int spacingX: 10
					property int spacingY: 10
					property int columns: 5
					property int visibleRows: 4
				

					height: flick.cellHeight
							+ (visibleRows - 1) * rowStep
					
					Behavior on hexRadius {
						NumberAnimation {
							duration: 180
							easing.type: Easing.OutCubic
						}
					}
					
					// Container outside the Flickable, so it’s not masked
					Item {
						id: highlightContainer

						z: 9999
						clip: false
						visible: isContentVisible
						

						layer.smooth: true
						
						Shape {
							
							id: selectedHexBorder
							visible: wallpaperController.currentSelected 
							// visible: false
							width: flick.cellWidth - 10
							height: flick.cellHeight - 10

							// Handles selection animation + state transitions
							
							
			

					

							

							// Bind scale to the selected item's visualScale
							scale: wallpaperController.currentSelected ? currentSelected.visualWrapperRef.visualScale : 1
					
							opacity: 1
			
						
							// Follow current selected position
							x: currentSelected ? currentSelected.targetX: 0
							y: currentSelected ? currentSelected.targetY : 0
						
							preferredRendererType: Shape.CurveRenderer
							antialiasing: true
							
							ShapePath {
								strokeWidth: 4
								strokeColor: colorsPalette.primary
								fillColor: "transparent"

								PathMove { x: selectedHexBorder.width * 0.5; y: 0 }
								PathLine { x: selectedHexBorder.width; y: selectedHexBorder.height * 0.25 }
								PathLine { x: selectedHexBorder.width; y: selectedHexBorder.height * 0.75 }
								PathLine { x: selectedHexBorder.width * 0.5; y: selectedHexBorder.height }
								PathLine { x: 0; y: selectedHexBorder.height * 0.75 }
								PathLine { x: 0; y: selectedHexBorder.height * 0.25 }
								PathLine { x: selectedHexBorder.width * 0.5; y: 0 }
								
							}
								Behavior on x {
									SpringAnimation {
										id: springX
										spring: 4
										damping: 0.25
									}
								}

								Behavior on y {
									SpringAnimation {
										id: springY
										spring: 4
										damping: 0.25
									}
								}
								Behavior on scale {
									
									SpringAnimation {
											spring: 6
											damping: 0.9 
										}
								}


						}
						
						
					}

					model: Math.ceil(filteredWallpapers.length / flick.columns)

					delegate: Item {
						id: rowItem
						width: flick.width
						height: flick.rowStep

						property int rowIndex: index

						Repeater {
							model: Math.max(
								0,
								Math.min(
									flick.columns,
									filteredWallpapers.length - rowIndex * flick.columns
								)
							)

							delegate: HexItem {
								controller: wallpaperController

								property int flatIndex: rowIndex * flick.columns + index

								container: flick
								flickRef: flick
								
								itemData: filteredWallpapers[flatIndex]
								itemIndex: flatIndex
								x: flick.baseX(flatIndex)
								y: 0

								inView: flatIndex >= flick.startIndex &&
										flatIndex < flick.endIndex
							}
						}
					}
			}
			Item {
				Layout.fillHeight: true   // TOP spacer
			}
		}
		
	}
	
		
	}

		SettingsPanel{}


    }
}
}