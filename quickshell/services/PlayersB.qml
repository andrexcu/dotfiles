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

// readonly property MprisPlayer active: props.manualActive 
//     ?? list.find(p => getIdentity(p) === Config.services.defaultPlayer) 
//     ?? list[0] 
//     ?? null
Singleton {
    id: root

    readonly property list<MprisPlayer> list: MprisController.displayPlayers

    // original active
    readonly property MprisPlayer active: props.manualActive 
    ?? list.find(p => hasMedia(p))  // ✅ only pick a player with media
    ?? list.find(p => getIdentity(p) === Config.services.defaultPlayer)
    ?? list[0] 
    ?? null


    property bool lastUserPaused: false 
    property bool lastUserPlayed: false 
    property bool isLoading: false
    
    property alias manualActive: props.manualActive

    function getIdentity(player: MprisPlayer): string {
        const alias = Config.services.playerAliases.find(a => a.from === player.identity);
        return alias?.to ?? player.identity;
    }
  

    readonly property MprisPlayer readyActive: _readyActiveBacking
    property MprisPlayer _readyActiveBacking: null
    // property MprisPlayer _readyActiveBacking: active.trackTitle || active.metadata?.title ? active : null
   
    function hasMedia(player: MprisPlayer): bool {
        if (!player) return false

        const title = player.trackTitle
        const artist = player.trackArtist 
        const art = player.trackArtUrl 

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
 

      // Optional: reactive update when the player list changes
    Connections {
        target: MprisController
        function onDisplayPlayersChanged() {
            // Force evaluation of `active` so `lastKnownActive` can update
            const _ = root.active
        }
    }

    PersistentProperties { id: props; property MprisPlayer manualActive; reloadableId: "players" }
      // Timer {
    //     interval: 150
    //     repeat: true
    //     running: true
    //     onTriggered: {
    //         // Pick first player that has valid media
    //         _readyActiveBacking = list.find(p => hasMedia(p)) ?? null
    //     }
    // }
    //  Timer {
    //     interval: 150
    //     repeat: true
    //     running: true
    //     onTriggered: {
    //         if (!active) {
    //             _readyActiveBacking = null
    //         } else {
    //             const title = (active.trackTitle || active.metadata?.title || "").trim()
    //             _readyActiveBacking = title.length > 0 ? active : null
    //         }
    //     }
    // }
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
        function playPause(): void { if (active?.canTogglePlaying) active.togglePlaying() }
        function previous(): void { if (active?.canGoPrevious) active.previous() }
        function next(): void { if (active?.canGoNext) active.next() }
        function stop(): void { active?.stop() }
    }

  
}
   // Timer {
    //     interval: 150
    //     repeat: true
    //     running: true
    //     onTriggered: {
    //         if (!active) {
    //             _readyActiveBacking = null
    //         } else {
    //             const title = (active.trackTitle || active.metadata?.title || "").trim()
    //             _readyActiveBacking = title.length > 0 ? active : null
    //         }
    //     }
    // }