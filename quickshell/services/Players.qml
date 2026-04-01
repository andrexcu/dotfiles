pragma Singleton



import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQml
import qs
import qs.modules.config
import qs.config
import qs.modules.common.components.misc
import qs.modules.common
import qs.modules.common.functions
import qs.services


Singleton {
    id: root

    readonly property list<MprisPlayer> list: MprisController.displayPlayers

    readonly property MprisPlayer active: props.manualActive 
        ?? list[0] 
        ?? null

    property bool lastUserPaused: false 
    property bool lastUserPlayed: false 
    property bool isLoading: false
    
    property alias manualActive: props.manualActive

    

    property MprisPlayer readyActive: _readyActiveBacking
    
    property MprisPlayer _readyActiveBacking: (active && (active.trackTitle || active.metadata?.title)) ? active : null
    
    Timer {
        interval: 300
        repeat: true
        running: true
        onTriggered: {
            const candidate = list.find(p => hasMedia(p))

            if (!candidate) return
            
            if (!isPlayerAlive(_readyActiveBacking)) {
            // _readyActiveBacking = candidate
             _readyActiveBacking = candidate ?? null
            } else if (!hasMedia(_readyActiveBacking) && hasMedia(candidate)) {
                // Only replace if a BETTER player exists
                _readyActiveBacking = candidate
            
      
            }
        }
    }
    // property MprisPlayer player: active
    property MprisPlayer player: readyActive
    Connections {
        target: MprisController
        function onDisplayPlayersChanged() {
           if (playerConnections.target && !isPlayerAlive(playerConnections.target)) {
                playerConnections.target = null
            }
        }
    }

    property real _positionCache: 0
    readonly property bool isYtMusicPlayer: MprisController.isYtMusicActive
    readonly property string effectiveTitle: isYtMusicPlayer ? YtMusic.currentTitle : (player?.trackTitle ?? "")
    readonly property string effectiveArtist: isYtMusicPlayer ? YtMusic.currentArtist : (player?.trackArtist ?? "")
    readonly property string effectiveArtUrl: isYtMusicPlayer ? YtMusic.currentThumbnail : (player?.trackArtUrl ?? "")
    // readonly property real effectivePosition: isYtMusicPlayer ? YtMusic.currentPosition : (player?.position ?? 0)
    
    function hasMedia(mplayer: MprisPlayer): bool {
        if (!mplayer) return false

        const title = mplayer.trackTitle ?? ""
        // const artist = mplayer.trackArtist ?? ""
        const art = mplayer.trackArtUrl ?? ""

        return title.length > 0 && (art.length > 0 || mplayer.isPlaying)
    }
    
    Connections {
        target: YtMusic
        function onCurrentThumbnailChanged() {
            if (isYtMusicPlayer) {
                updateArtAndInfo()
            }
        }
    }
    readonly property real effectivePosition:
    isYtMusicPlayer
        ? YtMusic.currentPosition
        : _positionCache

    
    Timer {
        interval: 1000
        repeat: true
        running: effectiveIsPlaying

        onTriggered: {
            if (!isPlayerAlive(player)) return
            if (isYtMusicPlayer) return
            if (player) {
                _positionCache += 1
            }
        }
    }




    readonly property real effectiveLength: isYtMusicPlayer ? YtMusic.currentDuration : (player?.length ?? 0)
    readonly property bool effectiveIsPlaying: isYtMusicPlayer ? YtMusic.isPlaying : (player?.isPlaying ?? false)
    readonly property bool effectiveCanSeek: isYtMusicPlayer ? YtMusic.canSeek : (player?.canSeek ?? false)
    readonly property bool hasPlayer: (player && player.trackTitle) || (isYtMusicPlayer && YtMusic.currentVideoId)
    
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: effectiveArtUrl ? Qt.md5(effectiveArtUrl) : ""
    property string artFilePath: artFileName ? `${artDownloadLocation}/${artFileName}` : ""
    property bool downloaded: false
    // property string displayedArtFilePath: downloaded ? Qt.resolvedUrl(artFilePath) : ""
    property int _downloadRetryCount: 0
    readonly property int _maxRetries: 3
    

    property string displayedArtFilePath: ""
    property string currentVisibleTitle: ""
    property string currentVisibleArtist: ""
    property string pendingArtUrl: ""
   
    Timer {
    id: artUpdateTimer
    interval: 50
    repeat: false
    onTriggered: updateArtAndInfoImmediate()
    }

    function updateArtAndInfo() {
        artUpdateTimer.restart()
    }

    function updateArtAndInfoImmediate() {
        Qt.callLater(() => {   // <-- delays execution to avoid racing with MPRIS
            const current = player
            if (!current) return

            const newArtUrl = current.trackArtUrl
            if (!newArtUrl) return

            if (newArtUrl === pendingArtUrl && downloaded) return
            pendingArtUrl = newArtUrl

            const fileName = Qt.md5(newArtUrl)
            const coverFilePath = `${artDownloadLocation}/${fileName}`

            artFileName = fileName
            artFilePath = coverFilePath

            if (coverArtDownloader.running && targetFile === newArtUrl) return

            coverArtDownloader.targetFile = newArtUrl
            coverArtDownloader.artFilePath = coverFilePath
            coverArtDownloader.running = true
        })
    }
    // function updateArtAndInfo() {
    //     const current = player
    //     if (!current) return;

    //     const newArtUrl = isYtMusicPlayer
    //         ? YtMusic.currentThumbnail
    //         : current.trackArtUrl

    //     if (!newArtUrl)
    //         return

    //     if (newArtUrl === pendingArtUrl && downloaded)
    //         return
    //     pendingArtUrl = newArtUrl

    //     const fileName = Qt.md5(newArtUrl)
    //     const coverFilePath = `${artDownloadLocation}/${fileName}`

    //     artFileName = fileName
    //     artFilePath = coverFilePath

    //     if (coverArtDownloader.running && targetFile === newArtUrl) return

    //     coverArtDownloader.targetFile = newArtUrl
    //     coverArtDownloader.artFilePath = coverFilePath
    //     coverArtDownloader.running = true
    // }

    function isPlayerReady(player) {
        return player && player.trackTitle && player.trackTitle.length > 0
    }


    Connections {
        id: playerConnections
        target: null
        ignoreUnknownSignals: true

      function safeUpdate(callback) {
            if (!isPlayerAlive(player)) return
            try { callback() } 
            catch(e) { console.warn("Skipped update due to dead MPRIS service:", e) }
        }

        function onPositionChanged() {
        Qt.callLater(() => {
            if (!isPlayerAlive(player)) {
                playerConnections.target = null
                return
            }

            // ⚠️ safest possible guarded access
            let pos
            try {
                pos = player.position
            } catch (e) {
                playerConnections.target = null
                return
            }

            if (pos !== undefined && pos !== null) {
                _positionCache = pos
            }
        })
        }


        function onMetadataChanged() {
            safeUpdate(() => {
                currentVisibleTitle = StringUtils.cleanMusicTitle(player.trackTitle)
                currentVisibleArtist = player.trackArtist
                updateArtAndInfo()
            })
        }

        function onTrackArtUrlChanged() {
            safeUpdate(() => {
                _downloadRetryCount = 0
                updateArtAndInfo()
            })
        }
    }

    function checkAndDownloadArt() {
        if (!root.effectiveArtUrl) {
            downloaded = false
            _downloadRetryCount = 0
            return
        }
        // artExistsChecker.running = true
    }

    function retryDownload() {
        if (_downloadRetryCount < _maxRetries && root.effectiveArtUrl) {
            _downloadRetryCount++
            retryTimer.start()
        }
    }

    Timer {
        id: retryTimer
        interval: 1000 * root._downloadRetryCount
        repeat: false
        onTriggered: {
            if (root.effectiveArtUrl && !root.downloaded) {
                coverArtDownloader.targetFile = root.effectiveArtUrl
                coverArtDownloader.artFilePath = root.artFilePath
                coverArtDownloader.running = true
            }
        }
    }
    Process {
        id: coverArtDownloader
        property string targetFile
        property string artFilePath
        command: ["/usr/bin/bash", "-c", `
            target="$1"
            out="$2"
            dir="$3"
            
            if [ -f "$out" ]; then exit 0; fi
            mkdir -p "$dir"
            tmp="$out.tmp"
            /usr/bin/curl -sSL --connect-timeout 10 --max-time 30 "$target" -o "$tmp" && \
            [ -s "$tmp" ] && /usr/bin/mv -f "$tmp" "$out" || { rm -f "$tmp"; exit 1; }
        `, 
        "_", 
        targetFile, 
        artFilePath, 
        root.artDownloadLocation
        ]
        onExited: (exitCode) => {
            if (exitCode === 0) {

                // ❗ Ignore outdated downloads
                if (targetFile !== pendingArtUrl) {
                    // A newer request exists → skip applying this result
                    if (pendingArtUrl) {
                        targetFile = pendingArtUrl
                        artFilePath = `${artDownloadLocation}/${Qt.md5(pendingArtUrl)}`
                        running = true
                    }
                    return
                }

                // ✅ Only apply if it's still the latest
                downloaded = true
                displayedArtFilePath = Qt.resolvedUrl(artFilePath)
                _downloadRetryCount = 0

                // ✅ If another new one came during this exact moment
                if (pendingArtUrl && pendingArtUrl !== targetFile) {
                    targetFile = pendingArtUrl
                    artFilePath = `${artDownloadLocation}/${Qt.md5(pendingArtUrl)}`
                    running = true
                }

            } else {
                downloaded = false

                // ❗ Avoid retrying outdated URL
                if (targetFile === pendingArtUrl) {
                    retryDownload()
                }
            }
        }
    }
       
    

    // visibility

    property MprisPlayer stablePlayer: null

    function updateStable() {
        const activeStable = root.active

        if (activeStable) {
            stablePlayer = activeStable
            return
        }
        if (list.length > 0) {
            stablePlayer = list[0]
            return
        }

        stablePlayer = null
    }

    Connections {
        target: root

        function onPlayerChanged() {
            updateStable()
            playerConnections.target = player
             _positionCache = 0
            // Show whatever is currently available immediately
            currentVisibleTitle = player?.trackTitle
                ? StringUtils.cleanMusicTitle(player.trackTitle)
                : currentVisibleTitle   // 👈 KEEP OLD if empty

            currentVisibleArtist = player?.trackArtist
                ? player.trackArtist
                : currentVisibleArtist  // 👈 KEEP OLD if empty

            pendingArtUrl = ""
            _downloadRetryCount = 0
            updateArtAndInfo()
        }
    }


    Component.onCompleted: {
        updateStable()
        updateArtAndInfo()
    }
     
    property int currentLoopState: 0  // 0 = no loop, 1 = looping
        

    function toggleLoopState() {

        
        if (isYtMusicPlayer) { 
            YtMusic.cycleRepeatMode()
        } else {
            // const next = currentLoopState === 0 ? 1 : 0
            const next = (MprisController.loopState + 1) % 3
            MprisController.setLoopState(next)
        }

        
        
    }

    Connections {
        target: MprisController
        function onLoopStateChanged() {
            if(!isYtMusicPlayer) {
                currentLoopState = MprisController.loopState
                console.log("MPRIS loop state changed, now:", currentLoopState)
            }  
        }
    }

    Connections {
        target: YtMusic
        function onRepeatModeChanged() {
            currentLoopState = YtMusic.repeatMode
            console.log("ytmusic repeat mode changed, now:", currentLoopState)
        }
    }

    function isPlayerAlive(player) {
        return player && root.list.includes(player)
    }        

    PersistentProperties { id: props; property MprisPlayer manualActive; reloadableId: "players" }
      
}


