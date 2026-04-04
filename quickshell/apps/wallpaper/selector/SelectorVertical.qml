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

	Component.onCompleted: {
		cardShowTimer.start()
	}

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

		function startListing() {
			if (!wallpaperDir) {
				lastError = "Wallpaper directory not set"
				return
			}
			// Use ls for faster listing (faster than find for single directory)
			listProcess.exec(["sh", "-c", "ls -U '" + wallpaperDir + "' 2>/dev/null | grep -iE '\\.(jpg|jpeg|png|webp|bmp)$' | sort"])
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

			// Step 0: apply wallpaper immediately for preview
			// let awwwArgs = [
			// 	"img", `"${wallpaperSelector.currentFullPath}"`,
			// 	"--transition-type", "wave",
			// 	"--transition-fps", "60",
			// 	"--transition-duration", "0.5",
			// 	"--transition-wave", "25,15",
			// 	"--transition-angle", "45",
			// 	"--transition-bezier", ".4,0,.2,1"
			// ]
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


		function randomWallpaper() {
			if (filteredWallpapers.length === 0) return;

			let newIndex = flick.currentIndex;

			if (filteredWallpapers.length > 1) {
				do {
					newIndex = Math.floor(Math.random() * filteredWallpapers.length);
				} while (newIndex === flick.currentIndex);
			}

			flick.currentIndex = newIndex;

			applyWallpaper(filteredWallpapers[newIndex]);
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
					// Check dependencies first, then continue
					depsProcess.exec(["sh","-c","(command -v ffmpeg >/dev/null 2>&1 && echo FFOK); (command -v matugen >/dev/null 2>&1 && echo MTOK)"])
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


		QtObject {
			id: thumbs
			property var thumbData: {}
			property bool pendingUpdate: false

			function updateThumbs() {
				if (listThumbsProcess.running) {
					pendingUpdate = true
					return
				}
				pendingUpdate = false
				listThumbsProcess.exec(["sh", "-c", "ls -U '" + wallpaperSelector.thumbnailDir + "'"])
			}

			function onListThumbsExited() {
				let files = listThumbsCollector.text.trim().split("\n")
				let data = {}
				for (let i = 0; i < files.length; i++) {
					if (files[i].length > 0) data[files[i]] = true
				}
				thumbData = data

				// Check for missing thumbnails
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

				if (pendingUpdate) updateThumbs() // handle any missed calls
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

		// --- matugenProcess ---
		Io.Process {
			id: matugenProcess
			property string requestPath: ""
			property string requestName: ""
			command: []

			onStarted: {
				requestPath = wallpaperSelector.currentFullPath
				requestName = selectedWallpaper
				matugenKilled = false // reset flag on actual start
			}

			onExited: function(exitCode) {
				if (exitCode !== 0 && !matugenKilled) {
					// Only show error if we didn't kill it intentionally
					showNotification("Error", "matugen.sh failed", "dialog-error")
				}

				// Trigger switchwallProcess immediately
				if (switchwallProcess.running) {
					switchwallProcess.signal("SIGKILL")
				}

				switchwallProcess.requestPath = requestPath
				switchwallProcess.requestName = requestName
				switchwallProcess.command = [
					"bash",
					wallpaperSelector.switchwallPath,
					"--image",
					requestPath
				]
				switchwallProcess.running = true
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
		// Dependency check process
		Io.Process {
			id: depsProcess
			command: []
			stdout: Io.StdioCollector { id: depsCollector }
			onExited: function(exitCode, exitStatus) {
				let out = depsCollector.text
				hasFfmpeg = out.indexOf("FFOK") !== -1
				hasMatugen = out.indexOf("MTOK") !== -1
				if (!hasFfmpeg) {
					showNotification("Warning", "ffmpeg not found. Thumbnails will be loaded from full images and may be slower.", "dialog-warning")
				}
				if (!hasMatugen) {
					showNotification("Warning", "matugen not found. You can browse wallpapers but cannot apply them.", "dialog-warning")
				}
				// Ensure thumbnail directory exists (even without ffmpeg)
				mkdirThumbsProcess.exec(["sh","-c","mkdir -p '" + thumbnailDir + "'"])
			}
		}

	// Ensure thumbnail directory exists
	Io.Process {
		id: mkdirThumbsProcess
		command: []
		onExited: function(exitCode, exitStatus) {
			validateWallDirProcess.exec(["sh","-c","[ -d '" + wallpaperDir + "' ] || exit 1"])
		}
	}

	// Validate wallpaper directory before listing
	Io.Process {
		id: validateWallDirProcess
		command: []
		onExited: function(exitCode, exitStatus) {
			if (exitCode !== 0) {
				lastError = "Wallpaper directory not found: " + wallpaperDir
				showNotification("Error", lastError, "dialog-error")
			} else {
				startListing()
			}
		}
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
				wallpaperScroll.currentIndex = 0
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
			keyRoot.forceActiveFocus()
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

		WlrLayershell.namespace: "wallpaper-selector-parallel"
		WlrLayershell.layer: WlrLayer.Overlay
		// visible: wallpaperSelector.cardVisible
		WlrLayershell.keyboardFocus: wallpaperSelector.cardVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
		
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
	

 Item {
	id: cardContainer

	width: 1200
	height: 650
	anchors.centerIn: parent
	visible: wallpaperSelector.cardVisible
	
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
        Keys.enabled: true
		
		Keys.onPressed: function(event) {
			if (!filteredWallpapers || filteredWallpapers.length === 0) return;

			let nextIndex = wallpaperScroll.currentIndex;
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

			wallpaperScroll.currentIndex = nextIndex;
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
		anchors.margins: 16
		spacing: 12
		
		// Keys.onEscapePressed: Qt.quit()

		// Header
		RowLayout {
			Layout.fillWidth: true
			visible: false

			// TextField {
			// 		id: searchBox
			// 		placeholderText: "Filter Images..."
			// 		placeholderTextColor: colorsPalette.backgroundText70
			// 		Layout.fillWidth: true
			// 		font.pixelSize: 16
			// 		font.family: "JetBrainsMono Nerd Font"
			// 		color: colorsPalette.backgroundText70
		

			
			
			// 		cursorVisible: false
			// 		selectionColor: "transparent"



			// 		// text-field-animated-border
		
			// 		Component.onCompleted: {
			// 			searchBox.forceActiveFocus()
			// 		}

			// 		// Transparent background, so we can draw our own border/overlay

			// 		onTextChanged: {
			// 		if (!text || text.length === 0) {
			// 			filteredWallpapers = wallpapers
			// 		} else {
			// 			let query = text.toLowerCase()
			// 			filteredWallpapers = wallpapers.filter(w => w.toLowerCase().indexOf(query) !== -1)
			// 		}

			// 		// reset selection
			// 		wallpaperScroll.currentIndex = 0
			// 		if (filteredWallpapers.length > 0)
			// 			selectedWallpaper = filteredWallpapers[0]
			// 	}
			// }

			Item { Layout.fillWidth: true }

			Button {
				id: rescanBtn
				text: "Rescan"
				onClicked: startListing()
				background: Rectangle {
					radius: 8
					color: rescanBtn.down ? Qt.darker(colorSurfaceContainer, 1.3) : (rescanBtn.hovered ? Qt.lighter(colorSurfaceContainer, 1.2) : colorSurfaceContainer)
					border.color: colorOutline
					border.width: 1
				}
				contentItem: Text {
					text: rescanBtn.text
					color: colorOnSurface
					font.pixelSize: 14
					horizontalAlignment: Text.AlignHCenter
					verticalAlignment: Text.AlignVCenter
					elide: Text.ElideRight
				}
			}
			Button {
				id: randomBtn
				text: "Random"
				onClicked: randomWallpaper()
				background: Rectangle {
					radius: 8
					color: randomBtn.down ? Qt.darker(colorSurfaceContainer, 1.3) : (randomBtn.hovered ? Qt.lighter(colorSurfaceContainer, 1.2) : colorSurfaceContainer)
					border.color: colorOutline
					border.width: 1
				}
				contentItem: Text {
					text: randomBtn.text
					color: colorOnSurface
					font.pixelSize: 14
					horizontalAlignment: Text.AlignHCenter
					verticalAlignment: Text.AlignVCenter
					elide: Text.ElideRight
				}
			}
			Button {
				id: settingsBtn
				text: "Settings"
				onClicked: settingsOpen = true
				background: Rectangle {
					radius: 8
					color: settingsBtn.down ? Qt.darker(colorSurfaceContainer, 1.3) : (settingsBtn.hovered ? Qt.lighter(colorSurfaceContainer, 1.2) : colorSurfaceContainer)
					border.color: colorOutline
					border.width: 1
				}
				contentItem: Text {
					text: settingsBtn.text
					color: colorOnSurface
					font.pixelSize: 14
					horizontalAlignment: Text.AlignHCenter
					verticalAlignment: Text.AlignVCenter
					elide: Text.ElideRight
				}
			}
		}

		// Error message
		Rectangle {
			visible: lastError !== ""
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
		
		ScrollView {
			id: wallpaperScroll
			Layout.fillWidth: true
			Layout.fillHeight: true
			focus: true
			clip: false
			
			ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

			property int currentIndex: 0
			 // --- Method to scale items according to viewport ---
			// --- Method to scale items according to viewport ---
			function updateScales() {
				if (!wallpaperRepeater || wallpaperRepeater.count === 0) return

				var viewportTop = flick.contentY
				var viewportBottom = flick.contentY + cardContainer.height

				for (var i = 0; i < wallpaperRepeater.count; i++) {
					var item = wallpaperRepeater.itemAt(i)
					if (!item) continue

					var itemTop = item.y
					var itemBottom = item.y + wallpaperContainer.cellHeight

					// Top edge
					if (itemTop < viewportTop) {
						if (!item.touchedTop) {
							item.touchedTop = true
							item.scale = 0
						}
					} else if (item.touchedTop) {
						item.touchedTop = false
						item.scale = 1
					}

					// Bottom edge
					if (itemBottom > viewportBottom) {
						if (!item.touchedBottom) {
							item.touchedBottom = true
							item.scale = 0
						}
					} else if (item.touchedBottom) {
						item.touchedBottom = false
						item.scale = 1
					}
				}
			}

			Component.onCompleted: {
				// Start a small timer to wait until everything is ready
				initTimer.start()
			}

			Timer {
				id: initTimer
				interval: 50
				repeat: true
				running: false
				onTriggered: {
					// Ensure items exist and heights are valid
					if (wallpaperRepeater.count > 0 && flick.height > 0 && cardContainer.height > 0) {
						stop()           // stop the timer
						flick.contentY = 0   // snap top row fully visible
						wallpaperScroll.updateScales()  // update scale of items
					}
				}
			}

			Connections {
				target: flick
				function onContentYChanged() {
					wallpaperScroll.updateScales()
				}
			}
			Flickable {
				id: flick
				anchors.fill: parent
				// property real scalePadding: wallpaperContainer.cellHeight * 0.35
				contentWidth: wallpaperContainer.width
				contentHeight: wallpaperContainer.height
				
				// contentHeight: wallpaperContainer.height + scalePadding * 2

				interactive: true
				
				clip: true
				Behavior on contentY {
					NumberAnimation {
						duration: 210
						easing.type: Easing.InOutQuad
					}
				}
                MouseArea {
                        anchors.fill: parent
                        onWheel: (wheel) => {
                            flick.flick(0, wheel.angleDelta.y * 12)
                            wheel.accepted = true
                        }
				}
				Item {
					id: wallpaperContainer
					width: flick.width
					// y: flick.scalePadding
					// y: 0
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
						anchors.fill: parent
						// property Item currentItem: wallpaperRepeater.itemAt(wallpaperScroll.currentIndex)
						// visible: wallpaperSelector.cardVisible
						// && wallpaperRepeater.count > 0
						// && wallpaperRepeater.itemAt(wallpaperScroll.currentIndex).imageReady
						// visible: wallpaperSelector.cardVisible
						// && selectedHexBorder.currentItem.imageReady 
						z: 9999

						layer.smooth: true
						
						Shape {
							
							id: selectedHexBorder
							width: wallpaperContainer.cellWidth - 10
							height: wallpaperContainer.cellHeight - 10
							// visible: wallpaperSelector.cardVisible && wallpaperRepeater.count > 0
							visible: wallpaperSelector.cardVisible
													&& wallpaperRepeater.count > 0
													&& wallpaperRepeater.itemAt(wallpaperScroll.currentIndex).imageReady
							// property Item currentItem: wallpaperRepeater.itemAt(wallpaperScroll.currentIndex)
							// visible:  wallpaperSelector.cardVisible && currentItem
							

							property Item currentItem: wallpaperRepeater.count > 0 ? wallpaperRepeater.itemAt(wallpaperScroll.currentIndex) : null

							onCurrentItemChanged: {
								if (currentItem && currentItem.imageReady) {
									selectedHexBorder.visible = true
								}
							}
							x: currentItem ? currentItem.x : 0
							y: currentItem ? currentItem.y : 0
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

							Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
							Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
								
						}
						
						
					}
					
					Repeater {
						id: wallpaperRepeater
						model: filteredWallpapers

						Item {
							id: hexItem
							width: wallpaperContainer.cellWidth - 10
							height: wallpaperContainer.cellHeight - 10
							property bool imageReady: thumbImage.status === Image.Ready && thumbImage.paintedWidth > 0
							

							property int row: Math.floor(index / wallpaperContainer.columns)
							property int col: index % wallpaperContainer.columns

							x: col * (wallpaperContainer.cellWidth * 0.95 + wallpaperContainer.spacingX * 0.8)
							+ (row % 2 === 1 ? (wallpaperContainer.cellWidth * 0.95 + wallpaperContainer.spacingX * 0.8)/2 : 0)

							y: row * ((wallpaperContainer.cellHeight * 0.70) + wallpaperContainer.spacingY * 0.8) + 10


							property bool touchedTop: false
							property bool touchedBottom: false
							property bool hiddenRow: false
							Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
							Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
							Behavior on scale {
								NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
							}
							// // update touchedTop whenever flick view changes
							// onYChanged: {
							// 	if (y <= flick.contentY) {
							// 		touchedTop = true
							// 		width = wallpaperContainer.cellWidth - wallpaperContainer.cellWidth // basically 0
							// 		height = wallpaperContainer.cellHeight - wallpaperContainer.cellHeight
							// 	} else if (touchedTop) {
							// 		touchedTop = false
							// 		width = wallpaperContainer.cellWidth - 10
							// 		height = wallpaperContainer.cellHeight - 10
							// 	}
							// }
							Image {
								id: thumbImage
								fillMode: Image.PreserveAspectCrop
								width: parent.width
								height: parent.height
								anchors.centerIn: parent
								asynchronous: true

								property string thumbName: thumbnailPaths[modelData] || ""

								source: (thumbs.thumbData && thumbs.thumbData[thumbName])
										? ("file://" + wallpaperSelector.thumbnailDir + "/" + thumbName)
										: ""
							}
						
							
					
							Rectangle {
								visible: wallpaperSelector.cardVisible && !fadeInAnim.running
								anchors.fill: parent
								color: "#000000"
								opacity: wallpaperScroll.currentIndex === index ? 0.6 : 0
								Behavior on opacity {
									NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
								}
							}

							layer.enabled: true
							layer.smooth: true
							layer.effect: OpacityMask {
								maskSource: Shape {
									// anchors.fill: parent
									width: hexItem.width
									height: hexItem.height
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

							MouseArea {
								anchors.fill: parent
								onClicked: wallpaperScroll.currentIndex = index
								onDoubleClicked: applyWallpaper(modelData)
							}
						}
					}
				}
			}

    
		}

		
	}
	
}
	}
}
}