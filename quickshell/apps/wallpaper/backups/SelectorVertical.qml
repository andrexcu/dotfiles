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
				let defaultWall = homeDir + "/Pictures/Wallpapers"
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
				wallpaperController.currentSelected.visualWrapperRef.visualScale = 1.15
				
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
			vwPrev.flipAnim.stop()

			// Normalize current state
			
			vwPrev.visualScale = 1
			vwPrev.fadeOpacity = 1

			// Animate back to flat
			vwPrev.flipAnim.from = vwPrev.flipAngle
			vwPrev.flipAnim.to = 0
			vwPrev.flipAnim.start()
		}

		// Animate selected item (ENTER)
		var vw = selectedItem.visualWrapperRef
		vw.flipAnim.stop()

		// Prepare starting state
		vw.flipAngle = 0
		vw.visualScale = 0.25
		vw.fadeOpacity = 0

		// Animate flip in correct direction
		vw.flipAnim.from = 0
		vw.flipAnim.to = 180 * direction
		vw.flipAnim.start()
	}

	function updateVisual() {
		flick.applyVisual(selectedItem, 1, 1, 0)
		// Update selected & previous index
		wallpaperController.currentSelected = selectedItem
		wallpaperController.previousIndex = wallpaperController.currentIndex
	}

	function runFrame() {
		flick.updateScales()
		wallpaperContainer.updateGridFocusOffset()
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
			flipHex()

			// Apply scale + fade
			updateVisual()

			// Scaling selected hex
			scaleDelayTimer.start()

			runUpdateShift()

			// Parallax effect
			wallpaperContainer.updateGridFocusOffset()
			
			// Blur selected hex
			wallpaperController.blurTransition = true
			imgBlurInTimer.restart()
		}
	}
	
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
	
  ColumnLayout {
	// anchors.fill: parent
	anchors.centerIn: parent
	anchors.margins: 16
	spacing: 16
	
 Item {
	id: cardContainer
	
	
	property real paddingY: wallpaperContainer.cellHeight * 0.4
	property real paddingX: Math.max(wallpaperContainer.cellWidth, flick.width * 0.05)
	width: wallpaperContainer.width + paddingX * 2
	height: wallpaperContainer.height + paddingY * 2
	Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
	
	clip: true
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
	visible: wallpaperController.isContentVisible
	// visible: wallpaperController.cardVisible
	
 	opacity: 0
	
    property bool animateIn: wallpaperController.cardVisible

    onAnimateInChanged: {
      fadeInAnim.stop()
      if (animateIn) {
        opacity = 0
        fadeInAnim.start()
        focusTimer.restart()
      }
    }

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
        Keys.enabled: true
		function getRow(index) {
		return Math.floor(index / wallpaperContainer.columns)
		}

		function getCol(index) {
			return index % wallpaperContainer.columns
		}

		function toIndex(row, col) {
			return row * wallpaperContainer.columns + col
		}

		function isValidIndex(i) {
			return i >= 0 && i < filteredWallpapers.length
		}

		Keys.onPressed: function(event) {
			if (!filteredWallpapers || filteredWallpapers.length === 0)
				return;

			const cols = wallpaperContainer.columns;

			let index = wallpaperController.currentIndex;
			let row = getRow(index);
			let col = getCol(index);

			let newRow = row;
			let newCol = col;

			switch (event.key) {

				case Qt.Key_Right:
					newCol += 1;
					break;

				case Qt.Key_Left:
					newCol -= 1;
					break;

				case Qt.Key_Down:
					newRow += 1;
					break;

				case Qt.Key_Up:
					newRow -= 1;
					break;

				case Qt.Key_Return:
				case Qt.Key_Enter:
					actions.applyWallpaper(filteredWallpapers[index]);
					event.accepted = true;
					return;

				default:
					return;
			}

			// HARD BLOCK invalid columns
			if (newCol < 0 || newCol >= cols) {
				event.accepted = true;
				return;
			}

			let targetIndex = toIndex(newRow, newCol);

			// HARD BLOCK missing items
			if (!isValidIndex(targetIndex)) {
				event.accepted = true;
				return;
			}
			flick.cancelFlick()

			wallpaperController.currentIndex = targetIndex;

			// smooth scroll into view
			const item = wallpaperRepeater.itemAt(targetIndex);
			if (item) {
				const margin = 4;
				const viewportMargin = flick.height * 0.1
				let top = item.y - margin;
				let bottom = item.y + item.height + margin;

				if (top < flick.contentY - viewportMargin) {
					flick.contentY = top;
				} else if (bottom > flick.contentY + flick.height + viewportMargin) {
					flick.contentY = bottom - flick.height;
				}
			}
			event.accepted = true;
		}
	


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
			
		Flickable {
			id: flick
			property int verticalMargin: 15
			property real maxItemScale: 1
			property real itemOverflow: wallpaperContainer.cellHeight * (maxItemScale - 1)
			property int extraPadding: 25
			property real rowStep: wallpaperContainer.cellHeight * 0.75
			property int topMargin: 40
			property int bottomMargin: itemOverflow + extraPadding
	

			// Rectangle {
			// 	anchors.fill: parent
			// 	color: "transparent" 
			// 	border.color: "blue"       
			// 	border.width: 2
			// }
		
			contentWidth: Math.max(wallpaperContainer.width, width)
		
			contentHeight: wallpaperContainer.childrenRect.height
			height: wallpaperContainerWrapper.height
			
			boundsBehavior: Flickable.StopAtBounds
		
			Layout.fillHeight: false
			Layout.fillWidth: true

			focus: true
		
			interactive: true
			
			clip: false // important to make selector overflow

			property bool firstUpdateDone: false

			function applyVisual(item, scale, opacity) {
				item.visualWrapperRef.visualScale = scale
				item.visualWrapperRef.fadeOpacity = opacity
			}

			property bool selectedHexSettled: false

			property real topFactor: (5 * verticalMargin) / rowStep
			property real bottomFactor: (1.2 * verticalMargin) / rowStep

			property real viewportTop: contentY - (rowStep * topFactor)
			property real viewportBottom: contentY + height - (rowStep * bottomFactor)
			property bool layoutLock: false

			function updateScales() {
				if (layoutLock) return
				// skip updates when disabled or no items
				if (!wallpaperRepeater || wallpaperRepeater.count === 0) return

				for (var i = 0; i < wallpaperRepeater.count; i++) {
					var item = wallpaperRepeater.itemAt(i)
					if (!item) continue

					// approximate vertical bounds of item (hex ≠ full cell height)
					var itemTop = item.y
					var itemBottom = item.y + wallpaperContainer.cellHeight * 0.6

					// --- SELECTED ITEM (independent behavior) ---
					if (item === wallpaperController.currentSelected) {

						// fully outside OR touching viewport edge → hide (prevents pop-in)
						if (
							itemBottom < viewportTop || itemTop > viewportBottom ||
							(itemTop < viewportTop && itemBottom > viewportTop) ||
							(itemBottom > viewportBottom && itemTop < viewportBottom)
						) {
							applyVisual(item, 0, 0)
						} else {
							// fully inside → keep highlighted scale
							applyVisual(item, 1.15, 1)
						}
						continue
					}

					// --- VISIBILITY STATES (non-selected items) ---

					// completely inside viewport bounds
					var fullyVisible =
						itemTop >= viewportTop && itemBottom <= viewportBottom

					// completely outside viewport bounds
					var completelyOutside =
						itemBottom <= viewportTop || itemTop >= viewportBottom

					// --- APPLY VISUAL STATE ---
					if (fullyVisible) {
						// normal visible item
						applyVisual(item, 1, 1)

					} else if (completelyOutside) {
						// far outside → shrink + hide
						applyVisual(item, 0.6, 0)

					} else {
						// partially overlapping viewport → hide (clean edge cutoff)
						applyVisual(item, 0, 0)
					}
				}

				// mark first full pass done 
				firstUpdateDone = true
			}

			onMovementEnded: {
				layoutLock = true

				contentY = Math.round(contentY / rowStep) * rowStep

				Qt.callLater(() => {
					layoutLock = false
					requestFrame()
				})
			}
			
			Behavior on contentY {
				NumberAnimation {
					duration: 210
					easing.type: Easing.BezierSpline
					easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
				}
			}
			
			Connections {
				target: flick
				function onContentYChanged() {
					wallpaperController.requestFrame()
					wallpaperController.runUpdateShift()
					if (!searchBox.activeFocus) {
						flick.forceActiveFocus()
					}
				}
			}

				MouseArea {
					anchors.fill: parent
					focus: true
					onWheel: (wheel) => {
						flick.flick(0, wheel.angleDelta.y * 12) // vertical
						wheel.accepted = true
					}

					onPressed: {
						flick.forceActiveFocus()
					}
					
				}

				Item {
					id: wallpaperContainerWrapper
					property int wrapperWidth: Math.max(wallpaperContainer.width, flick.width)
					property int wrapperHeight: wallpaperContainer.height
					// property int wrapperHeight: Math.max(wallpaperContainer.height,flick.height)
					width: wrapperWidth
					property real safePadding: wallpaperContainer.cellHeight * 0.15
					height: wrapperHeight + (safePadding - 30)
					MouseArea {
							anchors.fill: parent
	
							onClicked: {
								
								Qt.callLater(() => flick.forceActiveFocus())
							}


						}

					// Rectangle {
					// 	anchors.fill: parent
					// 	color: "transparent" 
					// 	border.color: "green"       
					// 	border.width: 10
					// }
				
						
				Item {
					id: wallpaperContainer

					property real cellWidthFactor: 0.95
					property real spacingXFactor: 0.8
					// Derived value (important!)
    				property real effectiveCellStepX: cellWidth * cellWidthFactor + spacingX * spacingXFactor
					width: columns * effectiveCellStepX

					clip: false

					
					property real baseOffsetX: Math.max((flick.width - gridWidth()) / 2, 0)
					property real globalShiftX: 0
					property real baseBiasX: 40
				
					x: (flick.width - gridWidth()) / 2 + globalShiftX
					y: 0
					
					function updateGridFocusOffset() {
						var selVW = wallpaperController.currentSelected
									&& wallpaperController.currentSelected.visualWrapperRef
									? wallpaperController.currentSelected.visualWrapperRef
									: null

						var selIndex = wallpaperController.currentIndex
						var cols = wallpaperContainer.columns

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
						return (wallpaperContainer.width - gridWidth()) / 2;
					}

					function gridWidth() {
						var step = effectiveCellStepX;

						// worst-case width includes stagger
						var base = (columns - 1) * step + cellWidth;

						// add stagger allowance (critical fix)
						return base + step / 2;
					}


					function itemY(index) {
						var columns = wallpaperContainer.columns;
						var row = Math.floor(index / columns);

						var totalRows = Math.ceil(wallpaperRepeater.count / columns);

						var stepY = wallpaperContainer.cellHeight * 0.75;

						// include full visual footprint of last row (important fix)
						var totalHeight = (totalRows - 1) * stepY
										+ wallpaperContainer.cellHeight;

						// optional safety margin for visual overflow (recommended)
						var visualPadding = wallpaperContainer.cellHeight * 0.1;

						var viewportHeight= flick.height

						
						var verticalOffset =
							Math.max((viewportHeight - totalHeight) / 2 + visualPadding / 2, 0);

						return verticalOffset + row * stepY;
					}
			

					property int cellWidth: 190
					property int cellHeight: Math.round(cellWidth * Math.sqrt(3)/2 * 1.2) 
					property int spacingX: 10
					property int spacingY: 10
					property int columns: 5
					property int visibleRows: 4
					property real rowStep: wallpaperContainer.cellHeight * 0.75

					height: wallpaperContainer.cellHeight
							+ (visibleRows - 1) * rowStep
					
					
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
							width: wallpaperContainer.cellWidth - 10
							height: wallpaperContainer.cellHeight - 10

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
								strokeColor: Colors.primary
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
					
					Repeater {
						id: wallpaperRepeater
						model: filteredWallpapers
						onItemAdded: function(item, i) {
							if (i === wallpaperRepeater.count - 1) {
								wallpaperController.requestFrame()
							}
						}

						Item {
							id: hexItem
							z: isSelected ? 999 : 1
							property bool isSelected: wallpaperController.currentIndex === index
						
						
							
							width: wallpaperContainer.cellWidth - 10
							height: wallpaperContainer.cellHeight - 10
							property bool imageReady: thumbImage.status === Image.Ready && thumbImage.paintedWidth > 0
							 
							property bool isHidden: false
					
							
					
							property real baseX: wallpaperContainer.itemX(index)
							property real baseY: wallpaperContainer.itemY(index)

							
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

								var cols = wallpaperContainer.columns
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
								shiftX = computeShiftX()
								shiftY = computeShiftY()
							}
							
							Connections {
								target: wallpaperController.currentSelected
										? wallpaperController.currentSelected.visualWrapperRef
										: null

								function onVisualScaleChanged() {
									wallpaperContainer.updateGridFocusOffset()
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

								var cols = wallpaperContainer.columns
								var selRow = Math.floor(selIndex / cols)
								var row = Math.floor(index / cols)

								if (row < selRow) return -10
								if (row > selRow) return 10
								return 0
							}

							x: targetX
						
    						y: targetY
							
							Behavior on x {
								enabled: flick.firstUpdateDone
								NumberAnimation {
									duration: 400
									easing.type: Easing.BezierSpline
									easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
								}
							}

							Behavior on y {
								enabled: flick.firstUpdateDone
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
							// 	var cols = wallpaperContainer.columns
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
								var totalCols = wallpaperContainer.columns
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
								var totalCols = wallpaperContainer.columns
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
								var totalColumns = wallpaperContainer.columns
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
								var cols = wallpaperContainer.columns

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
								if (gen === 0) return 1.15

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
								property real visualScale: 0.25
							
								scale: visualScale	
								// Component.onCompleted: {
								// 	Qt.callLater(() => {
								// 		visualWrapper.visualScale = 1
								// 	})
									
								// }

    							opacity: fadeOpacity
								
								Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
								Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
								
								// onXChanged: {}
								
								Behavior on scale {
									enabled: flick.firstUpdateDone
									SpringAnimation {
											spring: 6
											damping: 0.9 
										}
								}

								Behavior on opacity { 
									enabled: flick.firstUpdateDone
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
									visible: wallpaperController.cardVisible && !fadeInAnim.running
									color: "#000000"
									
									opacity: wallpaperController.currentIndex === index
									? 0.6: 0
									// : ((!selVW || selVW.visualScale < 1) ? 0 : Math.min(0.6, gen * 0.12))
									Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
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
											PathMove { x: width * 0.5; y: 0 }
											PathLine { x: width; y: height * 0.25 }
											PathLine { x: width; y: height * 0.75 }
											PathLine { x: width * 0.5; y: height }
											PathLine { x: 0; y: height * 0.75 }
											PathLine { x: 0; y: height * 0.25 }
											PathLine { x: width * 0.5; y: 0 }
										}
									}
								}
							}
							
						
							MouseArea {
								anchors.fill: parent
								enabled: visualWrapperRef.visualScale > 0 
								&& visualWrapperRef.fadeOpacity > 0
								
								onClicked: {
									wallpaperController.currentIndex = index
									Qt.callLater(() => flick.forceActiveFocus())
								}

								onDoubleClicked: actions.applyWallpaper(modelData)
							}
						}
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
	RowLayout {
			id: textContainer
			Layout.fillWidth: true
			Layout.alignment: Qt.AlignHCenter
			visible: wallpaperController.cardVisible
			
			z: 9999
			

			// visible: wallpaperController.cardVisible
			// && wallpaperRepeater.count > 0
			// && wallpaperRepeater.itemAt(wallpaperController.currentIndex).imageReady
			// Rectangle {
			// 	anchors.fill: parent
				
			// 	color: "transparent" 
			// 	border.color: "red"       
			// 	border.width: 1
			// }
			Item { Layout.fillWidth: true }
			Item {
				id: skewField
				Layout.alignment: Qt.AlignHCenter
				layer.enabled: true
				layer.smooth: true
				
				
				width: 260
				height: 36

				Shape {
					anchors.fill: parent
					preferredRendererType: Shape.CurveRenderer
					antialiasing: true
					ShapePath {
						fillColor: Colors.background
                		strokeColor: "transparent"
						strokeWidth: 1

						startX: 10; startY: 0
						PathLine { x: 260; y: 0 }
						PathLine { x: 250; y: 36 }
						PathLine { x: 0;   y: 36 }
						PathLine { x: 10;  y: 0 }
					}
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
							if (!text || text.length === 0) {
								filteredWallpapers = wallpapers
							} else {
								let query = text.toLowerCase()
								filteredWallpapers = wallpapers.filter(w => w.toLowerCase().indexOf(query) !== -1)
							}

							wallpaperController.currentIndex = 0

							if (filteredWallpapers.length > 0)
								selectedWallpaper = filteredWallpapers[0]

							wallpaperController.requestFrame()
						}
					}
				}
			}

			Item { Layout.fillWidth: true }

			// Button {
			// 	id: rescanBtn
			// 	text: "Rescan"
			// 	onClicked: {
			// 		startListing()
			// 		initTimer.start()
			// 	}
			// 	background: Rectangle {
			// 		radius: 8
			// 		color: rescanBtn.down ? Qt.darker(colorSurfaceContainer, 1.3) : (rescanBtn.hovered ? Qt.lighter(colorSurfaceContainer, 1.2) : colorSurfaceContainer)
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
			// 		color: randomBtn.down ? Qt.darker(colorSurfaceContainer, 1.3) : (randomBtn.hovered ? Qt.lighter(colorSurfaceContainer, 1.2) : colorSurfaceContainer)
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
			// 		color: settingsBtn.down ? Qt.darker(colorSurfaceContainer, 1.3) : (settingsBtn.hovered ? Qt.lighter(colorSurfaceContainer, 1.2) : colorSurfaceContainer)
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
  }
}
}