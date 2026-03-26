pragma Singleton



import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQml
import Caelestia
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
    // property MprisPlayer _readyActiveBacking: null
    property MprisPlayer _readyActiveBacking: active.trackTitle || active.metadata?.title ? active : null
   
    function hasMedia(mplayer: MprisPlayer): bool {
        if (!mplayer) return false

        const title = mplayer.trackTitle
        const artist = mplayer.trackArtist 
        const art = mplayer.trackArtUrl 

        return title && title.length > 0 && artist && artist.length > 0 && art && art.length > 0
    }

    Timer {
        interval: 150
        repeat: true
        running: true
        onTriggered: {
            const candidate = list.find(p => hasMedia(p))

            if (!candidate) return

            // Only switch if:
            // - nothing is shown yet
            // - OR current readyActive lost media
            if (!_readyActiveBacking || !hasMedia(_readyActiveBacking)) {
                _readyActiveBacking = candidate
            }
        }
    }
 
    // property MprisPlayer player: active
    property MprisPlayer player: readyActive
      // Optional: reactive update when the player list changes
    Connections {
        target: MprisController
        function onDisplayPlayersChanged() {
            // Force evaluation of `active` so `lastKnownActive` can update
            const _ = root.active
        }
    }

    property real _positionCache: player?.position ?? 0
    readonly property bool isYtMusicPlayer: MprisController.isYtMusicActive
    readonly property string effectiveArtUrl: 
        isYtMusicPlayer 
            ? YtMusic.currentThumbnail 
            : (player?.trackArtUrl ?? "")
    // readonly property real effectivePosition: isYtMusicPlayer ? YtMusic.currentPosition : (player?.position ?? 0)
    readonly property real effectivePosition:
    isYtMusicPlayer
        ? YtMusic.currentPosition
        : _positionCache


    Timer {
        interval: 1000
        repeat: true
        running: effectiveIsPlaying

        onTriggered: {
            if (isYtMusicPlayer) return

            if (player) {
                _positionCache += 1
            }
        }
    }

    Connections {
        target: player
        ignoreUnknownSignals: true

        function onPositionChanged() {
            _positionCache = player.position
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
        interval: 100
        repeat: true
        running: true
        onTriggered: {
            const current = player // or Players.readyActive (recommended)
            if (!current) return

            const newTitle = current.trackTitle
            const newArtist = current.trackArtist

            if (newTitle && newTitle.length > 0) {
                root.currentVisibleTitle = StringUtils.cleanMusicTitle(newTitle)
            }

            if (newArtist && newArtist.length > 0) {
                root.currentVisibleArtist = newArtist
            }

            if (current.trackArtUrl) {
                updateArtAndInfo()
            }
        }
    }


    function updateArtAndInfo() {
        const current = player
        if (!current) return;

        const newArtUrl = isYtMusicPlayer
            ? YtMusic.currentThumbnail
            : current.trackArtUrl;

        if (!newArtUrl) return;

        // If the same URL is already displayed and downloaded, do nothing
        if (pendingArtUrl === newArtUrl && downloaded && displayedArtFilePath) return;

        pendingArtUrl = newArtUrl;

        const fileName = Qt.md5(newArtUrl);
        const coverFilePath = `${artDownloadLocation}/${fileName}`;

        artFileName = fileName;
        artFilePath = coverFilePath;

        if (!coverArtDownloader.running) {
            coverArtDownloader.targetFile = pendingArtUrl
            coverArtDownloader.artFilePath = coverFilePath
            coverArtDownloader.running = true
        }
    }


    function isPlayerReady(player) {
        return player && player.trackTitle && player.trackTitle.length > 0
    }


    onPlayerChanged: {
        updateArtAndInfo()
        if (player) _positionCache = player.position ?? 0
        else _positionCache = 0
    }

    Connections {
        target: player
        ignoreUnknownSignals: true

        function onMetadataChanged() { updateArtAndInfo() }
        function onTrackArtUrlChanged() { 
            _downloadRetryCount = 0
            checkAndDownloadArt()
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
                downloaded = true
                // Update displayedArtFilePath immediately for the just-finished download
                displayedArtFilePath = Qt.resolvedUrl(artFilePath)
                _downloadRetryCount = 0

                // If there’s a newer pendingArtUrl, download it next
                if (pendingArtUrl && pendingArtUrl !== targetFile) {
                    targetFile = pendingArtUrl
                    artFilePath = `${artDownloadLocation}/${Qt.md5(pendingArtUrl)}`
                    running = true
                }
            } else {
                downloaded = false
                retryDownload()
            }
        }
        // onExited: (exitCode) => {
        //     if (exitCode === 0) {
        //         downloaded = true
        //         // Only update displayedArtFilePath now
        //         displayedArtFilePath = Qt.resolvedUrl(artFilePath)
        //         _downloadRetryCount = 0

        //         // If a new pending URL appeared while downloading, start it
        //         if (pendingArtUrl !== targetFile) {
        //             targetFile = pendingArtUrl
        //             artFilePath = `${artDownloadLocation}/${Qt.md5(pendingArtUrl)}`
        //             running = true
        //         }
        //     } else {
        //         downloaded = false
        //         retryDownload()
        //     }
        // }
    }

    PersistentProperties { id: props; property MprisPlayer manualActive; reloadableId: "players" }
    
    // Media shortcuts
    CustomShortcut { name: "mediaToggle"; description: "Toggle media playback"
        onPressed: { active?.canTogglePlaying && active.togglePlaying() }
    }

    CustomShortcut { name: "mediaPrev"; description: "Previous track"
        onPressed: { active?.canGoPrevious && active.previous() }
    }

    CustomShortcut { name: "mediaNext"; description: "Next track"
        onPressed: { active?.canGoNext && active.next() }
    }

    CustomShortcut { name: "mediaStop"; description: "Stop media playback"
        onPressed: active?.stop()
    }

    // IPC interface for external scripts
    IpcHandler {
        target: "mpris"

        function getActive(prop: string): string {
            return active ? active[prop] ?? "Invalid property" : "No active player";
        }

        function list(): string {
            return root.list.map(p => root.getIdentity(p)).join("\n");
        }

        function play(): void { if (active?.canPlay) active.play() }
        function pause(): void { if (active?.canPause) active.pause() }
        function togglePlaying(): void { if (active?.canTogglePlaying) active.togglePlaying() }
        function previous(): void { if (active?.canGoPrevious) active.previous() }
        function next(): void { if (active?.canGoNext) active.next() }
        function stop(): void { active?.stop() }
    }
}
