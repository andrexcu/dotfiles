pragma Singleton
import QtQuick
import Quickshell
import qs
import qs.services
import Quickshell.Io as Io

QtObject {
    id: matugenCacheService
    
    property QtObject matugenProcess: Io.Process {
        property string requestPath: ""
        property string requestName: ""       
	    property string switchwallPath: Config.homeDir + "/.config/quickshell/scripts/colors/switchwall.sh"
        property bool matugenKilled: false

        onStarted: {
            requestPath = WallpaperService.currentFullPath
            requestName = WallpaperService.selectedWallpaper
            matugenKilled = false
        }

        onExited: function(exitCode) {
            // if (exitCode !== 0 && !matugenKilled) {
            //     NotificationService.show(
            //         "Error",
            //         "matugen.sh failed",
            //         0,
            //         "dialog-error"
            //     )
            // } else if (!matugenKilled) {
            //     // This will fire BEFORE wallpaper is applied
            //     NotificationService.show(
            //         "Wallpaper Applied",
            //         "Wallpaper '" + requestName + "' applied successfully",
            //         9999,
            //         "dialog-information"
            //     )
            // }

            // Continue to actual wallpaper apply
            if (switchwallProcess.running) {
                switchwallProcess.signal("SIGKILL")
            }

            switchwallProcess.requestPath = requestPath
            switchwallProcess.requestName = requestName

            switchwallProcess.exec([
                "bash",
                switchwallPath,
                "--image",
                requestPath
            ])
        }
    }
        // --- switchwallProcess ---
    property QtObject switchwallProcess: Io.Process {
        property string requestPath: ""
        property string requestName: ""
        command: []

        onExited: function(exitCode) {
            if (exitCode === 0) {
                NotificationService.show(
                    "Wallpaper Applied",
                    "Wallpaper '" + requestName + "' applied successfully",
                    9999,
                    "dialog-information"
                )
            } else {
                NotificationService.show(
                    "Error",
                    "switchwall.sh failed",
                    0,
                    "dialog-error"
                )
            }
        }
    }
}