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
    
    property color primary: colorData.primary ?? "#ffb4ab"
    property color primaryText: colorData.primaryText ?? "#690005"
    property color primaryContainer: colorData.primaryContainer ?? "#b12723"
    property color primaryContainerText: colorData.primaryContainerText ?? "#ffffff"
    property color primaryForeground: colorData.onPrimary ?? "#690005"
    
    property color secondary: colorData.secondary ?? "#ffb4ab"
    property color secondaryText: colorData.secondaryText ?? "#5b1915"
    property color secondaryContainer: colorData.secondaryContainer ?? "#792f29"
    property color secondaryContainerText: colorData.secondaryContainerText ?? "#ffd7d2"
    
    property color tertiary: colorData.tertiary ?? "#8bceff"
    property color tertiaryText: colorData.tertiaryText ?? "#00344e"
    property color tertiaryContainer: colorData.tertiaryContainer ?? "#006390"
    property color tertiaryContainerText: colorData.tertiaryContainerText ?? "#ffffff"
    
    property color background: colorData.background ?? "#1d100e"
    property color backgroundText: colorData.backgroundText ?? "#f7ddd9"
    property color surface: colorData.surface ?? "#1d100e"
    property color surfaceText: colorData.surfaceText ?? "#f7ddd9"
    property color surfaceVariant: colorData.surfaceVariant ?? "#5a413e"
    property color surfaceVariantText: colorData.surfaceVariantText ?? "#e2beba"
    property color surfaceContainer: colorData.surfaceContainer ?? "#2c1f1d"
    
    property color error: colorData.error ?? "#ffb4ab"
    property color errorText: colorData.errorText ?? "#690005"
    property color errorContainer: colorData.errorContainer ?? "#93000a"
    property color errorContainerText: colorData.errorContainerText ?? "#ffdad6"


    property color outline: colorData.outline ?? "#a98986"
    property color shadow: colorData.shadow ?? "#000000"
    property color inverseSurface: colorData.inverseSurface ?? "#f7ddd9"
    property color inverseSurfaceText: colorData.inverseSurfaceText ?? "#3d2c2b"
    property color inversePrimary: colorData.inversePrimary ?? "#b32824"
}