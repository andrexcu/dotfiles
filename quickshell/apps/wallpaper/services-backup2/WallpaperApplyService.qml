pragma Singleton
import QtQuick
import Quickshell
import qs
import qs.services
import Quickshell.Io as Io
    
// listing and applying wallpaper
QtObject {
    id: wallpaperApplyService

    
    property string matugenPath: Config.homeDir + "/Scripts/matugen.sh"
    // function showNotification(title, message, icon) {
    //     console.log("[" + title + "] " + message)
    // }
    // this generates matugen colors from wallpaper
    function applyWallpaper(wallpaperName) {
        WallpaperService.selectedWallpaper = wallpaperName
        WallpaperService.currentFullPath = Config.options.wallpaperDir + "/" + wallpaperName

        let awwwArgs = [
            "img", `"${WallpaperService.currentFullPath}"`,
            "--transition-type", "wave",
            "--transition-fps", "60",
            "--transition-duration", "0.5",
            "--transition-wave", "25,15",
            "--transition-angle", "45",
            "--transition-bezier", ".4,0,.2,1"
        ]
    
        awwwProcess.exec(["sh", "-c", ["awww"].concat(awwwArgs).join(" ")])

        // Step 1: kill previous matugen if running
        if (MatugenCacheService.matugenProcess.running) {
            MatugenCacheService.matugenKilled = true
            MatugenCacheService.matugenProcess.signal("SIGKILL")
        }

        // Step 2: run matugen (triggers switchwall automatically)
        Qt.callLater(() => {
                MatugenCacheService.matugenProcess.exec([
                "bash",
                matugenPath,
                WallpaperService.currentFullPath
            ])
        })
    }		

    
    // --- awwwProcess ---
    property QtObject awwwProcess: Io.Process {
       onExited: function(exitCode) {
            if (exitCode !== 0) {
                // NotificationService.show(
                //     "Error",
                //     "Wallpaper failed",
                //     0,
                //     "dialog-error"
                // )
                return
            }

            // NotificationService.show(
            //     "Wallpaper Applied",
            //     WallpaperService.selectedWallpaper + " applied",
            //     9999,
            //     "dialog-information"
            // )
        }
    }
}