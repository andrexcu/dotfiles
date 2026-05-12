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
	// 		if (output.count === 0) {
	// 			lastError = "No wallpapers found in " + wallpaperDir
	// 			showNotification("Error", lastError, "dialog-error")
	// 			return
	// 		}

	// 		let files = output.split("\n").filter(f => f.count > 0)

	// 		// Build wallpaper list + thumbnail paths
	// 		let processed = []
	// 		let paths = {}

	// 		for (let i = 0; i < files.count; i++) {
	// 			let filename = files[i].split("/").pop()
	// 			if (filename.count > 0) {
	// 				processed.push(filename)

	// 				let parts = filename.split(".")
	// 				let baseName = parts.count > 1
	// 					? parts.slice(0, -1).join(".")
	// 					: filename

	// 				paths[filename] = baseName + ".png"
	// 			}
	// 		}

	// 		wallpapers = WallpaperService.shuffleArray(processed)
	// 		thumbnailPaths = paths

	// 		if (wallpapers.count > 0) {
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
	// property var colors: Colors {}
	
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

	property bool rowsChanged: false
	property bool columnsChanged: false
	Connections {
		target: Config.options.layouts

		function onRowsChanged() {
			wallpaperController.rowsChanged = true
			// flick.height = flick.cellHeight
			// 				+ (Config.options.layouts.rows - 1) * flick.rowStep
			console.log(
				// "rows:", Config.options.layouts.rows
				"rows changed:", wallpaperController.rowsChanged
				
			)
			// flick.visibleRows = Config.options.layouts.rows
		}

		function onColumnsChanged() {
			wallpaperController.columnsChanged = true
			console.log(
				// "columns:", Config.options.layouts.columns
				"columns changed:", wallpaperController.columnsChanged
			)
			// flick.columns = Config.options.layouts.columns
		}
	}
	
	Connections {
		target: Config.options.effects

		function onPixelChanged() {
			console.log(
				"pixel effect:", Config.options.effects.pixel
			)
		}
	}

	Component.onCompleted: {  
		// flick.columns = Config.options.layouts.columns
		// flick.visibleRows = Config.options.layouts.rows
		
		cardShowTimer.start()
		

			console.log(
				"columns: ", WatcherService.columns,
				"rows: ", WatcherService.rows,
				// "walldir: ", Config.options.wallpaperDir,
				// "pixel effect:", Config.options.effects.pixel
			)
		
		// wallpaperController.cardVisible = true
		// scaleDelayTimer.start()
		// selectedItem.visualWrapperRef.width = flick.cellWidth - 10
		// selectedItem.visualWrapperRef.height = flick.cellHeight - 10
		// console.log("path: " + Config.options.wallpaperDir)
		// console.log("thumbs generated: ", WatcherService.thumbsGenerated)
		// console.log("pathisempty: ", WatcherService.pathEmpty)
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
	property int hoveredIndex: 0
	property int previousHoveredIndex: 0
	property int previousIndex: 0

	property Item currentItem: null
	property Item previousItem: null
	property real currentTargetX
	property real currentTargetY

	property bool isSelected: false
		

	// function setIndex(i) {

	// 	wallpaperController.previousIndex = wallpaperController.currentIndex
	// 	wallpaperController.currentIndex = i

	// 	wallpaperController.previousItem = wallpaperController.currentItem
	// }

	// function computeDir() {

	// 	var curr = wallpaperController.currentItem
	// 	var prev = wallpaperController.previousItem

	// 	if (!curr || !prev)
	// 		return 1

	// 	var cx = curr.mapToItem(null, 0, 0).x
	// 	var px = prev.mapToItem(null, 0, 0).x

	// 	return (cx > px) ? 1 : -1
	// }
	// function flipHex() {

	// 	var wSelected = wallpaperController.currentItem
	// 	var wPrevious = wallpaperController.previousItem

	// 	if (!wSelected?.visualWrapperRef || !wPrevious?.visualWrapperRef)
	// 		return

	// 	var cx = wSelected.mapToItem(null, 0, 0).x
	// 	var px = wPrevious.mapToItem(null, 0, 0).x

	// 	var dir = (cx > px) ? 1 : -1

		// Qt.callLater(() => {

		// 	var vPrev = wPrevious.visualWrapperRef

		// 	vPrev.flipAnim.stop()
		// 	vPrev.flipAnim.from = 0
		// 	vPrev.flipAnim.to = 180 * dir
		// 	vPrev.flipAnim.start()

		// 	var v = wSelected.visualWrapperRef

		// 	v.flipAnim.stop()
		// 	v.flipAnim.from = -180 * dir
		// 	v.flipAnim.to = 0
		// 	v.flipAnim.start()
		// })
	// }

	property real currentItemX
	property real currentItemY

	// Connections {
	// 	target: wallpaperController.currentItem
	// 	function onXChanged() { highlightContainer.updateBorder() }
	// 	function onYChanged() { highlightContainer.updateBorder() }
	// }
	property bool _flipLock: false
	Connections {
    target: wallpaperController
	
    function onCurrentIndexChanged() {
			if(Config.options.effects.blur) {
				wallpaperController.blurTransition = true
				imgBlurInTimer.restart()
			}
			
		}
	// function onhoveredIndexChanged() {
	// 	console.log("hovered: ", hoveredIndex)
	// }
	}

		property int hexRadius: 90
	Behavior on hexRadius { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }
	property int hexRows: WallpaperService.rows
	property int hexCols: WallpaperService.columns
	Behavior on hexRows { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }
	Behavior on hexCols { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }


	property int cardHeight: hexGridHeight
	property int hexCardWidth: selectorPanel.width
	property int cardWidth: hexCardWidth
	Behavior on cardWidth { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }
	
	property int hexGridHeight: {
		var rows = hexRows
		var r = 105
		var spacing = 6
		var hexH = Math.ceil(r * 1.73205)
		var stepY = hexH + spacing
		var contentH = (rows - 1) * stepY + hexH + hexH / 2
		return contentH + 90
	}
	
  	Behavior on cardHeight { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
    
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

	property real paddingY: flick.cellHeight * 0.5
	
	// property real gridWidth:
    // WallpaperService.columns * flick.effectiveCellStepX

	// property real paddingX:
	// flick.gridWidth + flick.cellWidth
	// // property real paddingX: Math.max(flick.cellWidth, flick.width + flick.cellWidth * 0.5 * 2) 
	// width: paddingX
	// height: flick.height + paddingY * 1.5
	// Layout.fillWidth: true
	width: wallpaperController.cardWidth
	height: wallpaperController.cardHeight
	anchors.centerIn: parent
	Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
	// anchors.centerIn: parent
	clip: false
	// testing
	Rectangle {
        anchors.fill: parent
        color: "transparent" 
        border.color: "red"       
        border.width: 1
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
		width: parent.width
    	height: parent.height
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
		Layout.fillWidth: true
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
				Layout.alignment: Qt.AlignHCenter

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
    			// anchors.horizontalCenter: parent.horizontalCenter

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
	// MouseArea {
	// 	anchors.fill: parent
	// 	propagateComposedEvents: true

	// 	onWheel: function(wheel) {

	// 		var step = flick._stepX

	// 		const maxX = flick.contentWidth - flick.width

	// 		const dir =
	// 			(wheel.angleDelta.y > 0 || wheel.angleDelta.x > 0)
	// 			? -1
	// 			: 1

	// 		flick.contentX = Math.max(
	// 			0,
	// 			Math.min(maxX, flick.contentX + dir * step)
	// 		)

	// 		wheel.accepted = true
	// 	}

	// 	onPressed: function(mouse) { mouse.accepted = false }
	// 	onReleased: function(mouse) { mouse.accepted = false }
	// 	onClicked: function(mouse) { mouse.accepted = false }
	// }



	// anchors {
	// 	top: parent.top
	// 	bottom: parent.bottom
	// 	horizontalCenter: parent.horizontalCenter
	// }
	// visible: wallpaperController.isContentVisible
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
}
	// prevent clicks from closing when clicking inside
	MouseArea {
		anchors.fill: parent
		onClicked: {}
	}

	
    // Item {
    //     id: keyRoot
    //     anchors.fill: parent
    //     focus: true
	// 	clip: false
    	

		
		ListView {
			id: flick
			visible: wallpaperController.cardVisible
			
			opacity: WatcherService.thumbsGenerated ? 1 : 0
			Behavior on opacity { 
				NumberAnimation { 
					duration: 350; 
					easing.type: Easing.InOutQuad 
				} 
			}
			anchors.centerIn: parent
			
			boundsBehavior: Flickable.StopAtBounds
			flickDeceleration: 1500
			flickableDirection: Flickable.HorizontalFlick
			maximumFlickVelocity: 3000
			orientation: ListView.Horizontal

			// Layout.fillHeight: 
			Layout.fillWidth: true
			property int _rows: wallpaperController.hexRows
			property real _r: wallpaperController.hexRadius
			property real _gridSpacing: 6
			property real _hexW: _r * 2
			property real _hexH: Math.ceil(_r * 1.73205)
			property real _stepX: 1.5 * _r + _gridSpacing
			property real _stepY: _hexH + _gridSpacing
			property real _gridContentH: (_rows - 1) * _stepY + _hexH + _hexH / 2
			property real _yOffset: Math.max(0, (height - _gridContentH) / 2)
			property real _visibleBand: hexCols * _stepX
			property real _fadeZone: (width - _visibleBand) / 2

			property int visibleCols:
			Math.floor(flick.width / flick._stepX)
			Rectangle {
				anchors.fill: parent
				color: "transparent" 
				border.color: "green"       
				border.width: 1
			}
			focus: true

			interactive: false
			
			clip: false // important to make selector overflow

			property bool firstUpdateDone: false

	
			property bool selectedHexSettled: false

			// property real topFactor: (5 * verticalMargin) / rowStep
			// property real bottomFactor: (1.2 * verticalMargin) / rowStep

			// property real viewportTop: contentY - (rowStep * topFactor)
			// property real viewportBottom: contentY + height - (rowStep * bottomFactor)
			// property bool layoutLock: false
			contentWidth:
    		Math.ceil(filteredWallpapers.count / WallpaperService.rows) * colStep
			// contentHeight: Math.ceil(filteredWallpapers.count / WallpaperService.columns) * rowStep
			
			
			function applyVisual(item, scale, opacity) {
				item.visualWrapperRef.visualScale = scale
				item.visualWrapperRef.fadeOpacity = opacity
			}

		
			property real rowStep: flick.cellHeight * 0.75
			property real colStep: flick.cellWidth * 0.75

			property int startCol:
				Math.floor((contentX + colStep * 0.5) / colStep)

			property int startIndex:
				startCol * WallpaperService.rows

			property int endIndex:
				startIndex + WallpaperService.columns * WallpaperService.rows
			
			onMovementEnded: {
				contentX = Math.round(contentX / colStep) * colStep
				Qt.callLater(() => requestFrame())
			}

			Behavior on contentX {
				NumberAnimation {
					duration: 150
					easing.type: Easing.BezierSpline
					easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
				}
			}
			
			// property int startRow:
			// 	Math.floor((contentY + rowStep * 0.5) / rowStep)

			// property int startIndex:
			// 	startRow * WallpaperService.columns

			// property int endIndex:
			// 	startIndex + WallpaperService.rows * WallpaperService.columns

			// onMovementEnded: {
			// 	contentY = Math.round(contentY / rowStep) * rowStep
			// 	Qt.callLater(() => {
			// 		requestFrame()
			// 	})
			// }
			
			// Behavior on contentY {
			// 	NumberAnimation {
			// 		duration: 150
			// 		easing.type: Easing.BezierSpline
			// 		easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
			// 	}
			// }
	
			Component.onCompleted: {
				flick.forceActiveFocus()
				flick.updateGridFocusOffset()
				
			}
				property real lastContentX: 0
				property int scrollDir: 0
				property int lastDir: 0
				property real dirThreshold: 0.5

				Connections {
					target: flick
					property int lastDir: 0

					function onContentXChanged() {
						var dx = flick.contentX - flick.lastContentX

						if (Math.abs(dx) > flick.dirThreshold) {

							// RIGHT = +
							// LEFT = -
							flick.scrollDir = dx > 0 ? 1 : -1

							if (flick.scrollDir !== lastDir) {
								// console.log(
								// 		flick.scrollDir > 0
								// 			? "scroll right"
								// 			: "scroll left"
								// 	)
								lastDir = flick.scrollDir
							}

							flick.lastContentX = flick.contentX
						}

						wallpaperController.requestFrame()
					}
				}
			// property real lastContentY: 0
			// property int scrollDir: 0
			// property int lastDir: 0
			// property real dirThreshold: 0.5

			
			// Connections {
			// 	target: flick
			// 	property int lastDir: 0

			// 		function onContentYChanged() {
			// 		var dy = flick.contentY - flick.lastContentY

			// 		if (Math.abs(dy) > flick.dirThreshold) {
			// 			flick.scrollDir = dy > 0 ? 1 : -1

			// 			if (flick.scrollDir !== lastDir) {
			// 				// console.log(flick.scrollDir > 0 ? "scroll ↓" : "scroll ↑")
			// 				lastDir = flick.scrollDir
			// 			}

			// 			flick.lastContentY = flick.contentY
			// 		}

			// 		wallpaperController.requestFrame()
			// 	}
			// 	// function onContentYChanged() {
			// 	// 	flick.scrollDir = flick.contentY > flick.lastContentY ? 1 : -1
			// 	// 	flick.lastContentY = flick.contentY
			// 	// 	wallpaperController.requestFrame()
				
			// 	// }
			// }

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

	

					
					// width: WallpaperService.columns * effectiveCellStepX
					// Derived value (important!)
					// width: gridWidth()
					
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
				


				function ripple(dx, dy, sx, sy, strength) {

					var selParity = sx % 2   // FIX: axis swap

					var shiftX = 0
					var shiftY = 0

					var upSide =
						dy < 0 ||
						(dx < 0 && sy + dy <= sy - (selParity === 0 ? 1 : 0)) ||
						(dx > 0 && sy + dy <= sy - (selParity === 0 ? 1 : 0))

					var downSide =
						dy > 0 ||
						(dx < 0 && sy + dy >= sy + (selParity === 0 ? 0 : 1)) ||
						(dx > 0 && sy + dy >= sy + (selParity === 0 ? 0 : 1))


					if (upSide) shiftY = -15 * strength
					else if (downSide) shiftY = 15 * strength

					if (dx < 0) shiftX = -10 * strength
					else if (dx > 0) shiftX = 10 * strength
					// if (upSide) shiftY = -15
					// else if (downSide) shiftY = 15

					// if (dx < 0) shiftX = -10
					// else if (dx > 0) shiftX = 10

					return Qt.point(shiftX, shiftY)
				}

				//vertical ripple
				// function ripple(dx, dy, sx, sy) {

				// 	var selParity = sy % 2

				// 	var shiftX = 0
				// 	var shiftY = 0

				// 	var leftSide =
				// 		dx < 0 ||
				// 		(dy < 0 && sx + dx <= sx - (selParity === 0 ? 1 : 0)) ||
				// 		(dy > 0 && sx + dx <= sx - (selParity === 0 ? 1 : 0))

				// 	var rightSide =
				// 		dx > 0 ||
				// 		(dy < 0 && sx + dx >= sx + (selParity === 0 ? 0 : 1)) ||
				// 		(dy > 0 && sx + dx >= sx + (selParity === 0 ? 0 : 1))

				// 	if (leftSide) shiftX = -15
				// 	else if (rightSide) shiftX = 15

				// 	if (dy < 0) shiftY = -10
				// 	else if (dy > 0) shiftY = 10

				// 	return Qt.point(shiftX, shiftY)
				// }
				
				// property real baseOffsetX: Math.max((flick.width - gridWidth()) / 2, 0)
				
				property real globalShiftX: 0
				property real globalShiftY: 0

				
				// function updateGridFocusOffset() {
				// 	if (!Config.options.effects.parallax) {
				// 		globalShiftX = 0
				// 		globalShiftY = 0
				// 		return
				// 	}

				// 	var selIndex = wallpaperController.currentIndex
				// 	var rows = WallpaperService.rows   // swapped

				// 	if (selIndex < 0) return
				// 	if (selIndex < startIndex || selIndex >= endIndex) {
				// 		globalShiftX = 0
				// 		globalShiftY = 0
				// 		return
				// 	}

				// 	var start = flick.startIndex
				// 	var localIndex = selIndex - start

				// 	// SWAP: col/row
				// 	var row = localIndex % rows
				// 	var col = Math.floor(localIndex / rows)

				// 	var visibleCols = Math.ceil(flick.width / flick.colStep)

				// 	var centerRow = (rows - 1) / 2
				// 	var centerCol = (visibleCols - 1) / 2

				// 	var offsetX = row - centerRow
				// 	var offsetY = col - centerCol

				// 	var newShiftX = -offsetX * 24
				// 	var newShiftY = -offsetY * 15

				// 	if (Math.abs(newShiftX - globalShiftX) < 0.01 &&
				// 		Math.abs(newShiftY - globalShiftY) < 0.01)
				// 		return

				// 	globalShiftX = newShiftX
				// 	globalShiftY = newShiftY
				// }	
				// function updateGridFocusOffset() {
				// 	if (!Config.options.effects.parallax) {
				// 		globalShiftX = 0
				// 		globalShiftY = 0
				// 		return
				// 	}

				// 	var selIndex = wallpaperController.currentIndex
				// 	var cols = WallpaperService.columns

				// 	if (selIndex < 0) return
				// 	if (selIndex < startIndex || selIndex >= endIndex) {
				// 		globalShiftX = 0
				// 		globalShiftY = 0
				// 		return
				// 	}

				// 	var start = flick.startIndex
				// 	var localIndex = selIndex - start

				// 	var col = localIndex % cols
				// 	var row = Math.floor(localIndex / cols)

				// 	var visibleRows = Math.ceil(flick.height / flick.rowStep)

				// 	var centerCol = (cols - 1) / 2
				// 	var centerRow = (visibleRows - 1) / 2

				// 	var offsetX = col - centerCol
				// 	var offsetY = row - centerRow

				// 	var newShiftX = -offsetX * 24
				// 	var newShiftY = -offsetY * 15

				// 	if (Math.abs(newShiftX - globalShiftX) < 0.01 &&
				// 		Math.abs(newShiftY - globalShiftY) < 0.01)
				// 		return

				// 	globalShiftX = newShiftX
				// 	globalShiftY = newShiftY
				// }

				
				function updateGridFocusOffset() {

					if (!Config.options.effects.parallax) {
						globalShiftX = 0
						globalShiftY = 0
						return
					}

					var selIndex = wallpaperController.currentIndex
					var rows = WallpaperService.rows

					if (selIndex < 0) return

					if (selIndex < startIndex || selIndex >= endIndex) {
						globalShiftX = 0
						globalShiftY = 0
						return
					}

					var start = flick.startIndex
					var localIndex = selIndex - start

					var row = localIndex % rows
					var col = Math.floor(localIndex / rows)

					var visibleCols =
						Math.ceil(flick.width / flick.colStep)

					var centerRow = (rows - 1) / 2
					var centerCol = (visibleCols - 1) / 2

					var offsetY = row - centerRow
					var offsetX = col - centerCol

					var newShiftX = -offsetX * 24
					var newShiftY = -offsetY * 15

					if (Math.abs(newShiftX - globalShiftX) < 0.01 &&
						Math.abs(newShiftY - globalShiftY) < 0.01)
						return

					globalShiftX = newShiftX
					globalShiftY = newShiftY
				}
				

				
					Behavior on globalShiftX {
						NumberAnimation {
							duration: 500
							easing.type: Easing.BezierSpline
							easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
						}
					}
					
					Behavior on globalShiftY {
						NumberAnimation {
							duration: 500
							easing.type: Easing.BezierSpline
							easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
						}
					}
						
					

					width:
						(WallpaperService.columns - 1) * colStep + flick.cellWidth
					
					
					property int totalCols: Math.ceil(filteredWallpapers.count / WallpaperService.rows)
					property real gridWidth: (totalCols - 1) * colStep + cellWidth
					property real offset: Math.max((flick.width - gridWidth) / 2, 0)
			


					
					property real cellHeightFactor: 0.95
					property real spacingYFactor: 0.8

					property real effectiveCellStepY:
						cellHeight * cellHeightFactor + spacingY * spacingYFactor

					property real gridHeight:
						WallpaperService.rows * effectiveCellStepY
						+ effectiveCellStepY / 2

					height: cardContainer.height

					
					// function baseY(index) {

					// 	var rows = WallpaperService.rows
					// 	var row = index % rows
					// 	var col = Math.floor(index / rows)

					// 	var step = effectiveCellStepY

					// 	var offset = (height - gridHeight) / 2

					// 	var y = offset + row * step

					// 	if (col % 2 === 1)
					// 		y += step / 2

					// 	return y
					// }
					

					property int cellHeight: _r * 2

					property int cellWidth: Math.round(cellHeight * Math.sqrt(3)/2 * 1.3) 
					


					property int spacingX: 10
					property int spacingY: 10
					Behavior on _r {
						NumberAnimation {
							duration: 180
							easing.type: Easing.OutCubic
						}
					}
					// Connections {
					// 	target: Config
					// 	function onReadyChanged() {
					// 		flick.columns =
					// 		Config.root.ready ? Config.options.layouts.columns : 5

					// 		flick.visibleRows =
					// 		Config.root.ready ? Config.options.layouts.rows : 4
					// 	}
					// }

					// property int columns: 5
							

					// property int visibleRows: 4
							
					// property int visibleRows: Config.options.layouts.rows
				

					

					// function itemPosX(i) {
					// 	return gridOffsetX() + baseX(i) + baseBiasX
					// }

					// function itemPosY(i) {
					// 	let row = Math.floor(i / WallpaperService.columns)
					// 	return row * rowStep + gridVerticalOffset()
					// }
					
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
			// 		x: wallpaperController.currentItem
			// 		? wallpaperController.currentItem.targetX
			// 		: 0

			// 		y: wallpaperController.currentItem
			// 		? wallpaperController.currentItem.targetY
			// 		- flick.contentY
				
			// 		: 0
			

			// 		scale: currentItem.visualWrapperRef.visualScale
			// 		opacity: 1
					
			// 		preferredRendererType: Shape.CurveRenderer
			// 		antialiasing: true

			// 		ShapePath {
			// 			strokeWidth: 4
			// 			strokeColor: colors.primary
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
			property real stepX: flick.colStep
			function visibleCols() {
    return Math.ceil(flick.width / flick.colStep)
}


property real gestureTime: 0.22   // seconds (feel)
property real step: flick.colStep
property real colsVisible: flick.width / step
property real wheelFactor: 0.25   // fraction of viewport per tick

		MouseArea {
			anchors.fill: parent
			focus: true

			propagateComposedEvents: true

				onWheel: (wheel) => {

					const maxX = flick.contentWidth - flick.width

					if ((flick.contentX <= 0 && wheel.angleDelta.y > 0) ||
						(flick.contentX >= maxX - 0.5 && wheel.angleDelta.y < 0)) {
						return
					}

					const scrollBias = 8
					let scale = Math.round(flick.width / flick.colStep) + scrollBias

					// KEEP RAW SIGN (CRITICAL)
					let v = wheel.angleDelta.y * scale

					flick.flick(v, 0)

					wheel.accepted = true
				}
			// onWheel: (wheel) => {

			// 	const maxX = flick.contentWidth - flick.width

			// 	if ((flick.contentX <= 0 && wheel.angleDelta.y > 0) ||
			// 		(flick.contentX >= maxX - 0.5 && wheel.angleDelta.y < 0)) {
			// 		return
			// 	}

			// 	let cols = Math.round(flick.width / flick.colStep)

			
			// 	let scale = cols + 7

			// 	let v = wheel.angleDelta.y * scale

			// 	flick.flick(v, 0)

			// 	wheel.accepted = true
			// }

			// onWheel: (wheel) => {
			// 	const maxX = flick.contentWidth - flick.width

			// 	const atStart = flick.contentX <= 0
			// 	const atEnd = flick.contentX >= maxX - 0.5

			// 	if (atEnd && wheel.angleDelta.y < 0) return
			// 	if (atStart && wheel.angleDelta.y > 0) return

			// 	flick.flick(wheel.angleDelta.y * 12, 0)
			// 	wheel.accepted = true
			// }

			onClicked: (mouse) => {
				flick.forceActiveFocus()
				mouse.accepted = false
			}
		}

   		Keys.enabled: true
	

		Keys.onPressed: function(event) {

    let oldIndex = wallpaperController.currentIndex

   let handled = InputHandler.navigate(event, {
		size: filteredWallpapers.count,
		rows: WallpaperService.rows,   // correct axis base
		currentIndex: oldIndex,

		onApply: (i) =>
			WallpaperApplyService.applyWallpaper(filteredWallpapers[i]),

		onMove: (i) => {
			flick.cancelFlick()
			wallpaperController.previousIndex = wallpaperController.currentIndex
			wallpaperController.currentIndex = i
			smartScroll(i, oldIndex)
		}
	})

		if (handled)
			event.accepted = true
	}

	function smartScroll(i, oldIndex) {

    let rows = WallpaperService.rows
    let col = Math.floor(i / rows)

    let colLeft = col * flick.colStep
    let colRight = colLeft + flick.colStep

    let viewLeft = flick.contentX
    let viewRight = flick.contentX + flick.width

    let maxCol =
        Math.ceil(filteredWallpapers.count / rows) - 1

    // LEFT
    if (colLeft < viewLeft) {
        flick.contentX = Math.max(0, colLeft)
        return
    }

    // RIGHT
    if (colRight > viewRight) {

        let visibleCols =
            Math.floor(flick.width / flick.colStep)

        let target =
            col - visibleCols + 1

        target = Math.max(0, target)
        target = Math.min(maxCol, target)

        flick.contentX = target * flick.colStep
        return
    }
}


		function snap() {
			flick.contentY =
				Math.round(flick.contentY / flick.rowStep) * flick.rowStep
		}

					
					// model: Math.ceil(filteredWallpapers.count / WallpaperService.columns)
					model: Math.ceil(filteredWallpapers.count / WallpaperService.rows)
					// property real _fadeZone: flick.rowStep
				
					add: Transition {
						NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 800; easing.type: Easing.OutCubic }
						NumberAnimation { property: "scale"; from: 0.25; to: 1; duration: 800; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
					
					}
					remove: Transition {
						NumberAnimation { property: "opacity"; to: 0; duration: 180; easing.type: Easing.InCubic }
					}
					// displaced: Transition {
					// 	NumberAnimation { properties: "x,y"; duration: 180; easing.type: Easing.OutCubic }
					// }

					delegate: Item {
						id: colItem
						// width: flick.width
						// height: flick.rowStep
						// property int rowIndex: index
						width: flick.colStep
						height: flick.height
						property int colIndex: index
						// visible: false
						opacity: WatcherService.thumbsGenerated ? 1 : 0
						readonly property real _colCenter: (x - flick.contentX) + width * 0.5
						
						
					

		

						property real _arcFactor: Config.options.hexArc.enabled ? Config.options.hexArc.intensity : 0
						Behavior on _arcFactor { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }

						readonly property real _arcOffset: {
						if (_arcFactor === 0) return 0
						var viewCenterX = flick.width / 2
						var normalized = (_colCenter - viewCenterX) / Math.max(1, viewCenterX)
						return -normalized * normalized * flick._r * _arcFactor
						}
						
						Repeater {
							id: hexRepeater
							model: Math.max(
							0,
							Math.min(
									WallpaperService.rows,
									filteredWallpapers.count - colIndex * WallpaperService.rows
								)
							)
							// model: Math.max(
							// 	0,
							// 	Math.min(
							// 		WallpaperService.columns,
							// 		filteredWallpapers.count - rowIndex * WallpaperService.columns
							// 	)
							// )
							
							delegate: HexItem {
								id: hexItem
								controller: wallpaperController
								property int rowIndex: index
								// property bool isReady: false
								// visible: true
								// Component.onCompleted: {
								// 	isReady = true
								// }
								states: [
									State {
										name: "in"
										when: _inView
										PropertyChanges {
											target: hexItem
											_colScale: 1
										}
									},
									State {
										name: "out"
										when: !_inView
										PropertyChanges {
											target: hexItem
											_colScale: 0
										}
									},
								]
									 
								transitions: [
								    // ENTER
								    Transition {
								        from: "out"
								        to: "in"
										NumberAnimation {
											properties: "_colScale"
											from: 0
											to: 1
											duration: 300
											// easing.type: Easing.InExpo
											// easing.type: Easing.InOutQuart
											// easing.type: Easing.OutBack
											// easing.overshoot: 1.4
											easing.type: Easing.BezierSpline
											easing.bezierCurve: [0.18, 1.0, 0.3, 1.0]
										}
							
								    },
									
								    // EXIT HexItem
								    Transition {
								        from: "in"
								        to: "out"
								       	NumberAnimation {
											duration: 300
											properties: "_colScale"
											from: 1; 
											to: 0
											easing.type: Easing.OutBack
											// easing.overshoot: 1.4
										}
								    },
											// easing.type: Easing.OutExpo
											// easing.type: Easing.OutQuart
											// easing.type: Easing.OutBack
											
								]
										
								// property int flatIndex: rowIndex * WallpaperService.columns + index
								property int flatIndex: colIndex * WallpaperService.rows + index	
								property bool _isSelected: wallpaperController.currentIndex === flatIndex

								property int cols: WallpaperService.columns
									
								
								// property real itemCenterY: y + height * 0.5
								// property real viewCenterY: flick.contentY + flick.height * 0.5
								// property bool _nearTop: itemCenterY < viewCenterY - deadZone
								property real deadZone: 20
								property real itemCenterX: x + width * 0.5
								// property real viewCenterX: flick.contentX + width * 0.5
								// property bool _nearLeft: itemCenterX < viewCenterX
								readonly property real _colCenter: (x - flick.contentX) + width * 0.5
								readonly property bool _nearLeft: _colCenter < flick.width / 2
								// readonly property bool _insideView: _colCenter > -hexListView._hexW && _colCenter < hexListView.width + hexListView._hexW
								// readonly property bool _nearEdge: _colCenter < hexListView._fadeZone || _colCenter > (hexListView.width - hexListView._fadeZone)
								property bool _inView: flatIndex >= flick.startIndex &&
										flatIndex < flick.endIndex
								property int rows: WallpaperService.rows

								property int hoveredIdx: wallpaperController.hoveredIndex
								property int hx: Math.floor(hoveredIdx / rows)
								property int hy: hoveredIdx % rows

								property int hdx: xIdx - hx
								property int hdy: yIdx - hy
								
								property bool _hoverRippleOff:
									hoveredIdx < flick.startIndex || hoveredIdx >= flick.endIndex


								property int selIndex: wallpaperController.currentIndex
								property int sx: Math.floor(selIndex / rows)   // was % cols
								property int sy: selIndex % rows               // was / cols

								property int xIdx: Math.floor(flatIndex / rows)
								property int yIdx: flatIndex % rows

								property int dx: xIdx - sx
								property int dy: yIdx - sy

								property bool _rippleOff:
									selIndex < flick.startIndex || selIndex >= flick.endIndex

								property var _hoverRipple: flick.ripple(hdx, hdy, hx, hy, 0.5)
								property var _ripple:
									flick.ripple(dx, dy, sx, sy, 1.0)
									
								// property int selIndex: wallpaperController.currentIndex
								// property int sx: selIndex % cols
								// property int sy: Math.floor(selIndex / cols)

								// property int xIdx: flatIndex % cols
								// property int yIdx: Math.floor(flatIndex / cols)

								// property int dx: xIdx - sx
								// property int dy: yIdx - sy
								
								// property bool _rippleOff: selIndex < flick.startIndex || selIndex >= flick.endIndex
								// property var _ripple: flick.ripple(dx, dy, sx, sy) 
								// originFixY: (transformOrigin === Item.Top) ? height * 0.5 : -height * 0.5
								 
								// property real _colScale: 0
								// property real _selectedScale: _isSelected ? 1.125 : 1
								property real _colScale: 0
								// Behavior on _colScale { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
								scale: _colScale
								// Behavior on scale {
								// 	// enabled: flickRef.firstUpdateDone
								// 	NumberAnimation {
								// 		duration: 400
								// 		easing.type: Easing.BezierSpline
								// 		easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
								// 	}
								// }
								opacity: _colScale < 0.01 ? 0 : 1
								// opacity: _inView ? 1 : 0
								Behavior on opacity { 
									NumberAnimation { 
										duration: 250; 
										easing.type: Easing.InOutQuad 
										// easing.type: Easing.InOutQuad 
										// easing.type: Easing.InCubic
									} 
								}

								// Component.onCompleted: {
								// 	_colScale = 0
								// 	opacity = 1   // visible immediately
								// 	Qt.callLater(() => _colScale = 1)
								// }
								// x: colIndex * flick._stepX / 2
								viewY:
								((flick.height - flick.gridHeight) / 2)
								+ rowIndex * flick.effectiveCellStepY
								+ (colItem.colIndex % 2 ? flick.effectiveCellStepY / 2 : 0)
								viewX: flick.offset
								
								// y: flick._yOffset + rowIndex * flick._stepY + (colItem.colIndex % 2 !== 0 ? flick._hexH / 2 : 0) + colItem._arcOffset
								arcOffset: colItem._arcOffset
								shiftX: flick.globalShiftX
								shiftY: flick.globalShiftY
								// rowScale: _colScale
								container: flick
								flickRef: flick
								rippleOff: _rippleOff
								ripple: _ripple
								hoverRipple: _hoverRipple
								hoverRippleOff: _hoverRippleOff

								parallaxX: {
									var viewCenterX = flick.width / 2
									var hexCenterX = x + width / 2

									var normalized = (hexCenterX - viewCenterX) / Math.max(1, viewCenterX)
									var falloffFactor = 1.0 + Math.abs(normalized) * 0.2
									return -normalized * flick._r * 0.45 * falloffFactor
								}

								parallaxY: {
									var viewCenterY = flick.height / 2
									var hexCenterY = y + height / 2

									var normalized = (hexCenterY - viewCenterY) / Math.max(1, viewCenterY)
									var falloffFactor = 1.0 + Math.abs(normalized) * 0.2
									return -normalized * flick._r * 0.45 * falloffFactor
								}
								// parallaxX: {
								// var viewCenterX = flick.width / 2
								// var hexCenterX = x + width / 2
								// var normalized = (hexCenterX - viewCenterX) / Math.max(1, viewCenterX)

								// return -normalized * flick._r * 0.6
								// }
								
								// parallaxY: {
								// var viewCenterY = flick.height / 2
								// var hexCenterY = y + height / 2
								// var normalized = (hexCenterY - viewCenterY) / Math.max(1, viewCenterY)
							
								// return -normalized * flick._r * 0.6
								// }
								
								// hexBorder: highlightContainer
								// scale: _colScale
								itemData: filteredWallpapers.get(flatIndex)
								itemIndex: flatIndex
								inView: _inView
								// transformOrigin: Item.Center
								// transformOrigin: {
								// 	if (isSelected) return Item.Center
								// 	if (flick.scrollDir < 0) {
								// 		// scroll up → original
								// 		return _nearTop ? Item.Top : Item.Bottom
								// 	} else {
								// 		// scroll down → flipped
								// 		return _nearTop ? Item.Bottom : Item.Top
								// 	}
								// }
								// property bool entering: _inView && _colScale === 0
								clampDir: flick.scrollDir === 0 ? 1 : flick.scrollDir
								// transformOrigin: colItem._nearLeft ? Item.Left : Item.Right
								// transformOrigin: {
								// 	if (isSelected) return Item.Center

								// 	if (flick.scrollDir < 0) {
								// 		return _nearLeft ? Item.Right : Item.Left
								// 	} else {
								// 		return _nearLeft ? Item.Left : Item.Right
								// 	}
								// }
								// transformOrigin: {
								// 	if (isSelected) return Item.Center

								// 	if (flick.scrollDir < 0) {
								// 		// scroll left
								// 		return _nearLeft ? Item.Left : Item.Right
								// 	} else {
								// 		// scroll right
								// 		return _nearLeft ? Item.Right : Item.Left
								// 	}
								// }
								// transformOrigin: {
								// 	if (isSelected)
								// 		return Item.Center

								// 	var entering = scale < 1 && inView

								// 	if (flick.scrollDir < 0) {
								// 		return entering
								// 			? (_nearLeft ? Item.Left : Item.Right)   // appear outside→inside
								// 			: (_nearLeft ? Item.Right : Item.Left)   // disappear fade out
								// 	} else {
								// 		return entering
								// 			? (_nearLeft ? Item.Right : Item.Left)
								// 			: (_nearLeft ? Item.Left : Item.Right)
								// 	}
								// }
							
							}

								
															// targetX: _inView ?
								// flick.baseX(flatIndex) + ripple.x : flick.baseX(flatIndex)
    							// targetY: _inView ?
								// flick.baseY(flatIndex) + ripple.y : flick.baseY(flatIndex)
						}
					}
			}
			
	
	
	
		
	

		// SettingsPanel{}


    
}
}