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

	// Process for getting wallpaper home directory
    property QtObject homeProcess: Io.Process {
        command: []
        stdout: Io.StdioCollector {
            id: homeCollector
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                
                // Add logging here
                console.log("Thumbnail dir set to:", Config.cacheDir)
                WatcherService.thumbModel.folder = "file://" + Config.cacheDir
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

    function startListingFromModel() {
        if (!WatcherService.wallpaperModel.count) {
            lastError = "No wallpapers found in " + Config.options.wallpaperDir
            NotificationService.show("Error", lastError, 0, "dialog-error")
            return
        }

        let processed = []
        let paths = {}

        for (let i = 0; i < WatcherService.wallpaperModel.count; i++) {
            let filename = WatcherService.wallpaperModel.get(i, "fileName")
            if (filename.length > 0) {
                processed.push(filename)

                let parts = filename.split(".")
                let baseName = parts.length > 1 ? parts.slice(0, -1).join(".") : filename
                paths[filename] = baseName + ".png"
            }
        }
        
        wallpapers = shuffleArray(processed)
        WallpaperCacheService.thumbnailPaths = paths

        // if (wallpapers.length > 0) {
        //     wallpaperController.currentIndex = 0
        //     selectedWallpaper = wallpapers[0]
        // }

        WallpaperCacheService.updateThumbs()
    }
}