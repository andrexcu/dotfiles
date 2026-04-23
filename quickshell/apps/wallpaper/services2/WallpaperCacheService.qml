pragma Singleton
import QtQuick
import Quickshell
import qs
import qs.services
import Quickshell.Io as Io

QtObject {
    id: wallpaperCacheService

    property var thumbData: {}
    property bool pendingUpdate: false
    property string wallDir: "file://" + Config.options.wallpaperDir
    Component.onCompleted: {
        console.log(wallDir)
    }
    // ffmpeg batch thumbnail generator
	property string setupCmd: "mkdir -p '" + Config.cacheDir + "' && find '" + wallDir +  + "' -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \\) -print0 | xargs -0 -P 4 -I {} bash -c 'base=$(basename \"{}\"); name=\"${base%.*}\"; thumb=\"" + Config.cacheDir + "/${name}.png\"; [ ! -f \"$thumb\" ] && ffmpeg -y -i \"{}\" -vf \"scale=200:208:force_original_aspect_ratio=increase,crop=200:208:(in_w-200)/2:(in_h-208)/2,format=rgb24\" -q:v 5 -frames:v 1 \"$thumb\" 2>/dev/null || true'"
    // property string setupCmd:
    // "mkdir -p '" + Config.cacheDir + "' && " +
    // "find '" + Config.options.WallpaperDir + "' -maxdepth 1 -type f " +
    // "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \\) -print0 | " +
    // "xargs -0 -P 4 -I {} bash -c '"
    // + "file=\"{}\"; "
    // + "base=$(basename \"$file\"); "
    // + "name=\"${base%.*}\"; "
    // + "thumb=\"" + Config.cacheDir + "/${name}.png\"; "
    // + "[ ! -f \"$thumb\" ] && ffmpeg -y -i \"$file\" "
    // + "-vf \"scale=200:208:force_original_aspect_ratio=increase,crop=200:208:(in_w-200)/2:(in_h-208)/2\" "
    // + "-frames:v 1 \"$thumb\" >/dev/null 2>&1 || true'"
    
    property var thumbnailPaths: ({})
    function updateThumbs() {
        pendingUpdate = false
        let data = {}
        for (var i = 0; i < WatcherService.thumbModel.count; i++) {
            let name = WatcherService.thumbModel.get(i, "fileName")
            data[name] = true
        }

        thumbData = data

        // check for missing thumbnails
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
        console.log("Using thumbModel.count: " + WatcherService.thumbModel.count)
        // check missing thumbnails
    }

    property QtObject thumbnailProcess: Io.Process {
        command: []

        onStarted: console.log("Generating thumbnails...")

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                console.log("Thumbnails generated successfully")
                // Only refresh if some thumbnails were missing
                updateThumbs() 
            }
        }
    }
}