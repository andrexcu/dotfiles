import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Effects
import QtCore
import Quickshell.Wayland
import qs.components
import Quickshell
import Quickshell.Io as Io
import Quickshell.Hyprland
import QtQuick.Window
import Quickshell.Widgets
import qs.colors
import Qt.labs.platform
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import qs
import qs.services

Item {
    id: hexItem
    // z: isSelected ? 2 : 1

    property var controller
    property var container
    property var flickRef
    // property var repeater
 
    property bool isSelected: controller.currentIndex === index

   
    width: container.cellWidth - 10
    height: container.cellHeight - 10
  
    property bool imageReady: thumbImage.status === Image.Ready && thumbImage.paintedWidth > 0
        
    property bool isHidden: false

    property real baseX: container.itemX(index)
    property real baseY: container.itemY(index)

    
    property real targetX: baseX + shiftX
	
    
    function computeShiftX() {
        var selIndex = controller.currentIndex
        if (index === selIndex) return 0

        // If selected hex is scaled to 0 (offscreen), don't give space
        
        if (!controller.selectedVisual || controller.selectedVisual.visualScale < 1) return 0;

        var cols = container.columns
        var selRow = Math.floor(selIndex / cols)
        var selCol = selIndex % cols
        var row = Math.floor(index / cols)
        var col = index % cols

        // Left side of selection
        if (col < selCol || 
            (row < selRow && col <= selCol - (selRow % 2 === 0 ? 1 : 0)) || 
            (row > selRow && col <= selCol - (selRow % 2 === 0 ? 1 : 0)))
            return -20

        // Right side of selection
        if (col > selCol || 
            (row < selRow && col >= selCol + (selRow % 2 === 0 ? 0 : 1)) ||
            (row > selRow && col >= selCol + (selRow % 2 === 0 ? 0 : 1)))
            return 20

        return 0
    }			

    function updateShift() {
        shiftX = computeShiftX()
        shiftY = computeShiftY()
    }
    
    Connections {
        target: controller.currentSelected
                ? controller.currentSelected.visualWrapperRef
                : null

        function onVisualScaleChanged() {
          
            container.updateGridFocusOffset() 
            updateShift()
            // width = container.cellWidth - 10
            // height = container.cellWidth - 10
        }
    }
    
    // Update shiftX and scale all at start
   
    // Component.onCompleted: {
    //     if (repeater.count > 0) {
            
    //         controller.currentSelected = repeater.itemAt(controller.currentIndex)
    //     }
    // }

    property real targetY: baseY + shiftY
    function computeShiftY() {
        var selIndex = controller.currentIndex
        if (index === selIndex) return 0

        // If selected hex is scaled to 0 (offscreen), don't give space
        // var controller.selectedVisual = controller.currentSelected?.visualWrapperRef;
        if (!controller.selectedVisual || controller.selectedVisual.visualScale === 0) return 0;

        var cols = container.columns
        var selRow = Math.floor(selIndex / cols)
        var row = Math.floor(index / cols)

        if (row < selRow) return -10
        if (row > selRow) return 10
        return 0
    }

    x: targetX

    y: targetY
    
    Behavior on x {
        enabled: flickRef.firstUpdateDone
        NumberAnimation {
            duration: 400
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
        }
    }

    Behavior on y {
        enabled: flickRef.firstUpdateDone
        NumberAnimation {
            duration: 400
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
        }
    }
                        
    
    property bool hiddenRow: false
    property alias visualWrapperRef: visualWrapper

    property real shiftX: 0
    property real shiftY: 0
// property var selIndex: controller.currentIndex
// property int generation: getGeneration(index, selIndex)

// property real scaleTarget: getScale(generation)

// property var shift: computeShift(index, selIndex)


    // function getGridPos(i) {
    // 	var cols = container.columns
    // 	return {
    // 		x: i % cols,
    // 		y: Math.floor(i / cols)
    // 	}
    // }

    // function getGeneration(index, selIndex) {
    // 	var a = getGridPos(index)
    // 	var b = getGridPos(selIndex)

    // 	var dx = a.x - b.x
    // 	var dy = a.y - b.y

    // 	// grid distance (simple approximation)
    // 	return Math.max(Math.abs(dx), Math.abs(dy))
    // }
    // function getScale(gen) {
    // 	if (gen === 0) return 1.15
    // 	if (gen === 1) return 1.0
    // 	if (gen === 2) return 0.85
    // 	if (gen === 3) return 0.7
    // 	return 0.65
    // }

    
    /* FUNCTIONS FOR TESTING:

    ** BOOLEAN TO IDENTIFY WHICH DIRECTION THE HEXAGON IS POSITIONED
    ** INCLUDING ALL ADJACANT TO THE SELECTED NEIGHBORS HEXAGON

    property bool moveLeft: {
        var selected = controller.currentIndex
        var totalCols = container.columns
        var selRow = Math.floor(selected / totalCols)
        var selCol = selected % totalCols

        var row = Math.floor(index / totalCols)
        var col = index % totalCols

        if (index === selected) return false

        // 1. Left hexes in same row
        if (row === selRow && col < selCol) return true

        // 2. Upper-left column relative to selected
        if (row < selRow) {
            var offset = (selRow % 2 === 0) ? -1 : 0
            if (col <= selCol + offset) return true
        }

        // 3. Lower-left column relative to selected
        if (row > selRow) {
            var offset = (selRow % 2 === 0) ? -1 : 0
            if (col <= selCol + offset) return true
        }

        return false
    }

    property bool moveRight: {
        var selected = controller.currentIndex
        var totalCols = container.columns
        var selRow = Math.floor(selected / totalCols)
        var selCol = selected % totalCols

        var row = Math.floor(index / totalCols)
        var col = index % totalCols

        if (index === selected) return false

        // 1. Right hexes in same row
        if (row === selRow && col > selCol) return true

        // 2. Upper-right column relative to selected
        if (row < selRow) {
            var offset = (selRow % 2 === 0) ? 0 : 1
            if (col >= selCol + offset) return true
        }

        // 3. Lower-right column relative to selected
        if (row > selRow) {
            var offset = (selRow % 2 === 0) ? 0 : 1
            if (col >= selCol + offset) return true
        }

        return false
    }

    ** 6 NEIGHBOR HEXAGONS OF THE CURRENTLY SELECTED
    */
    property bool isNeighbor: {
        var selected = controller.currentIndex
        var totalColumns = container.columns
        var row = Math.floor(index / totalColumns)
        var col = index % totalColumns
        var selectedRow = Math.floor(selected / totalColumns)
        var selectedCol = selected % totalColumns

        if (index === selected) return false  // selected itself is not a neighbor

        // Left / Right neighbors in the same row
        if (row === selectedRow && (col === selectedCol - 1 || col === selectedCol + 1)) return true

        // Row above (upper-left / upper-right)
        if (row === selectedRow - 1) {
            if (selectedRow % 2 === 0) { // even selected row
                if (col === selectedCol - 1 || col === selectedCol) return true
            } else { // odd selected row
                if (col === selectedCol || col === selectedCol + 1) return true
            }
        }

        // Row below (lower-left / lower-right)
        if (row === selectedRow + 1) {
            if (selectedRow % 2 === 0) { // even selected row
                if (col === selectedCol - 1 || col === selectedCol) return true
            } else { // odd selected row
                if (col === selectedCol || col === selectedCol + 1) return true
            }
        }

        return false
    } 
    function getHexPos(i) {
        var cols = container.columns

        var row = Math.floor(i / cols)
        var col = i % cols

        // offset correction (odd-row shift)
        var x = col - Math.floor(row / 2)
        var y = row

        return { x: x, y: y }
    }
    function hexDistance(a, b) {
        var dx = a.x - b.x
        var dy = a.y - b.y
        var dz = -dx - dy

        return Math.max(Math.abs(dx), Math.abs(dy), Math.abs(dz))
    }

    property int gen: {
        var sel = controller.currentIndex
        if (index === sel) return 0

        var a = getHexPos(index)
        var b = getHexPos(sel)

        return hexDistance(a, b)
    }
    property real scaleTarget: {
        if (gen === 0) return 1.15

        // smooth falloff
        return Math.max(0.6, 1.05 - gen * 0.18)
    }

// property int gen: hexDistance(
//     getHexPos(index),
//     getHexPos(controller.currentIndex)
// )
    
        Item {
        id: visualWrapper
        // property real baseY: 0
        // property real yOffset: 0

        // y: baseY + yOffset

        // Connections {
        //     target: hexItem
        //     function onBaseYChanged() {
        //         visualWrapper.baseY = hexItem.baseY
        //     }
        // }
        width: parent.width
        height: parent.height
        property alias flipAnim: flipAnim
        // Behavior on yOffset {
        //     NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        // }
        // property real baseWidth: container.cellWidth - 10
        // property real baseHeight: container.cellHeight - 10

        // property real visualWidth: baseWidth
        // property real visualHeight: baseHeight

   


        // Behavior on visualWidth {
        //     NumberAnimation {
        //         duration: 180
        //         easing.type: Easing.OutCubic
        //     }
        // }

        // Behavior on visualHeight {
        //     NumberAnimation {
        //         duration: 180
        //         easing.type: Easing.OutCubic
        //     }
        // }
        // width: parent.width
        // height: parent.height
   
        property real fadeOpacity: 0
        property real visualScale: 0
    
        scale: visualScale	

        opacity: fadeOpacity


        
        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
        
        // onXChanged: {}
         

        Behavior on scale {
            enabled: flickRef.firstUpdateDone
               NumberAnimation {
                duration: 350

                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
            }
            // SpringAnimation {
            //     spring: 6
            //     damping: 0.9 
            // }
            // Anim {
            //     // animCurve: AnimList.curves.emphasizedAccel
            //     // animDuration: AnimList.durations.expressiveDefaultSpatial
            // }
        }

        Behavior on opacity { 
            enabled: flickRef.firstUpdateDone
            NumberAnimation { 
                duration: 400; 
                easing.type: Easing.InOutQuad 
            } 
        }
            

        transform: Rotation {
            id: yRotation
            origin.x: visualWrapper.width / 2
            origin.y: visualWrapper.height / 2
            axis { x: 0; y: 1; z: 0 }
            angle: visualWrapper.flipAngle
        }
        //  property real enterOffsetY: 0

    // transform: Translate {
    //     y: visualWrapper.enterOffsetY
    // }

    // Behavior on enterOffsetY {
    //     NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    // }
        property real flipAngle: 0


        NumberAnimation {
            id: flipAnim
            target: visualWrapper
            property: "flipAngle"
            duration: 300
            easing.type: Easing.InOutQuad
        }
        
        property bool isSelected: false

   


    Image {
        id: thumbImage
        fillMode: Image.PreserveAspectCrop
        anchors.fill: parent
        anchors.centerIn: parent
        asynchronous: true
        sourceSize.width: width
        sourceSize.height: height
        property string thumbName: WallpaperCacheService.thumbnailPaths[modelData] || ""
        source: (WallpaperCacheService.thumbData && WallpaperCacheService.thumbData[thumbName])
                ? ("file://" + Config.cacheDir + "/" + thumbName)
                : ""
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: wallpaperController.currentIndex === index && 
            wallpaperController.blurTransition ? 1 : 0
            blurMax: 32
            Behavior on blur {
                enabled: true
                NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
            }
        }
    }


    



        // Image {
        // 	id: currentImage
        // 	anchors.fill: parent
        // 	fillMode: Image.PreserveAspectCrop
        // 	asynchronous: true
        // 	source: coverArtContainer.currentSource
        // 	opacity: 1

        // 	property real blurLevel: 0
        // 	layer.enabled: Appearance.effectsEnabled
        // 	layer.effect: MultiEffect {
        // 		blurEnabled: true
        // 		blur: currentImage.blurLevel
        // 		blurMax: 32
        // 		Behavior on blur { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
        // 	}
        // }
// Rectangle {
//     anchors.fill: parent
//     visible: controller.cardVisible && !fadeInAnim.running

//     color: {
//         if (gen === 0) return "transparent"   // selected
//         if (gen === 1) return "red"
//         if (gen === 2) return "orange"
//         if (gen === 3) return "yellow"
// 		if (gen === 4) return "blue"
// 		if (gen === 5) return "green"
// 		if (gen === 6) return "violet"
// 		if (gen === 7) return "purple"
//         return "blue"
//     }

//     Behavior on opacity {
//         NumberAnimation {
//             duration: 200
//             easing.type: Easing.InOutQuad
//         }
//     }
// }
        // Rectangle {
        // 	anchors.fill: parent
        // 	visible: controller.cardVisible && !fadeInAnim.running
        // 	color: isSecondGen ? "red" : "transparent"
        // 	Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
        // }
        Rectangle {
            anchors.fill: parent
            visible: hexItem.controller.cardVisible && !fadeInAnim.running
            color: "#000000"
            
            opacity: hexItem.controller.currentIndex === index
            ? 0.6: 0
            // : ((!controller.selectedVisual || controller.selectedVisual.visualScale < 1) ? 0 : Math.min(0.6, gen * 0.12))
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
        }
        

        layer.enabled: true
        layer.smooth: true
        
        layer.effect: OpacityMask {
            maskSource: Shape {
                width: visualWrapper.width
                height: visualWrapper.height
                anchors.centerIn: parent
                preferredRendererType: Shape.CurveRenderer
                antialiasing: true
                
                ShapePath {
                    fillColor: "white"
                    strokeColor: fillColor
                    strokeWidth: 0
                    PathMove { x: width * 0.5; y: 0 }
                    PathLine { x: width; y: height * 0.25 }
                    PathLine { x: width; y: height * 0.75 }
                    PathLine { x: width * 0.5; y: height }
                    PathLine { x: 0; y: height * 0.75 }
                    PathLine { x: 0; y: height * 0.25 }
                    PathLine { x: width * 0.5; y: 0 }
                }
            }
        }
    }
    

    MouseArea {
        anchors.fill: parent
        enabled: visualWrapperRef.visualScale > 0 
        && visualWrapperRef.fadeOpacity > 0
        
        onClicked: {
            controller.currentIndex = index
            Qt.callLater(() => flickRef.forceActiveFocus())
        }

        onDoubleClicked: WallpaperApplyService.applyWallpaper(modelData)
    }
}