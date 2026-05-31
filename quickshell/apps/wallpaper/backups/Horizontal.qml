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

Scope {
	id: wallpaperController

	// helper functions
	QtObject {
		id: utils
		
		// Fisher-Yates shuffle: shuffles array in place
		function shuffleArray(arr) {
			for (let i = arr.length - 1; i > 0; i--) {
				const j = Math.floor(Math.random() * (i + 1));
				[arr[i], arr[j]] = [arr[j], arr[i]];
			}
			return arr;
		}
		
		function randomWallpaperFisherYates(wallpapers, currentWallpaper) {
			if (!wallpapers || wallpapers.length === 0) return;

			// Make a copy
			let copy = wallpapers.slice();

			// Fisher-Yates shuffle
			for (let i = copy.length - 1; i > 0; i--) {
				const j = Math.floor(Math.random() * (i + 1));
				[copy[i], copy[j]] = [copy[j], copy[i]];
			}

			// Pick the first wallpaper that's not the current one
			let chosen = copy.find(w => w !== currentWallpaper) || copy[0];

			actions.applyWallpaper(chosen);
		}
	}
	
	// thumbnail Handler
	QtObject {
		id: thumbs
		property var thumbData: {}
		property bool pendingUpdate: false

		function updateThumbs() {
			pendingUpdate = false
			let data = {}
			for (var i = 0; i < thumbModel.count; i++) {
				let name = thumbModel.get(i, "fileName")
				data[name] = true
			}
			thumbData = data

			// Now you can check for missing thumbnails etc. just like before
			let allExist = true
			for (let key in thumbnailPaths) {
				if (!thumbData[thumbnailPaths[key]]) {
					allExist = false
					break
				}
			}

			if (!allExist && !thumbnailProcess.running) {
				console.log("Missing thumbnails, generating...")
				thumbnailProcess.exec(["sh", "-c", setupCmd])
			} else {
				console.log("All thumbnails exist, skipping generation")
			}
		}

		function onListThumbsExited() {
			let files = listThumbsCollector.text.trim().split("\n")
			let data = {}
			for (let i = 0; i < files.length; i++) {
				if (files[i].length > 0) data[files[i]] = true
			}
			thumbData = data

			
			console.log("Using thumbModel.count: " + thumbModel.count)
			// check missing thumbnails
		}
	}

	// listing and applying wallpaper
	QtObject {
    	id: actions

		function showNotification(title, message, icon) {
			console.log("[" + title + "] " + message)
		}

		// this generates matugen colors from wallpaper
		function applyWallpaper(wallpaperName) {
			selectedWallpaper = wallpaperName
			wallpaperController.currentFullPath = wallpaperDir + "/" + wallpaperName

			let awwwArgs = [
				"img", `"${wallpaperController.currentFullPath}"`,
				"--transition-type", "wave",
				"--transition-fps", "60",
				"--transition-duration", "0.5",
				"--transition-wave", "25,15",
				"--transition-angle", "45",
				"--transition-bezier", ".4,0,.2,1"
			]
		
			awwwProcess.exec(["sh", "-c", ["awww"].concat(awwwArgs).join(" ")])

			// Step 1: kill previous matugen if running
			if (matugenProcess.running) {
				matugenKilled = true
				matugenProcess.signal("SIGKILL")
			}

			// Step 2: run matugen (triggers switchwall automatically)
			Qt.callLater(() => {
				matugenProcess.exec([
					"bash",
					wallpaperController.matugenPath,
					wallpaperController.currentFullPath
				])
			})
		}		
	
		function startListingFromModel() {
			if (!wallpaperModel.count) {
				lastError = "No wallpapers found in " + wallpaperDir
				showNotification("Error", lastError, "dialog-error")
				return
			}

			let processed = []
			let paths = {}

			for (let i = 0; i < wallpaperModel.count; i++) {
				let filename = wallpaperModel.get(i, "fileName")
				if (filename.length > 0) {
					processed.push(filename)

					let parts = filename.split(".")
					let baseName = parts.length > 1 ? parts.slice(0, -1).join(".") : filename
					paths[filename] = baseName + ".png"
				}
			}

			wallpapers = utils.shuffleArray(processed)
			thumbnailPaths = paths

			if (wallpapers.length > 0) {
				wallpaperController.currentIndex = 0
				selectedWallpaper = wallpapers[0]
			}

			thumbs.updateThumbs()
		}
	}

	// Process for getting home directory
	Io.Process {
		id: homeProcess
		command: []
		stdout: Io.StdioCollector {
			id: homeCollector
		}
		onExited: function(exitCode, exitStatus) {
			if (exitCode === 0) {
				homeDir = homeCollector.text.trim()
				// Defaults
				let defaultWall = homeDir + "/Pictures/Wallpaper"
				let defaultThumb = homeDir + "/.cache/wall-select"
				// Load saved settings if present
				wallpaperDir = wallpaperController.savedWallpaperDir && wallpaperController.savedWallpaperDir.length > 0 ? wallpaperController.savedWallpaperDir : defaultWall
				thumbnailDir = wallpaperController.savedThumbnailDir && wallpaperController.savedThumbnailDir.length > 0 ? wallpaperController.savedThumbnailDir : defaultThumb

					// ✅ Add logging here
				console.log("Thumbnail dir set to:", thumbnailDir)
				thumbModel.folder = "file://" + thumbnailDir
				wallpaperModel.folder = "file://" + wallpaperDir
			
			} else {
				lastError = "Failed to get home directory"
				showNotification("Error", lastError, "dialog-error")
			}
		}
	}

	Io.Process {
		id: thumbnailProcess
		command: []

		onStarted: console.log("Generating thumbnails...")

		onExited: function(exitCode, exitStatus) {
			if (exitCode === 0) {
				console.log("Thumbnails generated successfully")
				// Only refresh if some thumbnails were missing
				thumbs.updateThumbs() 
			}
		}
	}

	// sibling process
	Io.Process {
		id: listThumbsProcess
		command: []
		stdout: Io.StdioCollector { id: listThumbsCollector }

		onExited: function(exitCode) {
			if (exitCode === 0) {
				thumbs.onListThumbsExited()
			}
		}
	}

	Io.Process {
		id: matugenProcess
		property string requestPath: ""
		property string requestName: ""

		onStarted: {
			requestPath = wallpaperController.currentFullPath
			requestName = selectedWallpaper
			matugenKilled = false
		}

		onExited: function(exitCode) {
			if (exitCode !== 0 && !matugenKilled) {
				notifyProcess.exec([
					"notify-send",
					"Error",
					"matugen.sh failed",
					"-i", "dialog-error"
				])
			} else if (!matugenKilled) {
				// ⚠️ This will fire BEFORE wallpaper is applied
				notifyProcess.exec([
					"notify-send",
					"-r", "9999",
					"Wallpaper Applied",
					"Wallpaper '" + requestName + "' applied successfully",
					"-i", "dialog-information"
				])
			}

			// Continue to actual wallpaper apply
			if (switchwallProcess.running) {
				switchwallProcess.signal("SIGKILL")
			}

			switchwallProcess.requestPath = requestPath
			switchwallProcess.requestName = requestName

			switchwallProcess.exec([
				"bash",
				wallpaperController.switchwallPath,
				"--image",
				requestPath
			])
		}
	}
	
	// --- switchwallProcess ---
	Io.Process {
		id: switchwallProcess
		property string requestPath: ""
		property string requestName: ""
		command: []

		onExited: function(exitCode) {
			if (exitCode === 0) {
				showNotification(
					"Wallpaper Applied",
					"Wallpaper '" + requestName + "' applied successfully",
					"dialog-information"
				)
			} else {
				showNotification("Error", "switchwall.sh failed", "dialog-error")
			}
		}
	}

	// --- awwwProcess ---
	Io.Process {
		id: awwwProcess
		onExited: function() {
			showNotification("Wallpaper Applied", selectedWallpaper + " applied", "dialog-information")
		}
	}

	Io.Process {
		id: notifyProcess
		command: []
	}

	// Process for listing wallpapers
	Io.Process {
		id: listProcess
		command: []
		stdout: Io.StdioCollector {
			id: listCollector
		}

		onExited: function(exitCode, exitStatus) {
			if (exitCode !== 0) {
				lastError = "Failed to scan wallpaper directory"
				showNotification("Error", lastError, "dialog-error")
				return
			}

			// Parse output
			let output = listCollector.text.trim()
			if (output.length === 0) {
				lastError = "No wallpapers found in " + wallpaperDir
				showNotification("Error", lastError, "dialog-error")
				return
			}

			let files = output.split("\n").filter(f => f.length > 0)

			// Build wallpaper list + thumbnail paths
			let processed = []
			let paths = {}

			for (let i = 0; i < files.length; i++) {
				let filename = files[i].split("/").pop()
				if (filename.length > 0) {
					processed.push(filename)

					let parts = filename.split(".")
					let baseName = parts.length > 1
						? parts.slice(0, -1).join(".")
						: filename

					paths[filename] = baseName + ".png"
				}
			}

			wallpapers = utils.shuffleArray(processed)
			thumbnailPaths = paths

			if (wallpapers.length > 0) {
				wallpaperController.currentIndex = 0
				selectedWallpaper = wallpapers[0]
			}

			// 🔥 ONLY trigger thumbnail scan (non-blocking)
			thumbs.updateThumbs()
		}
	}
	
	
	// =======================
	// CONFIGURATION
	// =======================
	// property var Colors: Colors {}
	property var wallpapers: []
	property var filteredWallpapers: wallpapers   // initially same as full list
	property string selectedWallpaper: ""
	property string lastError: ""
	property int currentIndex: 0

	// Boolean
	property bool hasFfmpeg: false
	property bool hasMatugen: false
	property bool settingsOpen: false
	property bool selectorOpen: false
	property bool showDelegateBorder: true
	property bool matugenKilled: false
	property bool cardVisible: false
	property bool _previousSelectedHex: false
	property bool framePending: false
	property bool isContentVisible: wallpaperController.cardVisible && wallpaperRepeater.count > 0
	&& currentItem && currentItem.imageReady
	
	// tracking items
	property Item currentSelected: null
	property Item selectedItem: wallpaperRepeater.itemAt(wallpaperController.currentIndex)
	property Item previousItem: (wallpaperController.previousIndex >= 0 &&
						wallpaperController.previousIndex < wallpaperRepeater.count)
						? wallpaperRepeater.itemAt(wallpaperController.previousIndex)
						: null

	// Path
	property var thumbnailPaths: ({})
	property string homeDir: ""
	property string wallpaperDir: ""
	property string thumbnailDir: ""
	property string savedWallpaperDir: ""
	property string savedThumbnailDir: ""
	property string currentFullPath: ""
	property string matugenPath: homeDir + "/Scripts/matugen.sh"
	property string switchwallPath: homeDir + "/.config/quickshell/scripts/colors/switchwall.sh"

	// Computed property for convenience
	property Item currentItem: (wallpaperController.currentIndex >= 0 && wallpaperController.currentIndex < wallpaperRepeater.count)
		? wallpaperRepeater.itemAt(wallpaperController.currentIndex)
		: null


	property int previousIndex: 0


	// ffmpeg batch thumbnail generator
	property string setupCmd: "mkdir -p '" + thumbnailDir + "' && find '" + wallpaperDir + "' -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \\) -print0 | xargs -0 -P 4 -I {} bash -c 'base=$(basename \"{}\"); name=\"${base%.*}\"; thumb=\"" + thumbnailDir + "/${name}.png\"; [ ! -f \"$thumb\" ] && ffmpeg -y -i \"{}\" -vf \"scale=200:208:force_original_aspect_ratio=increase,crop=200:208:(in_w-200)/2:(in_h-208)/2,format=rgb24\" -q:v 5 -frames:v 1 \"$thumb\" 2>/dev/null || true'"
	
	// Path Listeners
	onWallpaperDirChanged: {
		if (wallpaperDir && wallpaperDir !== wallpaperController.savedWallpaperDir) {
			wallpaperController.savedWallpaperDir = wallpaperDir
		}
	}

	onThumbnailDirChanged: {
		if (thumbnailDir && thumbnailDir !== wallpaperController.savedThumbnailDir) {
			wallpaperController.savedThumbnailDir = thumbnailDir
		}
	}

	
	FolderListModel {
		id: thumbModel
		nameFilters: ["*.png"]
		showDirs: false
		showHidden: false
		sortField: FolderListModel.Name

		// onStatusChanged: {
		// 	if (status === FolderListModel.Ready) {
		// 		console.log("Thumbnails loaded: " + count)
		// 		for (var i = 0; i < count; i++) {
		// 			console.log("thumbname: " + get(i, "fileName"))
		// 		}
		// 	}
		// }
	}

	FolderListModel {
		id: wallpaperModel
			nameFilters: [ "*.png", "*.jpg" ]
		showDirs: false
		showHidden: false
		sortField: FolderListModel.Name

		onStatusChanged: {
			if (status === FolderListModel.Ready) {
				console.log("Wallpapers loaded: " + count)
				
				if (count > 0) {
					lastError = ""           // Clear the error once wallpapers are loaded
					actions.startListingFromModel()  // Your function to set wallpapers + thumbs
					wallpaperController.requestFrame()
					
				} else {
					lastError = "No wallpapers found in " + wallpaperDir
				}
			}
		}			
	}
			
	Timer {
		id: cardShowTimer
		interval: 50
		onTriggered: wallpaperController.cardVisible = true
	}

	Timer {
		id: focusTimer
		interval: 50
		onTriggered: {
			homeProcess.exec(["sh", "-c", "echo $HOME"])
			// keyRoot.forceActiveFocus()
		}
	}

	Component.onCompleted: {  
		cardShowTimer.start()
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
				wallpaperController.currentSelected.visualWrapperRef.visualScale = 1
				
			} 
		}
	}

	function flipHex() {
		var wSelected = wallpaperController.selectedItem
		var wPrevious = wallpaperController.previousItem

		if (!wSelected) return
		
		// Compute movement direction
		var direction = 1

		if (wPrevious && wPrevious !== wSelected) {
			direction = (wPrevious.x < wSelected.x) ? 1 : -1
		}

		// Animate previous item (EXIT)
		if (wPrevious && wPrevious !== wSelected) {
			var vwPrev = previousItem.visualWrapperRef
			// vwPrev.flipAnim.stop()

			// Normalize current state
			
			// vwPrev.visualScale = 1
			// vwPrev.fadeOpacity = 1

			// Animate back to flat
			// vwPrev.flipAnim.from = vwPrev.flipAngle
			// vwPrev.flipAnim.to = 0
			// vwPrev.flipAnim.start()
		}

		// Animate selected item (ENTER)
		var vw = selectedItem.visualWrapperRef
		// vw.flipAnim.stop()

		// Prepare starting state
		vw.flipAngle = 0
		vw.visualScale = 0.25
		vw.fadeOpacity = 0

		// Animate flip in correct direction
		// vw.flipAnim.from = 0
		// vw.flipAnim.to = 180 * direction
		// vw.flipAnim.start()
	}

	function updateVisual() {
		flick.applyVisual(selectedItem, 1, 1, 0)
		// Update selected & previous index
		wallpaperController.currentSelected = selectedItem
		wallpaperController.previousIndex = wallpaperController.currentIndex
	}

	function runFrame() {
		// flick.updateScales()
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
	
	// effects on change
	Connections {
		target: wallpaperController
		function onCurrentIndexChanged() {
			// flip animation
			// flipHex()

			// Apply scale + fade
			updateVisual()

			// Scaling selected hex
			scaleDelayTimer.start()

			runUpdateShift()

			// Parallax effect
			// flick.updateGridFocusOffset()
			
			// Blur selected hex
			wallpaperController.blurTransition = true
			imgBlurInTimer.restart()
		}
	}
	
	property int cardHeight: hexhGridHeight
	property int hexCardWidth: selectorPanel.width
	property int cardWidth: hexCardWidth
	Behavior on cardWidth { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
	
	property int hexhGridHeight: {
		var rows = 3
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
	
        // Pick screen (optional, but good practice)
        screen: Quickshell.screens[0]
		// visible: false
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
	
//   ColumnLayout {
// 	// anchors.fill: parent
// 	anchors.centerIn: parent
// 	anchors.margins: 16
// 	spacing: 16
	
	
 Item {
	id: cardContainer
	
	width: wallpaperController.cardWidth
	height: wallpaperController.cardHeight
	anchors.centerIn: parent
	Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
	// anchors.centerIn: parent
	clip: false
	
	// testing
	// Rectangle {
    //     anchors.fill: parent
    //     color: "transparent" 
    //     border.color: "red"       
    //     border.width: 1
    // }
	
	// anchors {
	// 	top: parent.top
	// 	bottom: parent.bottom
	// 	horizontalCenter: parent.horizontalCenter
	// }
	// visible: wallpaperController.isContentVisible
	visible: wallpaperController.cardVisible
	
 	opacity: 0
	
    property bool animateIn: wallpaperController.cardVisible

    onAnimateInChanged: {
    
      if (animateIn) {
        opacity = 1
        focusTimer.restart()
      }
    }

    // NumberAnimation {
    //   id: fadeInAnim
    //   target: cardContainer
    //   property: "opacity"
    //   from: 0; to: 1
    //   duration: 50
    //   easing.type: Easing.OutCubic
    // }

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
	
 }		
		Flickable {
			id: flick
			opacity: wallpaperController.cardVisible ? 1 : 0
			property real maxItemScale: 1
			property real itemOverflow: flick.cellHeight * (maxItemScale - 1)
			property int extraPadding: 25
			property real _rowStep: flick.cellHeight * 0.75
			property int topMargin: 40
			property int bottomMargin: itemOverflow + extraPadding
	
			anchors.horizontalCenter: cardContainer.horizontalCenter
			anchors.verticalCenter: cardContainer.verticalCenter
			
			Rectangle {
				anchors.fill: parent
				color: "transparent" 
				border.color: "blue"       
				border.width: 2
			}
			
			property real __rowStep: flick.cellHeight * 0.75
			property real _colStep: flick.cellWidth * 0.75
			width: flick.cellWidth + (columns - 1) * _colStep
			height: cardContainer.height

			// Component.onCompleted: {
			// 	// flick.prune()
			// 		if(!contentWidth) return

			// 		const lastItem = wallpaperRepeater.itemAt(wallpaperRepeater.count - 1);

			// 		// return lastItem.x + lastItem.width;
			// 		console.log("repeater lastitem:", lastItem)
				
				
			// }
			contentWidth: {
				if (wallpaperRepeater.count === 0) return width;

				const lastItem = wallpaperRepeater.itemAt(wallpaperRepeater.count - 1);

				return lastItem.x + lastItem.width;
			}
			// height: flick.cellHeight + (3 - 1) * __rowStep
			// contentWidth: Math.max(flick.width, width)
	// 	property real _contentWidth:
    // Math.ceil(filteredWallpapers.length / visibleRows) * _colStep + cellWidth
			// property real _contentWidth: filteredWallpapers.length * _colStep
			// contentWidth:  _contentWidth
		    
			// property real _contentHeight: Math.ceil(filteredWallpapers.length / visibleRows) * _rowStep
			// contentHeight: _contentHeight

			// contentHeight: Math.max(wallpaperContainer.height, height)


		

			// height: flick.height
			// width: cardContainer.width

			boundsBehavior: Flickable.StopAtBounds
			flickableDirection: Flickable.HorizontalFlick
			// Layout.fillHeight: false
			// Layout.fillWidth: true

			focus: true
		
			interactive: true
			
			clip: false // important to make selector overflow

			property bool firstUpdateDone: true

			function applyVisual(item, scale, opacity) {
				item.visualWrapperRef.visualScale = scale
				item.visualWrapperRef.fadeOpacity = opacity
			}

			property bool selectedHexSettled: false

			property int verticalMargin: 15
			
			
			property int horizontalMargin: 30

			property real visibleBand:
				(columns - 1) * _colStep + (cellWidth)


			property real marginFactor: 0.1
			
			property real fadeZone:
				Math.max(0, (width - visibleBand) * 0.5 + (flick._r * 0.4))

			property real viewportLeft:
				contentX - fadeZone

			property real viewportRight:
				contentX + width - fadeZone
				
			property real bufferFactor: 0.5
			property int hStartCol:
				Math.floor((contentX + _colStep * bufferFactor) / _colStep)
				
			property int hStartIndex:
				hStartCol * visibleRows

			property int hEndIndex:
				Math.min(filteredWallpapers.length, hStartIndex + visibleRows * columns)
			// property real leftFactor:
			// 	(5 * horizontalMargin) / _colStep

			// property real rightFactor:
			// 	(1.2 * horizontalMargin) / _colStep

			// property real viewportLeft:
			// 	contentX - (_colStep * leftFactor)

			// property real viewportRight:
			// 	contentX + width - (_colStep * rightFactor)

			property bool layoutLock: false

			// function updateScales() {
			// 	if (!wallpaperRepeater || wallpaperRepeater.count === 0) return

			// 	for (var i = 0; i < wallpaperRepeater.count; i++) {
			// 		var item = wallpaperRepeater.itemAt(i)
			// 		if (!item) continue

			// 		var itemLeft = item.x
			// 		var itemRight = item.x + flick.cellWidth * 0.6

			// 		// selected item
			// 		// if (item === wallpaperController.currentSelected) {

			// 		// 	if (
			// 		// 		itemRight < viewportLeft ||
			// 		// 		itemLeft > viewportRight ||

			// 		// 		(itemLeft < viewportLeft &&
			// 		// 		itemRight > viewportLeft) ||

			// 		// 		(itemRight > viewportRight &&
			// 		// 		itemLeft < viewportRight)
			// 		// 	) {
			// 		// 		applyVisual(item, 0, 0)
			// 		// 	} else {
			// 		// 		applyVisual(item, 1, 1)
			// 		// 	}

			// 		// 	continue
			// 		// }

			// 		// normal visibility
			// 		var fullyVisible =
			// 			itemLeft >= viewportLeft &&
			// 			itemRight <= viewportRight

			// 		var completelyOutside =
			// 			itemRight <= viewportLeft ||
			// 			itemLeft >= viewportRight

			// 		if (fullyVisible) {
			// 			applyVisual(item, 1, 1)

			// 		} else if (completelyOutside) {
			// 			// var center = flick.contentX + flick.width * 0.5

			// 			// var dist = Math.abs(item.x + item.width * 0.5 - center)

			// 			// var t = Math.min(1, dist / (flick.width * 0.5))

			// 			// var s = 1 - (t * 0.3)   // 1 → 0.7
			// 			// applyVisual(item, s, 0)
			// 			applyVisual(item, 0, 0)

			// 		} else {
			// 			applyVisual(item, 0, 0)
			// 		}
			// 	}

			// 	firstUpdateDone = true
			// }

			onMovementEnded: {
				contentX = Math.round(contentX / _colStep) * _colStep
			}
			
			Behavior on contentX {
				NumberAnimation {
					duration: 150
					easing.type: Easing.BezierSpline
					easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
				}
			}
			
			property real dirThreshold: 0.5
			property real lastContentX: 0
			property int scrollDirX: 0
			property int lastDirX: 0

			Connections {
				target: flick
				property int lastDirX: 0


				function onContentXChanged() {
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
	


				   Keys.enabled: true
				   Keys.onPressed: function(event) {
						// if(!WatcherService.thumbsGenerated) return
						// if(!flick.listViewShown) return

						let oldIndex = wallpaperController.currentIndex

						let ctx = {
							size: filteredWallpapers.length,
							currentIndex: oldIndex,

							rows: flick.visibleRows,
							columns: flick.columns,

							onApply: (i) =>
								WallpaperApplyService.applyWallpaper(filteredWallpapers[i]),

							onMove: (i) => {
								flick.cancelFlick()
								// wallpaperController.previousIndex = flick.currentIndex
								wallpaperController.currentIndex = i
							

								Qt.callLater(() => {

									smartScroll(i, oldIndex)
								})
								
							}
						}

						let handled = InputHandler.hNavigate(event, ctx)

						if (handled)
							event.accepted = true
					}

		
					function smartScroll(i, oldIndex) {

						

							let rows = flick.visibleRows
							let col = Math.floor(i / rows)

							let colLeft = col * flick._colStep
							let colRight = colLeft + flick._colStep

							let viewLeft = flick.contentX
							let viewRight = flick.contentX + flick.width

							let maxCol = Math.ceil(filteredWallpapers.length / rows) - 1

							if (colLeft < viewLeft) {
								flick.contentX = Math.max(0, colLeft)
								
								flick.cancelFlick()
								flick.flick(0, 0) 
								return
							}

							if (colRight > viewRight) {

								let visibleCols = flick.columns

								let target = col - visibleCols + 1

								target = Math.max(0, Math.min(maxCol, target))

								flick.contentX = target * flick._colStep
								flick.cancelFlick()
								flick.flick(0, 0) 

								return
							}

						
					
					}
					// function getCol(index) {
					// 	return Math.floor(index / flick.visibleRows)
					// }

					// function getRow(index) {
					// 	return index % flick.visibleRows
					// }

					// function toIndex(col, row) {
					// 	return col * flick.visibleRows + row
					// }

					// function isValidIndex(i) {
					// 	return i >= 0 && i < filteredWallpapers.length
					// }

					// Keys.onPressed: function(event) {
					// if (!filteredWallpapers || filteredWallpapers.length === 0)
					// 	return;

					// let index = wallpaperController.currentIndex;

					// let col = getCol(index);
					// let row = getRow(index);

					// let newCol = col;
					// let newRow = row;

					// switch (event.key) {

					// 	case Qt.Key_Right:
					// 		newCol += 1;
					// 		break;

					// 	case Qt.Key_Left:
					// 		newCol -= 1;
					// 		break;

					// 	case Qt.Key_Down:
					// 		newRow += 1;
					// 		break;

					// 	case Qt.Key_Up:
					// 		newRow -= 1;
					// 		break;

					// 	case Qt.Key_Return:
					// 	case Qt.Key_Enter:
					// 		actions.applyWallpaper(filteredWallpapers[index]);
					// 		event.accepted = true;
					// 		return;

					// 	default:
					// 		return;
					// }

					// let targetIndex = toIndex(newCol, newRow);

					// if (!isValidIndex(targetIndex)) {
					// 	event.accepted = true;
					// 	return;
					// }

					// flick.cancelFlick()

					// wallpaperController.currentIndex = targetIndex

					// 	// smooth scroll into view
					// 	const item = wallpaperRepeater.itemAt(targetIndex);
					// 	if (item) {
					// 		const margin = 4;
					// 		const viewportMargin = flick.width * 0.1

					// 		let left = item.x - margin;
					// 		let right = item.x + item.width + margin;

					// 		if (left < flick.contentX - viewportMargin) {
					// 			flick.contentX = left;
					// 		} else if (right > flick.contentX + flick.width + viewportMargin) {
					// 			flick.contentX = right - flick.width;
					// 		}
					// 	}
					// }


				// Item {
				// 	id: flickWrapper
				// 	property int wrapperWidth: Math.max(flick.width, flick.width)
				// 	// property int wrapperHeight: Math.max(flick.height,flick.height)
				// 	width: wrapperWidth
				// 	property int wrapperHeight: flick.height
				// 	property real safePadding: flick.cellHeight * 0.15
				// 	height: wrapperHeight + (safePadding - 30)
			
				
						
				// Item {
				// 	id: flick
					
					property real cellHeightFactor: 0.95
					Behavior on cellHeightFactor {
						NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic }
					}

					property real spacingYFactor: 0.8
					Behavior on spacingYFactor {
						NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic }
					}
					
					property int spacingY: 10
					property real effectiveCellStepY:
						cellHeight * cellHeightFactor + spacingY * spacingYFactor

					
					property real baseOffsetX: Math.max((flick.width - gridHeight) / 2, 0)
					property real globalShiftX: 0
					property real baseBiasX: 0
					
				
					// x: (flick.width - gridWidth()) / 2 + globalShiftX
					// y: 0
					
					function updateGridFocusOffset() {
						var selVW = wallpaperController.currentSelected
									&& wallpaperController.currentSelected.visualWrapperRef
									? wallpaperController.currentSelected.visualWrapperRef
									: null

						var selIndex = wallpaperController.currentIndex
						var cols = flick.columns

						var col = selIndex % cols
						var centerCol = Math.floor(cols / 2)

						var offset = col - centerCol

						// 🚨 KEY CHANGE HERE
						if (!selVW || selVW.opacity === 0) {
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
					

			
					// function baseY(index) {
					// 	var row = index % visibleRows
					// 	var col = Math.floor(index / visibleRows)

					// 	var step = effectiveCellStepY
					// 	var y = row * step

					// 	if (col % 2 === 1)
					// 		y += step / 2

					// 	return y
					// }

					property real gridOffsetY: (flick.height - gridHeight) / 2
					
					

					// function itemY(index) {
					// 	return gridOffsetY + baseY(index)
					// }

					

					property real gridHeight:
						visibleRows * effectiveCellStepY
						+ effectiveCellStepY / 2

					property int totalCols: Math.ceil(filteredWallpapers.length / flick.visibleRows)
					
					property real gridWidth: (totalCols - 1) * _colStep + cellWidth
					// function gridHeight() {
					// 	var step = effectiveCellStepY

					// 	var base =
					// 		(visibleRows - 1) * step + cellHeight

					// 	return base + step / 2
					// }
					// property real _gridInset: 4
					// property real offset: Math.max((
					// 	((flick.columns - 1) * _colStep + flick.cellWidth) - gridWidth) / 2, 0) + _gridInset

					// property real offset:
					// 	Math.max(
					// 		(flick.width - gridWidth) / 2 + _gridInset,
					// 		0
					// 	)

					property real _gridInset: flick.cellWidth * 0.05
					property real offset: Math.max((
						((columns - 1) * _colStep + flick.cellWidth) - gridWidth) / 2, 0) + _gridInset	
					// property colOffset: Math.floor(index / visibleRows)

					function itemX(index) {
						var rows = flick.visibleRows
						var col = Math.floor(index / rows)

						var totalCols =
							Math.ceil(wallpaperRepeater.count / rows)

						var stepX = flick.cellWidth * 0.75

						var totalWidth =
							(totalCols - 1) * stepX +
							flick.cellWidth

						var visualPadding =
							flick.cellWidth * 0.1

						var viewportWidth =
							flick.width

						var horizontalOffset =
							Math.max(
								(viewportWidth - totalWidth) / 2 +
								visualPadding / 2,
								0
							)

						return horizontalOffset + col * stepX
					}

					
			

					// property int cellWidth: 190
					// property int cellHeight: Math.round(cellWidth * Math.sqrt(3)/2 * 1.2) 
					property int _r:  90
					property int cellHeight: _r * 2
					property int cellWidth: Math.round(cellHeight * Math.sqrt(3)/2 * 1.3)
					property int spacingX: 10
					// property int spacingY: 10
					property int columns: 5
					property int visibleRows: 3
					// property real _rowStep: flick.cellHeight * 0.75

					// height: flick.cellHeight
					// 		+ (visibleRows - 1) * _rowStep
					
					
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
					// Container outside the Flickable, so it’s not masked
					Item {
						id: highlightContainer

						z: 9999
						clip: false
						visible: isContentVisible
						

						layer.smooth: true
						
						Shape {
							
							id: selectedHexBorder
							// visible: false
							visible: wallpaperController.currentSelected 
							width: flick.cellWidth - 10
							height: flick.cellHeight - 10

							// Handles selection animation + state transitions
							
							
			
							property real deadZone: 20
								
							property real itemCenterY: y + height * 0.5
							property real viewCenterY: flick.contentY + flick.height * 0.5
							property bool _nearTop: itemCenterY < viewCenterY - deadZone
							transformOrigin: {
								if (scale > 0.99)
									return Item.Center

								var movingLeft = flick.scrollDirX < 0
								return movingLeft ? Item.Left: Item.Right
							}
							// transformOrigin: {
							// 	if (flick.scrollDirY < 0) {
							// 		return _nearTop ? Item.Top : Item.Bottom
							// 	} else {
							// 		return _nearTop ? Item.Bottom : Item.Top
							// 	}
								
							// }
					

							

							// Bind scale to the selected item's visualScale
							scale: wallpaperController.currentSelected ? currentSelected.visualScale : 1
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
							x: currentSelected ? currentSelected.targetX: 0
							y: currentSelected ? currentSelected.targetY : 0
						
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
								Behavior on scale {
								
									NumberAnimation {
										duration: 250
										easing.type: Easing.BezierSpline
										easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
										
									}
							
								}
								// Behavior on scale {
									
								// 	SpringAnimation {
								// 			spring: 6
								// 			damping: 0.9 
								// 		}
								// }


						}
						
						
					}
					
					Repeater {
						id: wallpaperRepeater
						model: filteredWallpapers
						// onItemAdded: function(item, i) {
						// 	if (i === wallpaperRepeater.count - 1) {
						// 		wallpaperController.requestFrame()
						// 	}
						// }

						Item {
							id: hexItem
							z: isSelected ? 999 : 1
							property bool isSelected: wallpaperController.currentIndex === index
						
						
						
							width: flick.cellWidth - 10
							height: flick.cellHeight - 10

							
							property bool imageReady: thumbImage.status === Image.Ready && thumbImage.paintedWidth > 0
							 
							property bool isHidden: false
					
							property real itemLeft: x
							property real itemRight: x + flick.cellWidth * 0.6
							
							property bool fullyVisible:
								itemLeft >= flick.viewportLeft &&
								itemRight <= flick.viewportRight
							property real epsilon: 2.0
							

							// property bool completelyOutside:
							// 	itemRight <= flick.viewportLeft ||
							// 	itemLeft >= flick.viewportRight
							property bool _inView: 
								((index >= flick.hStartIndex) &&
								(index<  flick.hEndIndex))


							property real visualScale: _inView ? 1 : 0
							
							visible: scale > 0 ? true : false
							scale: visualScale

							// property real fadeOpacity: {
							// 	if (fullyVisible) {
							// 		return 1

							// 	} else if (completelyOutside) {
									
							// 		return 0

							// 	} else {
							// 		return 0
							// 	}
							// }
							opacity: scale < 0.01 ? 0 : 1
							// opacity: 1
							// Behavior on opacity { 
							// 		NumberAnimation { 
							// 			duration: 300; 
							// 			easing.type: Easing.InCubic
							// 	} }
							Behavior on scale {
							
								NumberAnimation {
									duration: 250
									easing.type: Easing.BezierSpline
									easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
									
								}
						
							}
							readonly property real _hexCenterX: (x - flick.contentX) + width * 0.5
							readonly property bool _nearLeft: _hexCenterX < flick.width / 2
							// transformOrigin: _nearLeft ? Item.Left: Item.Right
							transformOrigin: {
								if (scale > 0.99)
									return Item.Center

								var movingLeft = flick.scrollDirX < 0
								return movingLeft ? Item.Left: Item.Right
							}
								// return movingLeft
								// 	? (_nearLeft ? Item.Left:Item.Left)
								// 	: (_nearLeft ? Item.Right : Item.Right)
							property real col: Math.floor(index / flick.visibleRows)
							property real row: index % flick.visibleRows

							property real itemY:
							row * flick.effectiveCellStepY +
							(col % 2 ? flick.effectiveCellStepY * 0.5 : 0)
							
							property real baseX: flick.offset + col * flick._colStep
							property real baseY: flick.gridOffsetY + itemY

							
							property real targetX: baseX + shiftX
							
							function isSelectedVisible() {
								var selIndex = wallpaperController.currentIndex
								if (selIndex < 0 || selIndex >= wallpaperRepeater.count) return false

								var selItem = wallpaperRepeater.itemAt(selIndex)
								if (!selItem) return false

								// Use centralized viewport values
								if (selItem.y + selItem.height < flick.viewportTop || selItem.y > flick.viewportBottom) {
									
									return false
								} else {
									
									return true
								}
							}


							property Item selVW: (
								selectedHexBorder &&
								wallpaperController.currentSelected &&
								wallpaperController.currentSelected.visualWrapperRef
							) ? wallpaperController.currentSelected.visualWrapperRef : null
							// property Item selVW: selectedHexBorder?.currentSelected?.visualWrapperRef	
							
							function computeShiftX() {
								var selIndex = wallpaperController.currentIndex
								if (index === selIndex) return 0

								// If selected hex is scaled to 0 (offscreen), don't give space
								
								if (!selVW || selVW.visualScale < 1) return 0;

								var cols = flick.columns
								var selRow = Math.floor(selIndex / cols)
								var selCol = selIndex % cols
								var row = Math.floor(index / cols)
								var col = index % cols

								// Left side of selection
								if (col < selCol || 
									(row < selRow && col <= selCol - (selRow % 2 === 0 ? 1 : 0)) || 
									(row > selRow && col <= selCol - (selRow % 2 === 0 ? 1 : 0)))
									return -20

								// Right side of selection
								if (col > selCol || 
									(row < selRow && col >= selCol + (selRow % 2 === 0 ? 0 : 1)) ||
									(row > selRow && col >= selCol + (selRow % 2 === 0 ? 0 : 1)))
									return 20

								return 0
							}			

							function updateShift() {
								return
								// shiftX = computeShiftX()
								// shiftY = computeShiftY()
							}
							
							Connections {
								target: wallpaperController.currentSelected
										? wallpaperController.currentSelected.visualWrapperRef
										: null

								function onVisualScaleChanged() {
									flick.updateGridFocusOffset()
									updateShift()
								}
							}

							// Update shiftX and scale all at start
							Component.onCompleted: {
								
								if (wallpaperRepeater.count > 0) {
									
									wallpaperController.currentSelected = wallpaperRepeater.itemAt(wallpaperController.currentIndex)
								}
							}

							property real targetY: baseY + shiftY
							function computeShiftY() {
								var selIndex = wallpaperController.currentIndex
								if (index === selIndex) return 0

								// If selected hex is scaled to 0 (offscreen), don't give space
								// var selVW = wallpaperController.currentSelected?.visualWrapperRef;
								if (!selVW || selVW.visualScale === 0) return 0;

								var cols = flick.columns
								var selRow = Math.floor(selIndex / cols)
								var row = Math.floor(index / cols)

								if (row < selRow) return -10
								if (row > selRow) return 10
								return 0
							}

							x: targetX
						
    						y: targetY
							

							Behavior on x {
							
								NumberAnimation {
									duration: 400
									easing.type: Easing.BezierSpline
									easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
								}
							}

							Behavior on y {
							
								NumberAnimation {
									duration: 400
									easing.type: Easing.BezierSpline
									easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
								}
							}
												
							
							property bool hiddenRow: false
							property alias visualWrapperRef: visualWrapper
						

						// property var selIndex: wallpaperController.currentIndex
						// property int generation: getGeneration(index, selIndex)

						// property real scaleTarget: getScale(generation)

						// property var shift: computeShift(index, selIndex)

						property real shiftX: 0
						property real shiftY: 0
							// function getGridPos(i) {
							// 	var cols = flick.columns
							// 	return {
							// 		x: i % cols,
							// 		y: Math.floor(i / cols)
							// 	}
							// }

							// function getGeneration(index, selIndex) {
							// 	var a = getGridPos(index)
							// 	var b = getGridPos(selIndex)

							// 	var dx = a.x - b.x
							// 	var dy = a.y - b.y

							// 	// grid distance (simple approximation)
							// 	return Math.max(Math.abs(dx), Math.abs(dy))
							// }
							// function getScale(gen) {
							// 	if (gen === 0) return 1.15
							// 	if (gen === 1) return 1.0
							// 	if (gen === 2) return 0.85
							// 	if (gen === 3) return 0.7
							// 	return 0.65
							// }

							
							/* FUNCTIONS FOR TESTING:

							** BOOLEAN TO IDENTIFY WHICH DIRECTION THE HEXAGON IS POSITIONED
							** INCLUDING ALL ADJACANT TO THE SELECTED NEIGHBORS HEXAGON

							property bool moveLeft: {
								var selected = wallpaperController.currentIndex
								var totalCols = flick.columns
								var selRow = Math.floor(selected / totalCols)
								var selCol = selected % totalCols

								var row = Math.floor(index / totalCols)
								var col = index % totalCols

								if (index === selected) return false

								// 1. Left hexes in same row
								if (row === selRow && col < selCol) return true

								// 2. Upper-left column relative to selected
								if (row < selRow) {
									var offset = (selRow % 2 === 0) ? -1 : 0
									if (col <= selCol + offset) return true
								}

								// 3. Lower-left column relative to selected
								if (row > selRow) {
									var offset = (selRow % 2 === 0) ? -1 : 0
									if (col <= selCol + offset) return true
								}

								return false
							}

							property bool moveRight: {
								var selected = wallpaperController.currentIndex
								var totalCols = flick.columns
								var selRow = Math.floor(selected / totalCols)
								var selCol = selected % totalCols

								var row = Math.floor(index / totalCols)
								var col = index % totalCols

								if (index === selected) return false

								// 1. Right hexes in same row
								if (row === selRow && col > selCol) return true

								// 2. Upper-right column relative to selected
								if (row < selRow) {
									var offset = (selRow % 2 === 0) ? 0 : 1
									if (col >= selCol + offset) return true
								}

								// 3. Lower-right column relative to selected
								if (row > selRow) {
									var offset = (selRow % 2 === 0) ? 0 : 1
									if (col >= selCol + offset) return true
								}

								return false
							}

							** 6 NEIGHBOR HEXAGONS OF THE CURRENTLY SELECTED
							*/
							property bool isNeighbor: {
								var selected = wallpaperController.currentIndex
								var totalColumns = flick.columns
								var row = Math.floor(index / totalColumns)
								var col = index % totalColumns
								var selectedRow = Math.floor(selected / totalColumns)
								var selectedCol = selected % totalColumns

								if (index === selected) return false  // selected itself is not a neighbor

								// Left / Right neighbors in the same row
								if (row === selectedRow && (col === selectedCol - 1 || col === selectedCol + 1)) return true

								// Row above (upper-left / upper-right)
								if (row === selectedRow - 1) {
									if (selectedRow % 2 === 0) { // even selected row
										if (col === selectedCol - 1 || col === selectedCol) return true
									} else { // odd selected row
										if (col === selectedCol || col === selectedCol + 1) return true
									}
								}

								// Row below (lower-left / lower-right)
								if (row === selectedRow + 1) {
									if (selectedRow % 2 === 0) { // even selected row
										if (col === selectedCol - 1 || col === selectedCol) return true
									} else { // odd selected row
										if (col === selectedCol || col === selectedCol + 1) return true
									}
								}

								return false
							} 
							function getHexPos(i) {
								var cols = flick.columns

								var row = Math.floor(i / cols)
								var col = i % cols

								// offset correction (odd-row shift)
								var x = col - Math.floor(row / 2)
								var y = row

								return { x: x, y: y }
							}
							function hexDistance(a, b) {
								var dx = a.x - b.x
								var dy = a.y - b.y
								var dz = -dx - dy

								return Math.max(Math.abs(dx), Math.abs(dy), Math.abs(dz))
							}

							property int gen: {
								var sel = wallpaperController.currentIndex
								if (index === sel) return 0

								var a = getHexPos(index)
								var b = getHexPos(sel)

								return hexDistance(a, b)
							}
							property real scaleTarget: {
								if (gen === 0) return 1

								// smooth falloff
								return Math.max(0.6, 1.05 - gen * 0.18)
							}

// property int gen: hexDistance(
//     getHexPos(index),
//     getHexPos(wallpaperController.currentIndex)
// )
								
							 Item {
								id: visualWrapper
								
								property alias flipAnim: flipAnim
								width: parent.width
        						height: parent.height
								
								
								property real fadeOpacity: 1
								property real visualScale: 1

								scale: visualScale	


								property real deadZone: 20
								
								property real itemCenterX: x + width * 0.5
								property real viewCenterX: flick.contentX + flick.width * 0.5

								// property bool _nearLeft:
								// 	itemCenterX < viewCenterX - deadZone
								// transformOrigin: _nearLeft ? Item.Right : Item.Left
								
								// transformOrigin: {
								// 	if (visualWrapperRef.scale > 0.99) return Item.Center

								// 	if (flick.scrollDirX < 0) {
								// 		return _nearLeft ? Item.Right: Item.Left
								// 	} else {
								// 		return _nearLeft ?  Item.Right : Item.Left
								// 	}
									
								// }
								// Component.onCompleted: {
								// 	Qt.callLater(() => {
								// 		visualWrapper.visualScale = 1
								// 	})
									
								// }
							
								
    							opacity: fadeOpacity
								
								// Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
								// Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
								
								// onXChanged: {}
								
								Behavior on scale {
								
									NumberAnimation {
										duration: 250
										easing.type: Easing.BezierSpline
										easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
										
									}
									// SpringAnimation {
									// 		spring: 6
									// 		damping: 0.9 
									// 	}
									// NumberAnimation { 
									// duration: 358; easing.type: Easing.OutCubic 
									// }
								}

								Behavior on opacity { 
									
									NumberAnimation { 
										duration: 300; 
										easing.type: Easing.InOutQuad 
								} }
									

								transform: Rotation {
									id: yRotation
									origin.x: visualWrapper.width / 2
									origin.y: visualWrapper.height / 2
									axis { x: 0; y: 1; z: 0 }
									angle: visualWrapper.flipAngle
								}

								property real flipAngle: 0

				
								NumberAnimation {
									id: flipAnim
									target: visualWrapper
									property: "flipAngle"
									duration: 300
									easing.type: Easing.InOutQuad
								}
								
								property bool isSelected: false
								
								Image {
									id: thumbImage
									fillMode: Image.PreserveAspectCrop
									anchors.fill: parent
									anchors.centerIn: parent
									asynchronous: true
									property string thumbName: thumbnailPaths[modelData] || ""
									// source: "file://" + wallpaperController.thumbnailDir + "/" + thumbName
									source: (thumbs.thumbData && thumbs.thumbData[thumbName])
											? ("file://" + wallpaperController.thumbnailDir + "/" + thumbName)
											: ""
											
									layer.enabled: true
								    layer.effect: MultiEffect {
										blurEnabled: true
										blur: wallpaperController.currentIndex === index && 
										wallpaperController.blurTransition ? 1 : 0
										blurMax: 32
										Behavior on blur {
											enabled: true
											NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
										}
									}
								}
						

							



								// Image {
								// 	id: currentImage
								// 	anchors.fill: parent
								// 	fillMode: Image.PreserveAspectCrop
								// 	asynchronous: true
								// 	source: coverArtContainer.currentSource
								// 	opacity: 1

								// 	property real blurLevel: 0
								// 	layer.enabled: Appearance.effectsEnabled
								// 	layer.effect: MultiEffect {
								// 		blurEnabled: true
								// 		blur: currentImage.blurLevel
								// 		blurMax: 32
								// 		Behavior on blur { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
								// 	}
								// }
// Rectangle {
//     anchors.fill: parent
//     visible: wallpaperController.cardVisible && !fadeInAnim.running

//     color: {
//         if (gen === 0) return "transparent"   // selected
//         if (gen === 1) return "red"
//         if (gen === 2) return "orange"
//         if (gen === 3) return "yellow"
// 		if (gen === 4) return "blue"
// 		if (gen === 5) return "green"
// 		if (gen === 6) return "violet"
// 		if (gen === 7) return "purple"
//         return "blue"
//     }

//     Behavior on opacity {
//         NumberAnimation {
//             duration: 200
//             easing.type: Easing.InOutQuad
//         }
//     }
// }
								// Rectangle {
								// 	anchors.fill: parent
								// 	visible: wallpaperController.cardVisible && !fadeInAnim.running
								// 	color: isSecondGen ? "red" : "transparent"
								// 	Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
								// }
								Rectangle {
									anchors.fill: parent
									visible: imageReady
									color: "#000000"
									
									opacity: wallpaperController.currentIndex === index
									? 0.6: 0
									// : ((!selVW || selVW.visualScale < 1) ? 0 : Math.min(0.6, gen * 0.12))
									Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InCubic } }
								}
								

								layer.enabled: true
								layer.smooth: true
								
								layer.effect: OpacityMask {
									maskSource: Shape {
										width: visualWrapper.width
										height: visualWrapper.height
										anchors.centerIn: parent
										preferredRendererType: Shape.CurveRenderer
										antialiasing: true
										
										ShapePath {
											fillColor: "white"
											strokeColor: fillColor
											strokeWidth: 0
											
											PathMove { x: width * 0.25; y: 0 }
											PathLine { x: width * 0.75; y: 0 }
											PathLine { x: width;        y: height * 0.5 }
											PathLine { x: width * 0.75; y: height }
											PathLine { x: width * 0.25; y: height }
											PathLine { x: 0;            y: height * 0.5 }
											PathLine { x: width * 0.25; y: 0 }
										}
									}
								}
							}
							
						
							MouseArea {
								anchors.fill: parent
								// enabled: visualWrapperRef.visualScale > 0 
								// && visualWrapperRef.fadeOpacity > 0
								
								onClicked: {
									wallpaperController.currentIndex = index
									Qt.callLater(() => flick.forceActiveFocus())
								}

								onDoubleClicked: actions.applyWallpaper(modelData)
							}
						}
					}
				
				
			}
		
	
		
	
	// RowLayout {
	// 		id: textContainer
	// 		Layout.fillWidth: true
	// 		Layout.alignment: Qt.AlignHCenter
	// 		visible: wallpaperController.cardVisible
			
	// 		z: 9999
			

	// 		// visible: wallpaperController.cardVisible
	// 		// && wallpaperRepeater.count > 0
	// 		// && wallpaperRepeater.itemAt(wallpaperController.currentIndex).imageReady
	// 		// Rectangle {
	// 		// 	anchors.fill: parent
				
	// 		// 	color: "transparent" 
	// 		// 	border.color: "red"       
	// 		// 	border.width: 1
	// 		// }
	// 		Item { Layout.fillWidth: true }
	// 		Item {
	// 			id: skewField
	// 			Layout.alignment: Qt.AlignHCenter
	// 			layer.enabled: true
	// 			layer.smooth: true
				
				
	// 			width: 260
	// 			height: 36

	// 			Shape {
	// 				anchors.fill: parent
	// 				preferredRendererType: Shape.CurveRenderer
	// 				antialiasing: true
	// 				ShapePath {
	// 					fillColor: Colors.background
    //             		strokeColor: "transparent"
	// 					strokeWidth: 1

	// 					startX: 10; startY: 0
	// 					PathLine { x: 260; y: 0 }
	// 					PathLine { x: 250; y: 36 }
	// 					PathLine { x: 0;   y: 36 }
	// 					PathLine { x: 10;  y: 0 }
	// 				}
	// 			}

	// 			Item {
	// 				anchors.fill: parent
	// 				clip: false

	// 				TextField {
	// 					id: searchBox
	// 					anchors.fill: parent

	// 					anchors.leftMargin: 10
	// 					anchors.rightMargin: 10

	// 					background: null

	// 					placeholderText: "Filter Images..."
	// 					placeholderTextColor: Colors.backgroundText70

	// 					font.pixelSize: 16
	// 					font.family: "JetBrainsMono Nerd Font"
	// 					color: Colors.backgroundText70

	// 					focus: true
	// 					cursorVisible: false
	// 					selectionColor: "transparent"

	// 					focusPolicy: Qt.StrongFocus
	// 					activeFocusOnPress: true

	// 					MouseArea {
	// 						anchors.fill: parent
	// 						onPressed: Qt.callLater(() => searchBox.forceActiveFocus())
	// 					}

	// 					onTextChanged: {
	// 						if (!text || text.length === 0) {
	// 							filteredWallpapers = wallpapers
	// 						} else {
	// 							let query = text.toLowerCase()
	// 							filteredWallpapers = wallpapers.filter(w => w.toLowerCase().indexOf(query) !== -1)
	// 						}

	// 						wallpaperController.currentIndex = 0

	// 						if (filteredWallpapers.length > 0)
	// 							selectedWallpaper = filteredWallpapers[0]

	// 						wallpaperController.requestFrame()
	// 					}
	// 				}
	// 			}
	// 		}

	// 		Item { Layout.fillWidth: true }

	// 		// Button {
	// 		// 	id: rescanBtn
	// 		// 	text: "Rescan"
	// 		// 	onClicked: {
	// 		// 		startListing()
	// 		// 		initTimer.start()
	// 		// 	}
	// 		// 	background: Rectangle {
	// 		// 		radius: 8
	// 		// 		color: rescanBtn.down ? Qt.darker(colorSurfaceContainer, 1.3) : (rescanBtn.hovered ? Qt.lighter(colorSurfaceContainer, 1.2) : colorSurfaceContainer)
	// 		// 		border.color: colorOutline
	// 		// 		border.width: 1
	// 		// 	}
	// 		// 	contentItem: Text {
	// 		// 		text: rescanBtn.text
	// 		// 		color: colorOnSurface
	// 		// 		font.pixelSize: 14
	// 		// 		horizontalAlignment: Text.AlignHCenter
	// 		// 		verticalAlignment: Text.AlignVCenter
	// 		// 		elide: Text.ElideRight
	// 		// 	}
	// 		// }
	// 		// Button {
	// 		// 	id: randomBtn
	// 		// 	text: "Random"
	// 		// 	onClicked: utils.randomWallpaperFisherYates(filteredWallpapers, filteredWallpapers[wallpaperController.currentIndex]);
	// 		// 	background: Rectangle {
	// 		// 		radius: 8
	// 		// 		color: randomBtn.down ? Qt.darker(colorSurfaceContainer, 1.3) : (randomBtn.hovered ? Qt.lighter(colorSurfaceContainer, 1.2) : colorSurfaceContainer)
	// 		// 		border.color: colorOutline
	// 		// 		border.width: 1
	// 		// 	}
	// 		// 	contentItem: Text {
	// 		// 		text: randomBtn.text
	// 		// 		color: colorOnSurface
	// 		// 		font.pixelSize: 14
	// 		// 		horizontalAlignment: Text.AlignHCenter
	// 		// 		verticalAlignment: Text.AlignVCenter
	// 		// 		elide: Text.ElideRight
	// 		// 	}
	// 		// }
	// 		// Button {
	// 		// 	id: settingsBtn
	// 		// 	text: "Settings"
	// 		// 	onClicked: settingsOpen = true
	// 		// 	background: Rectangle {
	// 		// 		radius: 8
	// 		// 		color: settingsBtn.down ? Qt.darker(colorSurfaceContainer, 1.3) : (settingsBtn.hovered ? Qt.lighter(colorSurfaceContainer, 1.2) : colorSurfaceContainer)
	// 		// 		border.color: colorOutline
	// 		// 		border.width: 1
	// 		// 	}
	// 		// 	contentItem: Text {
	// 		// 		text: settingsBtn.text
	// 		// 		color: colorOnSurface
	// 		// 		font.pixelSize: 14
	// 		// 		horizontalAlignment: Text.AlignHCenter
	// 		// 		verticalAlignment: Text.AlignVCenter
	// 		// 		elide: Text.ElideRight
	// 		// 	}
	// 		// }
	// 	}
  
}
}