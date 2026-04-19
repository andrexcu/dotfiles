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
    property int itemIndex
    property var itemData
    property var hexBorder
    // property real targetX
    // property real targetY
   
    property bool inView
    property bool isSelected: controller.currentIndex === itemIndex
    property bool rippleOff
    property real originFixY
    width: container.cellWidth - 10
    height: container.cellHeight - 10
  
    property bool imageReady: thumbImage.status === Image.Ready && thumbImage.paintedWidth > 0
    property int currentScale
    property bool isHidden: false
    property var ripple
    property bool hasEntered: false

    property real enterT: inView ? 0 : 1
 
   function clamp(v) {
        return Math.sign(v) * Math.min(Math.abs(v), 2)
    }
  
    property point globalPos: mapToItem(highlightContainer, 0, 0)
    property real globalX: globalPos.x
    property real globalY: globalPos.y

    property real layoutX: clamp(dx) * 30 * enterT
    property real layoutY: clamp(dy) * 30 * enterT

//    property real dirX: dx / Math.max(1, Math.abs(dx) + Math.abs(dy))
//     property real dirY: dy / Math.max(1, Math.abs(dx) + Math.abs(dy))

//     property real d: Math.sqrt(dx*dx + dy*dy)
//     property real k: Math.min(1, d / 2)

    // property real layoutX: dirX * 80 * k * enterT
    // property real layoutY: dirY * 80 * k * enterT

    // property real dist: Math.min(2, Math.sqrt(dx*dx + dy*dy))

    // property real layoutX: dx * dist * 10 * enterT
    // property real layoutY: dy * dist * 10 * enterT
    // property real layoutX:0
    // property real layoutY: 0

    property real targetX: flick.baseX(itemIndex) + layoutX + (rippleOff ? 0 : ripple.x)
    property real targetY: flick.baseY(itemIndex) + layoutY + (rippleOff ? 0 : ripple.y)
    x: targetX
    y: targetY

    // onXChanged: {
    //     console.log("hexItem X position: ", x)
    // }
    // y: flick.baseY(itemIndex) + ripple.y + originFixY * (1 - scale)
    // property real layoutX: 0
    // property real layoutY: 0
    // targetX: !rippleOff ?
    // flick.baseX(itemIndex) + layoutX + ripple.x : flick.baseX(itemIndex)

    // targetY: !rippleOff ?
    // flick.baseY(itemIndex) + layoutY + ripple.y : flick.baseY(itemIndex)

   
    // Behavior on scale {
    //     // enabled: flickRef.firstUpdateDone
    //     NumberAnimation {
    //         duration: 400
    //         easing.type: Easing.BezierSpline
    //         easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
    //     }
    // }
    Behavior on targetX {
        NumberAnimation {
                duration: 350
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
                onRunningChanged: {
                    if (!running) {
                        // highlightContainer.updateBorder()
                        // controller.currentItemX = hexItem.x
                        // console.log("final X:", controller.currentItem.x)
                    }
                }
            }
    }

    Behavior on targetY {
        NumberAnimation {
                duration: 350
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
                // onRunningChanged: {
                //     if (!running) {
                //         controller.currentItemY = hexItem.y
                //         console.log("final Y:", controller.currentItemY)
                //     }
                // }
            }
        }

   
    property real _lastTop: -1
    property real _lastBottom: -1
    // Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
    // Component.onCompleted: {
    //     scale = 0
    //     // console.log("i=", itemIndex,
    //     //     "data= ", itemData)
    // }

    // onTargetXChanged: {
    //     controller.registerItem(itemIndex, this)

    // Component.onCompleted: controller.registerItem(flatIndex, this)
    // Component.onDestruction: controller.unregisterItem(flatIndex)

    function computeShiftX() {
        var selIndex = controller.currentIndex
        if (itemIndex === selIndex) return 0

        // If selected hex is scaled to 0 (offscreen), don't give space
        
        if (!controller.selectedVisual || controller.selectedVisual.visualScale < 1) return 0;

        var cols = container.columns
        var selRow = Math.floor(selIndex / cols)
        var selCol = selIndex % cols
        var row = Math.floor(itemIndex / cols)
        var col = itemIndex % cols

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
    
    // Connections {
    //     target: controller.currentSelected
    //             ? controller.currentSelected.visualWrapperRef
    //             : null
                
    //     function onVisualScaleChanged() {
         
    //         updateShift()
    //         container.updateGridFocusOffset() 
    //     }
    // }
    
   
    function computeShiftY() {
        var selIndex = controller.currentIndex
        if (itemIndex === selIndex) return 0

        // If selected hex is scaled to 0 (offscreen), don't give space
        // var controller.selectedVisual = controller.currentSelected?.visualWrapperRef;
        if (!controller.selectedVisual || controller.selectedVisual.visualScale === 0) return 0;

        var cols = container.columns
        var selRow = Math.floor(selIndex / cols)
        var row = Math.floor(itemIndex / cols)

        if (row < selRow) return -10
        if (row > selRow) return 10
        return 0
    }

  
    
    // Behavior on targetY {
    //     // enabled: flickRef.firstUpdateDone
    //     NumberAnimation {
    //         duration: 400
    //         easing.type: Easing.BezierSpline
    //         easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
    //     }
    // }

    // Behavior on targetX {
    //     // enabled: flickRef.firstUpdateDone
    //     NumberAnimation {
    //         duration: 400
    //         easing.type: Easing.BezierSpline
    //         easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
    //     }
    // }
                        
    
    property bool hiddenRow: false
    property alias visualWrapperRef: visualWrapper

    property real shiftX: 0
    property real shiftY: 0

    property bool _visibleState: true

        Shape {
            id: selectedHexBorder
            z: 9999
            visible: isSelected
            // visible: true

            width: container.cellWidth - 10
            height: container.cellHeight - 10

            x: 0
            y: 0

            scale: visualWrapperRef.visualScale
            opacity: 1
            preferredRendererType: Shape.CurveRenderer
            antialiasing: true
            ShapePath {
                strokeWidth: 2
                strokeColor: "#FAF9F6"
                fillColor: "transparent"

                PathMove { x: width * 0.5; y: 0 }
                PathLine { x: width; y: height * 0.25 }
                PathLine { x: width; y: height * 0.75 }
                PathLine { x: width * 0.5; y: height }
                PathLine { x: 0; y: height * 0.75 }
                PathLine { x: 0; y: height * 0.25 }
                PathLine { x: width * 0.5; y: 0 }
            }

            Behavior on scale {
                SpringAnimation { spring: 6; damping: 0.9 }
            }
        }



    //     property bool moveLeft: {
    //     var selected = controller.currentIndex
    //     var totalCols = container.columns
    //     var selRow = Math.floor(selected / totalCols)
    //     var selCol = selected % totalCols

    //     var row = Math.floor(index / totalCols)
    //     var col = index % totalCols

    //     if (index === selected) return false

    //     // 1. Left hexes in same row
    //     if (row === selRow && col < selCol) return true

    //     // 2. Upper-left column relative to selected
    //     if (row < selRow) {
    //         var offset = (selRow % 2 === 0) ? -1 : 0
    //         if (col <= selCol + offset) return true
    //     }

    //     // 3. Lower-left column relative to selected
    //     if (row > selRow) {
    //         var offset = (selRow % 2 === 0) ? -1 : 0
    //         if (col <= selCol + offset) return true
    //     }

    //     return false
    // }

    // property bool moveRight: {
    //     var selected = controller.currentIndex
    //     var totalCols = container.columns
    //     var selRow = Math.floor(selected / totalCols)
    //     var selCol = selected % totalCols

    //     var row = Math.floor(index / totalCols)
    //     var col = index % totalCols

    //     if (index === selected) return false

    //     // 1. Right hexes in same row
    //     if (row === selRow && col > selCol) return true

    //     // 2. Upper-right column relative to selected
    //     if (row < selRow) {
    //         var offset = (selRow % 2 === 0) ? 0 : 1
    //         if (col >= selCol + offset) return true
    //     }

    //     // 3. Lower-right column relative to selected
    //     if (row > selRow) {
    //         var offset = (selRow % 2 === 0) ? 0 : 1
    //         if (col >= selCol + offset) return true
    //     }

    //     return false
    // }

    //     property int dirScore: {
    //         var selected = controller.currentIndex
    //         var cols = container.columns

    //         var sx = selected % cols
    //         var sy = Math.floor(selected / cols)

    //         var x = index % cols
    //         var y = Math.floor(index / cols)

    //         var dx = x - sx
    //         var dy = y - sy

    //         // IMPORTANT: weight horizontal stronger than vertical
    //         return dx * 2 + dy
    //     }
        property bool _registered: false

        // onItemIndexChanged: {
        //     if (_registered) {
        //         controller.unregisterItem(itemIndex)
        //     }

        //     controller.registerItem(itemIndex, this)
        //     _registered = true
        // }
        // onTargetXChanged: {
        //     controller.currentTargetX = targetX
        //     console.log(controller.currentTargetX)
        // }

        // onTargetYChanged: {
        //     controller.currentTargetY = targetY
        //     console.log(controller.currentTargetY)
        // }

        Item {
        id: visualWrapper
  
        width: parent.width
        height: parent.height
         
        property alias flipAnim: flipAnim

     
        // property real fadeOpacity: inView ? 1 : 0
        property real visualScale: isSelected ? 1.12 : 1
        scale: visualScale	
        Behavior on scale {
                // enabled: flickRef.firstUpdateDone
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
                }
            }
        // opacity: fadeOpacity
        
        // Behavior on scale {

        //        NumberAnimation {
        //         duration: 350

        //         easing.type: Easing.BezierSpline
        //         easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
        //     }
       
        // }
        
        // Behavior on opacity { 
       
        //     NumberAnimation { 
        //         duration: 150; 
        //         easing.type: Easing.InOutQuad 
        //     } 
        // }
         
        transform: Rotation {
            id: yRotation
            origin.x: visualWrapper.width / 2
            origin.y: visualWrapper.height / 2
            axis { x: 0; y: 1; z: 0 }
            angle: visualWrapper.flipAngle
        }
 
        property real flipAngle: 0


        NumberAnimation {
            id: flipAnim
            target: visualWrapper
            property: "flipAngle"
            duration: 300
            easing.type: Easing.InOutQuad
        }

    Image {
        id: thumbImage
        fillMode: Image.PreserveAspectCrop
        opacity: inView ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
        anchors.fill: parent
        anchors.centerIn: parent
        asynchronous: true
        sourceSize.width: width
        sourceSize.height: height
        smooth: true
        property string thumbName: WallpaperCacheService.thumbnailPaths[itemData] || ""
        source: (WallpaperCacheService.thumbData && WallpaperCacheService.thumbData[thumbName])
                ? ("file://" + Config.cacheDir + "/" + thumbName)
                : ""
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: wallpaperController.currentIndex === itemIndex && 
            wallpaperController.blurTransition ? 1 : 0
            blurMax: 32
            Behavior on blur {
                enabled: true
                NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
            }
        }
    }

  
        // Rectangle {
        //     anchors.fill: parent
        //     visible: hexItem.controller.cardVisible && !fadeInAnim.running
       
        //   color: {
        //         if (isSelected)
        //             return "transparent"

        //         if (dirScore < 0)
        //             return "red"

        //         return "blue"
        //     }

        //     Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }
        // }
        
        Rectangle {
            anchors.fill: parent
            visible: hexItem.controller.cardVisible && !fadeInAnim.running
            color: "#000000"
            opacity: isSelected
            ? 0.6: 0
            Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }
        }

        // : ((!controller.selectedVisual || controller.selectedVisual.visualScale < 1) ? 0 : Math.min(0.6, gen * 0.12))

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
    
  	// Connections {
    //     target: wallpaperController

    //     function onCurrentIndexChanged() {
    //         controller.currentItem = hexItem

    //         console.log(
	// 		"current index: ", currentIndex,
	// 		// "current item: ", currentItem,
	// 		"current scale: ", currentItem.visualWrapperRef.visualScale,
	// 		// "current opacity: ", currentItem.visualWrapperRef.fadeOpacity
			
	// 		)
    //     }
    // }

    onIsSelectedChanged: {
        if (!isSelected) return

        controller.previousItem = controller.currentItem
        controller.currentItem = hexItem
        
    }

    MouseArea {
        anchors.fill: parent
        // enabled: visualWrapperRef.visualScale > 0 
        // && visualWrapperRef.fadeOpacity > 0
      	onWheel: (wheel) => {
            flick.flick(0, wheel.angleDelta.y * 12) // vertical
            wheel.accepted = true
        }
        onClicked: {
            controller.currentIndex = itemIndex
            Qt.callLater(() => flickRef.forceActiveFocus())
        }

        onDoubleClicked: WallpaperApplyService.applyWallpaper(itemData)
    }
}