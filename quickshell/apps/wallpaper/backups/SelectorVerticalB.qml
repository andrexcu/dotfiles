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
// import QtGraphicalEffects 

// import QtQuick.Shapes
// import QtQuick.Window
// import QtQuick.Controls
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
  id: wallpaperSelector

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

			applyWallpaper(chosen);
		}
		
	}



	// Color scheme
	readonly property color colorBackground: "#151217"
	readonly property color colorSurface: "#221e24"
	readonly property color colorSurfaceContainer: "#2c292e"
	readonly property color colorOnSurface: "#e8e0e8"
	readonly property color colorPrimary: "#dcb9f8"
	readonly property color colorError: "#ffb4ab"
	readonly property color colorOutline: "#4a454d"

	// Configuration
	property var colorsPalette: Colors {}
	property string homeDir: ""
	property string wallpaperDir: ""
	property string thumbnailDir: ""
	property var wallpapers: []
	property var filteredWallpapers: wallpapers   // initially same as full list
	property string selectedWallpaper: ""
	property string lastError: ""
	property bool hasFfmpeg: false
	property bool hasMatugen: false
	property bool settingsOpen: false
	property bool selectorOpen: false

	property string currentFullPath: ""
	property string matugenPath: homeDir + "/Scripts/matugen.sh"
	property string switchwallPath: homeDir + "/.config/quickshell/scripts/colors/switchwall.sh"
	// property bool animating: false
	
	
	property bool showDelegateBorder: true
	property int currentIndex: 0
	

	// Cache for base names to avoid repeated calculations
	property var thumbnailPaths: ({})

	

	// Keep settings in sync
	onWallpaperDirChanged: {
		if (wallpaperDir && wallpaperDir !== wallpaperSelector.savedWallpaperDir) {
			wallpaperSelector.savedWallpaperDir = wallpaperDir
		}
	}

	onThumbnailDirChanged: {
		if (thumbnailDir && thumbnailDir !== wallpaperSelector.savedThumbnailDir) {
			wallpaperSelector.savedThumbnailDir = thumbnailDir
		}
	}

			function showNotification(title, message, icon) {
			console.log("[" + title + "] " + message)
		}

		// Flag to ignore errors if we intentionally killed matugen
		property bool matugenKilled: false

		// --- applyWallpaper function ---
		function applyWallpaper(wallpaperName) {
			selectedWallpaper = wallpaperName
			wallpaperSelector.currentFullPath = wallpaperDir + "/" + wallpaperName

			let awwwArgs = [
				"img", `"${wallpaperSelector.currentFullPath}"`,
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
					wallpaperSelector.matugenPath,
					wallpaperSelector.currentFullPath
				])
			})
		}


	

				
		property string savedWallpaperDir: ""
		property string savedThumbnailDir: ""
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
					let defaultThumb = homeDir + "/.cache/wallpaper-picker"
					// Load saved settings if present
					wallpaperDir = wallpaperSelector.savedWallpaperDir && wallpaperSelector.savedWallpaperDir.length > 0 ? wallpaperSelector.savedWallpaperDir : defaultWall
					thumbnailDir = wallpaperSelector.savedThumbnailDir && wallpaperSelector.savedThumbnailDir.length > 0 ? wallpaperSelector.savedThumbnailDir : defaultThumb

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
				wallpaperSelector.currentIndex = 0
				selectedWallpaper = wallpapers[0]
			}

			thumbs.updateThumbs()
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
						startListingFromModel()  // Your function to set wallpapers + thumbs
						Qt.callLater(() => {
							flick.contentY = 0         // snap top
							flick.updateScales()       // update scale
						})
						
					} else {
						lastError = "No wallpapers found in " + wallpaperDir
					}
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

					// You can also reference thumbModel here if you want
					console.log("Using thumbModel.count: " + thumbModel.count)

					// check missing thumbnails, etc.
				}
			}
	
		
		
		property string setupCmd: "mkdir -p '" + thumbnailDir + "' && find '" + wallpaperDir + "' -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \\) -print0 | xargs -0 -P 4 -I {} bash -c 'base=$(basename \"{}\"); name=\"${base%.*}\"; thumb=\"" + thumbnailDir + "/${name}.png\"; [ ! -f \"$thumb\" ] && ffmpeg -y -i \"{}\" -vf \"scale=200:208:force_original_aspect_ratio=increase,crop=200:208:(in_w-200)/2:(in_h-208)/2,format=rgb24\" -q:v 5 -frames:v 1 \"$thumb\" 2>/dev/null || true'"
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
				requestPath = wallpaperSelector.currentFullPath
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
					wallpaperSelector.switchwallPath,
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
				wallpaperSelector.currentIndex = 0
				selectedWallpaper = wallpapers[0]
			}

			// 🔥 ONLY trigger thumbnail scan (non-blocking)
			thumbs.updateThumbs()
		}
	}

	property bool cardVisible: false

	Timer {
		id: cardShowTimer
		interval: 50
		onTriggered: wallpaperSelector.cardVisible = true
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

		
		// component.onCompleted: {
		// 	function checkThumbnailExists(filename) {
		// 	return thumbnailPaths[filename] && thumbs.thumbData[thumbnailPaths[filename]]
		// 	}
		// }
		// Connections {
		// 	target: wallpaperSelector
			
		// 	// onThumbnailDirChanged: {
		// 	// 	console.log("Thumbnail dir updated: " + thumbnailDir)
		// 	// }
		// }
	
	// FolderListModel {
	// 	id: thumbModel
	// 	showDirs: false
	// 	showHidden: false
	// 	sortField: FolderListModel.Name
	// 	nameFilters: ["*.png"]

	// 	onStatusChanged: {
	// 		if (status === FolderListModel.Ready) {
	// 			console.log("Thumbnails loaded: " + count)
	// 			for (var i = 0; i < count; i++) {
	// 				console.log(get(i).fileName)
	// 			}
	// 		}
	// 	}
	// }


	// Component.onCompleted: {
		
	// 	if (thumbnailDir && thumbnailDir.length > 0) {
	// 		thumbModel.folder = thumbnailDir.startsWith("file://")
	// 			? thumbnailDir
	// 			: "file://" + thumbnailDir
	// 	}
		
	// 	cardShowTimer.start()
		
	// }

	property bool isContentVisible: wallpaperSelector.cardVisible && wallpaperRepeater.count > 0
	&& currentItem && currentItem.imageReady
	property Item currentItem: (wallpaperSelector.currentIndex >= 0 && wallpaperSelector.currentIndex < wallpaperRepeater.count)
    ? wallpaperRepeater.itemAt(wallpaperSelector.currentIndex)
    : null	

	property int previousIndex: -1

	// Computed property for convenience
	property Item previousItem: (wallpaperSelector.previousIndex >= 0 && wallpaperSelector.previousIndex < wallpaperRepeater.count)
		? wallpaperRepeater.itemAt(wallpaperSelector.previousIndex)
		: null
	// property Item currentItem: (wallpaperSelector.currentIndex >= 0 && wallpaperSelector.currentIndex < wallpaperRepeater.count)
	// ? wallpaperRepeater.itemAt(wallpaperSelector.currentIndex)
	// : null
	
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
			active: wallpaperSelector.cardVisible
		}
		WlrLayershell.namespace: "wallpaper-selector-parallel"
		WlrLayershell.layer: WlrLayer.Overlay
		// visible: wallpaperSelector.cardVisible
		
		WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
		
		exclusionMode: ExclusionMode.Ignore

		Shortcut {
			sequence: "Escape"
			onActivated: {
				wallpaperSelector.cardVisible = false
				Qt.quit()
			}
		}
		DimOverlay {
			active: wallpaperSelector.cardVisible
			// active: false
		}


		MouseArea {
		anchors.fill: parent
		onClicked: {
				wallpaperSelector.cardVisible = false
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
	
	width: 1400
	height: 740
	Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
	// height: 800
	// anchors.centerIn: parent
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
	visible: wallpaperSelector.isContentVisible
	// visible: wallpaperSelector.cardVisible
	
 	opacity: 0
	
    property bool animateIn: wallpaperSelector.cardVisible

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
		
		Keys.onPressed: function(event) {
			if (!filteredWallpapers || filteredWallpapers.length === 0) return;

			let nextIndex = wallpaperSelector.currentIndex;
			const cols = wallpaperContainer.columns;
			const maxIndex = filteredWallpapers.length - 1;

			let row = Math.floor(nextIndex / cols);
			let col = nextIndex % cols;

			switch(event.key) {
				case Qt.Key_Right: if(col < cols-1 && nextIndex < maxIndex) nextIndex++; break;
				case Qt.Key_Left: if(col > 0) nextIndex--; break;
				case Qt.Key_Down: if((row+1)*cols + col <= maxIndex) nextIndex += cols; break;
				case Qt.Key_Up: if(row > 0) nextIndex -= cols; break;
				case Qt.Key_Return:
				case Qt.Key_Enter:
					applyWallpaper(filteredWallpapers[nextIndex]);
					event.accepted = true;
					return;
				default: return;
			}

			wallpaperSelector.currentIndex = nextIndex;
			const item = wallpaperRepeater.itemAt(nextIndex);
			if (item) {
				const strokeMargin = 4; // half of border stroke width, tweak if needed

				const top = item.y - strokeMargin;
				const bottom = item.y + item.height + strokeMargin;

				if (top < flick.contentY) {
					flick.contentY = top;
				} else if (bottom > flick.contentY + flick.height) {
					flick.contentY = bottom - flick.height;
				}

				// Move border exactly over item
				selectedHexBorder.x = item.x;
				selectedHexBorder.y = item.y;
			}

			if (event.key === Qt.Key_Escape) {
				wallpaperSelector.cardVisible = false
				event.accepted = true
				Qt.quit()
			}

			event.accepted = true;
		}
	


	ColumnLayout {
		anchors.fill: parent
		anchors.topMargin: 16
		anchors.bottomMargin: 48
		anchors.leftMargin: 16
		anchors.rightMargin: 16
		anchors.margins: 16
		spacing: 48
		clip: false
		// Keys.onEscapePressed: Qt.quit()

		// Header
		
		
		// Error message
		Rectangle {
			visible: isContentVisible && lastError !== ""
			color: colorError
			radius: 4
			height: 40
			Layout.fillWidth: true

			Text {
				text: lastError
				color: colorOnSurface
				font.pixelSize: 12
				anchors.centerIn: parent
			}
		}

		// Wallpaper grid - Optimized GridLayout with efficient rendering
		// RowLayout {
		// Layout.fillWidth: true
	
		// Layout.alignment: Qt.AlignHCenter
		// Item { Layout.fillWidth: true }
	

			
		Flickable {
			id: flick
			property int verticalMargin: 20
			height: cardContainer.height - 170// account for error message and spacing
			y: flick.verticalMargin
			contentWidth: Math.max(wallpaperContainer.width, width)
			// contentHeight: Math.max(wallpaperContainer.height + verticalMargin, height)
			// contentHeight: Math.max(wallpaperContainer.height, height)
			contentHeight: {
				if (wallpaperRepeater.count === 0) return height;
				const lastItem = wallpaperRepeater.itemAt(wallpaperRepeater.count - 1);
				return lastItem.y + lastItem.height;
			}
			
			boundsBehavior: Flickable.StopAtBounds
			Layout.fillHeight: false
			Layout.fillWidth: true
			Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
			// anchors.horizontalCenter: parent.horizontalCenter
			focus: true
	
			
			interactive: true
			
			clip: false

			
			// property int currentIndex: 0
			 // --- Method to scale items according to viewport ---
			property bool firstUpdateDone: false
			function updateScales() {
				if (!wallpaperRepeater || wallpaperRepeater.count === 0) return

				var viewportTop = flick.contentY
				var viewportBottom = flick.contentY + (cardContainer.height - flick.y - flick.verticalMargin)

				for (var i = 0; i < wallpaperRepeater.count; i++) {
					var item = wallpaperRepeater.itemAt(i)
					if (!item) continue

					var itemTop = item.y
					var itemBottom = item.y + wallpaperContainer.cellHeight

					// Fully visible
					if (itemTop >= viewportTop && itemBottom <= viewportBottom) {
						item.visualWrapperRef.visualScale = 1
						item.visualWrapperRef.fadeOpacity = 1
						item.visualWrapperRef.flipAngle = 0
					}
					// Leaving top (scrolling down)
					else if (itemBottom < viewportTop) {
						item.visualWrapperRef.visualScale = 0.6
						item.visualWrapperRef.fadeOpacity = 0
						item.visualWrapperRef.flipAngle = -90
					}
					// Leaving bottom (scrolling up)
					else if (itemTop > viewportBottom) {
						item.visualWrapperRef.visualScale = 0.6
						item.visualWrapperRef.fadeOpacity = 0
						item.visualWrapperRef.flipAngle = 90
					}
					// Entering from top (scrolling up)
					else if (itemTop < viewportTop && itemBottom > viewportTop) {
						item.visualWrapperRef.visualScale = 0
						item.visualWrapperRef.fadeOpacity = 0
						item.visualWrapperRef.flipAngle = -90
					}
					// Entering from bottom (scrolling down)
					else if (itemBottom > viewportBottom && itemTop < viewportBottom) {
						item.visualWrapperRef.visualScale = 0
						item.visualWrapperRef.fadeOpacity = 0
						item.visualWrapperRef.flipAngle = 90
					}
				}

				firstUpdateDone = true
			}
			// Component.onCompleted: {
			// 	// Start a small timer to wait until everything is ready
			// 	if(isContentVisible) {
			// 		flick.updateScales()
			// 	}
				
				
			// }
			// Connections {
			// 	target: flick
			// 	function
			// }
			// Timer {
			// 	id: initTimer
			// 	interval: 50
			// 	repeat: true
			// 	running: false
			// 	onTriggered: {
			// 		// Ensure items exist and heights are valid
					
			// 			       // stop the timer
			// 			   // snap top row fully visible
			// 			flick.updateScales()  // update scale of items
					
			// 	}
			// }

			Connections {
				target: flick
				function onContentYChanged() {
					flick.updateScales()
					flick.forceActiveFocus()
					
				}
			}
			onActiveFocusChanged: {
				if (!activeFocus) {
					flick.forceActiveFocus()
					
				}
			}
				onContentYChanged: {
					
        			updateScales()
					flick.forceActiveFocus()
				}
				Behavior on contentY {
					NumberAnimation {
						duration: 210
						easing.type: Easing.InOutQuad
					}
				}
				MouseArea {
					anchors.fill: parent
					focus: false
					onWheel: (wheel) => {
						flick.flick(0, wheel.angleDelta.y * 12) // vertical
						wheel.accepted = true
					}
				}
                // MouseArea {
                //         anchors.fill: parent
				// 		focus: false
                //         onWheel: (wheel) => {
                //             flick.flick(0, wheel.angleDelta.y * 12)
                //             wheel.accepted = true
                //         }
				// }
				Item {
					id: wallpaperContainerWrapper
					property int wrapperWidth: Math.max(wallpaperContainer.width, flick.width)
					property int wrapperHeight: Math.max(wallpaperContainer.height,flick.height)
					width: wrapperWidth
					height: wrapperHeight
				// onWidthChanged: wallpaperContainer.x = (flick.width - wallpaperContainer.width)/2
				Item {
					id: wallpaperContainer
					width: columns * (cellWidth * 0.95 + spacingX * 0.8)
					anchors.horizontalCenter: parent.horizontalCenter
					// anchors.verticalCenter: parent.verticalCenter
					clip: false
					x: (flick.contentWidth - width) / 2 
					// y: Math.max((flick.height - height)/2, 0)
					//  property real verticalOffset: 0

    				// property real verticalPadding: Math.max((flick.height - height) / 2, 0)
            		// y: verticalPadding
					y: 0   // top padding inside the Flickable
        

					property int cellWidth: 200
					property int cellHeight: Math.round(cellWidth * Math.sqrt(3)/2 * 1.2) 
					property int spacingX: 10
					property int spacingY: 10
					property int columns: 5
					// property int columns: Math.max(1, Math.floor(width / (cellWidth * 0.75)))
					height: {
						const count = filteredWallpapers ? filteredWallpapers.length : 0;
						const rows = Math.ceil(count / columns);
						return rows * (cellHeight + spacingY)
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
							width: wallpaperContainer.cellWidth - 10
							height: wallpaperContainer.cellHeight - 10
							
							
							
							Connections {
								target: wallpaperSelector
								function onCurrentIndexChanged() {
									var selectedItem = wallpaperRepeater.itemAt(wallpaperSelector.currentIndex)
									var previousItem = (wallpaperSelector.previousIndex >= 0 && wallpaperSelector.previousIndex < wallpaperRepeater.count)
														? wallpaperRepeater.itemAt(wallpaperSelector.previousIndex)
														: null

									if (!selectedItem) return

									// Animate previous item back to normal scale & flip
									if (previousItem && previousItem !== selectedItem) {
										Qt.callLater(() => {
											previousItem.visualWrapperRef.visualScale = 1
											previousItem.visualWrapperRef.flipAngle = previousItem.visualWrapperRef.flipAngle === 180 ? 0 : 180
										})
									}

									// Set selected item scale to 1 immediately
									selectedItem.visualWrapperRef.visualScale = 1
									selectedItem.visualWrapperRef.fadeOpacity = 1

									// Animate current item's flip
									selectedItem.visualWrapperRef.flipAngle = selectedItem.visualWrapperRef.flipAngle === 180 ? 0 : 180

									// Save current as previous
									wallpaperSelector.previousIndex = wallpaperSelector.currentIndex
									selectedHexBorder.currentSelected = selectedItem

									// Start timer to scale up after 1 second
									scaleDelayTimer.start()
								}
							}
							Timer {
								id: scaleDelayTimer
								interval: 450  
								repeat: false
								onTriggered: {
									if (selectedHexBorder.currentSelected) {
										selectedHexBorder.currentSelected.visualWrapperRef.visualScale = 1.15
									}
								}
							}
							// Track currently selected item
							property Item currentSelected: null

							// Bind scale to the selected item's visualScale
							scale: selectedHexBorder.currentSelected ? currentSelected.visualWrapperRef.visualScale : 1
							// Behavior on opacity {
							// 	NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
							// }
							opacity: 1
							// Always react to current item fadeOpacity
							// property real borderOpacity: wallpaperSelector.currentItem
							// 							? wallpaperSelector.currentItem.visualWrapperRef.fadeOpacity
							// 							: 0
							// opacity: borderOpacity
													
						
							// opacity: (wallpaperSelector.currentItem &&
							// wallpaperSelector.currentItem.y + wallpaperSelector.currentItem.height > flick.contentY &&
							// wallpaperSelector.currentItem.y < flick.contentY + flick.height) ? 1 : 0
							// Connections {
							// 	target: wallpaperSelector

							// 	function onCurrentIndexChanged() {
							// 		Qt.callLater(() => {
							// 			var item = wallpaperRepeater.itemAt(wallpaperSelector.currentIndex)
							// 			if (!item) return

							// 			flick.cancelFlick()
							// 			flick.ensureItemVisible(item)

							// 			selectedHexBorder.opacity = (item.y + item.height > flick.contentY &&
							// 			item.y < flick.contentY + flick.height) ? 1 : 0
							// 			selectedHexBorder.x = item.x
							// 			selectedHexBorder.y = item.y
										
							// 		})
							// 	}
							// }
						
							
							x: wallpaperSelector.currentItem ? wallpaperSelector.currentItem.x : 0
							y: wallpaperSelector.currentItem ? wallpaperSelector.currentItem.y : 0
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
										spring: 3
										damping: 0.25
									}
								}

								Behavior on y {
									SpringAnimation {
										id: springY
										spring: 3
										damping: 0.25
									}
								}
								Behavior on scale {
									enabled: flick.firstUpdateDone
									SpringAnimation {
											spring: 6
											damping: 0.9   // important!
										}
								}
								//  Behavior on scale {
								// 	NumberAnimation { duration: 600; easing.type: Easing.InOutQuad }
								// }

						}
						
						
					}
					
					Repeater {
						id: wallpaperRepeater
						model: filteredWallpapers
						onItemAdded: function(item, i) {  // <-- i is the index of the added item
							if (i === wallpaperRepeater.count - 1) {
								Qt.callLater(() => {
									flick.contentY = 0
									flick.updateScales()
								})
							}
						}
						Item {
							id: hexItem
							z: isSelected ? 999 : 1
							property bool isSelected: wallpaperSelector.currentIndex === index
							// property bool isSelected: wallpaperSelector.currentIndex === index
							// opacity: isSelected ? 1 : Math.max(0, Math.pow(visualScale, 0.1))
							// property real visualScale: 1
							width: wallpaperContainer.cellWidth - 10
							height: wallpaperContainer.cellHeight - 10
							property bool imageReady: thumbImage.status === Image.Ready && thumbImage.paintedWidth > 0

							// Behavior on opacity {
							// 	NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
							// }
							 
							property bool isHidden: false
					
							property int row: Math.floor(index / wallpaperContainer.columns)
							property int col: index % wallpaperContainer.columns

							x: col * (wallpaperContainer.cellWidth * 0.95 + wallpaperContainer.spacingX * 0.8)
							+ (row % 2 === 1 ? (wallpaperContainer.cellWidth * 0.95 + wallpaperContainer.spacingX * 0.8)/2 : 0)

							y: row * ((wallpaperContainer.cellHeight * 0.70) + wallpaperContainer.spacingY * 0.8) + 10


							property bool touchedTop: false
							property bool touchedBottom: false
							property bool hiddenRow: false
							property alias visualWrapperRef: visualWrapper
						
				
							 Item {
								id: visualWrapper
								width: parent.width
        						height: parent.height
								
								
								property real fadeOpacity: 1
								property real visualScale: 1
    							opacity: fadeOpacity
								scale: visualScale
								Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
								Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

								Behavior on scale {
									enabled: flick.firstUpdateDone
									SpringAnimation {
											spring: 6
											damping: 0.9   // important!
										}
								}
								Behavior on opacity { 
									enabled: flick.firstUpdateDone && !hexItem.isSelected
									NumberAnimation { 
										duration: 300; easing.type: Easing.InOutQuad 
								} }
									

								transform: Rotation {
									id: yRotation
									origin.x: visualWrapper.width / 2
									origin.y: visualWrapper.height / 2
									axis { x: 0; y: 1; z: 0 }
									angle: visualWrapper.flipAngle
								}
								NumberAnimation on flipAngle {
									id: flipAnim
									duration: 300
									easing.type: Easing.InOutQuad
								}
								Behavior on flipAngle {
									enabled: flick.firstUpdateDone && !hexItem.isSelected
									NumberAnimation {
										duration: 300
										easing.type: Easing.InOutQuad
									}
								}
								 property bool isSelected: false
								property real flipAngle: 0
								Image {
									id: thumbImage
									fillMode: Image.PreserveAspectCrop
									anchors.fill: parent
									anchors.centerIn: parent
									asynchronous: true
									property string thumbName: thumbnailPaths[modelData] || ""
									source: (thumbs.thumbData && thumbs.thumbData[thumbName])
											? ("file://" + wallpaperSelector.thumbnailDir + "/" + thumbName)
											: ""
								}

								Rectangle {
									anchors.fill: parent
									visible: wallpaperSelector.cardVisible && !fadeInAnim.running
									color: "#000000"
									opacity: wallpaperSelector.currentIndex === index ? 0.6 : 0
									Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
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
							
							// MouseArea {
							// 	anchors.fill: parent
							// 	onClicked: updateHighlight(index)
							// 	onDoubleClicked: applyWallpaper(modelData)
							// }
							MouseArea {
								anchors.fill: parent
								enabled: visualWrapperRef.visualScale > 0.25
								onClicked: {
									onClicked: wallpaperSelector.currentIndex = index
								}

								onDoubleClicked: applyWallpaper(modelData)
							}
							// MouseArea {
							// 	anchors.fill: parent
							// 	onClicked: wallpaperSelector.currentIndex = index
								
							// 	onDoubleClicked: applyWallpaper(modelData)
							// }
						}
					}
				}
				}
			}

    	
		
		
		}
		
	}
	
		
	}
	RowLayout {
			Layout.fillWidth: true
			Layout.alignment: Qt.AlignHCenter
			visible: wallpaperSelector.isContentVisible
			// z: 9999
			// visible: wallpaperSelector.cardVisible
			// && wallpaperRepeater.count > 0
			// && wallpaperRepeater.itemAt(wallpaperSelector.currentIndex).imageReady
			// Rectangle {
			// 	anchors.fill: parent
			// 	color: "transparent" 
			// 	border.color: "red"       
			// 	border.width: 1
			// }
			Item { Layout.fillWidth: true }
			TextField {
					id: searchBox
					placeholderText: "Filter Images..."
					placeholderTextColor: colorsPalette.backgroundText70
					Layout.fillWidth: false
					Layout.alignment: Qt.AlignHCenter
					font.pixelSize: 16
					font.family: "JetBrainsMono Nerd Font"
					color: colorsPalette.backgroundText70
					focus: true
		


			
					cursorVisible: false
					selectionColor: "transparent"



					// text-field-animated-border
		
					// Component.onCompleted: {
					// 	searchBox.forceActiveFocus()
					// }

					// Transparent background, so we can draw our own border/overlay
					onTextChanged: {
					if (!text || text.length === 0) {
						filteredWallpapers = wallpapers
					} else {
						let query = text.toLowerCase()
						filteredWallpapers = wallpapers.filter(w => w.toLowerCase().indexOf(query) !== -1)
					}

					// reset selection
					wallpaperSelector.currentIndex = 0
					if (filteredWallpapers.length > 0)
						selectedWallpaper = filteredWallpapers[0]
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
			// 	onClicked: utils.randomWallpaperFisherYates(filteredWallpapers, filteredWallpapers[wallpaperSelector.currentIndex]);
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