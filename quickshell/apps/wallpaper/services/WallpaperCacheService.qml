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
    // ffmpeg batch thumbnail generator
	// property string setupCmd: "mkdir -p '" + Config.cacheDir + "' && find '" + Config.options.wallpaperDir + "' -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \\) -print0 | xargs -0 -P 4 -I {} bash -c 'base=$(basename \"{}\"); name=\"${base%.*}\"; thumb=\"" + Config.cacheDir + "/${name}.png\"; [ ! -f \"$thumb\" ] && ffmpeg -y -i \"{}\" -vf \"scale=200:208:force_original_aspect_ratio=increase,crop=200:208:(in_w-200)/2:(in_h-208)/2,format=rgb24\" -q:v 5 -frames:v 1 \"$thumb\" 2>/dev/null || true'"
    
    // property string setupCmd:
    // "mkdir -p '" + Config.cacheDir + "' && " +
    // "find '" + Config.options.wallpaperDir + "' -maxdepth 1 -type f " +
    // "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \\) -print0 | " +
    // "xargs -0 -P 4 -I {} bash -c 'file=\"{}\"; base=$(basename \"$file\"); name=\"${base%.*}\"; " +
    // "thumb=\"" + Config.cacheDir + "/${name}.png\"; " +
    // "[ -f \"$thumb\" ] || ffmpeg -y -i \"$file\" -vf \"scale=200:208:force_original_aspect_ratio=increase,crop=200:208:(in_w-200)/2:(in_h-208)/2\" " +
    // "-frames:v 1 \"$thumb\" >/dev/null 2>&1'"

    //  "file=\"{}\"; " +
    //         "base=$(basename \"$file\"); " +
    //         "name=\"${base%.*}\"; " +
    //         "thumb=\"" + Config.cacheDir + "/${name}.png\"; " +

    // -- md5 --
    // "file=\"{}\"; " +
    //         "name=$(printf \"%s\" \"$file\" | md5sum | awk \"{print \$1}\"); " +
    //         "thumb=\"" + Config.cacheDir + "/${name}.png\"; " +


    // property string setupCmd:
    //     "mkdir -p '" + Config.cacheDir + "' && " +

    //     "STOP_FILE='" + Config.cacheDir + "/.stop' && " +
    //     "rm -f \"$STOP_FILE\" && " +

    //     "find '" + Config.options.wallpaperDir + "' -maxdepth 1 -type f " +
    //     "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \\) -print0 | " +

    //     "xargs -0 -P 4 -I {} bash -c '" +
    //     "file=\"{}\"; " +
    //     "base=$(basename \"$file\"); " +
    //     "base=\"${base%.*}\"; " +
    //     "size=$(stat -c%s \"$file\"); " +
    //     "id=\"${base}_${size}\"; " +

    //     "echo \"$file|$id\"; " +
    //     "thumb=\"" + Config.cacheDir + "/${id}.png\"; " +

    //         "if [ -f \"$STOP_FILE\" ]; then exit 0; fi; " +

    //         "[ -f \"$thumb\" ] || ffmpeg -y -i \"$file\" " +
    //         "-vf \"scale=200:208:force_original_aspect_ratio=increase,crop=200:208:(in_w-200)/2:(in_h-208)/2\" " +
    //         "-frames:v 1 \"$thumb\" >/dev/null' "

        // "file=\"{}\"; " +
        // "base=$(basename \"$file\"); " +
        // "name=\"${base%.*}\"; " +
        // "dir=$(dirname \"$file\"); " +
        // "folder=$(basename \"$dir\"); " +
        // "thumb=\"" + Config.cacheDir + "/${folder}-${name}.png\"; " +
           

property string setupCmd:
    "mkdir -p '" + Config.cacheDir + "' && " +

    "find '" + Config.options.wallpaperDir + "' -maxdepth 1 -type f " +
    "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \\) -print0 | " +

    "xargs -0 -P 4 -I {} bash -c '" +
    "file=\"{}\"; " +
    "base=$(basename \"$file\"); " +
    "base=\"${base%.*}\"; " +
    "size=$(stat -c%s \"$file\"); " +
    "id=\"${base}_${size}\"; " +

    "echo \"$file|$id\"; " +
    "thumb=\"" + Config.cacheDir + "/${id}.png\"; " +

    "[ -f \"$thumb\" ] || ffmpeg -y -i \"$file\" " +
    "-vf \"scale=200:208:force_original_aspect_ratio=increase,crop=200:208:(in_w-200)/2:(in_h-208)/2\" " +
    "-frames:v 1 \"$thumb\" >/dev/null' "


// function hashPath(file) {
//     return Qt.md5(file)
// }
// function updateThumbs() {
//     pendingUpdate = false

//     let count = WatcherService.wallpaperModel.count
//     let missing = false

//     console.log("=== updateThumbs ===")

//     for (let i = 0; i < count; i++) {

//         let file = WatcherService.wallpaperModel.get(i, "filePath")
//         if (!file) continue

//         let hash = hashPath(file)
//         let thumbFile = Config.cacheDir + "/" + hash + ".png"

//         console.log("check:", file, "->", thumbFile)

//         // REAL check: must exist in thumbModel
//         if (!WatcherService.thumbModel.get(i, "fileName")) {
//             missing = true
//             break
//         }
//     }

//     console.log("missing:", missing)

//     if (missing && !thumbnailProcess.running) {
//         thumbnailProcess.exec(["sh", "-c", setupCmd])
//     } else {
//         console.log("SKIP")
//     }
// }

    property var thumbnailPaths: ({})
    property bool forceRescan: false
    // function updateThumbs() {

    //     if (thumbsGenerating && !forceRescan)
    //         return

    //     forceRescan = false

    //     pendingUpdate = false
    //     let data = {}

    //     for (var i = 0; i < WatcherService.thumbModel.count; i++) {
    //         let name = WatcherService.thumbModel.get(i, "fileName")
    //         data[name] = true
    //     }

    //     thumbData = data

    //     let allExist = true
    //     for (let key in thumbnailPaths) {
    //         if (!thumbData[thumbnailPaths[key]]) {
    //             allExist = false
    //             break
    //         }
    //     }

    //     if (!allExist && !thumbnailProcess.running) {
    //         // console.log("Missing thumbnails, generating...")
    //         thumbnailProcess.exec(["sh", "-c", setupCmd])
    //     } else {
    //         console.log("All thumbnails exist, skipping generation")
    //     }
    // }
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
            // console.log("Missing thumbnails, generating...")
            thumbnailProcess.exec(["sh", "-c", setupCmd])
        } else {
            console.log("All thumbnails exist, skipping generation")
        }
    }

   function onListThumbsExited() {
    let files = listThumbsCollector.text.trim().split("\n")
    let data = {}

    for (let i = 0; i < files.length; i++) {
        let f = files[i].trim()
        if (!f) continue

        // IMPORTANT: normalize ONLY filename
        let clean = f.split("/").pop()   // remove path noise

        // remove garbage artifacts if still present
        clean = clean.replace("  -", "")

        data[clean] = true
    }

    WallpaperCacheService.thumbData = data
}
    // function onListThumbsExited() {
    //     let files = listThumbsCollector.text.trim().split("\n")
    //     let data = {}
    //     for (let i = 0; i < files.length; i++) {
    //         if (files[i].length > 0) data[files[i]] = true
    //     }
        
    //     thumbData = data
    //     console.log("Using thumbModel.count: " + WatcherService.thumbModel.count)
    //     // check missing thumbnails
    // }

    // sibling process
	property QtObject listThumbsProcess: Io.Process {
		command: []
		stdout: Io.StdioCollector { id: listThumbsCollector }

		onExited: function(exitCode) {
			if (exitCode === 0) {
				wallpaperCacheService.onListThumbsExited()
			}
		}
	}
    // onStarted: console.log("Generating thumbnails...")
    // property int thumbPid: -1
    // property bool ready: false
    // ready = true
    property int thumbVersion: 0
    property bool initialLoadDone: false

    property bool thumbsGenerating: false

    // function triggerThumbReset() {

    //     forceRescan = true

    //     // HARD reset model state
    //     WatcherService.thumbModel.folder = ""

    //     Qt.callLater(() => {
    //         WatcherService.thumbModel.folder =
    //             "file://" + Config.options.wallpaperDir

    //         Qt.callLater(() => {
    //             updateThumbs()
    //         })
    //     })
    // }

    property QtObject thumbnailProcess: Io.Process {
        command: []
        onStarted: {
            WatcherService.thumbModel.folder =
                "file://" + Config.cacheDir
            thumbsGenerating = true
        }    

        onExited: function(exitCode) {
            if (exitCode !== 0)
                return

            Qt.callLater(() => {
                
                updateThumbs()
                thumbsGenerating = false
                
                 
            })
        }
    }
                // thumbsGenerating = false
                // let m = WatcherService.thumbModel
                // let p = m.folder

                // m.folder = ""
                // m.folder = p

    property QtObject killProcess: Io.Process {
        command: []
    }
}