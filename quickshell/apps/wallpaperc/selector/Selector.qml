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
	// property var colors: Colors {}
	
	property var filteredWallpapers: WallpaperService.wallpapers   // initially same as full list
	property int filteredModel: filteredWallpapers ? filteredWallpapers.length : 0

	Component.onCompleted: {
		cardShowTimer.start()
		
	}
	

	// property ListModel filteredWallpapers: WallpaperService.wallpapers
	// property ListModel filteredWallpapers: ListModel {}

	// function syncFiltered() {
	// 	let src = WallpaperService.wallpapers

	// 	filteredWallpapers.clear()

	// 	let i = 0

	// 	function step() {
	// 		const batch = 50

	// 		for (let j = 0; j < batch && i < src.length; j++, i++)
	// 			filteredWallpapers.append(src.get(i))

	// 		if (i < src.length)
	// 			Qt.callLater(step)
	// 	}

	// 	step()
	// }

	
	// Connections {
	// 	target: WallpaperService.wallpapers

	// 	function onCountChanged() {
	// 		syncFiltered()
	// 	}
	// }
	property bool isHorizontal: Config.options.orientation.isHorizontal

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
	// 					wallpaperController.previousIndex < wallpaperRepeater.length)
	// 					? wallpaperRepeater.itemAt(wallpaperController.previousIndex)
	// 					: null

	// Path
	
	property string homeDir: ""
	property string wallpaperDir: ""
	property string savedWallpaperDir: ""

	

	// Computed property for convenience
	// property Item currentItem: (wallpaperController.currentIndex >= 0 && wallpaperController.currentIndex < wallpaperRepeater.length)
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
			// flick.height = flick.hCellHeight
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

	// property bool allowAnim: false
	// Connections {
	// 	target: Config.options.orientation
	// 	function onIsHorizontalChanged() {
	// 		wallpaperController.currentIndex = 0

	// 		if(isHorizontal) {
	// 			flick.vOuterParallax()
	// 		} else {
	// 			flick.hOuterParallax()
	// 		}
	// 	}
	// }
	
	Connections {
		target: Config.options.effects

		function onPixelChanged() {
			console.log(
				"pixel effect:", Config.options.effects.pixel
			)
		}
	}

	
		// wallpaperController.cardVisible = true
		// scaleDelayTimer.start()
		// selectedItem.visualWrapperRef.width = flick.hCellWidth - 10
		// selectedItem.visualWrapperRef.height = flick.hCellHeight - 10
		// console.log("path: " + Config.options.wallpaperDir)
		// console.log("thumbs generated: ", WatcherService.thumbsGenerated)
		// console.log("pathisempty: ", WatcherService.pathEmpty)

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
		if(isHorizontal) {
			flick.hOuterParallax()
		} else {
			flick.vOuterParallax()
		}
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
	
	property int hexRadius: 85
	Behavior on hexRadius { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }
	property int hexRows: WallpaperService.rows
	property int hexCols: WallpaperService.columns
	Behavior on hexRows { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }
	Behavior on hexCols { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }


	property int cardHeight: hexhGridHeight
	property int hexCardWidth: selectorPanel.width
	property int cardWidth: hexCardWidth
	Behavior on cardWidth { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }
	
	property int hexhGridHeight: {
		var rows = hexRows
		var r = 105
		var spacing = 6
		var hexH = Math.ceil(r * 1.73205)
		var stepY = hexH + spacing
		var contentH = (rows - 1) * stepY + hexH + hexH / 2
		return contentH + 90
	}
	
  	Behavior on cardHeight { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
    

	property bool pathChanged: false

	// Connections {
	// 	target: wallpaperController
	// 	function onFilteredWallpapersChanged() {
	// 		pathChanged = true
    //     	Qt.callLater(() => pathChanged = false)
	// 	}
	// }
	// Timer {
	// 	id: pathTimer
	// 	interval: 0
	// 	repeat: false
	// 	running: false

	// 	onTriggered: {
	// 		wallpaperController.pathChanged = true
	// 	}
	// }

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

		// HyprlandFocusGrab {
		// 	windows: [ selectorPanel ]
		// 	active: wallpaperController.cardVisible
		// }
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

	// property real paddingY: flick.hCellHeight * 0.5
	
	// property real hGridWidth:
    // WallpaperService.columns * flick.effectiveCellStepX

	// property real paddingX:
	// flick.hGridWidth + flick.hCellWidth
	// // property real paddingX: Math.max(flick.hCellWidth, flick.width + flick.hCellWidth * 0.5 * 2) 
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
		anchors.centerIn: parent
		Layout.fillWidth: true
		color: "transparent"
		// border.color: "red"
		// border.width: 1
		width: parent.width
    	height: parent.height
		// STATE
		property bool isLoading: !WatcherService.thumbsGenerated && !WatcherService.pathEmpty
		property bool isEmpty: !WatcherService.thumbsGenerated && WatcherService.pathEmpty
		property bool isDone: WatcherService.thumbsGenerated

		// opacity: wallpaperController.cardVisible ? 1 : 0
		NumberAnimation {
			id: stateAnim
			target: selectorState
			property: "opacity"
			duration: 350 // different
			easing.type: Easing.InQuad
		}

		onIsLoadingChanged: {
			stateAnim.from = 0
			stateAnim.to = 1
			stateAnim.restart()
		
		}

		onIsEmptyChanged: {
			stateAnim.from = 0
			stateAnim.to = 1
			stateAnim.restart()
			
		}
		
		

		Behavior on opacity {
			NumberAnimation {
				duration: 150
				easing.type: Easing.InOutQuad
			}
		}

		

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
	// prevent clicks from closing when clicking inside
	MouseArea {
		anchors.fill: parent
		onClicked: {}
	}
}

	

	
    // Item {
    //     id: keyRoot
    //     anchors.fill: parent
    //     focus: true
	// 	clip: false
    	

	
		
		ListView {
			id: flick
			visible: wallpaperController.cardVisible
			anchors.horizontalCenter: cardContainer.horizontalCenter
			anchors.verticalCenter: cardContainer.verticalCenter
			
			// opacity: (WatcherService.thumbsGenerated
			// ) ? 1 : 0
			
			// Behavior on opacity { 
			// 	// enabled: pathChanged
			// 	NumberAnimation { 
			// 		duration: 350; 
			// 		easing.type: Easing.InOutQuad 
			// 	} 
			// }

			// Component.onCompleted: {
			// 	hexRows = WallpaperService.rows
			// 	hexCols = WallpaperService.columns
			// }
			property bool listViewShown: true
			NumberAnimation {
				id: listViewFade
				target: flick
				property: "opacity"
				duration: 350
				easing.type: Easing.InQuad
				onStarted: {
					flick.listViewShown = false
				}
    			onStopped: {
					flick.listViewShown = true
				}
			}
			property bool _layoutLock: false

	

			// anchors.centerIn: parent
			// Layout.alignment:
			boundsBehavior: Flickable.StopAtBounds
			flickDeceleration: 1500
			maximumFlickVelocity: 3000

			// property bool listViewFade: false



			Connections {
				target: wallpaperController
				function onFilteredWallpapersChanged() {
					listViewFade.from = 0
					listViewFade.to = 1
					listViewFade.restart()
					// flick.forceActiveFocus()
				}
			}

			orientation: isHorizontal 
			? ListView.Horizontal : ListView.Vertical

			// flickableDirection: isHorizontal
			// ? Flickable.HorizontalFlick
			// : Flickable.VerticalFlick

			
			Layout.fillHeight: true
			Layout.fillWidth: true
	
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
			// contentWidth:
    		// Math.ceil((filteredWallpapers ? filteredModel : 0) / WallpaperService.rows) * colStep
			// contentHeight: 
			// Math.ceil((filteredWallpapers ? filteredModel : 0) / WallpaperService.columns) * rowStep
			
			// contentWidth:
    		// Math.ceil(filteredModel / WallpaperService.rows) * colStep
			// contentHeight: 
			// Math.ceil(filteredModel / WallpaperService.columns) * rowStep

			// contentHeight: Math.ceil(filteredModel / WallpaperService.columns) * rowStep
			
			
			// function applyVisual(item, scale, opacity) {
			// 	item.visualWrapperRef.visualScale = scale
			// 	item.visualWrapperRef.fadeOpacity = opacity
			// }

		

			
		
				// if(isHorizontal) {
				// 		flick.vOuterParallax()
				// 	} else {
				// 		flick.hOuterParallax()
				// 	}


			// property int _rows: isHorizontal ?
			// wallpaperController.hexCols : wallpaperController.hexRows 
			// property int _cols: isHorizontal ?
			// wallpaperController.hexRows : wallpaperController.hexCols
			// property int contentCols: isHorizontal
			// 	? WallpaperService.rows
			// 	: WallpaperService.columns

			// property int contentRows: isHorizontal
			// 	? WallpaperService.columns
			// 	: WallpaperService.rows
			
			onOrientationChanged: {		

				wallpaperController.currentIndex = 0

				listViewFade.from = 0
				listViewFade.to = 1
				listViewFade.restart()
				globalShiftX = 0
				globalShiftY = 0
				if(isHorizontal) {
                    flick.vOuterParallax()
                } else {
                    flick.hOuterParallax()
                }  
				// _contentWidth = Math.ceil(filteredModel / _cols) * colStep
				// _contentHeight = Math.ceil(filteredModel / _rows) * rowStep
				
				Qt.callLater(() => {
				
					flick.forceActiveFocus()
				})

				
			}
		

			// property int visibleCols:
			// Math.floor((flick.width ? flick.width : 0) / flick._stepX)
			// property int visibleRows:
			// Math.ceil((flick.height ? flick.height : 0) / flick._stepY)
			
			property int _rows: WallpaperService.rows
			property int _cols: WallpaperService.columns

			

			property real _contentWidth: Math.ceil(filteredModel / _cols) * colStep
		    property real _contentHeight: Math.ceil(filteredModel / _rows) * rowStep

			contentWidth: listViewShown ? _contentWidth : 0
			contentHeight: listViewShown ? _contentHeight : 0

			
	
		
			property real rowStep: flick.vCellHeight * 0.75
			property real colStep: flick.hCellWidth * 0.75

			property int hStartCol:
				Math.floor((contentX + colStep * 0.5) / colStep)

			property int hStartIndex:
				hStartCol * _rows
				
			property int hEndIndex: Math.min(
				filteredModel,
				hStartIndex + _rows * _cols
			)
			
			property int vStartRow:
				Math.floor((contentY + rowStep * 0.5) / rowStep)

			property int vStartIndex:
				vStartRow * _cols

			property int vEndIndex:
				Math.min(
					filteredModel,
					vStartIndex + _cols * _rows
				)

			onMovementEnded: {
				if(!flick.listViewShown) return
				Qt.callLater(() => {
					if (isHorizontal) {

					contentX = Math.round(contentX / colStep) * colStep
					}
					else {

					contentY = Math.round(contentY / rowStep) * rowStep
					}
					requestFrame()
				})
			}

			
			Behavior on contentX {
				enabled: flick.listViewShown && isHorizontal
				NumberAnimation {
					duration: 150
					easing.type: Easing.BezierSpline
					easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
				}
			}

			Behavior on contentY {
				enabled: flick.listViewShown && !isHorizontal
				NumberAnimation {
					duration: 150
					easing.type: Easing.BezierSpline
					easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
				}
			}
			
	
			
				property real lastContentX: 0
				property int scrollDirX: 0
				property int lastDirX: 0
				property real dirThreshold: 0.5

				property real lastContentY: 0
				property int scrollDirY: 0
				property int lastDirY: 0
			

				Connections {
					target: flick
					

					function onContentXChanged() {

						if (!flick.listViewShown) return
						var dx = flick.contentX - flick.lastContentX

						if (Math.abs(dx) > flick.dirThreshold) {

							// RIGHT = +
							// LEFT = -
							flick.scrollDirX = dx > 0 ? 1 : -1

							if (flick.scrollDirX !== flick.lastDirX) {
								flick.lastDirX = flick.scrollDirX
							}

							flick.lastContentX = flick.contentX
						}

						wallpaperController.requestFrame()
					}

					function onContentYChanged() {
							if (!flick.listViewShown) return
						var dy = flick.contentY - flick.lastContentY

						if (Math.abs(dy) > flick.dirThreshold) {

							flick.scrollDirY = dy > 0 ? 1 : -1

							// console.log(flick.scrollDirY > 0 ? "DOWN" : "UP")

							if (flick.scrollDirY !== flick.lastDirY) {
								flick.lastDirY = flick.scrollDirY
							}

							flick.lastContentY = flick.contentY
						}

						wallpaperController.requestFrame()
					}
				}
		
				

				// horizontal ripple
				function hRipple(dx, dy, sx, sy, strength) {

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

					return Qt.point(shiftX, shiftY)
				}

				//vertical ripple
				function vRipple(dx, dy, sx, sy, strength) {

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

					if (leftSide) shiftX = -15 * strength
					else if (rightSide) shiftX = 15 * strength

					if (dy < 0) shiftY = -10 * strength
					else if (dy > 0) shiftY = 10 * strength

					return Qt.point(shiftX, shiftY)
				}
				
				property real globalShiftX: 0
				property real globalShiftY: 0
				property bool parallaxAnimating: false
				
				function hOuterParallax() {

					if(!isHorizontal) return
					if (!Config.options.effects.parallax) {
						globalShiftX = 0
						globalShiftY = 0
						return
					}

					var selIndex = wallpaperController.currentIndex
					

					if (selIndex < 0) return

					if (selIndex < hStartIndex || selIndex >= hEndIndex) {
						globalShiftX = 0
						globalShiftY = 0
						return
					}

					var localIndex = selIndex - hStartIndex

					var col = localIndex % _cols
					var row = Math.floor(localIndex / _cols)

				

					var centerCol = (_cols - 1) / 2
					var centerRow = (_rows - 1) / 2

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
				
				function vOuterParallax() {

					if(!isHorizontal) return
					
					if (!Config.options.effects.parallax) {
						globalShiftX = 0
						globalShiftY = 0
						return
					}

					var selIndex = wallpaperController.currentIndex
					

					if (selIndex < 0) return
					if (selIndex < vStartIndex || selIndex >= vEndIndex) {
						globalShiftX = 0
						globalShiftY = 0
						return
					}

					var localIndex = selIndex - vStartIndex

					var col = localIndex % _cols
					var row = Math.floor(localIndex / _cols)

					

					var centerCol = (_cols - 1) / 2
					var centerRow = (_rows - 1) / 2

					var offsetX = col - centerCol
					var offsetY = row - centerRow

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
					// width:
					// 	(WallpaperService.columns - 1) * colStep + flick.hCellWidth
					
					// height: cardContainer.height

					// width: parent.width 

					// height:
					// 	(WallpaperService.rows - 1) * rowStep
					// 	+ flick.cellHeight

					// width: (WallpaperService.columns - 1) * colStep + flick.hCellWidth
					
					// height: cardContainer.height

					property real hWidth:
						(WallpaperService.columns - 1) * colStep
						+ flick.hCellWidth

					property real vWidth:
						cardContainer.width

					property real hHeight:
						cardContainer.height

					property real vHeight:
						(WallpaperService.rows - 1) * rowStep
						+ flick.vCellHeight

					

					width: isHorizontal 
					? (WallpaperService.columns - 1) * colStep + flick.hCellWidth : cardContainer.width
					
					height: isHorizontal
					? cardContainer.height : (WallpaperService.rows - 1) * rowStep + flick.vCellHeight
					
				
					
					property int totalCols: Math.ceil(filteredModel / WallpaperService.rows)
					
					// horizontal grid layout
					property real hGridWidth: (totalCols - 1) * colStep + hCellWidth
					property real hGridHeight:
						WallpaperService.rows * effectiveCellStepY
						+ effectiveCellStepY / 2
					
					// vertical grid layout
					property real vGridWidth:
					WallpaperService.columns * effectiveCellStepX + effectiveCellStepX / 2
					property real vGridHeight:
					(totalRows - 1) * rowStep + vCellHeight


				

					property int totalRows:
					Math.ceil(filteredModel / WallpaperService.columns)
				
					property real hOffset: Math.max((
						((WallpaperService.columns - 1) * colStep + flick.hCellWidth) - hGridWidth) / 2, 0)
					property real vOffset:
					Math.max((
						((WallpaperService.rows - 1) * rowStep + flick.vCellHeight) - vGridHeight) / 2, 0)
					


					
					property real cellHeightFactor: 0.95
					property real spacingYFactor: 0.8

					property real effectiveCellStepY:
						hCellHeight * cellHeightFactor + spacingY * spacingYFactor
					

					property real cellWidthFactor: 0.95
					property real spacingXFactor: 0.8
					property real effectiveCellStepX: cellWidth * cellWidthFactor + spacingX * spacingXFactor
					
					

					

					property int hCellHeight: _r * 2
					property int hCellWidth: Math.round(hCellHeight * Math.sqrt(3)/2 * 1.3)
					
					property int vCellWidth: _r * 2
					property int vCellHeight: Math.round(vCellWidth * Math.sqrt(3)/2 * 1.2) 
					
					property int cellHeight: wallpaperController.isHorizontal
					? hCellHeight : vCellHeight

					property int cellWidth: wallpaperController.isHorizontal
					? hCellWidth : vCellWidth
					
					// property real hGridHeight:
					// (totalRows - 1) * rowStep + vCellHeight
					// property real hOffset: Math.max((flick.width - hGridWidth) / 2, 0)
					// property real vOffset:
					// Math.max((flick.height - hGridHeight) / 2, 0)
					// Behavior on hCellHeight { NumberAnimation { duration: 350; } }
					// Behavior on hCellWidth { NumberAnimation { duration: 350; } }
					// Behavior on vCellHeight { NumberAnimation { duration: 350; } }
					// Behavior on vCellWidth { NumberAnimation { duration: 350; } }
					// 	Behavior on cellHeight { NumberAnimation { duration: 200; 
					// 	 easing.type: Easing.BezierSpline
					// easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
					// 	} }
					// 	Behavior on cellWidth { NumberAnimation { duration: 200; 
					// 	 easing.type: Easing.BezierSpline
					// easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
					// 	} }

					property real _base: _r * 2	
					property int spacingX: 10
					property int spacingY: 10
					Behavior on _r {
						NumberAnimation {
							duration: 180
							easing.type: Easing.OutCubic
						}
					}
				

			property real stepX: flick.colStep
			// function visibleCols() {
			// 	return Math.ceil(flick.width / flick.colStep)
			// }


		MouseArea {
			anchors.fill: parent
			focus: true

			propagateComposedEvents: true
			onWheel: (wheel) => {
				// if(!flick.listViewShown) return
				const isH = isHorizontal

				const max = isH
					? flick.contentWidth - flick.width
					: flick.contentHeight - flick.height

				const pos = isH ? flick.contentX : flick.contentY

				if ((pos <= 0 && wheel.angleDelta.y > 0) ||
					(pos >= max - 0.5 && wheel.angleDelta.y < 0)) {
					return
				}

				const bias = 7
				const scale = isH
					? Math.round(flick.width / flick.colStep) + bias
					: Math.round(flick.height / flick.rowStep) + bias

				const v = wheel.angleDelta.y * scale

				if (isH) flick.flick(v, 0)
				else      flick.flick(0, v)

				wheel.accepted = true
			}
				// onWheel: (wheel) => {

				// 	const maxX = flick.contentWidth - flick.width

				// 	if ((flick.contentX <= 0 && wheel.angleDelta.y > 0) ||
				// 		(flick.contentX >= maxX - 0.5 && wheel.angleDelta.y < 0)) {
				// 		return
				// 	}

				// 	const scrollBias = 8
				// 	let scale = Math.round(flick.width / flick.colStep) + scrollBias

				// 	// KEEP RAW SIGN (CRITICAL)
				// 	let v = wheel.angleDelta.y * scale

				// 	flick.flick(v, 0)

				// 	wheel.accepted = true
				// }
		

			onClicked: (mouse) => {
				flick.forceActiveFocus()
				mouse.accepted = false
			}
		}

   		Keys.enabled: true
	
		function snapTo(i) {

			flick.cancelFlick()
			flick.contentX = flick.contentX
			flick.contentY = flick.contentY

			let rows = WallpaperService.rows
			let cols = WallpaperService.columns

			if (isHorizontal) {
				let col = Math.floor(i / rows)
				flick.contentX = col * flick.colStep
			} else {
				let row = Math.floor(i / cols)
				flick.contentY = row * flick.rowStep
			}
		}
		Keys.onPressed: function(event) {

			let oldIndex = wallpaperController.currentIndex

			let ctx = {
				size: filteredModel,
				currentIndex: oldIndex,

				rows: WallpaperService.rows,
				columns: WallpaperService.columns,

				onApply: (i) =>
					WallpaperApplyService.applyWallpaper(filteredWallpapers[i]),

				onMove: (i) => {
					flick.cancelFlick()
					wallpaperController.previousIndex = wallpaperController.currentIndex
					wallpaperController.currentIndex = i
					Qt.callLater(() => {
						smartScroll(i, oldIndex)
					})
				}
			}

			let handled = isHorizontal
				? InputHandler.hNavigate(event, ctx)
				: InputHandler.vNavigate(event, ctx)

			if (handled)
				event.accepted = true
		}

		function smartScroll(i, oldIndex) {

			if (isHorizontal) {

				let rows = WallpaperService.rows
				let col = Math.floor(i / rows)

				let colLeft = col * flick.colStep
				let colRight = colLeft + flick.colStep

				let viewLeft = flick.contentX
				let viewRight = flick.contentX + flick.width

				let maxCol = Math.ceil(filteredModel / rows) - 1

				if (colLeft < viewLeft) {
					flick.contentX = Math.max(0, colLeft)
					return
				}

				if (colRight > viewRight) {

					let visibleCols = Math.floor(flick.width / flick.colStep)

					let target = col - visibleCols + 1

					target = Math.max(0, Math.min(maxCol, target))

					flick.contentX = target * flick.colStep
					return
				}

			} else {

				let cols = WallpaperService.columns
				let row = Math.floor(i / cols)

				let rowTop = row * flick.rowStep
				let rowBottom = rowTop + flick.rowStep

				let viewTop = flick.contentY
				let viewBottom = flick.contentY + flick.height

				let maxRow = Math.floor((filteredModel - 1) / cols)

				if (rowTop < viewTop) {
					flick.contentY = Math.max(0, rowTop)
					return
				}

				if (rowBottom > viewBottom) {

					let visibleRows = Math.floor(flick.height / flick.rowStep)

					let target = row - visibleRows + 1

					target = Math.max(0, Math.min(maxRow, target))

					flick.contentY = target * flick.rowStep
					return
				}
			}
		}


		// function snap() {
		// 	flick.contentY =
		// 		Math.round(flick.contentY / flick.rowStep) * flick.rowStep
		// }

					
					// model: Math.ceil(filteredModel / WallpaperService.rows)
					// model: Math.ceil(
					// 	filteredModel /
					// 	WallpaperService.rows
					// )
					// model: Math.ceil(
					// 	filteredModel /
					// 	Math.min(
					// 		WallpaperService.rows,
					// 		WallpaperService.columns
					// 	)
					// )
					// property real _fadeZone: flick.rowStep

					// function colRows(c) {
					// 	let C = WallpaperService.columns
					// 	let r = WallpaperService.rows
					// 	let center = Math.floor((C - 1) / 2)

					// 	let d = Math.min(
					// 		Math.abs(c - center),
					// 		Math.abs(c - (C - 1 - center))
					// 	)

					// 	return r + (center - d)
					// }
					// function totalItems() {
					// 	let sum = 0
					// 	for (let c = 0; c < WallpaperService.columns; c++) {
					// 		sum += colRows(c)
					// 	}
					// 	return sum
					// }

					// model: totalItems()
					// 	Behavior on model {
					// 	NumberAnimation { duration: 150 }
					// }
					
					// model: isHorizontal ?
					// Math.ceil(filteredModel / WallpaperService.rows):
					// Math.ceil(filteredModel / WallpaperService.columns)

					model: flick.listViewShown && isHorizontal 
					? Math.ceil((filteredWallpapers ? filteredModel : 0) / Math.max(1, _rows))
					: Math.ceil((filteredWallpapers ? filteredModel : 0) / Math.max(1, _cols))
				


					// model: isHorizontal
					// ? Math.ceil(filteredModel / Math.max(1, WallpaperService.rows))
					// : Math.ceil(filteredModel / Math.max(1, WallpaperService.columns))
					// add: Transition {
					// 	NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Style.animEnter; easing.type: Easing.OutCubic }
					// 	NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: Style.animEnter; easing.type: Easing.OutCubic }
					// }
					// remove: Transition {
					// 	NumberAnimation { property: "opacity"; to: 0; duration: Style.animNormal; easing.type: Easing.InCubic }
					// }
					// displaced: Transition {
					// 	NumberAnimation { properties: "x,y"; duration: Style.animMedium; easing.type: Easing.OutCubic }
					// }

					delegate: Item {
						id: hexDelegate
						
						width: Math.min(flick.colStep, flick.width)
						height: Math.min(flick.rowStep, flick.height)
						property int hColIndex: index
						property int vRowIndex: index
						property bool ready: WatcherService.thumbsGenerated
						opacity: ready ? 1 : 0

						// Behavior on opacity { 
						// NumberAnimation { 
						// 	duration: 250; 
						// 	easing.type: Easing.InOutQuad  
						// }
						// }
						// property bool ready: 
						// cardVisible && filteredModel > 0 && WatcherService.thumbsGenerated 
						// Component.onCompleted: {
						// 	ready = true
						// }
						// opacity: ready ? 1 : 0
						// property bool allowAnim: true
		
						// NumberAnimation {
						// 	id: hexDelegateFade
						// 	target: hexDelegate
						// 	property: "opacity"
						// 	duration: 50
						// 	easing.type: Easing.OutQuad
						// 	onStarted: {
						// 		hexDelegate.allowAnim = false
						// 	}
						// 	onStopped: {
						// 		hexDelegate.allowAnim = true
						// 	}
						// }

						// Component.onCompleted: {
						// 	hexDelegateFade.start()
						// }
						
						// opacity: WatcherService.thumbsGenerated && allowAnim
						//  ? 1 : 0
						// opacity: allowAnim ? 1:0
						// opacity: flick.listViewShown ? 1:0


						readonly property real _arcX: (x - flick.contentX) + width * 0.5
						readonly property real _arcY: (y - flick.contentY) + height * 0.5
						

						property real _arcFactor: Config.options.hexArc.enabled ? Config.options.hexArc.intensity : 0
						Behavior on _arcFactor { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }

						readonly property real _hArcOffset: {
						if (_arcFactor === 0) return 0
						var viewCenterX = flick.width / 2
						var normalized = (_arcX - viewCenterX) / Math.max(1, viewCenterX)
						return -normalized * normalized * flick._r * _arcFactor
						}
						
						readonly property real _vArcOffset: {
							if (_arcFactor === 0) return 0

							var viewCenterY = flick.height / 2
							var normalized =
								(_arcY - viewCenterY) /
								Math.max(1, viewCenterY)

							return -normalized * normalized
								* flick._r
								* _arcFactor
						}
						Repeater {
							id: hexRepeater
			
							
							model: isHorizontal ? Math.max(
							0,
							Math.min(
									WallpaperService.rows,
									filteredModel - hColIndex * WallpaperService.rows
								)
							) : Math.max(
								0,
								Math.min(
									WallpaperService.columns,
									filteredModel - vRowIndex * WallpaperService.columns
								)
							)
						
							
							delegate: HexItem {
								id: hexItem
								// visible: flick.listViewShown
								controller: wallpaperController
								property int hRowIndex: index
								property int vColIndex: index

								
				
								// property int flatIndex:
								// Math.floor(hColIndex * WallpaperService.rows,
								// vRowIndex * WallpaperService.columns) + index
								// property int flatIdx: hexCol.colIdx * hexListView._rows + rowIdx
								property int flatIndex: isHorizontal 
								? hexDelegate.hColIndex * flick._rows + hRowIndex
								: hexDelegate.vRowIndex * flick._cols + vColIndex
								// property int flatIndex: isHorizontal
								// ? hColIndex * WallpaperService.rows + index:	
								// vRowIndex * WallpaperService.columns + index

								property bool _isSelected: wallpaperController.currentIndex === flatIndex

								
									
							

								
								readonly property real _hexCenterX: (baseX - flick.contentX) + width * 0.5
								readonly property real _hexCenterY: (baseY - flick.contentY) + height * 0.5
								readonly property bool _nearLeft: _hexCenterX < flick.width * 0.5
								readonly property bool _nearTop: _hexCenterY < flick.height * 0.5
								
								
								property real itemCenterY: y + height * 0.5
								property real viewCenterY: flick.contentY + flick.height * 0.5
								
									

								property bool _inView: isHorizontal
								? (flatIndex >= flick.hStartIndex &&
								flatIndex <  flick.hEndIndex)

								: (flatIndex >= flick.vStartIndex &&
								flatIndex <  flick.vEndIndex)

								
								
								property int rows: WallpaperService.rows
								property int selIndex: wallpaperController.currentIndex
				
								


								
								property int sx: Math.floor(selIndex / rows)   // was % cols
								property int sy: selIndex % rows               // was / cols

								property int xIdx: Math.floor(flatIndex / rows)
								property int yIdx: flatIndex % rows

								property int dx: xIdx - sx
								property int dy: yIdx - sy

								property bool _rippleOffH:
									selIndex < flick.hStartIndex || selIndex >= flick.hEndIndex

								property bool _hoverRippleOffH:
									hoveredIdx < flick.hStartIndex || hoveredIdx >= flick.hEndIndex
								property int hoveredIdx: wallpaperController.hoveredIndex

								property int hx: Math.floor(hoveredIdx / rows)
								property int hy: hoveredIdx % rows

								property int hdx: xIdx - hx
								property int hdy: yIdx - hy
								property var _hoverRippleH: flick.hRipple(hdx, hdy, hx, hy, 0.5)
								property var _rippleH: flick.hRipple(dx, dy, sx, sy, 1.0)


								property int columns: WallpaperService.columns

								property int vs: selIndex % columns
								property int vt: Math.floor(selIndex / columns)

								property int vx: flatIndex % columns
								property int vy: Math.floor(flatIndex / columns)

								property int vdx: vx - vs
								property int vdy: vy - vt


								property bool _rippleOffV:
									selIndex < flick.vStartIndex || selIndex >= flick.vEndIndex


								property bool _hoverRippleOffV:
									hoveredIdx < flick.vStartIndex || hoveredIdx >= flick.vEndIndex


								property int vHoveredIdx: wallpaperController.hoveredIndex

								property int vhx: vHoveredIdx % columns
								property int vhy: Math.floor(vHoveredIdx / columns)

								property int vhdx: vx - vhx
								property int vhdy: vy - vhy


								property var _hoverRippleV:
									flick.vRipple(vhdx, vhdy, vhx, vhy, 0.5)

								property var _rippleV:
									flick.vRipple(vdx, vdy, vs, vt, 1.0)
									
								property int cols: WallpaperService.columns

								// property real _hexScale: 0
								property real _hexScale: _inView ? 1 : 0
								Behavior on _hexScale { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
								scale: _hexScale


								property real baseX: isHorizontal
									? flick.hOffset
									: (((flick.width ? flick.width : 0) - flick.vGridWidth) / 2)
										+ vColIndex * flick.effectiveCellStepX
										+ (hexDelegate.vRowIndex % 2
											? flick.effectiveCellStepX / 2
											: 0)

								property real baseY: isHorizontal
									? (((flick.height ? flick.height : 0) - flick.hGridHeight) / 2)
										+ hRowIndex * flick.effectiveCellStepY
										+ (hexDelegate.hColIndex % 2
											? flick.effectiveCellStepY / 2
											: 0)
									: flick.vOffset


								viewX: baseX
											
								viewY: baseY
								
								hArcOffset: isHorizontal ? _hArcOffset : 0
								vArcOffset: isHorizontal ? 0: _vArcOffset

								shiftX: filteredModel > 0 ? flick.globalShiftX : 0
								shiftY: filteredModel > 0 ? flick.globalShiftY : 0

								// Behavior on shiftX {
							
								// 	NumberAnimation {
									
								// 		duration: 350
								// 		easing.type: Easing.BezierSpline
								// 		easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
										
								// 	}
								// }

								// Behavior on shiftY {
							
								// 	NumberAnimation {
									
								// 		duration: 350
								// 		easing.type: Easing.BezierSpline
								// 		easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
										
								// 	}
								// }
								// rowScale: _hexScale
								container: flick
								flickRef: flick

								rippleOffH: _rippleOffH
								rippleH: _rippleH
								hoverRippleH: _hoverRippleH
								hoverRippleOffH: _hoverRippleOffH

								rippleOffV: _rippleOffV
								rippleV: _rippleV
								hoverRippleV: _hoverRippleV
								hoverRippleOffV: _hoverRippleOffV

								nearLeft: _nearLeft
								nearTop: _nearTop

								innerParallaxX: {
									var viewCenterX = flick.width * 0.5
									var hexCenterX = x + width * 0.5

									var normalized = (hexCenterX - viewCenterX) / Math.max(1, viewCenterX)
									normalized = Math.max(-1, Math.min(1, normalized))

									var falloff = 1.0 + Math.abs(normalized) * 0.2

									return -normalized * flick._r * 0.45 * falloff
								}

								innerParallaxY: {
									var viewCenterY = flick.height * 0.5
									var hexCenterY = y + height * 0.5

									var normalized = (hexCenterY - viewCenterY) / Math.max(1, viewCenterY)
									normalized = Math.max(-1, Math.min(1, normalized))

									var falloff = 1.0 + Math.abs(normalized) * 0.2

									return -normalized * flick._r * 0.45 * falloff
								}
				
								transformOrigin: {
									if (isHorizontal) return Item.Center
									if (isSelected) return Item.Center
									if (flick.scrollDirY < 0) {
										// scroll up - original
										return _nearTop ? Item.Top : Item.Bottom
									} else {
										// scroll down - flipped
										return _nearTop ? Item.Bottom : Item.Top
									}
								}
								itemData: filteredWallpapers[flatIndex]
								itemIndex: flatIndex
								inView: _inView
								clampDir: flick.scrollDirX === 0 ? 1 : flick.scrollDirX
								
							
							}

								
								
						}
					}
			}
			
	
	
	
		
	

		SettingsPanel{}


    
}
}