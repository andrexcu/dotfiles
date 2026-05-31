pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: colors
    
    property var colorFile: FileView {
        path: Quickshell.env("HOME") + "/.cache/matugen/quickshell-colors.json"
        preload: true
        watchChanges: true
        onFileChanged: this.reload()
    }

    property var colorData: {
        try {
            return JSON.parse(colorFile.text())
        } catch (e) {
            return {}
        }
    }
        property color primary: colorData.primary ?? "#90caf9"
        property color primaryLight: colorData.primaryLight ?? "#bbdefb"
        property color primaryText: colorData.primaryText ?? "#001e3c"
        property color primaryContainer: colorData.primaryContainer ?? "#1976d2"
        property color primaryContainerText: colorData.primaryContainerText ?? "#ffffff"
        property color primaryForeground: colorData.onPrimary ?? "#001e3c"

        property color secondary: colorData.secondary ?? "#64b5f6"
        property color secondaryText: colorData.secondaryText ?? "#0d1b2a"
        property color secondaryContainer: colorData.secondaryContainer ?? "#1565c0"
        property color secondaryContainerText: colorData.secondaryContainerText ?? "#0b3d91"

        property color tertiary: colorData.tertiary ?? "#81d4fa"
        property color tertiaryText: colorData.tertiaryText ?? "#002b3d"
        property color tertiaryContainer: colorData.tertiaryContainer ?? "#0288d1"
        property color tertiaryContainerText: colorData.tertiaryContainerText ?? "#ffffff"

        property color background: colorData.background ?? "#0b1a2a"
        property color backgroundText: colorData.backgroundText ?? "#e3f2fd"
        property color surface: colorData.surface ?? "#0b1a2a"
        property color surfaceText: colorData.surfaceText ?? "#e3f2fd"
        property color surfaceVariant: colorData.surfaceVariant ?? "#1c2c3a"
        property color surfaceVariantText: colorData.surfaceVariantText ?? "#b3cde0"
        property color surfaceContainer: colorData.surfaceContainer ?? "#132030"

        property color error: colorData.error ?? "#ef9a9a"
        property color errorText: colorData.errorText ?? "#3b0a0a"
        property color errorContainer: colorData.errorContainer ?? "#c62828"
        property color errorContainerText: colorData.errorContainerText ?? "#ffffff"

        property color outline: colorData.outline ?? "#6fa8dc"
        property color shadow: colorData.shadow ?? "#000000"
        property color inverseSurface: colorData.inverseSurface ?? "#e3f2fd"
        property color inverseSurfaceText: colorData.inverseSurfaceText ?? "#0d1b2a"
        property color inversePrimary: colorData.inversePrimary ?? "#1976d2"

        // with transparency
        property color backgroundt90: Qt.alpha(colorData.background ?? "#0b1a2a", 0.92)
        property color backgroundt80: Qt.alpha(colorData.background ?? "#0b1a2a", 0.80)
        property color backgroundt70: Qt.alpha(colorData.background ?? "#0b1a2a", 0.70)
        property color backgroundt50: Qt.alpha(colorData.background ?? "#0b1a2a", 0.50)
        property color backgroundt30: Qt.alpha(colorData.background ?? "#0b1a2a", 0.30)
        property color backgroundText70: Qt.alpha(colorData.backgroundText ?? "#0b1a2a", 0.70)

    // property color backgroundt70: Qt.hsla(
    //     Qt.hsla(baseColor).hslSaturation * 0.5,
    //     Qt.hsla(baseColor).hslLightness * 0.5,
    //     0.70
    // )
    // property color primaryContainert90: Qt.alpha(colorData.primaryContainer ?? "#2c1f1d", 0.90)
}