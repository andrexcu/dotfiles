pragma Singleton
import QtQuick
import Quickshell
import Qt.labs.folderlistmodel
import qs

QtObject {
    id: watcherService

    property FolderListModel thumbModel: FolderListModel {
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