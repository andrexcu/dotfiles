pragma Singleton

import QtQuick
import Quickshell
import qs.services
import qs
import Quickshell.Io as Io

QtObject {
    id: wallpaperService
    property var wallpapers: []
    property string currentFullPath: ""
    property string selectedWallpaper: ""
    property bool thumbsGenerated: WatcherService.current === WatcherService.total
    property string lastFilePath: lastFolder(Config.options.wallpaperDir)
	// Process for getting wallpaper home directory
    function lastFolder(path) {
        let clean = path.replace(/\/$/, "")
        let parts = clean.split("/")
        return parts[parts.length - 1]
    }
        function lastFile(path) {
        let clean = path.replace(/\/$/, "")
        let parts = clean.split("/")
        return parts[parts.length - 1]
    }

    function parse(filePath) {
    let clean = filePath.replace(/\/$/, "")
    let parts = clean.split("/")

    return {
        folder: parts[parts.length - 2],
        file: parts[parts.length - 1],
        name: parts[parts.length - 1].split(".")[0]
    }
}

    property Timer startTimer: Timer {
   
        interval: 500
        running: true
        repeat: false

        onTriggered: {
            console.log("MODEL:", WatcherService.thumbModel.get(0, "fileName"))
            console.log("CACHE:", WallpaperCacheService.thumbnailPaths[0])
            // for (let k in WallpaperCacheService.thumbnailPaths) {
            //     console.log("KEY:", k)
            //     console.log("VAL:", WallpaperCacheService.thumbnailPaths[k])

            //     for (let p in WallpaperCacheService.thumbnailPaths[k]) {
            //         console.log("PROP:", p, WallpaperCacheService.thumbnailPaths[k][p])
            //     }

            //     break
            // }
        }
    }


   Component.onCompleted: {
    startTimer.start()


    }



    property QtObject homeProcess: Io.Process {
        command: []
        stdout: Io.StdioCollector {
            id: homeCollector
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                // let current = wallpaperService.relevantCount()
                // let total = WatcherService.wallpaperModel.count
                // if (current === total) {
                // }
                // Add logging here
                console.log("Thumbnail dir set to:", Config.cacheDir)
                    // WatcherService.thumbModel.folder = "file://" + Config.cacheDir
                WatcherService.wallpaperModel.folder = "file://" + Config.options.wallpaperDir
                
            } else {
                lastError = "Failed to get home directory"
                showNotification("Error", lastError, "dialog-error")
            }
        }
    }
    
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

   function makeKey(filePath) {
    let parts = filePath.split("/")

    let base = parts[parts.length - 1] || ""
    let folder = parts.length > 1 ? parts[parts.length - 2] : ""

    let name = base.split(".")[0]

    return folder ? (folder + "-" + name + ".png") : (name + ".png")
}
function startListingFromModel() {
    if (!WatcherService.wallpaperModel.count) {
        lastError = "No wallpapers found in " + Config.options.wallpaperDir
        NotificationService.show("Error", lastError, 0, "dialog-error")
        return
    }

    let processed = []
    let paths = {}

    for (let i = 0; i < WatcherService.wallpaperModel.count; i++) {

        let filePath = WatcherService.wallpaperModel.get(i, "filePath")
        if (!filePath) continue

        processed.push(filePath)

        paths[filePath] = makeKey(filePath)
    }

    wallpapers = shuffleArray(processed)

    WallpaperCacheService.thumbnailPaths = paths
    WallpaperCacheService.updateThumbs()
}

    // function startListingFromModel() {
    //     if (!WatcherService.wallpaperModel.count) {
    //         lastError = "No wallpapers found in " + Config.options.wallpaperDir
    //         NotificationService.show("Error", lastError, 0, "dialog-error")
    //         return
    //     }

    //     let processed = []
    //     let paths = {}

    //     for (let i = 0; i < WatcherService.wallpaperModel.count; i++) {
    //         let filename = WatcherService.wallpaperModel.get(i, "fileName")
    //         if (filename.length > 0) {
    //             processed.push(filename)

    //             let parts = filename.split(".")
    //             let baseName = parts.length > 1 ? parts.slice(0, -1).join(".") : filename
    //             paths[filename] = baseName + ".png"
    //         } 
    //     }
        
    //     wallpapers = shuffleArray(processed)
    //     WallpaperCacheService.thumbnailPaths = paths

    //     WallpaperCacheService.updateThumbs()
    // }

    // function startListingFromModel() {
    //     if (!WatcherService.wallpaperModel.count) {
    //         lastError = "No wallpapers found in " + Config.options.wallpaperDir
    //         NotificationService.show("Error", lastError, 0, "dialog-error")
    //         return
    //     }

    //     let processed = []
    //     let paths = {}

    //     for (let i = 0; i < WatcherService.wallpaperModel.count; i++) {

    //         let file = WatcherService.wallpaperModel.get(i, "filePath")
    //         if (!file) continue

    //         processed.push(file)

    //         let hash = WallpaperCacheService.hashPath(file)

    //         paths[file] = hash
    //     }

    //     wallpapers = shuffleArray(processed)

    //     WallpaperCacheService.thumbnailPaths = paths

    //     WallpaperCacheService.updateThumbs()
    // }
    // function relevantCount() {
    //     let set = {}

    //     for (let i = 0; i < WatcherService.thumbModel.count; i++) {
    //         let name = WatcherService.thumbModel.get(i, "fileName")
    //         set[name.replace("  -.png", "")] = true
    //     }

    //     let c = 0

    //     for (let key in WallpaperCacheService.thumbnailPaths) {
    //         let hash = WallpaperCacheService.thumbnailPaths[key]
    //         if (set[hash]) c++
    //     }

    //     return c
    // }

   
function key(file) {
    let base = file.split("/").pop()

    // convert "Wallpapers-0anime.png" → "0anime.png"
    let parts = base.split("-")
    return parts.length > 1 ? parts[1] : base
}

function relevantCount() {
    let set = {}

    for (let i = 0; i < WatcherService.thumbModel.count; i++) {
        let file = WatcherService.thumbModel.get(i, "filePath")
        if (!file) continue

        let base = file.split("/").pop()
        let name = base.split(".")[0]

        set[name] = true
    }

    let c = 0

    for (let k in WallpaperCacheService.thumbnailPaths) {
        let cacheVal = WallpaperCacheService.thumbnailPaths[k]

        let base = cacheVal.split("/").pop()
        let name = base.split(".")[0]

        if (set[name]) c++
    }

    return c
}




    // function relevantCount() {
    //     let set = {}
    //     for (let i = 0; i < WatcherService.thumbModel.count; i++) {
    //         set[WatcherService.thumbModel.get(i, "fileName")] = true
    //     }

    //     let c = 0
    //     for (let key in WallpaperCacheService.thumbnailPaths) {
    //         if (set[WallpaperCacheService.thumbnailPaths[key]]) c++
    //     }
    //     return c
    // }
    
    property string stopFlag: Config.cacheDir + "/.stop"
    
    property Timer quitTimer: Timer {
        interval: 300
        repeat: false
        onTriggered: Qt.quit()
    }

    function killAllAndQuit() {
        // stop future loop
        WallpaperCacheService.killProcess.exec([
            "sh", "-c", "touch '" + stopFlag + "'"
        ])

        // kill running ffmpeg
        WallpaperCacheService.killProcess.exec([
            "pkill", "-9", "-f", "scale=200:208"
        ])

        // safe exit
        quitTimer.start()
    }
}