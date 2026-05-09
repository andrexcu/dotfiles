pragma Singleton
import QtQuick
import Quickshell
import Qt.labs.folderlistmodel
import qs
import qs.services

QtObject {
    id: watcherService
    property int current: WallpaperService.relevantCount()
    property int total: WatcherService.wallpaperModel.count
    property bool thumbsGenerated: current === total
    property bool pathEmpty: total === 0

    property FolderListModel thumbModel: FolderListModel {
        // folder: Config.cacheDir
        nameFilters: ["*.png"]
        showDirs: false
        showHidden: false
        sortField: FolderListModel.Name
    }

    property FolderListModel wallpaperModel: FolderListModel {
        folder: Config.options.wallpaperDir 
        nameFilters: [ "*.png", "*.jpg" ]
        showDirs: false
        showHidden: false
        sortField: FolderListModel.Name
    }



    property Connections _thumbCon: Connections {
        target: WatcherService.thumbModel       

        function onCountChanged() {

            // let current = WallpaperService.relevantCount()
            // let total = WatcherService.wallpaperModel.count
            console.log("thumbs updated:", current, "/", total)
            
        }
    }
    
    property Connections _setupCon: Connections { 
		target: WatcherService.wallpaperModel
		function onStatusChanged() {
			const m = target

			if (m.status !== FolderListModel.Ready)
				return

			console.log("Wallpapers loaded: " + m.count)

			if (m.count > 0) {
				// lastError = ""
				WallpaperService.startListingFromModel()
				// wallpaperController.requestFrame()
			} else {
				// lastError = "No wallpapers found in " + Config.options.wallpaperDir
			}
		}
	}
    
    property Connections _pathCon: Connections {
        target: Config.options
        function onWallpaperDirChanged() {
            WatcherService.wallpaperModel.folder = 
			"file://" + Config.options.wallpaperDir
        }
    }
}