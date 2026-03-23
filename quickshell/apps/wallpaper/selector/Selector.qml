import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
// import Qt.labs.settings as Labs
import QtQuick.Effects
import QtCore
import Quickshell
import Quickshell.Io as Io
import Quickshell.Hyprland
import QtQuick.Window
import Quickshell.Widgets
import qs.colors
import Qt.labs.platform
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
FloatingWindow {



	id: wallpaperWindow
	title: "WallpaperWindow"


  

	implicitWidth: 1280
	implicitHeight: 500
    // focus: true             // allow it to accept key events
    // Add shortcut to handle Escape key
	// color: "#ae151217"
	color: "#33000000"
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
	
	HyprlandFocusGrab {
		windows: [ wallpaperWindow ]
		active: wallpaperWindow.visible
	}
	// HyprlandFocusGrab {
    //     id: grab
    //     windows: [ window ]   
    //     active: wallpaperWindow.visible 
    // }

	Shortcut {
        sequence: "Escape"
        onActivated: {
			 Qt.quit()
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
	// property bool animating: false
	
	
	property bool showDelegateBorder: true
	property int currentIndex: 0
	

	// Cache for base names to avoid repeated calculations
	property var thumbnailPaths: ({})

	// Persistent settings for custom directories

	// Keep settings in sync
	onWallpaperDirChanged: {
		if (wallpaperDir && wallpaperDir !== keyRoot.savedWallpaperDir) {
			keyRoot.savedWallpaperDir = wallpaperDir
		}
	}

	onThumbnailDirChanged: {
		if (thumbnailDir && thumbnailDir !== keyRoot.savedThumbnailDir) {
			keyRoot.savedThumbnailDir = thumbnailDir
		}
	}
	// SequentialAnimation {
	// 		id: wsTransition
	// 		PropertyAnimation {
	// 			target: wsHighlight
	// 			property: "highlightOpacity"
	// 			to: 0.4
	// 			duration: 50
	// 			easing.type: Easing.OutQuad
	// 		}
	// 		ScriptAction {
	// 			script: bar.activeWsId = bar.targetWsId
	// 		}
	// 		ParallelAnimation {
	// 			PropertyAnimation {
	// 				target: wsHighlight
	// 				property: "highlightOpacity"
	// 				to: 1
	// 				duration: 300
	// 				easing.type: Easing.OutCubic
	// 			}
	// 			PropertyAnimation {
	// 				target: wsHighlight
	// 				property: "highlightScale"
	// 				from: 0.9
	// 				to: 1.0
	// 				duration: 300
	// 				easing.type: Easing.OutBack
	// 				easing.overshoot: 1.5
	// 			}
	// 		}
	// 	}
		function startListing() {
			if (!wallpaperDir) {
				lastError = "Wallpaper directory not set"
				return
			}
			// Use ls for faster listing (faster than find for single directory)
			listProcess.exec(["sh", "-c", "ls -1 '" + wallpaperDir + "' 2>/dev/null | grep -iE '\\.(jpg|jpeg|png|webp|bmp)$' | sort"])
		}

			function showNotification(title, message, icon) {
			console.log("[" + title + "] " + message)
		}


		// function applyWallpaper(wallpaperName) {
		// 	selectedWallpaper = wallpaperName
		// 	let fullPath = wallpaperDir + "/" + wallpaperName
		// 	let scriptPath = homeDir + "/Scripts/matugen.sh"
		// 	let applyWallpaperPath = homeDir + "/.config/quickshell/scripts/colors/switchwall.sh"
		// 	// --- Step 1: Run matugen.sh normally ---
		// 	// matugenProcess.exec(["bash", scriptPath, fullPath])
		// 	matugenProcess.exec([
		// 	"bash",
		// 	scriptPath,
		// 	fullPath,
		// 	"--source-color-index", "0"
		// 	])
		// 	// --- Step 2: Run awww for transition ---
		// 	let awwwArgs = [
		// 		"img",
		// 		`"${fullPath}"`,
		// 		"--transition-fps", "60",
		// 		"--transition-type", "any",
		// 		"--transition-duration", "1.4",
		// 		"--transition-bezier", "0,0,1,1"
		// 	]
		// 	awwwProcess.exec(["sh", "-c", ["awww"].concat(awwwArgs).join(" ")])

		// 	// --- Step 3: Trigger QuickShell notification when awww finishes ---
		// 	awwwProcess.onExited.connect(function() {
		// 	notifyProcess.command = ["notify-send", "Wallpaper Applied", wallpaperName]
		// 	notifyProcess.running = true
		// 	})

		// 	// --- Step 4: Hide the wallpaper picker window ---
		// 	wallpaperWindow.visible = false
		// }
		

		// function applyWallpaper(wallpaperName) {
		// 	selectedWallpaper = wallpaperName
		// 	let fullPath = wallpaperDir + "/" + wallpaperName
		// 	let matugenPath = homeDir + "/Scripts/matugen.sh"
		// 	let switchwallPath = homeDir + "/.config/quickshell/scripts/colors/switchwall.sh"

		// 	// Step 1: Run matugen
		// 	matugenProcess.exec(["bash", matugenPath, fullPath])

		// 	// Step 2: When matugen finishes, run switchwall
		// 	matugenProcess.onExited.connect(function(exitCode) {
		// 		if (exitCode !== 0) {
		// 			showNotification("Error", "matugen.sh failed", "dialog-error")
		// 			return
		// 		}

		// 		switchwallProcess.exec(["bash", switchwallPath, "--image", fullPath])
		// 	})

		// 	// Step 3: When switchwall finishes, run transition
		// 	switchwallProcess.onExited.connect(function(exitCode) {
		// 		if (exitCode !== 0) {
		// 			showNotification("Error", "switchwall.sh failed", "dialog-error")
		// 			return
		// 		}

		// 		let awwwArgs = [
		// 			"img",
		// 			`"${fullPath}"`,
		// 			"--transition-fps", "60",
		// 			"--transition-type", "any",
		// 			"--transition-duration", "1.4",
		// 			"--transition-bezier", "0,0,1,1"
		// 		]
		// 		awwwProcess.exec(["sh", "-c", ["awww"].concat(awwwArgs).join(" ")])
		// 	})

		// 	// Step 4: Notify when transition finishes
		// 	awwwProcess.onExited.connect(function() {
		// 		showNotification("Wallpaper Applied", wallpaperName + " applied", "dialog-information")
		// 		wallpaperWindow.visible = false
		// 		Qt.quit() 
		// 	})
			
		// }
		function applyWallpaper(wallpaperName) {
			selectedWallpaper = wallpaperName
			let fullPath = wallpaperDir + "/" + wallpaperName
			let matugenPath = homeDir + "/Scripts/matugen.sh"
			let switchwallPath = homeDir + "/.config/quickshell/scripts/colors/switchwall.sh"

			// --- Step 0: Start wallpaper transition immediately ---
			let awwwArgs = [
				"img",
				`"${fullPath}"`,
				"--transition-fps", "60",
				"--transition-type", "any",
				"--transition-duration", "1.4", // faster transition
				"--transition-bezier", "0,0,1,1"
			]
			awwwProcess.exec(["sh", "-c", ["awww"].concat(awwwArgs).join(" ")])

			// --- Step 1: Run matugen asynchronously ---
			matugenProcess.exec(["bash", matugenPath, fullPath])

			matugenProcess.onExited.connect(function(exitCode) {
				if (exitCode !== 0) {
					showNotification("Error", "matugen.sh failed", "dialog-error")
					return
				}

				// --- Step 2: Run switchwall asynchronously after matugen finishes ---
				switchwallProcess.exec(["bash", switchwallPath, "--image", fullPath,])
			})

			

			// --- Step 3: Notify and quit after wallpaper transition ---
			awwwProcess.onExited.connect(function() {
				showNotification("Wallpaper Applied", wallpaperName + " applied", "dialog-information")
				wallpaperWindow.visible = false
				
			})

			// --- Step 4: Optional: notify if switchwall fails ---
			switchwallProcess.onExited.connect(function(exitCode) {
				if (exitCode !== 0) {
					showNotification("Error", "switchwall.sh failed", "dialog-error")
				}
				Qt.quit()
			})
		}

		function randomWallpaper() {
			if (filteredWallpapers.length === 0) return;

			let newIndex = wallpaperGridView.currentIndex;

			if (filteredWallpapers.length > 1) {
				do {
					newIndex = Math.floor(Math.random() * filteredWallpapers.length);
				} while (newIndex === wallpaperGridView.currentIndex);
			}

			wallpaperGridView.currentIndex = newIndex;

			applyWallpaper(filteredWallpapers[newIndex]);
		}



    Item {
        id: keyRoot
        anchors.fill: parent
        focus: true
        Keys.enabled: true
		
        // Component.onCompleted: keyRoot.forceActiveFocus()
		// Settings {
		// 	id: appSettings
		// 	category: "WallpaperPicker"
		// 	property string savedWallpaperDir: ""
		// 	property string savedThumbnailDir: ""
			
		// }	
		property string savedWallpaperDir: ""
		property string savedThumbnailDir: ""
		Component.onCompleted: {
		// Focus
			// Get home directory first, then start listing
			homeProcess.exec(["sh", "-c", "echo $HOME"])
			keyRoot.forceActiveFocus()

		}
			// function updateHighlightAtIndex(index) {
			// 	wallpaperGridView.currentIndex = index
			// 	wallpaperGridView.positionViewAtIndex(index, GridView.Visible)

			// 	// wait until the item is created
			// 	Qt.callLater(function() {
			// 		let item = wallpaperGridView.itemAt(index)
			// 		if (!item) return

			// 		let pos = item.mapToItem(wallpaperScroll.contentItem, 0, 0)
			// 		wallpaperHighlightBorder.targetX = pos.x
			// 		wallpaperHighlightBorder.targetY = pos.y
			// 		wallpaperHighlightBorder.targetWidth = item.width
			// 		wallpaperHighlightBorder.targetHeight = item.height
			// 		wallpaperHighlightBorder.scale = 0.92
			// 		wallpaperHighlightBorder.scale = 1.0
			// 		wallpaperTransition.restart()

			// 		// optional
			// 		selectedWallpaper = filteredWallpapers[index]

			// 		wallpaperScroll.contentY = Math.min(
			// 			Math.max(pos.y - wallpaperScroll.height / 2 + item.height / 2, 0),
			// 			wallpaperScroll.contentHeight - wallpaperScroll.height
			// 		)
			// 	})
			// }

			Keys.onPressed: function(event) {
            if (wallpaperGridView.count === 0) return

            const cellW = wallpaperGridView.cellWidth
            const cellH = wallpaperGridView.cellHeight
            const cols = Math.floor(wallpaperGridView.width / cellW)
            const maxIndex = filteredWallpapers.length - 1

            let nextIndex = wallpaperGridView.currentIndex
            let row = Math.floor(nextIndex / cols)
            let col = nextIndex % cols

            switch(event.key) {
                case Qt.Key_Right:
                    if (col < cols - 1 && nextIndex < maxIndex) nextIndex++
                    break
                case Qt.Key_Left:
                    if (col > 0) nextIndex--
                    break
                case Qt.Key_Down:
                    if ((row + 1) * cols + col <= maxIndex) nextIndex += cols
                    break
                case Qt.Key_Up:
                    if (row > 0) nextIndex -= cols
                    break
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    applyWallpaper(filteredWallpapers[nextIndex])
                    event.accepted = true
                    return
                default:
                    return
            }

            wallpaperGridView.currentIndex = nextIndex
            wallpaperGridView.forceActiveFocus()
            event.accepted = true
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
				let defaultThumb = homeDir + "/.cache/wallpaper-picker"
				// Load saved settings if present
				wallpaperDir = keyRoot.savedWallpaperDir && keyRoot.savedWallpaperDir.length > 0 ? keyRoot.savedWallpaperDir : defaultWall
				thumbnailDir = keyRoot.savedThumbnailDir && keyRoot.savedThumbnailDir.length > 0 ? keyRoot.savedThumbnailDir : defaultThumb
				// Check dependencies first, then continue
				depsProcess.exec(["sh","-c","(command -v ffmpeg >/dev/null 2>&1 && echo FFOK); (command -v matugen >/dev/null 2>&1 && echo MTOK)"])
			} else {
				lastError = "Failed to get home directory"
				showNotification("Error", lastError, "dialog-error")
			}
		}
	}

	// Process for creating thumbnails (parallel generation)
	Io.Process {
		id: thumbnailProcess
		command: []
		onExited: function(exitCode, exitStatus) {
			if (exitCode === 0) {
				console.log("Thumbnails generated successfully")
			}
		}
	}

	// Process for executing matugen
		Io.Process {
			id: matugenProcess
			command: []
			onExited: function(exitCode, exitStatus) {
				if (exitCode === 0) {
					showNotification("Wallpaper Applied", "Wallpaper '" + selectedWallpaper + "' applied successfully", "dialog-information")
					wallpaperWindow.visible = false
					// Qt.quit()   // <-- quit only after the process actually finishes
				} else {
					lastError = "Failed to apply wallpaper"
					showNotification("Error", lastError, "dialog-error")
				}
			}
		}
		Io.Process {
			id: switchwallProcess
			command: []
			onExited: function(exitCode, exitStatus) {
				if (exitCode === 0) {
					showNotification("Wallpaper Applied", "Wallpaper '" + selectedWallpaper + "' applied successfully", "dialog-information")
					wallpaperWindow.visible = false
					// Qt.quit()   // <-- quit only after the process actually finishes
				} else {
					lastError = "Failed to apply wallpaper"
					showNotification("Error", lastError, "dialog-error")
				}
			}
		}


		// Process to run awww (detached, wallpaper applied immediately)
		Io.Process {
			id: awwwProcess
			command: []
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

	// Fisher–Yates shuffle helper
	function shuffleArray(arr) {
		for (let i = arr.length - 1; i > 0; i--) {
			const j = Math.floor(Math.random() * (i + 1));
			[arr[i], arr[j]] = [arr[j], arr[i]];
		}
		return arr;
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
			} else {
				// Parse and process files efficiently
				let output = listCollector.text.trim()
				if (output.length === 0) {
					lastError = "No wallpapers found in " + wallpaperDir
					showNotification("Error", lastError, "dialog-error")
					return
				}
				
				let files = output.split("\n").filter(f => f.length > 0)
				// Extract filenames and pre-calculate thumbnail paths
				let processed = []
				let paths = {}
				for (let i = 0; i < files.length; i++) {
					let filename = files[i].split("/").pop()
					if (filename.length > 0) {
						processed.push(filename)
						// Pre-calculate base name for thumbnail
						let parts = filename.split(".")
						let baseName = parts.length > 1 ? parts.slice(0, -1).join(".") : filename
						paths[filename] = baseName + ".png"
					}
				}
				
				// wallpapers = processed
				wallpapers = utils.shuffleArray(processed);
				thumbnailPaths = paths
				if (wallpapers.length > 0) {
					wallpaperGridView.currentIndex = 0
					selectedWallpaper = wallpapers[0]   // optional but recommended
				}
				
				if (wallpapers.length === 0) {
					// lastError = "No wallpapers found in " + wallpaperDir
					// showNotification("Error", lastError, "dialog-error")
				} else {
					// Generate missing thumbnails in parallel (using xargs -P for parallel processing)
					// ffmpeg
					let setupCmd = "mkdir -p '" + thumbnailDir + "' && find '" + wallpaperDir + "' -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \\) -print0 | xargs -0 -P 4 -I {} bash -c 'base=$(basename \"{}\"); name=\"${base%.*}\"; thumb=\"" + thumbnailDir + "/${name}.png\"; [ ! -f \"$thumb\" ] && ffmpeg -i \"{}\" -vf \"scale=250:140:force_original_aspect_ratio=decrease,pad=250:140:(ow-iw)/2:(oh-ih)/2\" -q:v 5 -frames:v 1 \"$thumb\" 2>/dev/null || true'"
					// // magick
					// let setupCmd = "mkdir -p '" + thumbnailDir + "' && find '" + wallpaperDir + "' -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \\) -print0 | xargs -0 -P 4 -I {} bash -c 'base=$(basename \"{}\"); name=\"${base%.*}\"; thumb=\"" + thumbnailDir + "/${name}.png\"; [ ! -f \"$thumb\" ] && /usr/bin/magick \"{}\" -resize 250x140^ -gravity center -extent 250x140 \"$thumb\" || true'"
					thumbnailProcess.exec(["sh", "-c", setupCmd])
				}
			}
		}
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

		TextField {
				id: searchBox
				placeholderText: "Filter Images..."
				placeholderTextColor: colorsPalette.backgroundText70
				Layout.fillWidth: true
				font.pixelSize: 16
				font.family: "JetBrainsMono Nerd Font"
				color: colorsPalette.backgroundText70
	
				
				// background: Rectangle {
				// 	color: "transparent"
				// 	radius: 10
				// 	clip: true
				// 	Rectangle {
				// 		id: searchHighlightBorder
				// 		anchors.fill: parent
				// 		color: "transparent"
				// 		// border.color: colorsPalette.primary
				// 		radius: 10
				// 		opacity: searchHighlightBorder.progress
				// 		// opacity: 1  // initial opacity

				// 		property real progress: 0

			
				// 		Rectangle {
				// 			anchors.right: parent.right
				// 			anchors.top: parent.top
				// 			height: 2
				// 			radius: 10
				// 			width: parent.width * searchHighlightBorder.progress
				// 			// color: colorsPalette.primary
				// 			border.color: colorsPalette.primary
				// 		}

				
				// 		Rectangle {
				// 			anchors.right: parent.right
				// 			anchors.top: parent.top
				// 			width: 2
				// 			radius: 10
				// 			height: parent.height * searchHighlightBorder.progress
				// 			// color: colorsPalette.primary
				// 			border.color: colorsPalette.primary
				// 		}

						
				// 		Rectangle {
				// 			anchors.left: parent.left
				// 			anchors.bottom: parent.bottom
				// 			height: 2
				// 			radius: 10
				// 			width: parent.width * searchHighlightBorder.progress
				// 			// color: colorsPalette.primary
				// 			border.color: colorsPalette.primary
				// 		}

						
				// 		Rectangle {
				// 			anchors.left: parent.left
				// 			anchors.bottom: parent.bottom
				// 			width: 2
				// 			radius: 10
				// 			height: parent.height * searchHighlightBorder.progress
				// 			// color: colorsPalette.primary
				// 			border.color: colorsPalette.primary
				// 		}

				// 		// Animation: grow + pause + fade
				// 		SequentialAnimation {
				// 			id: searchBorderAnim
				// 			PropertyAnimation { target: searchHighlightBorder; property: "progress"; from: 0; to: 1; duration: 600; easing.type: Easing.OutQuad }
				// 			PauseAnimation { duration: 400 } // pause at full size
				// 			PropertyAnimation { target: searchHighlightBorder; property: "opacity"; from: 1; to: 0; duration: 400 }
				// 		}

				// 		function showTextHighlight() {
				// 			searchHighlightBorder.progress = 0
				// 			searchHighlightBorder.opacity = 1
				// 			searchBorderAnim.restart()
				// 		}
				// 	}
				// }

			
			// background: Rectangle {
			// 	color: "transparent"
			// 	radius: 10
			// 	clip: true

			// 	Canvas {
			// 		id: searchHighlightCanvas
			// 		anchors.fill: parent

			// 		property real progress: 0
			// 		property real borderWidth: 2

			// 		onProgressChanged: requestPaint()

			// 		onPaint: {
			// 			var ctx = getContext("2d")
			// 			ctx.reset()
			// 			ctx.clearRect(0, 0, width, height)

			// 			ctx.lineWidth = borderWidth
			// 			ctx.strokeStyle = "red"  // replace with colorsPalette.primaryLight
			// 			ctx.lineCap = "round"

			// 			var p = progress
			// 			var w = width
			// 			var h = height

			// 			// Draw top edge
			// 			ctx.beginPath()
			// 			ctx.moveTo(0, 0)
			// 			ctx.lineTo(w * p, 0)
			// 			ctx.stroke()

			// 			// Draw right edge
			// 			ctx.beginPath()
			// 			ctx.moveTo(w, 0)
			// 			ctx.lineTo(w, h * p)
			// 			ctx.stroke()

			// 			// Draw bottom edge
			// 			ctx.beginPath()
			// 			ctx.moveTo(w, h)
			// 			ctx.lineTo(w - w * p, h)
			// 			ctx.stroke()

			// 			// Draw left edge
			// 			ctx.beginPath()
			// 			ctx.moveTo(0, h)
			// 			ctx.lineTo(0, h - h * p)
			// 			ctx.stroke()
			// 		}

			// 		PropertyAnimation {
			// 			id: searchBorderAnim
			// 			target: searchHighlightCanvas
			// 			property: "progress"
			// 			from: 0
			// 			to: 1
			// 			duration: 600
			// 			easing.type: Easing.OutQuad
			// 		}

			// 		PropertyAnimation {
			// 			id: searchFadeOut
			// 			target: searchHighlightCanvas
			// 			property: "opacity"
			// 			from: 1
			// 			to: 0
			// 			duration: 400
			// 		}

			// 		function showTextHighlight() {
			// 			progress = 0
			// 			opacity = 1
			// 			searchBorderAnim.restart()
			// 			searchBorderAnim.onStopped = searchFadeOut.start
			// 		}
			// 	}
			// 		onActiveFocusChanged: {
			// 				if (activeFocus) searchHighlightBorder.showTextHighlight()
			// 				else {
			// 					searchHighlightBorder.progressTop = 0
			// 					searchHighlightBorder.progressBottom = 0
			// 				}
			// 			}
			// }
		
		
				cursorVisible: false
				selectionColor: "transparent"



				// text-field-animated-border
	
				Component.onCompleted: {
					searchBox.forceActiveFocus()
				}

				// Transparent background, so we can draw our own border/overlay

				onTextChanged: {
				if (!text || text.length === 0) {
					filteredWallpapers = wallpapers
				} else {
					let query = text.toLowerCase()
					filteredWallpapers = wallpapers.filter(w => w.toLowerCase().indexOf(query) !== -1)
				}

				// reset selection
				wallpaperGridView.currentIndex = 0
				if (filteredWallpapers.length > 0)
					selectedWallpaper = filteredWallpapers[0]
			}
		}

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
			// anchors.fill: parent
			Layout.fillWidth: true
			Layout.fillHeight: true
			// layout.fill: parent
			ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
			clip: false
			Item {
				id: wallpaperContainer
				anchors.fill: parent
				// property int columns: 5
    			// property var rowWidths: []
					Rectangle {
						id: wallpaperHighlight
						radius: 10
						
						color: "transparent"
						// anchors.top: wallpaperGridView.contentItem.top
    					// anchors.left: wallpaperGridView.contentItem.left
						parent: wallpaperGridView.contentItem
						property real targetX: 0
						property real targetY: 0
						property real targetWidth: wallpaperGridView.cellWidth
						property real targetHeight: wallpaperGridView.cellHeight
						property real animatedBorderWidth: 0
						property bool isNeighbor: false

						// x: targetX
						// y: targetY
						    x: wallpaperGridView.currentItem
							? wallpaperGridView.currentItem.x
							: 0
							y: wallpaperGridView.currentItem
							? wallpaperGridView.currentItem.y
							: 0
						// width: targetWidth
						// height: targetHeight
						    width: wallpaperGridView.currentItem
						? wallpaperGridView.currentItem.width
						: 0
							height: wallpaperGridView.currentItem
							? wallpaperGridView.currentItem.height
							: 0
						transformOrigin: Item.Center


						border.width: 2
	
						border.color: colorsPalette.primary
						


						Behavior on animatedBorderWidth {
							NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
						}
							// Call this whenever currentIndex changes
						function showHighlightBorder() {
							animatedBorderWidth = 2  
						}

						function hideHighlightBorder() {
							animatedBorderWidth = 0  
						}
	
						opacity: 1  // start invisible
						
						Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
						Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
						Behavior on width  { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
						Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
				
						Behavior on scale {
							NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
						}	
						Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }


						property real progress: 0

						// // mask container
						Rectangle {
							z: 0
							id: borderMask
							anchors.fill: parent
							radius: wallpaperHighlight.radius
							color: "transparent"
							border.width: 2
							border.color: "transparent"
							clip: true
							layer.enabled: true
    					    layer.smooth: true
							visible: true
							// rotating gradient "energy"

		
							Rectangle {
								id: rotatingGlow
								width: parent.width * 2
								height: parent.height * 2
								anchors.centerIn: parent
								rotation: wallpaperHighlight.progress * 360

							gradient: Gradient {
								GradientStop { position: 0.0; color: "transparent" }
								GradientStop { position: 0.35; color: "transparent" }
								GradientStop { position: 0.4; color: colorsPalette.primary }
								GradientStop { position: 0.6; color: colorsPalette.primary }
								GradientStop { position: 0.65; color: "transparent" }
								GradientStop { position: 1.0; color: "transparent" }
							}
							}
						}

						NumberAnimation on progress {
							from: 0
							to: 1
							duration: 2000
							loops: Animation.Infinite
							running: true
						}

		
						Timer {
							id: fadeTimer
							interval: 800  
							running: false
							repeat: false
							onTriggered: {
								borderMask.opacity = 0.0
								wallpaperGridView.showDelegateBorder = true
							}

						}
						// Fade-in/out animation
						SequentialAnimation {
							id: fadeAnim
							running: false
							property int startDelay: 0

							PropertyAnimation {
							target: borderMask
							property: "opacity"
							to: 1.0
							duration: 250
							easing.type: Easing.OutQuad
						}

						PauseAnimation { duration: 0 }

						PropertyAnimation {
							target: borderMask
							property: "opacity"
							to: 0.0
							duration: 400
							easing.type: Easing.InQuad
						}

						onStarted: { 
							
							wallpaperGridView.navigating = true 
						    // console.log("navigating:", wallpaperGridView.navigating) 
						}

						onFinished: { wallpaperGridView.navigating = false 
						// console.log("navigating:", wallpaperGridView.navigating) 
						}
						}

						function showHighlight() {
							fadeAnim.stop()
							fadeAnim.start()
						}

					}
			}
			
				GridView {
					id: wallpaperGridView
					anchors.fill: parent
					model: filteredWallpapers
					
					// cellWidth: 249.5
					// cellHeight: 260 * 9 / 16 + 16
					cellWidth: 249.5
					cellHeight: 220 * 9 / 16 + 16
					clip: true
					property int columns: Math.floor(width / cellWidth)
					highlightFollowsCurrentItem: true
					boundsBehavior: Flickable.StopAtBounds
					flow: GridView.FlowLeftToRight
					property bool navigating: false
					
					delegate: Rectangle {
						// z: isCurrent ? 10 : 0

						// function showHighlight() {
						// 	fadeAnim.stop()
						// 	fadeAnim.start()
							  
						// }
						
						property bool isSameRow: {
							const current = wallpaperGridView.currentIndex
							if (current < 0) return false

							const row = Math.floor(index / columns)
							const currentRow = Math.floor(current / columns)

							return row === currentRow
						}
						// function showHighlight() {
						// 	fadeAnim.stop()
						// 	fadeAnim.start()
						// }
						// function showHighlight() {
						// 	wallpaperHighlight.fadeAnim.stop()
						// 	wallpaperHighlight.fadeAnim.start()
						// 	wallpaperHighlight.fadeTimer.start()
						// }

						    // Random width for each image on creation
						// property real randomWidth: wallpaperGridView.cellWidth * (0.7 + Math.random() * 0.6)
						// This will give widths from ~70% to ~130% of normal

						width: wallpaperGridView.cellWidth
						// width: wallpaperGridView.cellWidth
						//  width: isCurrent 
						// ? wallpaperGridView.cellWidth * 1.1 
						// : (isSameRow ? wallpaperGridView.cellWidth * 0.95 : wallpaperGridView.cellWidth)
						height: wallpaperGridView.cellHeight
						// width: isCurrent ? wallpaperGridView.cellWidth * 1.1 : wallpaperGridView.cellWidth
   						// height: isCurrent ? wallpaperGridView.cellHeight * 1.1 : wallpaperGridView.cellHeight
						color: "transparent"
						radius: 10
						property bool isCurrent: model.index === wallpaperGridView.currentIndex
						property bool showBorder: !wallpaperGridView.navigating && isCurrent
						property int columns: Math.floor(wallpaperGridView.width / wallpaperGridView.cellWidth)

						Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
						Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
						property bool isNeighbor: {
        					const current = wallpaperGridView.currentIndex
							const row = Math.floor(model.index / columns)
							const col = model.index % columns
							const currentRow = Math.floor(current / columns)
							const currentCol = current % columns

							// Check if it's exactly above, below, left, or right
							return (row === currentRow && Math.abs(col - currentCol) === 1) ||  // left/right
								(col === currentCol && Math.abs(row - currentRow) === 1)      // top/bottom
						}
						
						Rectangle {
						id: wallpaperHighlight
						anchors.fill: parent
						radius: 10
						color: "transparent"
						border.width: 0
						clip: true
						
						visible: isCurrent
						// visible: isCurrent



						// property real progress: 0

						// // // mask container
						// Rectangle {
						// 	z: 0
						// 	id: borderMask
						// 	anchors.fill: parent
						// 	radius: wallpaperHighlight.radius
						// 	color: "transparent"
						// 	// border.width: 3
						// 	border.color: "transparent"
						// 	clip: true
						// 	layer.enabled: true
    					//     layer.smooth: true
						// 	visible: true
					
						// 	// visible: false
						// 	// rotating gradient "energy"

		
						// 	Rectangle {
						// 		id: rotatingGlow
						// 		width: parent.width * 2
						// 		height: parent.height * 2
						// 		anchors.centerIn: parent
						// 		rotation: wallpaperHighlight.progress * 360
						// 	// 	gradient: Gradient {
						// 	// 	GradientStop { position: 0.0; color: "transparent" }
						// 	// 	GradientStop { position: 0.28; color: "transparent" }

						// 	// 	GradientStop { position: 0.33; color: colorsPalette.primary }
						// 	// 	GradientStop { position: 0.67; color: colorsPalette.primary }

						// 	// 	GradientStop { position: 0.72; color: "transparent" }
						// 	// 	GradientStop { position: 1.0; color: "transparent" }
						// 	// }
						// 	gradient: Gradient {
						// 		GradientStop { position: 0.0; color: "transparent" }
						// 		GradientStop { position: 0.35; color: "transparent" }
						// 		GradientStop { position: 0.4; color: colorsPalette.primary }
						// 		GradientStop { position: 0.6; color: colorsPalette.primary }
						// 		GradientStop { position: 0.65; color: "transparent" }
						// 		GradientStop { position: 1.0; color: "transparent" }
						// 	}
						// 	}
									
						// 	}
						// 		NumberAnimation on progress {
						// 			from: 0
						// 			to: 1
						// 			duration: 2000
						// 			loops: Animation.Infinite
						// 			running: true
						// 		}
								
						// 		Timer {
						// 		id: fadeTimer
						// 		interval: 400
						// 		running: false   // start stopped
						// 		repeat: false
						// 		onTriggered: fadeAnim.start()
						// 	}

						// 	// Fade-in/out animation
						// 	SequentialAnimation {
						// 		id: fadeAnim
						// 		running: false
						// 		property int startDelay: 0
						// 		PropertyAnimation {
						// 		target: wallpaperHighlight
						// 		property: "opacity"
						// 		to: 1.0
						// 		duration: 200
						// 		easing.type: Easing.OutQuad
						// 	}

						// 	PauseAnimation { duration: 0 }

						// 	PropertyAnimation {
						// 		target: wallpaperHighlight
						// 		property: "opacity"
						// 		to: 0.0
						// 		duration: 400
						// 		easing.type: Easing.InQuad
						// 	}
						// 	onStarted: { 
						// 		wallpaperGridView.navigating = true 
						// 		// console.log("navigating:", wallpaperGridView.navigating) 
						// 	}

						// 	onFinished: { wallpaperGridView.navigating = false 
						// 	// console.log("navigating:", wallpaperGridView.navigating) 
						// 	}
						

 
						// }
						    // This is how you correctly react to property changes

						// property real progressTop: 0
						// property real progressBottom: 0
						// readonly property real borderWidth: 3


						// // Top-left growing line
						// Rectangle {
						// 	anchors.right: parent.right
						// 	anchors.top: parent.top
						// 	width: (parent.width / 2 + parent.width * 0.5) * wallpaperHighlight.progressTop
						// 	height: (parent.height / 2 + parent.height * 0.5) * wallpaperHighlight.progressTop
						// 	color: "transparent"
						// 	border.width: wallpaperHighlight.borderWidth
						// 	border.color: colorsPalette.primary
						// 	radius: wallpaperHighlight.radius
						// }

						// // Bottom-right growing line
						// Rectangle {
						// 	anchors.left: parent.left
						// 	anchors.bottom: parent.bottom
						// 	width: (parent.width / 2 + parent.width * 0.5) * wallpaperHighlight.progressBottom
						// 	height: (parent.height / 2 + parent.height * 0.5) * wallpaperHighlight.progressBottom
						// 	color: "transparent"
						// 	border.width: wallpaperHighlight.borderWidth
						// 	border.color: colorsPalette.primary
						// 	radius: wallpaperHighlight.radius
						// }

						// ParallelAnimation {
						// 	running: isCurrent && !wallpaperGridView.navigating
						// 	loops: 1
						// 	PropertyAnimation { target: wallpaperHighlight; property: "progressTop"; from: 0; to: 1; duration: 600 }
						// 	PropertyAnimation { target: wallpaperHighlight; property: "progressBottom"; from: 0; to: 1; duration: 600 }
						// }
						
						}

	
						Behavior on border.width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
						Behavior on border.color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
						
						ClippingRectangle {
							anchors.fill: parent
							radius: 10
							antialiasing: true 
							color: "transparent"
							
							opacity: 10
							anchors.margins: 2
		
							// border.color: model.index === wallpaperGridView.currentIndex ? colorsPalette.primary : "transparent"
							border.width: 0
							// Wallpaper preview - optimized with pre-calculated paths
							Image {
								id: wallpaperImage
								anchors.fill: parent
								anchors.margins: 0
								property string thumbPath: thumbnailPaths[modelData] || ""
								source: thumbPath ? ("file://" + thumbnailDir + "/" + thumbPath) : ""
								fillMode: Image.PreserveAspectCrop
								smooth: true
								asynchronous: false
								cache: true
								mipmap: true
								
								onStatusChanged: {
									if (status === Image.Error && source !== "") {
										source = "file://" + wallpaperDir + "/" + modelData
									}
								}


								// property bool isNeighbor: {
								// 	const current = wallpaperGridView.currentIndex
								// 	if (current < 0) return false

								// 	const row = Math.floor(index / columns)
								// 	const col = index % columns

								// 	const currentRow = Math.floor(current / columns)
								// 	const currentCol = current % columns

								// 	const rowDiff = Math.abs(row - currentRow)
								// 	const colDiff = Math.abs(col - currentCol)

								// 	// Adjacent in ANY direction (including diagonals)
								// 	return (rowDiff <= 1 && colDiff <= 1) && !(rowDiff === 0 && colDiff === 0)
								// }
								
								    // Overlay rectangle for selection
								Rectangle {
									property bool isNeighbor: {
										const current = wallpaperGridView.currentIndex
										if (current < 0) return false

										const row = Math.floor(index / columns)
										const col = index % columns

										const currentRow = Math.floor(current / columns)
										const currentCol = current % columns

										const rowDiff = Math.abs(row - currentRow)
										const colDiff = Math.abs(col - currentCol)

										// Adjacent in cardinal directions only (no diagonals)
										return (rowDiff + colDiff === 1)
									}

									// property bool isNeighbor: {
									// 	const current = wallpaperGridView.currentIndex
									// 	if (current < 0) return false

									// 	const row = Math.floor(index / columns)
									// 	const col = index % columns

									// 	const currentRow = Math.floor(current / columns)
									// 	const currentCol = current % columns

									// 	const rowDiff = Math.abs(row - currentRow)
									// 	const colDiff = Math.abs(col - currentCol)

									// 	// Adjacent in ANY direction (including diagonals)
									// 	return (rowDiff <= 1 && colDiff <= 1) && !(rowDiff === 0 && colDiff === 0)
									// }
									anchors.fill: parent
									color: "#000000"                // black overlay
									opacity: model.index === wallpaperGridView.currentIndex || isNeighbor ? 0 : 0.4
									radius: 10                      // match clipping
									antialiasing: true

									  Behavior on opacity {
										NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
									}
								}
								
								// property bool isSameRow: {
								// const current = wallpaperGridView.currentIndex
								// if (current < 0) return false

								// const row = Math.floor(index / columns)
								// const currentRow = Math.floor(current / columns)

								// return row === currentRow
								// }
								// opacity: 1
								// opacity: isCurrent ? 0.5 : 1
								
								// //  Behavior on opacity { 
								// 	NumberAnimation { 
								// 		duration: 250        // adjust speed
								// 		easing.type: Easing.InOutQuad 
								// 	} 
								// }
								// ImageOpacity {
								// 	anchors.centerIn: parent
								// 	width: 40
								// 	height: 40
								// 	visible: true
								// 	z: 1
								// }

								BusyIndicator {
									anchors.centerIn: parent
									width: 40
									height: 40
									running: wallpaperImage.status === Image.Loading
									visible: wallpaperImage.status === Image.Loading
									z: 1
								}

							}
								
							MouseArea {
								anchors.fill: parent
								hoverEnabled: true

								onClicked: {
									wallpaperGridView.currentIndex = index
									currentIndex = index
									wallpaperWindow.selectedWallpaper = modelData
								}

								onDoubleClicked: {
									applyWallpaper(modelData)
								}
							}
						}
						// Component.onCompleted: {
                        // if (model.index === wallpaperGridView.currentIndex) {
                        //     Qt.callLater(() => updateHighlightAtIndex(model.index))
                        //    }
                        //  }
					}

					 onCurrentIndexChanged: {
						var item = wallpaperGridView.currentItem
						if (!item) return

						// Map the delegate to the container's coordinates
						var pos = item.mapToItem(wallpaperContainer, 0, 0)

						// Move the highlight rectangle
						wallpaperHighlight.targetX = pos.x
						wallpaperHighlight.targetY = pos.y
						wallpaperHighlight.targetWidth = item.width
						wallpaperHighlight.targetHeight = item.height
						wallpaperHighlight.scale = 0.92
						wallpaperHighlight.scale = 1.0
						// wallpaperTransition.restart()
						 // Reset progress
				
						var item = wallpaperGridView.currentItem
						if (item && item.showHighlight) {
							item.showHighlight()
						}

						// wallpaperHighlight.progressTop = 0
						// wallpaperHighlight.progressBottom = 0
						wallpaperHighlight.showHighlight()
						// Restart growing border animation
						// borderGrowAnim.restart()
						// currentItem.showHighlight()
						// onIsCurrentChanged: {
						// 	if (isCurrent) {
						// 		wallpaperHighlight.showHighlight()
						// 	}
						// }
						// if (GridView.isCurrentItem ) {
						// 	showHighlight()
						// }
						// wallpaperHighlightBorder.showHighlight()
						// wallpaperHighlightBorder.showHighlightBorder()
						// Scroll only if outside viewport
						const margin = 16
						const viewTop = wallpaperScroll.contentY
						const viewBottom = viewTop + wallpaperScroll.height
						const itemTop = pos.y
						const itemBottom = pos.y + item.height

						if (itemTop < viewTop + margin)
							wallpaperScroll.contentY = itemTop - margin
						else if (itemBottom > viewBottom - margin)
							wallpaperScroll.contentY = itemBottom - wallpaperScroll.height + margin
						
					}
					
					 Component.onCompleted: forceActiveFocus()
				}
				}
			    // SequentialAnimation {
				// 	id: wallpaperTransition

				// 	PropertyAnimation {
				// 		target: wallpaperHighlightBorder
				// 		property: "opacity"
				// 		to: 0.5
				// 		duration: 80
				// 		easing.type: Easing.OutQuad
				// 	}

				// 	PropertyAnimation {
				// 		target: wallpaperHighlightBorder
				// 		property: "opacity"
				// 		to: 1.0
				// 		duration: 200
				// 		easing.type: Easing.OutCubic
				// 	}
				// }
			
		}

		// // Status text
		// Text {
		// 	text: wallpapers.length > 0 ? `Loaded ${wallpapers.length} wallpapers` : "Loading wallpapers..."
		// 	font.pixelSize: 11
		// 	color: colorOutline
		// 	Layout.alignment: Qt.AlignRight | Qt.AlignBottom
		// }
		
		// Settings dialog
		// Dialog {
		// 	id: settingsDialog
		// 	visible: settingsOpen
		// 	modal: true
		// 	title: "Settings"
		// 	width: 720
		// 	height: 460
		// 	padding: 16
		// 	onVisibleChanged: if (!visible) settingsOpen = false
		// 	background: Rectangle {
		// 		radius: 12
		// 		color: colorSurface
		// 		border.color: colorOutline
		// 		border.width: 1
		// 	}
		// 	onAccepted: {
		// 		// Apply directories from fields and persist
		// 		wallpaperDir = wallDirField.text.trim()
		// 		thumbnailDir = thumbDirField.text.trim()
		// 		// Re-validate and rescan
		// 		mkdirThumbsProcess.exec(["sh","-c","mkdir -p '" + thumbnailDir + "'"])
		// 	}
		// 	contentItem: ColumnLayout {
		// 		spacing: 12
		// 		RowLayout {
		// 			Layout.fillWidth: true
		// 			Label { text: "Wallpaper directory:"; color: colorOnSurface }
		// 			TextField { id: wallDirField; text: wallpaperDir; Layout.fillWidth: true }
		// 			Button {
		// 				id: browseWallBtn
		// 				text: "Browse"
		// 				background: Rectangle { radius: 8; color: browseWallBtn.down ? Qt.darker(colorSurfaceContainer, 1.3) : (browseWallBtn.hovered ? Qt.lighter(colorSurfaceContainer, 1.2) : colorSurfaceContainer); border.color: colorOutline; border.width: 1 }
		// 				contentItem: Text { text: browseWallBtn.text; color: colorOnSurface; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
		// 				onClicked: wallpaperFolderDialog.open()
		// 			}
		// 		}
		// 		RowLayout {
		// 			Layout.fillWidth: true
		// 			Label { text: "Thumbnail directory:"; color: colorOnSurface }
		// 			TextField { id: thumbDirField; text: thumbnailDir; Layout.fillWidth: true }
		// 			Button {
		// 				id: browseThumbBtn
		// 				text: "Browse"
		// 				background: Rectangle { radius: 8; color: browseThumbBtn.down ? Qt.darker(colorSurfaceContainer, 1.3) : (browseThumbBtn.hovered ? Qt.lighter(colorSurfaceContainer, 1.2) : colorSurfaceContainer); border.color: colorOutline; border.width: 1 }
		// 				contentItem: Text { text: browseThumbBtn.text; color: colorOnSurface; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
		// 				onClicked: thumbnailFolderDialog.open()
		// 			}
		// 		}
		// 		RowLayout {
		// 			spacing: 16
		// 			Text { text: hasFfmpeg ? "ffmpeg: OK" : "ffmpeg: not found"; color: hasFfmpeg ? "#84e1a7" : colorError }
		// 			Text { text: hasMatugen ? "matugen: OK" : "matugen: not found"; color: hasMatugen ? "#84e1a7" : colorError }
		// 		}
		// 	}
		// 	footer: DialogButtonBox {
		// 		alignment: Qt.AlignRight
		// 		Button {
		// 			id: cancelBtn
		// 			text: "Cancel"
		// 			DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
		// 			background: Rectangle { radius: 8; color: cancelBtn.down ? Qt.darker(colorSurfaceContainer, 1.3) : (cancelBtn.hovered ? Qt.lighter(colorSurfaceContainer, 1.2) : colorSurfaceContainer); border.color: colorOutline; border.width: 1 }
		// 			contentItem: Text { text: cancelBtn.text; color: colorOnSurface; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
		// 		}
		// 		Button {
		// 			id: saveBtn
		// 			text: "Save"
		// 			DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
		// 			background: Rectangle { radius: 8; color: saveBtn.down ? Qt.darker(colorSurfaceContainer, 1.3) : (saveBtn.hovered ? Qt.lighter(colorSurfaceContainer, 1.2) : colorSurfaceContainer); border.color: colorOutline; border.width: 1 }
		// 			contentItem: Text { text: saveBtn.text; color: colorOnSurface; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
		// 		}
		// 	}
		// }

		// FolderDialog {
		// 	id: wallpaperFolderDialog
		// 	title: "Choose wallpaper directory"
		// 	onAccepted: {
		// 		wallpaperDir = wallpaperFolderDialog.selectedFolder
		// 		settingsOpen = true
		// 	}
		// }
		// FolderDialog {
		// 	id: thumbnailFolderDialog
		// 	title: "Choose thumbnail directory"
		// 	onAccepted: {
		// 		thumbnailDir = thumbnailFolderDialog.selectedFolder
		// 		settingsOpen = true
		// 	}
		// }
	
	}

}