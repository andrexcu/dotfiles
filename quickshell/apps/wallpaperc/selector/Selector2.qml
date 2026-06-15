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
		console.log(Config.homeDir,"/.config/Scripts/matugen.sh")
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
	// property bool isHorizontal: Config.options.orientation.isHorizontal
	property bool isHorizontal: true
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
		interval: 50
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
			// 				+ (Config.options.layouts.rows - 1) * flick._rowStep
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
			// 	flick.contentY = row * flick._rowStep
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

	function onCurrentItemChanged() {
		console.log(currentItem)
		
	}
	}
	
	property int hexRadius: 90
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
	
  	Behavior on cardHeight { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }
    

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
		visible: wallpaperController.cardVisible
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
				// flick.model = null
				Qt.callLater(() => {
					WallpaperService.selectorQuit()
				})
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
	opacity: 0
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
	// 	Rectangle {
    //     anchors.fill: parent
    //     color: "transparent" 
    //     border.color: "red"       
    //     border.width: 1
    // }

	
						
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
			duration: Style.animExpand
			easing.type: Easing.InQuad
		}

		onIsLoadingChanged: {
			// flick.globalShiftX = 0
			// flick.globalShiftY = 0
			stateAnim.from = 0
			stateAnim.to = 1
			stateAnim.restart()
		
		}

		onIsEmptyChanged: {
			// flick.globalShiftX = 0
			// flick.globalShiftY = 0
			stateAnim.from = 0
			stateAnim.to = 1
			stateAnim.restart()
			
		}

		onIsDoneChanged: {
			// flick.globalShiftX = 0
			// flick.globalShiftY = 0
		}
		
		
		Behavior on opacity {
			NumberAnimation {
				duration: Style.animFast
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
					Layout.preferredWidth: selectorState.width * 0.15
					height: 6
					visible: selectorState.isLoading

					background: Rectangle {
						color: Colors.background
						radius: 3
					}

					contentItem: Rectangle {
						width: bar.visualPosition * bar.width
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

	
 	
	
    property bool animateIn: wallpaperController.cardVisible

	// onAnimateInChanged: {
    //   if (animateIn) {
    //     opacity = 1
	// 	focusTimer.restart()
    //   }
    // }
	
	// onAnimateInChanged: {
	// 	fadeInAnim.stop()

	// 	if (animateIn) {
	// 		opacity = 0
	// 		fadeInAnim.start()

	// 		if (!focusTimer.running)
	// 			focusTimer.start()
	// 	}
	// }
    onAnimateInChanged: {
      fadeInAnim.stop()
      if (animateIn) {
        fadeInAnim.start()
        focusTimer.restart()
      }
    }

    NumberAnimation {
      id: fadeInAnim
      target: cardContainer
      property: "opacity"
      from: 0; to: 1
      duration: Style.animFast
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
		Flickable {
			id: flick
			// visible: false
			// anchors.top: cardContainer.top
			// anchors.bottom: cardContainer.bottom
			// anchors.topMargin: 20
			// anchors.bottomMargin: 20
			// anchors.left: cardContainer.left
			// anchors.right: cardContainer.right
			// visible: wallpaperController.cardVisible

			// cacheBuffer: width * 10
			
			// cacheBuffer: isHorizontal ?
			// effectiveCellStepX * 2 : effectiveCellStepY * 2
			// property real maxItemScale: 1
			// property real itemOverflow: flick.cellHeight * (maxItemScale - 1)
			// property int extraPadding: 25
	
			// property int topMargin: 40
			// property int bottomMargin: itemOverflow + extraPadding
	
			// anchors.horizontalCenter: cardContainer.horizontalCenter
			// anchors.verticalCenter: cardContainer.verticalCenter

			anchors.horizontalCenter: cardContainer.horizontalCenter
			anchors.verticalCenter: cardContainer.verticalCenter
			// reuseItems: true

			property bool _animatingNav: false
			// anchors.topMargin: 20
			// anchors.bottomMargin: 20
		 	// anchors.top: cardContainer.top
			// anchors.bottom: cardContainer.bottom
			// anchors.topMargin: 20
			// anchors.bottomMargin: 20
			// anchors.left: cardContainer.left
			// anchors.right: cardContainer.right
			property bool listViewShown: true
			property bool _firstLoad: true

			

			// Rectangle {
			// 	anchors.fill: parent
			// 	color: "transparent" 
			// 	border.color: "green"       
			// 	border.width: 1
			// }
	
			NumberAnimation {
				id: listViewFade
				target: flick
				property: "opacity"
				duration: Style.animExpand
				easing.type: Easing.InQuad

				onStarted: {	
					flick.listViewShown = false	
					// flick.globalShiftX = 0
					// flick.globalShiftY = 0
				}

    			onStopped: {
					flick.listViewShown = true 
				}
			}

			property bool _layoutLock: false

			boundsBehavior: Flickable.StopAtBounds
			// flickDeceleration: 1500
			// maximumFlickVelocity: 3000




			Connections {
				target: wallpaperController
				function onFilteredWallpapersChanged() {
					if (flick.filteredModel <= 0) return
					if (flick._contentWidth <= 0) return
					// if (flick._contentHeight <= 0) return
					
					listViewFade.from = 0
					listViewFade.to = 1
					listViewFade.restart()

				
				}
			}

			// reuseItems: true
			// cacheBuffer: isHorizontal ?
			// effectiveCellStepX * 2 : effectiveCellStepY * 2
			flickableDirection: Flickable.HorizontalFlick
			// orientation: ListView.Horizontal
			// flickableDirection: Flickable.AutoFlickDirection
			// flickableDirection: isHorizontal
			// ? Flickable.HorizontalFlick
			// : Flickable.VerticalFlick

			
			// Layout.fillHeight: true
			// Layout.fillWidth: true
	
			property real _r: wallpaperController.hexRadius
			property real _gridSpacing: 6
			property real _hexW: hCellWidth
			property real _hexH: hCellHeight
			property real _stepX: 1.5 * _r + _gridSpacing
			property real _stepY: _hexH + _gridSpacing
			property real _gridContentH: (_rows - 1) * _stepY + _hexH + _hexH / 2
			property real _yOffset: Math.max(0, (height - _gridContentH) / 2)
			property real _visibleBand: (wallpaperController.hexCols - 1) * _stepX + _hexW
			property real _fadeZone: (width - _visibleBand) / 2

			
			
		
			
			focus: true

			interactive: false
			
			clip: false // important to make selector overflow

			property bool firstUpdateDone: false

	
			property bool selectedHexSettled: false

			

			
			property int _rows: WallpaperService.rows
			property int _cols: WallpaperService.columns

			
			// property real _contentWidth: {
			// 	if (wallpaperRepeater.count === 0) return width;

			// 	const lastItem = wallpaperRepeater.itemAt(wallpaperRepeater.count - 1);

			// 	return lastItem.x + lastItem.width;
			// }
			
			property real _contentWidth: {
				if (wallpaperRepeater.count === 0) return width;

				const lastItem = wallpaperRepeater.itemAt(wallpaperRepeater.count - 1);

				return lastItem.x + lastItem.width;
			}
			
			// property real _contentWidth:  Math.max(
			// 		width,
			// 		contentItem.childrenRect.width
			// 	)
			// property real _contentHeight: cardContainer.Height
			// property real _contentWidth: Math.ceil(filteredModel / _cols) * _colStep
		    property real _contentHeight: Math.ceil(filteredModel / _rows) * _rowStep
			contentWidth:  _contentWidth
			contentHeight: _contentHeight

			
			property real bufferFactor: 0.5
			
			property real _rowStep: flick.vCellHeight * 0.75
			property real _colStep: flick.hCellWidth * 0.75

			property int hStartCol:
				Math.floor((contentX + _colStep * bufferFactor) / _colStep)


			property int hStartIndex:
				hStartCol * _rows

			property int hEndIndex:
				Math.min(filteredModel, hStartIndex + _rows * _cols)




			property int vStartRow:
				Math.floor((contentY + _rowStep * bufferFactor) / _rowStep)

			property int vStartIndex:
				vStartRow * _cols
				

			property int vEndIndex:
				Math.min(filteredModel, vStartIndex + _cols * _rows)

			

			property int verticalMargin: 15
			property real topFactor: (5 * verticalMargin) / _rowStep
			property real bottomFactor: (1.2 * verticalMargin) / _rowStep

			property real viewportTop: contentY - (_rowStep * topFactor)
			property real viewportBottom: contentY + height - (_rowStep * bottomFactor)

			// Component.onCompleted: {

			// 	contentX = Math.round(contentX / _colStep) * _colStep
			// }
			onMovementEnded: {

				if (filteredModel <= 0) return
				if (_contentWidth <= 0) return
				// if (_contentHeight <= 0) return
				if (isHorizontal) {
					contentX = Math.round(contentX / _colStep) * _colStep
				} else {
					contentY = Math.round(contentY / _rowStep) * _rowStep
				}

				returnToBounds()
				// const sx = _colStep
				// const sy = _rowStep

				// contentX = Math.round(contentX / sx) * sx
				// contentY = Math.round(contentY / sy) * sy

				//   returnToBounds()

				// const step = isHorizontal ? _cols : 1

				// wallpaperController.currentIndex = Math.round(wallpaperController.currentIndex)
			}
				// if (isHorizontal) {
				// 	contentX = Math.round(contentX / _colStep) * _colStep
				// } else {
				// 	contentY = Math.round(contentY / _rowStep) * _rowStep
				// }

				// returnToBounds()
			

		


		

			Behavior on contentX {
				enabled: flick.listViewShown && isHorizontal
				NumberAnimation {
					duration: Style.animNormal
					easing.type: Easing.BezierSpline
					easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
				}
			}

			Behavior on contentY {
				enabled: flick.listViewShown && !isHorizontal
				NumberAnimation {
					duration: Style.animNormal
					easing.type: Easing.BezierSpline
					easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
				}
			}
			
	
			
			// 	property real lastContentX: 0
			// 	property int scrollDirX: 0
			// 	property int lastDirX: 0
			// 	property real dirThreshold: 0.5

			// 	property real lastContentY: 0
			// 	property int scrollDirY: 0
			// 	property int lastDirY: 0
			

			
					

			// onContentXChanged: {
			// 	if (!isHorizontal) return
			// 	if (filteredModel <= 0) return

			// 	var dx = contentX - lastContentX

			// 	if (Math.abs(dx) > dirThreshold) {

			// 		scrollDirX = dx > 0 ? 1 : -1

			// 		console.log(scrollDirX > 0 ? "scroll →" : "scroll ←")

			// 		if (scrollDirX !== lastDirX)
			// 			lastDirX = scrollDirX
			// 	} else {
			// 		scrollDirX = 0
			// 	}

			// 	lastContentX = contentX
			// 	wallpaperController.requestFrame()
			// }

			// 	onContentYChanged: {
			// 		if (isHorizontal) return
			// 		if (filteredModel <= 0) return

			// 		var dy = contentY - lastContentY

			// 		if (Math.abs(dy) > dirThreshold) {

			// 			scrollDirY = dy > 0 ? 1 : -1

			// 			console.log(scrollDirY > 0 ? "scroll ↓" : "scroll ↑")

			// 			lastDirY = scrollDirY
			// 		}

			// 		lastContentY = contentY

			// 		wallpaperController.requestFrame()
			// 	}
			property real dirThreshold: 0.5

			property real lastContentY: 0
			property int scrollDirY: 0
			property int lastDirY: 0

			property real lastContentX: 0
			property int scrollDirX: 0
			property int lastDirX: 0

				Component.onCompleted: {
				// flick.prune()
			}
			Connections {
				target: flick
				property int lastDirY: 0
				property int lastDirX: 0

				function onContentYChanged() {
					var dy = flick.contentY - flick.lastContentY

					if (Math.abs(dy) > flick.dirThreshold) {
						flick.scrollDirY = dy > 0 ? 1 : -1

						if (flick.scrollDirY !== lastDirY) {
							// console.log(flick.scrollDir > 0 ? "scroll ↓" : "scroll ↑")
							lastDirY = flick.scrollDirY
						}

						flick.lastContentY = flick.contentY
					}

					wallpaperController.requestFrame()
				}

				
				function onContentXChanged() {
					// flick.prune()
					var dx = flick.contentX - flick.lastContentX

					if (Math.abs(dx) > flick.dirThreshold) {
						flick.scrollDirX = dx > 0 ? 1 : -1

						if (flick.scrollDirX !== lastDirX) {
							// console.log(flick.scrollDirX > 0 ? "scroll →" : "scroll ←")
							lastDirX = flick.scrollDirX
						}

						flick.lastContentX = flick.contentX
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
					if (flick.filteredModel <= 0) return
					if (flick._contentWidth <= 0) return
					if (flick._contentHeight <= 0) return
					
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

					var row = localIndex % _rows
					var col = Math.floor(localIndex / _rows)

				

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

					if (flick.filteredModel <= 0) return
					if (flick._contentWidth <= 0) return
					if (flick._contentHeight <= 0) return
					
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
						duration: Style.animSlow
						easing.type: Easing.BezierSpline
						easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
					}
				}
				
				Behavior on globalShiftY {
					
					NumberAnimation {
						duration: Style.animSlow
						easing.type: Easing.BezierSpline
						easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
					}
				}
			

					// property real hWidth:
					// 	(WallpaperService.columns - 1) * _colStep
					// 	+ flick.hCellWidth

					// property real vWidth:
					// 	cardContainer.width

					// property real hHeight:
					// 	cardContainer.height

					// property real vHeight:
					// 	(WallpaperService.rows - 1) * _rowStep
					// 	+ flick.vCellHeight

					
			// height: wallpaperContainer.cellHeight
			// 							+ (visibleRows - 1) * rowStep

					// width: isHorizontal 
					// ? (WallpaperService.columns - 1) * _colStep + flick.hCellWidth : cardContainer.width
					
					// height: isHorizontal
					// ? cardContainer.height : 

					// (WallpaperService.rows - 1) * _rowStep + flick.vCellHeight
					
					width: flick.hCellWidth + (_cols - 1) * _colStep
					height: cardContainer.height

					// width: isHorizontal 
					// ? flick.hCellWidth + (_cols - 1) * _colStep
					// : cardContainer.width
					
					// height: isHorizontal
					// ? cardContainer.height 
					// : flick.vCellHeight + (_rows - 1) * _rowStep
					
					// height: flick.vCellHeight
					// 	+ (_rows - 1) * _rowStep
					// width: isHorizontal 
					// ? (WallpaperService.columns - 1) * _colStep + flick.hCellWidth : cardContainer.width
					
					
					// height: isHorizontal
					// ? cardContainer.height : (WallpaperService.rows - 1) * _rowStep + flick.vCellHeight
					
				
					// property int totalCols: Math.ceil(filteredWallpapers.length / flick.visibleRows)
					property int totalCols: Math.ceil(filteredModel / _rows)
					
					// property real gridWidth: (totalCols - 1) * _colStep + cellWidth
					
					// horizontal grid layout
					property real hGridWidth: (totalCols - 1) * _colStep + hCellWidth
					property real hGridHeight:
						WallpaperService.rows * effectiveCellStepY
						+ effectiveCellStepY / 2
					
					// vertical grid layout
					property real vGridWidth:
					WallpaperService.columns * effectiveCellStepX + effectiveCellStepX / 2
					property real vGridHeight:
					(totalRows - 1) * _rowStep + vCellHeight


				

					property int totalRows:
					Math.ceil(filteredModel / WallpaperService.columns)

					property real gridOffsetY: (flick.height - hGridHeight) / 2

					property real _gridInset: flick.hCellWidth * 0.05
					property real hOffset: Math.max((
						((_cols - 1) * _colStep + flick.hCellWidth) - hGridWidth) / 2, 0) + _gridInset	
					
					property real vOffset:
					Math.max((
						((WallpaperService.rows - 1) * _rowStep + flick.vCellHeight) - vGridHeight) / 2, 0) + _gridInset
					
					
					property real cellHeightFactor: 0.95
					// Behavior on cellHeightFactor {
					// 	NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic }
					// }

					property real spacingYFactor: 0.8
					// Behavior on spacingYFactor {
					// 	NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic }
					// }

					property real effectiveCellStepY:
						hCellHeight * cellHeightFactor + spacingY * spacingYFactor

					property real cellWidthFactor: 0.95
					// Behavior on cellWidthFactor {
					// 	NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic }
					// }

					property real spacingXFactor: 0.8
					// Behavior on spacingXFactor {
					// 	NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic }
					// }

					property real effectiveCellStepX:
						cellWidth * cellWidthFactor + spacingX * spacingXFactor
					
					

					

					property int hCellHeight: _r * 2
					property int hCellWidth: Math.round(hCellHeight * Math.sqrt(3)/2 * 1.3)
					
					property int vCellWidth: _r * 2
					property int vCellHeight: Math.round(vCellWidth * Math.sqrt(3)/2 * 1.2) 
					
					property int cellHeight: wallpaperController.isHorizontal
					? hCellHeight : vCellHeight

					property int cellWidth: wallpaperController.isHorizontal
					? hCellWidth : vCellWidth
					
		

					property real _base: _r * 2	
					property int spacingX: 10
					property int spacingY: 10
					
					// Behavior on _r {
					// 	NumberAnimation {
					// 		duration: 180
					// 		easing.type: Easing.OutCubic
					// 	}
					// }
				

			property real stepX: flick._colStep
		

		property bool _wheelMode: false
		// pixelAligned: true
		// snapMode: ListView.NoSnap
		// snapMode: ListView.SnapOneItem

		
			MouseArea {
				anchors.fill: parent
				focus: true
				acceptedButtons: Qt.NoButton
				onWheel: (wheel) => {

					const max = flick.contentWidth - flick.width
					const pos = flick.contentX

					// clamp edges
					if ((pos <= 0 && wheel.angleDelta.y > 0) ||
						(pos >= max - 0.5 && wheel.angleDelta.y < 0)) {
						return
					}

					const bias = 7
					const scale =
						Math.round(flick.width / flick._colStep) + bias

					const v = wheel.angleDelta.y * scale

					flick.flick(v, 0)   // ONLY horizontal

					wheel.accepted = true
				}

				onPressed: {
					mouse.accepted = false
					// flick.forceActiveFocus()
				}
				onClicked: {
					mouse.accepted = false
				}
				
			}	

   		Keys.enabled: true
	

		//   highlightRangeMode: ListView.StrictlyEnforceRange
	 
	//   highlightFollowsCurrentItem: true
	// 	highlightMoveDuration: Style.animExpand
	// 	highlight: Item {}
	// 	preferredHighlightBegin: (width - effectiveCellStepX) / 2
	// 	preferredHighlightEnd: (width + effectiveCellStepX) / 2
	// 	highlightRangeMode: ListView.StrictlyEnforceRange
	  

    //   header: Item { width: (flick.width - flick.effectiveCellStepX) / 2 }
    //   footer: Item { width: (flick.width - flick.effectiveCellStepX) / 2 }
	
		// Keys.onEscapePressed: wallpaperController.cardVisible = false
		// property int _selectedCol: currentIndex
		// property int _selectedRow: 0



		Keys.onPressed: function(event) {
			if(!WatcherService.thumbsGenerated) return
			if(!flick.listViewShown) return

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

					

						let rows = flick._rows
						let col = Math.floor(i / rows)

						let colLeft = col * flick._colStep
						let colRight = colLeft + flick._colStep

						let viewLeft = flick.contentX
						let viewRight = flick.contentX + flick.width

						let maxCol = Math.ceil(filteredModel / rows) - 1

						if (colLeft < viewLeft) {
							flick.contentX = Math.max(0, colLeft)
							
							flick.cancelFlick()
							flick.flick(0, 0) 
							return
						}

						if (colRight > viewRight) {

							let visibleCols = flick._cols

							let target = col - visibleCols + 1

							target = Math.max(0, Math.min(maxCol, target))

							flick.contentX = target * flick._colStep
							flick.cancelFlick()
							flick.flick(0, 0) 

							return
						}

					
				
				}

		

				
				
					// populate: Transition {
					// 	NumberAnimation {
					// 		properties: "opacity,scale"
					// 		from: 0.92
					// 		to: 1
					// 		duration: Style.animExpand
						
					// 		easing.type: Easing.BezierSpline
					// 		easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
					// 	}
					// }

					// add: Transition {
					// 	ParallelAnimation {
					// 		PropertyAction { property: "opacity"; value: 0 }

					// 		NumberAnimation {
					// 			properties: "opacity"
					// 			from: 0
					// 			to: 1
					// 			duration: Style.animExpand
					// 			easing.type: Easing.OutCubic
					// 		}

					// 		NumberAnimation {
					// 			properties: "scale"
					// 			from: 0.94
					// 			to: 1
					// 			duration: Style.animExpand
					// 			easing.type: Easing.OutBack
					// 			easing.overshoot: 1.2
					// 		}
					// 	}
					// }

					// remove: Transition {
					// 	ParallelAnimation {
					// 		NumberAnimation {
					// 			properties: "opacity"
					// 			to: 0
					// 			duration: Style.animNormal
					// 			easing.type: Easing.InCubic
					// 		}

					// 		NumberAnimation {
					// 			properties: "scale"
					// 			to: 0.96
					// 			duration: Style.animNormal
					// 			easing.type: Easing.InCubic
					// 		}
					// 	}
					// }

					// displaced: Transition {
					// 	NumberAnimation {
					// 		properties: "x,y"
					// 		duration: Style.animMedium
					// 		easing.type: Easing.OutCubic
					// 	}
					// }

					// addDisplaced: displaced
					// removeDisplaced: displaced
					// move: displaced
					// moveDisplaced: displaced
						

				

					// add: Transition {
					// 	NumberAnimation { property: "opacity"; duration: Style.animEnter; easing.type: Easing.OutCubic }
					// 	NumberAnimation { property: "scale"; duration: Style.animEnter; easing.type: Easing.OutCubic }
					// }

					// remove: Transition {
					// 	NumberAnimation { property: "opacity"; to: 0; duration: Style.animNormal; easing.type: Easing.InCubic }
					// 	NumberAnimation { property: "scale"; to: 0.9; duration: Style.animNormal; easing.type: Easing.InCubic }
					// }

					// displaced: Transition {
					// 	NumberAnimation { properties: "x,y"; duration: Style.animMedium; easing.type: Easing.OutCubic }
					// }
					
						// property bool ready: WatcherService.thumbsGenerated
						// opacity: {
						// 	if (flick.filteredModel <= 0) return 0
						// 	if (flick._contentWidth <= 0) return 0
						// 	if (flick._contentHeight <= 0) return 0
						// 	return ready ? 1 : 0
						// }
				
					
				
						

						// readonly property bool _nearLeft: _hexCenterX < flick.width / 2

						// readonly property bool _insideView: _hexCenterX > -flick.effectiveCellStepX && _hexCenterX < flick.width + flick.effectiveCellStepX
						// readonly property bool _nearEdge: _hexCenterX < flick._fadeZone || _hexCenterX> (flick.width - flick._fadeZone)
						
						// readonly property bool _visible: _insideView && !_nearEdge
						// property real _hexScale: _visible ? 1 : 0
						// Behavior on _hexScale { enabled: !flick._initialSnap; NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic }}
						// readonly property bool _nearLeft: _colCenter < hexListView.width / 2
						
						
						// function prune() {
						// 	const start = flick.hStartIndex
						// 	const end = flick.hEndIndex

						// 	const buffer = 20

						// 	const next = filteredWallpapers.filter((_, i) =>
						// 		i >= start - buffer &&
						// 		i <= end + buffer
						// 	)

						// 	filteredWallpapers = next
						// }
						// onWidthChanged: prune()


							Item {
								id: highlightContainer

								z: 9999
								clip: false
								visible: WatcherService.thumbsGenerated
								

								layer.smooth: true
								
								Shape {
									
									id: selectedHexBorder
									visible: false
									// visible: wallpaperController.currentItem 
									width: flick.cellWidth - 10
									height: flick.cellHeight - 10

									// Handles selection animation + state transitions
									
									
					
									property real deadZone: 20
										
									property real itemCenterY: y + height * 0.5
									property real viewCenterY: flick.contentY + flick.height * 0.5
									property bool _nearTop: itemCenterY < viewCenterY - deadZone
									// transformOrigin: {
									// 	if (scale > 0.99)
									// 		return Item.Center

									// 	var movingLeft = flick.scrollDirX < 0
									// 	return movingLeft ? Item.Left: Item.Right
									// }
									// transformOrigin: {
									// 	if (flick.scrollDirY < 0) {
									// 		return _nearTop ? Item.Top : Item.Bottom
									// 	} else {
									// 		return _nearTop ? Item.Bottom : Item.Top
									// 	}
										
									// }
							

									scale: wallpaperController.currentItem ? currentItem.visualWrapperRef.visualScale: 1
									// scale: 1
									// Bind scale to the selected item's visualScale
									// scale: wallpaperController.currentItem.visualWrapper ? currentItem.visualWrapper.visualScale : 1
									// opacity: wallpaperController.currentSelected ? currentSelected.opacity : 1
									// Behavior on opacity { 
										
									// 		NumberAnimation { 
									// 			duration: 300; 
									// 			easing.type: Easing.InCubic
									// 	} }
									
									// opacity: scale < 1 ? 0 : 1
									// Behavior on opacity { 
									// 		enabled: flick.firstUpdateDone
									// 		NumberAnimation { 
									// 			duration: 150; 
									// 			easing.type: Easing.InCubic
									// 	} }
								
									// Follow current selected position
									x: currentItem? currentItem.targetX : 0
									y: currentItem ? currentItem.targetY : 0

									preferredRendererType: Shape.CurveRenderer
									antialiasing: true
									
									ShapePath {
										strokeWidth: 3
										strokeColor: Colors.primary
										// strokeColor: "#4fc3f7"
										fillColor: "transparent"

										PathMove { x: selectedHexBorder.width * 0.25; y: 0 }
										PathLine { x: selectedHexBorder.width * 0.75; y: 0 }
										PathLine { x: selectedHexBorder.width;        y: selectedHexBorder.height * 0.5 }
										PathLine { x: selectedHexBorder.width * 0.75; y: selectedHexBorder.height }
										PathLine { x: selectedHexBorder.width * 0.25; y: selectedHexBorder.height }
										PathLine { x: 0;            y: selectedHexBorder.height * 0.5 }
										PathLine { x: selectedHexBorder.width * 0.25; y: 0 }
										
									}
										Behavior on x {
											SpringAnimation {
												id: springX
												spring: 4.2
												damping: 0.35
												// damping: 1.0
											}
										}

										Behavior on y {
											SpringAnimation {
												id: springY
												spring: 4.2
												
												damping: 0.35
											}
										}
										NumberAnimation {
											duration: Style.animExpand
											easing.type: Easing.BezierSpline
											easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
										}
										// Behavior on scale {
											
										// 	SpringAnimation {
										// 			spring: 6
										// 			damping: 0.9 
										// 		}
										// }


								}
								
								
							}
								
								// width: flick._colStep
								// height: flick._rowStep
							Repeater {
							id: wallpaperRepeater
							model: filteredWallpapers
				
							delegate: HexItem {
								id: hexItem

								property int hColIndex: Math.floor(index / flick._rows)
								property int hRowIndex: index % flick._rows

								property int vRowIndex: Math.floor(index / flick._cols)
								property int vColIndex: index % flick._cols
								
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
								readonly property bool _nearLeft: _hexCenterX < flick.width / 2
								controller: wallpaperController
							
								// property bool _currentItem: ListView.isCurrentItem
								// currentItem: _currentItem
								
								// readonly property bool _nearTop: _hexCenterY < flick.height / 2
								readonly property real _hexCenterX: (x - flick.contentX) + width * 0.5
								readonly property real _hexCenterY: (y - flick.contentY) + height * 0.5
								property real deadZone: 20
								
								property real itemCenterY: y + height * 0.5
								property real viewCenterY: flick.contentY + flick.height * 0.5
								property bool _nearTop: itemCenterY < viewCenterY - deadZone
								
								property real itemCenterX: y + width * 0.5
								property real viewCenterX: flick.contentX + flick.width * 0.5
								// property bool _nearLeft: itemCenterX < viewCenterX - deadZone



								// property int flatIndex: isHorizontal 
								// ? hColIndex * flick._rows + hRowIndex
								// : vRowIndex * flick._cols + vColIndex
						
								// property bool _inView: _visible
								// property bool _inView:
								// y + height > flick.viewportTop &&
								// y < flick.viewportBottom
								
								property bool _inView: 
								((index >= flick.hStartIndex) &&
								(index<  flick.hEndIndex))
							

								property bool _isSelected: wallpaperController.currentIndex === index
								isSelected: _isSelected
								
								
								// readonly property real _colCenter: (x - flick.contentX) + width * 0.5
								// readonly property bool _insideViewX: _colCenter > -flick._hexW && _colCenter < flick.width + flick._hexW

								// readonly property bool _insideViewX: _hexCenterX > -flick.hCellWidth && _hexCenterX < flick.width + flick.hCellWidth
								// readonly property bool _nearEdgeX: _hexCenterX < flick._fadeZone || _hexCenterX > (flick.width - flick._fadeZone)
								// readonly property bool _nearLeft: _hexCenterX < flick.width / 2
								

				
								// property real _hexScale: _inView ? 1 : Math.min(1, dist / flick._fadeZone)
								
								// property real dist:
								// Math.min(_hexCenterX, flick.width - _hexCenterX)

								// // opacity: Math.min(1, dist / flick._fadeZone)
								// property real _hexScale: 0.8 + 0.2 * Math.min(1, dist / flick._fadeZone)
								
								
								
								
								
								// Behavior on _hexScale {
								// 	enabled: flick.listViewShown

								// 	SequentialAnimation {
								// 		PauseAnimation {
								// 			duration: flatIndex * 8
								// 		}

								// 		NumberAnimation {
								// 			duration: Style.animExpand
								// 			easing.type: Easing.OutCubic
								// 		}
								// 	}
								// }

								
								
								// property real itemCenterY: y + height * 0.5
								// property real viewCenterY: flick.contentY + flick.height * 0.5
								
									
								

								
								
								property int rows: flick._rows
								property int selIndex: wallpaperController.currentIndex
				
								


								
								property int sx: Math.floor(selIndex / rows)   // was % cols
								property int sy: selIndex % rows               // was / cols

								property int xIdx: Math.floor(index / rows)
								property int yIdx: index % rows

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

								property real hoverStr: 0.6
								property real rippleStr: 1.0
								property var _rippleH: flick.hRipple(dx, dy, sx, sy, rippleStr)

								property var _hoverRippleH: flick.hRipple(hdx, hdy, hx, hy, hoverStr)


								property int columns: flick._cols

								property int vs: selIndex % columns
								property int vt: Math.floor(selIndex / columns)

								property int vx: index % columns
								property int vy: Math.floor(index / columns)

								property int vdx: vx - vs
								property int vdy: vy - vt


								property bool _rippleOffV:
									selIndex < flick.vStartIndex || selIndex >= flick.vEndIndex


								property bool _hoverRippleOffV:
									hoveredIdx < flick.vStartIndex || hoveredIdx >= flick.vEndIndex


								property int vhx: hoveredIdx % columns
								property int vhy: Math.floor(hoveredIdx / columns)

								property int vhdx: vx - vhx
								property int vhdy: vy - vhy


								property var _hoverRippleV:
									flick.vRipple(vhdx, vhdy, vhx, vhy, hoverStr)

								property var _rippleV:
									flick.vRipple(vdx, vdy, vs, vt, rippleStr)
									
								property int cols: flick._cols


								
								property real _hexScale: _inView ? 1 : 0
								// visible: _hexScale > 0 ? true : false
		
								// property real _hexScale: {
								// 	// if (isSelected) {
								// 	// 	if (
								// 	// 		itemBottom < flick.viewportTop ||
								// 	// 		itemTop > flick.viewportBottom ||
								// 	// 		(itemTop < flick.viewportTop &&
								// 	// 		itemBottom > flick.viewportTop) ||
								// 	// 		(itemBottom > flick.viewportBottom &&
								// 	// 		itemTop < flick.viewportBottom)
								// 	// 	)
								// 	// 		return 0

								// 	// 	return 1.15
								// 	// }

								// 	if (fullyVisible)
								// 		return 1
								// 	else if (completelyOutside)
								// 		return 0.6
								// 	else
								// 		return 0
								// }

								Behavior on _hexScale {
									NumberAnimation {
										duration: 250
										easing.type: Easing.OutCubic
										// easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
										
									}
									// NumberAnimation { 
									// 	duration: Style.animExpand;
									// 	easing.type: Easing.OutCubic 
									// 	// 	easing.type: Easing.BezierSpline
									// 	// easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
										 
									// } 
								}
										// SpringAnimation {
										// 	spring: 6
										// 	damping: 0.9 
										// }
									 
								scale: _hexScale
								opacity: _hexScale < 0.01 ? 0 : 1
								
								// opacity: _inView ? 1 : 0
								// Behavior on opacity { 
								// 	NumberAnimation { 
								// 		duration: 350; 
								// 		easing.type: Easing.InOutQuad 
								// 	} 
								// }
				
								// Behavior on opacity { 
								// 	enabled: !isHorizontal
								// 	NumberAnimation { 
								// 		duration: 350; 
								// 		easing.type: Easing.InOutQuad 
								// 	} 
								// }
								// Behavior on opacity { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }
								// property int col: index % flick._cols
								// property int row: Math.floor(index / flick._cols)
									property real col: Math.floor(index / flick._rows)
									property real row: index % flick._rows

									property real itemY:
									row * flick.effectiveCellStepY +
									(col % 2 ? flick.effectiveCellStepY * 0.5 : 0)
									
									viewX: flick.hOffset + col * flick._colStep
									viewY: flick.gridOffsetY + itemY


								// 		viewX: isHorizontal
								// 	? flick.hOffset
								// 	: (((flick.width ? flick.width : 0) - flick.vGridWidth) / 2)
								// 		+ vColIndex * flick.effectiveCellStepX
								// 		+ (vRowIndex % 2
								// 			? flick.effectiveCellStepX / 2
								// 			: 0)

								// viewY: isHorizontal
								// 	? (((flick.height ? flick.height : 0) - flick.hGridHeight) / 2)
								// 		+ hRowIndex * flick.effectiveCellStepY
								// 		+ (hColIndex % 2
								// 			? flick.effectiveCellStepY / 2
								// 			: 0)
								// 	: flick.vOffset
									// property real baseX: flick.offset + col * flick._colStep
									// property real baseY: flick.gridOffsetY + itemY	


									// viewX: isHorizontal
									// ? flick.hOffset
									// : (((flick.width || 0) - flick.vGridWidth) / 2)
									// 	+ col * flick.effectiveCellStepX
									// 	+ (row % 2
									// 		? flick.effectiveCellStepX / 2
									// 		: 0)

									// 							viewY: isHorizontal
									// ? (((flick.height || 0) - flick.hGridHeight) / 2)
									// 	+ row * flick.effectiveCellStepY
									// 	+ (col % 2
									// 		? flick.effectiveCellStepY / 2
									// 		: 0)
									// : flick.vOffset
								// viewX: isHorizontal
								// ? flick.hOffset
								// : (((flick.width || 0) - flick.vGridWidth) / 2)
								// 	+ col * flick.effectiveCellStepX
								// 	+ (row % 2
								// 		? flick.effectiveCellStepX / 2
								// 		: 0)

								// viewY: isHorizontal
								// ? (((flick.height || 0) - flick.hGridHeight) / 2)
								// 	+ row * flick.effectiveCellStepY
								// 	+ (col % 2
								// 		? flick.effectiveCellStepY / 2
								// 		: 0)
								// : flick.vOffset

							
								// viewX: baseX
											
								// viewY: baseY
								
								// hArcOffset: isHorizontal ? _hArcOffset : 0
								// vArcOffset: isHorizontal ? 0: _vArcOffset

								shiftX: filteredModel > 0 ? flick.globalShiftX : 0
								shiftY: filteredModel > 0 ? flick.globalShiftY : 0

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

								property real normX: {
									let c = flick.width * 0.5
									return Math.max(-1, Math.min(1,
										((x + width * 0.5) - c) / Math.max(1, c)
									))
								}

								property real normY: {
									let c = flick.height * 0.5
									return Math.max(-1, Math.min(1,
										((y + height * 0.5) - c) / Math.max(1, c)
									))
								}
								// innerParallaxX: 0

								// innerParallaxY: 0
								innerParallaxX: {
									var f = 1.0 + Math.abs(normX) * 0.2
									return -normX * flick._r * 0.45 * f
								}

								innerParallaxY: {
									var f = 1.0 + Math.abs(normY) * 0.2
									return -normY * flick._r * 0.45 * f
								}	

								// transformOrigin: _nearLeft ? Item.Left: Item.Right
								// transformOrigin: {
								// 	if (scale > 0.99)
								// 		return Item.Center

								// 	var movingLeft = flick.scrollDirX < 0
								// 	return movingLeft ? Item.Left: Item.Right
								// }

								itemData: filteredWallpapers[index]
								itemIndex: visible ? index : 0
								inView: _inView
								// clampDirX: flick.scrollDirX === 0 ? 1 : flick.scrollDirX
								// clampDirY: flick.scrollDirY === 0 ? 1 : flick.scrollDirY
								
							}
							}
								
						
					
									// innerParallaxX: {
								// 	var viewCenterX = flick.width * 0.5
								// 	var hexCenterX = x + width * 0.5

								// 	var normalized = (hexCenterX - viewCenterX) / Math.max(1, viewCenterX)
								// 	normalized = Math.max(-1, Math.min(1, normalized))

								// 	var falloff = 1.0 + Math.abs(normalized) * 0.2

								// 	return -normalized * flick._r * 0.45 * falloff
								// }

								// innerParallaxY: {
								// 	var viewCenterY = flick.height * 0.5
								// 	var hexCenterY = y + height * 0.5

								// 	var normalized = (hexCenterY - viewCenterY) / Math.max(1, viewCenterY)
								// 	normalized = Math.max(-1, Math.min(1, normalized))

								// 	var falloff = 1.0 + Math.abs(normalized) * 0.2

								// 	return -normalized * flick._r * 0.45 * falloff
								// }
							
			}
			
	
	
	
		
	

		SettingsPanel{}


    
}
}