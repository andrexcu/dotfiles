pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    // function _resolve(path) { return path ? path.replace("~", homeDir) : "" }
    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || (homeDir + "/.cache")) + "/wall-select"
    readonly property string shellConfigPath:
    Quickshell.shellPath("") + "settings.json"
    property string defaultWallpaperDir: homeDir + "/Pictures/Wallpaper"

    // create config file
    property string filePath: shellConfigPath
    property alias options: configOptionsJsonAdapter
    property bool ready: false
    property int readWriteDelay: 50 // milliseconds
    property bool blockWrites: false

    signal configChanged()
   
    Timer {
        id: fileReloadTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: {
            configFileView.reload()
        }
    }

    Timer {
        id: fileWriteTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: {
            configFileView.writeAdapter()
        }
    }

    Process {
        id: pathProcess
        command: []  
    }
    

    FileView {
        id: configFileView
        path: root.filePath
        watchChanges: true
        blockWrites: root.blockWrites
        onFileChanged: fileReloadTimer.restart()
        onAdapterUpdated: fileWriteTimer.restart()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                console.log("[Config] File not found, creating new file.")
                // Ensure parent directory exists
                const parentDir = root.filePath.substring(0, root.filePath.lastIndexOf('/'))
                pathProcess.exec(["/usr/bin/mkdir", "-p", parentDir])
                Qt.callLater(() => {
                    configFileView.writeAdapter()
                })
            }            
            // Set ready even on failure so UI doesn't stay blank
            root.ready = true;
        }


        JsonAdapter {
            id: configOptionsJsonAdapter
            property string wallpaperDir: homeDir + "/Pictures/Wallpapers"
        }
    }
}