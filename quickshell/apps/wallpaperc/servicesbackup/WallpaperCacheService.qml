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
    
    // --filename attached--
        //     "file=\"{}\"; " +
        // "base=$(basename \"$file\"); " +
        // "name=\"${base%.*}\"; " +
        // "dir=$(dirname \"$file\"); " +
        // "folder=$(basename \"$dir\"); " +
        // "thumb=\"" + Config.cacheDir + "/${folder}-${name}.png\"; " +

    property string setupCmd:
        "mkdir -p '" + Config.cacheDir + "' && " +

        "STOP_FILE='" + Config.cacheDir + "/.stop' && " +
        "rm -f \"$STOP_FILE\" && " +

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
            "if [ -f \"$STOP_FILE\" ]; then exit 0; fi; " +

            "[ -f \"$thumb\" ] || ffmpeg -y -i \"$file\" " +
            "-vf \"scale=200:208:force_original_aspect_ratio=increase,crop=200:208:(in_w-200)/2:(in_h-208)/2\" " +
            "-frames:v 1 \"$thumb\" >/dev/null' "
        // "name=$(echo \"$file\" | md5sum | awk '{print $1}'); " +
        // "name=$(md5sum \"$file\" | awk '{print $1}'); " +
        // "name=$(file=\"{}\"; file=$(printf \"%s\" \"$file\" | tr -d '\\r' | sed 's|^file://||'); md5sum \"$file\" | cut -d' ' -f1); " +
        // "name=$(md5sum \"$file\" | cut -d\" \" -f1); " +
        // "name=$(md5sum \"$file\" | cut -d\" \" -f1); " +
           

            
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
            // console.log("Missing thumbnails, generating...")
            thumbnailProcess.exec(["sh", "-c", setupCmd])
        } else {
            console.log("All thumbnails exist, skipping generation")
        }
    }

//   function onListThumbsExited() {
//     let data = {}

//     let count = WatcherService.wallpaperModel.count

//     for (let i = 0; i < count; i++) {

//         let file = WatcherService.wallpaperModel.get(i, "filePath")
//         if (!file) continue

//         file = file.trim().replace(/\r/g, "")

//         let hash = WallpaperCacheService.hashPath(file)

//         data[hash] = true
//     }

//     WallpaperCacheService.thumbData = Object.assign({}, data)
// }
// function updateThumbs() {
//     pendingUpdate = false

//     console.log("=== updateThumbs ===")

//     // existing thumbnails (fileName = "1_593018.png")
//     let thumbSet = {}

//     for (let i = 0; i < WatcherService.thumbModel.count; i++) {
//         let name = WatcherService.thumbModel.get(i, "fileName")
//         if (!name) continue

//         let key = name.replace(".png", "")
//         thumbSet[key] = true
//     }

//     let allExist = true

//     for (let i = 0; i < WatcherService.wallpaperModel.count; i++) {

//         let file = WatcherService.wallpaperModel.get(i, "filePath")
//         if (!file) continue

//         file = file.trim().replace(/\r/g, "")

//         let base = file.split("/").pop().replace(/\.[^/.]+$/, "")

//         let size = WallpaperCacheService.fileSizes?.[file]
//         if (!size) {
//             console.log("MISSING SIZE:", file)
//             allExist = false
//             continue
//         }

//         let id = base + "_" + size

//         let exists = !!thumbSet[id]

//         console.log("check:", file, "-> id:", id, "exists:", exists)

//         if (!exists) {
//             console.log("MISSING:", id)
//             allExist = false
//         }
//     }

//     console.log("ALL EXIST:", allExist)

//     if (!allExist && !thumbnailProcess.running) {
//         thumbnailProcess.exec(["sh", "-c", setupCmd])
//     }
// }

function onListThumbsExited() {

    let data = {}

    for (let i = 0; i < WatcherService.wallpaperModel.count; i++) {

        let file = WatcherService.wallpaperModel.get(i, "filePath")
        if (!file) continue

        file = file.trim().replace(/\r/g, "")

        let base = file.split("/").pop().replace(/\.[^/.]+$/, "")

        let size = WallpaperCacheService.fileSizes?.[file]
        if (!size) continue

        let id = base + "_" + size

        data[file] = id
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
    property bool thumbsGenerating: false
    // property int thumbPid: -1


    property QtObject thumbnailProcess: Io.Process {
        command: []
        onStarted: {
            // thumbPid = thumbnailProcess.pid
            WatcherService.thumbModel.folder =
                "file://" + Config.cacheDir
            thumbsGenerating = true
        }    

        onExited: function(exitCode) {
            if (exitCode !== 0)
                return

            Qt.callLater(() => {
                
                updateThumbs()
                // let m = WatcherService.thumbModel
                // let p = m.folder

                // m.folder = ""
                // m.folder = p
                
                thumbsGenerating = false
            })
        }
    }

    property QtObject killProcess: Io.Process {
        command: []
    }
}