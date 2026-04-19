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


	// function updateVisual() {
	// 	// flick.applyVisual(selectedItem, 1, 1)
		// wallpaperController.currentSelected = selectedItem
	
		// wallpaperController.previousIndex = wallpaperController.currentIndex

	// }

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

	// computed values
	property int currentIndex: 0

	property Item currentItem: null
	property Item previousItem: null
	property real currentTargetX
	property real currentTargetY

	property bool isSelected: false
		

	function setIndex(i) {

		wallpaperController.previousIndex = wallpaperController.currentIndex
		wallpaperController.currentIndex = i

		wallpaperController.previousItem = wallpaperController.currentItem
	}

	function computeDir() {

		var curr = wallpaperController.currentItem
		var prev = wallpaperController.previousItem

		if (!curr || !prev)
			return 1

		var cx = curr.mapToItem(null, 0, 0).x
		var px = prev.mapToItem(null, 0, 0).x

		return (cx > px) ? 1 : -1
	}
	function flipHex() {

		var wSelected = wallpaperController.currentItem
		var wPrevious = wallpaperController.previousItem

		if (!wSelected?.visualWrapperRef || !wPrevious?.visualWrapperRef)
			return

		var cx = wSelected.mapToItem(null, 0, 0).x
		var px = wPrevious.mapToItem(null, 0, 0).x

		var dir = (cx > px) ? 1 : -1

		Qt.callLater(() => {

			var vPrev = wPrevious.visualWrapperRef

			vPrev.flipAnim.stop()
			vPrev.flipAnim.from = 0
			vPrev.flipAnim.to = 180 * dir
			vPrev.flipAnim.start()

			var v = wSelected.visualWrapperRef

			v.flipAnim.stop()
			v.flipAnim.from = -180 * dir
			v.flipAnim.to = 0
			v.flipAnim.start()
		})
	}
	property real currentItemX
	property real currentItemY

	Connections {
		target: wallpaperController.currentItem
		function onXChanged() { highlightContainer.updateBorder() }
		function onYChanged() { highlightContainer.updateBorder() }
	}
	Connections {
    target: wallpaperController
	
    function onCurrentIndexChanged() {
			flick.updateGridFocusOffset()
			
			// console.log(currentItem.targetX)
			// 
			// console.log(
			// 	"current item: ", currentItemX,
			
			// )
			// var currentScale = currentItem.visualWrapperRef.visualScale
			// var currentOpacity = currentItem.visualWrapperRef.fadeOpacity
			// var currentTargetX = currentItem.targetX
			// var currentTargetY = currentItem.targetY
			// var currentX = currentItem.x
			// var currentY = currentItem.y
			// flick.clampContent()
			
			// console.log(
			// // "current index: ", currentIndex,
			// // "current item: ", currentItem,
			// // "current scale: ", currentScale,
			// // "current opacity: ", currentOpacity,
			// "current targetX: ", currentTargetX,
			// "current targetY: ", currentTargetY,
			// "current X: ", currentX,
			// "current Y: ", currentY,
			// )
	
		// highlightContainer.target =
        //         wallpaperController.getItem(wallpaperController.currentIndex)
       
	    // console.log("target  X: ", highlightContainer.target.x, 
		// "target  Y: ", highlightContainer.target.y
		// )
		
		var wPrev = wallpaperController.currentIndex
        // if (wPrev && wPrev !== wallpaperController.currentSelected) {
        //     var vwPrev = wPrev.visualWrapperRef
        //     vwPrev.scaleAnim.stop()
        //     vwPrev.scaleAnim.from = vwPrev.visualScale
        //     vwPrev.scaleAnim.to = 1
        //     vwPrev.scaleAnim.start()
        // }

        // scaleDelayTimer.start()
		Qt.callLater(() => {

        flipHex()
		})
		// updateVisual()
        runUpdateShift()
       

        wallpaperController.blurTransition = true
        imgBlurInTimer.restart()
    }
}
property var itemMap: ({})
function registerItem(i, obj) {
    itemMap[i] = obj
}

function unregisterItem(i) {
    delete itemMap[i]
}

function getItem(i) {
    return itemMap[i] ?? null
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
	property real paddingX: Math.max(flick.cellWidth, flick.width * 1.2)
	width: paddingX
	height: flick.height * 1.1 + paddingY * 2
	Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
	
	clip: false
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
			Layout.fillWidth: true
			
			
			focus: true

			interactive: false
			
			clip: false // important to make selector overflow

			property bool firstUpdateDone: false

	
			property bool selectedHexSettled: false

			property real topFactor: (5 * verticalMargin) / rowStep
			property real bottomFactor: (1.2 * verticalMargin) / rowStep

			property real viewportTop: contentY - (rowStep * topFactor)
			property real viewportBottom: contentY + height - (rowStep * bottomFactor)
			property bool layoutLock: false
			contentHeight: Math.ceil(filteredWallpapers.length / columns) * rowStep
			
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
	
			Component.onCompleted: {
				flick.updateGridFocusOffset()
				flick.forceActiveFocus()
			}
			property real lastContentY: 0
			property int scrollDir: 0
			property int lastDir: 0
			property real dirThreshold: 0.5   // tweak (0.5–2)

			
			Connections {
				target: flick
				property int lastDir: 0

					onContentYChanged: {
					var dy = flick.contentY - flick.lastContentY

					if (Math.abs(dy) > flick.dirThreshold) {
						flick.scrollDir = dy > 0 ? 1 : -1

						if (flick.scrollDir !== lastDir) {
							console.log(flick.scrollDir > 0 ? "scroll ↓" : "scroll ↑")
							lastDir = flick.scrollDir
						}

						flick.lastContentY = flick.contentY
					}

					wallpaperController.requestFrame()
				}
				// function onContentYChanged() {
				// 	flick.scrollDir = flick.contentY > flick.lastContentY ? 1 : -1
				// 	flick.lastContentY = flick.contentY
				// 	wallpaperController.requestFrame()
				
				// }
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
				// Rectangle {
				// 	anchors.fill: parent
				// 	color: "transparent" 
				// 	border.color: "green"       
				// 	border.width: 1
				// }

	

					property real cellWidthFactor: 0.95
					property real spacingXFactor: 0.8
					// Derived value (important!)
    				property real effectiveCellStepX: cellWidth * cellWidthFactor + spacingX * spacingXFactor
					// width: gridWidth()
					width: columns * effectiveCellStepX
					
					// function ripple(index) {

					// 	var sel = wallpaperController.currentIndex
					// 	if (sel < 0) return Qt.point(0, 0)

					// 	// stable guard
					// 	if (sel < startIndex || sel >= endIndex)
					// 		return Qt.point(0, 0)

					// 	var cols = columns

					// 	var sx = sel % cols
					// 	var sy = Math.floor(sel / cols)

					// 	var x = index % cols
					// 	var y = Math.floor(index / cols)

					// 	var dx = x - sx
					// 	var dy = y - sy

					// 	var selParity = sy % 2

					// 	var shiftX = 0
					// 	var shiftY = 0

					// 	var leftSide =
					// 		dx < 0 ||
					// 		(y < sy && x <= sx - (selParity === 0 ? 1 : 0)) ||
					// 		(y > sy && x <= sx - (selParity === 0 ? 1 : 0))

					// 	var rightSide =
					// 		dx > 0 ||
					// 		(y < sy && x >= sx + (selParity === 0 ? 0 : 1)) ||
					// 		(y > sy && x >= sx + (selParity === 0 ? 0 : 1))

					// 	if (leftSide) shiftX = -15
					// 	else if (rightSide) shiftX = 15

					// 	if (dy < 0) shiftY = -10
					// 	else if (dy > 0) shiftY = 10

					// 	return Qt.point(shiftX, shiftY)
					// }
					function ripple(dx, dy, sx, sy) {

						var selParity = sy % 2

						var shiftX = 0
						var shiftY = 0

						var leftSide =
							dx < 0 ||
							(dy < 0 && sx + dx <= sx - (selParity === 0 ? 1 : 0)) ||
							(dy > 0 && sx + dx <= sx - (selParity === 0 ? 1 : 0))

						var rightSide =
							dx > 0 ||
							(dy < 0 && sx + dx >= sx + (selParity === 0 ? 0 : 1)) ||
							(dy > 0 && sx + dx >= sx + (selParity === 0 ? 0 : 1))

						if (leftSide) shiftX = -15
						else if (rightSide) shiftX = 15

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

						if (selIndex < 0) return

						// stable guard
						if (selIndex < startIndex || selIndex >= endIndex) {
							globalShiftX = 0
							return
						}

						var col = selIndex % cols
						var centerCol = Math.floor(cols / 2)

						var offset = col - centerCol

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

					function baseY(index) {

						var row = Math.floor(index / columns)

						var totalRows = Math.ceil(filteredWallpapers.length / columns)

						var visualPadding = cellHeight * 0.08

						var gridHeight =
							(totalRows - 1) * rowStep
							+ cellHeight


						var offset =
							Math.max((flick.height - gridHeight) / 2, 0)

						return offset + row - visualPadding
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

						function itemPosX(i) {
								return gridOffsetX() + baseX(i) + baseBiasX
							}

							function itemPosY(i) {
								let row = Math.floor(i / columns)
								return row * rowStep + gridVerticalOffset()
							}
					
					// Container outside the Flickable, so it’s not masked
			// 	Item {
			// 	id: highlightContainer

			// 	z: 9999
			// 	clip: false
			// 	layer.smooth: true
			
			// 	Shape {
			// 		id: selectedHexBorder

			// 		width: flick.cellWidth - 10
			// 		height: flick.cellHeight - 10
			// 		x: wallpaperController.currentItem ?
			// 		wallpaperController.currentItem.targetX : 0
			// 		y: wallpaperController.currentItem ?
			// 		wallpaperController.currentItem.targetY: 0
			

			// 		scale: currentItem.visualWrapperRef.visualScale
			// 		opacity: 1
					
			// 		preferredRendererType: Shape.CurveRenderer
			// 		antialiasing: true

			// 		ShapePath {
			// 			strokeWidth: 4
			// 			strokeColor: colorsPalette.primary
			// 			fillColor: "transparent"

			// 			PathMove { x: selectedHexBorder.width * 0.5; y: 0 }
			// 			PathLine { x: selectedHexBorder.width; y: selectedHexBorder.height * 0.25 }
			// 			PathLine { x: selectedHexBorder.width; y: selectedHexBorder.height * 0.75 }
			// 			PathLine { x: selectedHexBorder.width * 0.5; y: selectedHexBorder.height }
			// 			PathLine { x: 0; y: selectedHexBorder.height * 0.75 }
			// 			PathLine { x: 0; y: selectedHexBorder.height * 0.25 }
			// 			PathLine { x: selectedHexBorder.width * 0.5; y: 0 }
			// 		}

			// 		Behavior on x {
			// 			SpringAnimation { spring: 4; damping: 0.25 }
			// 		}

			// 		Behavior on y {
			// 			SpringAnimation { spring: 4; damping: 0.25 }
			// 		}

			// 		Behavior on scale {
			// 			SpringAnimation { spring: 6; damping: 0.9 }
			// 		}
			// 	}
			// }


   		Keys.enabled: true
	

		Keys.onPressed: function(event) {

			let oldIndex = wallpaperController.currentIndex

			let handled = InputHandler.navigate(event, {
				size: filteredWallpapers.length,
				columns: flick.columns,
				currentIndex: oldIndex,

				onApply: (i) =>
					WallpaperApplyService.applyWallpaper(filteredWallpapers[i]),

				onMove: (i) => {

					flick.cancelFlick()

					wallpaperController.currentIndex = i

					smartScroll(i, oldIndex)
				}
			})

			if (handled)
				event.accepted = true
		}

		function smartScroll(i) {

    let cols = flick.columns
    let row = Math.floor(i / cols)

    let rowTop = row * flick.rowStep
    let rowBottom = rowTop + flick.rowStep

    let viewTop = flick.contentY
    let viewBottom = flick.contentY + flick.height

    let maxRow = Math.floor((filteredWallpapers.length - 1) / cols)

    // UP → only if item fully above view
    if (rowTop < viewTop) {
        flick.contentY = Math.max(0, rowTop)
        return
    }

    // DOWN → only if item fully below view
    if (rowBottom > viewBottom) {
        let target = row - Math.floor(flick.height / flick.rowStep) + 1
        flick.contentY = Math.min(maxRow, target) * flick.rowStep
        return
    }
}


		function snap() {
			flick.contentY =
				Math.round(flick.contentY / flick.rowStep) * flick.rowStep
		}

					// property real _r: flick.hexRadius
					// property real _hexH: _r * 2
					// highlightFollowsCurrentItem: true
					// highlightMoveDuration: 350
					// highlight: Item {}
					// preferredHighlightBegin: (flick.height - flick._hexH) / 2
					// preferredHighlightEnd: (flick.height - flick._hexH) / 2
					// highlightRangeMode: ListView.StrictlyEnforceRange

					// header: Item { width: (flick.width - flick._hexH) / 2 }
					// footer: Item { width: (flick.width - flick._hexH) / 2 }
					


					// add: Transition {
					// 	NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250; easing.type: Easing.OutCubic }
					// 	NumberAnimation { property: "scale"; from: 0.85; to: 1; duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
					// }
					// remove: Transition {
					// 	NumberAnimation { property: "opacity"; to: 0; duration: 100; easing.type: Easing.InCubic }
					// }
					// displaced: Transition {
					// 	NumberAnimation { properties: "x,y"; duration: 150; easing.type: Easing.OutCubic }
					// }
					model: Math.ceil(filteredWallpapers.length / flick.columns)
					property real _fadeZone: flick.rowStep
					
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
								id: hexItem
								controller: wallpaperController
								states: [
									State {
										name: "in"
										when: _inView
										PropertyChanges {
											target: hexItem
											_rowScale: 1
										}
									},
									State {
										name: "out"
										when: !_inView
										PropertyChanges {
											target: hexItem
											_rowScale: 0
										}
									},
								]
									 
								transitions: [
								    // ENTER
								    Transition {
								        from: "out"
								        to: "in"
										NumberAnimation {
											properties: "_rowScale"
											from: 0
											to: 1
											duration: 180
											easing.bezierCurve: [0.18, 1.0, 0.3, 1.0]
										}
							
								    },

								    // EXIT (normal)
								    Transition {
								        from: "in"
								        to: "out"
								       	NumberAnimation {
											duration: 350
											properties: "_rowScale"
											from: 1; to: 0
											easing.type: Easing.OutBack
											easing.overshoot: 1.2
											
										}
								    },
								]
										
								property int flatIndex: rowIndex * flick.columns + index
								
								property bool _isSelected: wallpaperController.currentIndex === flatIndex

								property int cols: flick.columns
								
								
								property real deadZone: 20

								
								property real itemCenterY: y + height * 0.5
								property real viewCenterY: flick.contentY + flick.height * 0.5
								property bool _nearTop: itemCenterY < viewCenterY - deadZone
								
								property int selIndex: wallpaperController.currentIndex
								property bool _inView: flatIndex >= flick.startIndex &&
										flatIndex < flick.endIndex
								property int sx: selIndex % cols
								property int sy: Math.floor(selIndex / cols)

								property int xIdx: flatIndex % cols
								property int yIdx: Math.floor(flatIndex / cols)

								property int dx: xIdx - sx
								property int dy: yIdx - sy
							
								property bool _rippleOff: selIndex < flick.startIndex || selIndex >= flick.endIndex
								property var _ripple: flick.ripple(dx, dy, sx, sy) 
								originFixY: (transformOrigin === Item.Top) ? height * 0.5 : -height * 0.5
								property real _rowScale: 0

								Behavior on opacity { 
									NumberAnimation { 
										duration: 350; 
										easing.type: Easing.InOutQuad 
									} 
								}
								// property real _selectScale: _isSelected ? 1.12 : 1
								
								scale: _rowScale
								// Behavior on scale {
								// 	// enabled: flickRef.firstUpdateDone
								// 	NumberAnimation {
								// 		duration: 400
								// 		easing.type: Easing.BezierSpline
								// 		easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
								// 	}
								// }
								opacity: _rowScale < 0.01 ? 0 : 1
								
								container: flick
								flickRef: flick
								rippleOff: _rippleOff
								ripple: _ripple
								hexBorder: highlightContainer
								// scale: _rowScale
								
								itemData: filteredWallpapers[flatIndex]
								itemIndex: flatIndex
								inView: _inView
								// transformOrigin: Item.Center
								transformOrigin: {
									if (isSelected) return Item.Center
									if (flick.scrollDir < 0) {
										// scroll up → original
										return _nearTop ? Item.Top : Item.Bottom
									} else {
										// scroll down → flipped
										return _nearTop ? Item.Bottom : Item.Top
									}
								}
							
							}

								
															// targetX: _inView ?
								// flick.baseX(flatIndex) + ripple.x : flick.baseX(flatIndex)
    							// targetY: _inView ?
								// flick.baseY(flatIndex) + ripple.y : flick.baseY(flatIndex)
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