pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.services

/**
 * GameMode service - detects fullscreen windows and disables effects for performance.
 * 
 * Activates automatically when:
 * - autoDetect is enabled AND
 * - The focused window covers the full output (fullscreen)
 * 
 * Can also be toggled manually via toggle()/activate()/deactivate()
 * Manual state persists to file.
 */
import QtQuick

Singleton {
    id: root

    // Logging helper
    function _log(...args) {
        if (Quickshell.env("QS_DEBUG") === "1") console.log("[HyprlandGameMode]", ...args)
    }

    // -------------------------
    // Public API
    // -------------------------
    property bool active: _manualActive
    property bool manuallyActivated: _manualActive

    // Internal state
    property bool _manualActive: false

    // -------------------------
    // IPC handler (optional)
    // -------------------------
    IpcHandler {
        target: "hyprgamemode"
        function toggle() { root.toggle() }
        function activate() { root.activate() }
        function deactivate() { root.deactivate() }
        function status() { root._log("active:", root.active) }
    }

    // -------------------------
    // Actions
    // -------------------------
    function toggle() {
        _manualActive = !_manualActive
        _applyHyprlandState(_manualActive)
        _saveState()
        _log("Toggled manually:", _manualActive)
    }

    function activate() {
        _manualActive = true
        _applyHyprlandState(true)
        _saveState()
        _log("Activated manually")
    }

    function deactivate() {
        _manualActive = false
        _applyHyprlandState(false)
        _saveState()
        _log("Deactivated manually")
    }

    // -------------------------
    // Apply Hyprland GameMode changes
    // -------------------------
    function _applyHyprlandState(enable) {
        if (enable) {
            Quickshell.execDetached(["hyprctl", "--batch",
                "keyword animations:enabled 0;" +
                "keyword decoration:shadow:enabled 0;" +
                "keyword decoration:blur:enabled 0;" +
                "keyword general:gaps_in 0;" +
                "keyword general:gaps_out 0;" +
                "keyword general:border_size 1;" +
                "keyword decoration:rounding 0;" +
                "keyword general:allow_tearing 1"
            ])
        } else {
            Quickshell.execDetached(["hyprctl", "--batch",
                "keyword animations:enabled 1;" +
                "keyword decoration:shadow:enabled 1;" +
                "keyword decoration:blur:enabled 1;" +
                "keyword general:gaps_in 5;" +
                "keyword general:gaps_out 10;" +
                "keyword general:border_size 2;" +
                "keyword decoration:rounding 8;" +
                "keyword general:allow_tearing 0"
            ])
        }
    }

    // -------------------------
    // State persistence
    // -------------------------
    readonly property string _stateFile: Quickshell.env("HOME") + "/.local/state/quickshell/user/hyprgamemode_active"

    Process {
        id: saveProcess
        running: false
        command: ["/usr/bin/bash", "-c",
            "mkdir -p ~/.local/state/quickshell/user; echo " + (_manualActive ? "1" : "0") + " > " + root._stateFile
        ]
    }

    function _saveState() {
        saveProcess.running = true
    }

    FileView {
        id: stateReader
        path: Qt.resolvedUrl(root._stateFile)

        onLoaded: {
            root._manualActive = (stateReader.text().trim() === "1")
            _log("Loaded state:", root._manualActive)
        }

        onLoadFailed: (err) => {
            root._manualActive = false
            _log("No saved state found")
        }
    }

    Component.onCompleted: {
        stateReader.reload()
    }
}
