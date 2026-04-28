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
    property var controller
    property var container
    property var flickRef
    property int itemIndex
    property var itemData
    property var hexBorder
    property real shiftX
    property real shiftY
    // property real targetX
    // property real targetY
   
    property bool inView
    property bool isSelected: controller.currentIndex === itemIndex
    property bool isPrevious: controller.previousIndex === itemIndex
    property bool rippleOff
    // property real originFixY
    width: container.cellWidth - 10
    height: container.cellHeight - 10
  
    property bool imageReady: thumbImage.status === Image.Ready && thumbImage.paintedWidth > 0
    property int currentScale
    property bool isHidden: false
    property var ripple
    property bool hasEntered: false
    property real rowScale
    property real enterT: inView ? 0 : 1
    property bool entering: _rowScale < 1 && _inView
    
    function clamp(v) {
        return Math.sign(v) * Math.min(Math.abs(v), 2)
    }

    property real layoutX: entering ? 0 : clamp(dx) * 30 * enterT
    property real layoutY: entering ? 0 : clamp(dy) * 30 * enterT
  
    property real targetX:
    flick.baseX(itemIndex)
    + layoutX
    + (entering ? 0 : (rippleOff ? 0 : ripple.x))

    property real targetY:
    flick.baseY(itemIndex)
    + layoutY
    + (entering ? 0 : (rippleOff ? 0 : ripple.y))

    // x: targetX + (entering ? 0 : shiftX)
    // y: targetY + (entering ? 0 : shiftY)
    
    x: targetX + shiftX
    y: targetY + shiftY
      //  property real layoutX: 0
    // property real layoutY: 0
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

    
    // Connections {
    //     target: controller.currentSelected
    //             ? controller.currentSelected.visualWrapperRef
    //             : null
                
    //     function onVisualScaleChanged() {
         
    //         updateShift()
            // container.updateGridFocusOffset() 
    //     }
    // }
    

  
    
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

    //  strokeColor: "#FAF9F6"
    property bool _visibleState: true
    
    Shape {
    id: selectedHexBorder
    
    opacity: _inView && (isSelected || isPrevious)
         ? Math.min(1, selectedHexBorder.t * 1.2)
         : 0

   scale: visualWrapperRef.visualScale

    Behavior on scale {
        NumberAnimation {
            duration: 350
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
        }
    }
    //  Behavior on opacity {
    //     NumberAnimation {
    //         duration: 350
    //         easing.type: Easing.BezierSpline
    //         easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
    //     }
    // }
    
    width: container.cellWidth - 10
    height: container.cellHeight - 10
    z: 9999

    property real t: 0
    property real tt: Math.min(1, selectedHexBorder.t * 1.2)

    property bool active: isSelected
    property bool leaving: isPrevious && !isSelected

    preferredRendererType: Shape.CurveRenderer
    antialiasing: true

    // ======================
    // ANIMATION DRIVER
    // ======================

    NumberAnimation {
        id: anim
        target: selectedHexBorder
        property: "t"
        duration: 350
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
    }

    onActiveChanged: {
        if (!active) return
        anim.stop()
        anim.from = 1
        anim.to = 1
        anim.restart()
    }

    onLeavingChanged: {
        if (!leaving) return
        anim.stop()
        anim.from = 1
        anim.to = 0
        anim.restart()
    }

    // ======================
    // PATHS (ALL USE SELECTEDHEX)
    // ======================

    ShapePath {
        strokeWidth: isSelected ? 2 : 1.125
        strokeColor: Colors.primary
        fillColor: "transparent"

        PathMove { x: width * 0.5; y: 0 }
        PathLine {
            x: width * 0.5 - (width * 0.5) * selectedHexBorder.t
            y: (height * 0.25) * selectedHexBorder.t
        }
    }

    ShapePath {
        strokeWidth: isSelected ? 2 : 1.125
        strokeColor: Colors.primary
        fillColor: "transparent"

        PathMove { x: width * 0.5; y: 0 }
        PathLine {
            x: width * 0.5 + (width * 0.5) * selectedHexBorder.t
            y: (height * 0.25) * selectedHexBorder.t
        }
    }

    ShapePath {
        strokeWidth: isSelected ? 2 : 1.125
        strokeColor: Colors.primary
        fillColor: "transparent"

        PathMove { x: width * 0.5; y: height }
        PathLine {
            x: width * 0.5 - (width * 0.5) * selectedHexBorder.t
            y: height - (height * 0.25) * selectedHexBorder.t
        }
    }

    ShapePath {
        strokeWidth: isSelected ? 2 : 1.125
        strokeColor: Colors.primary
        fillColor: "transparent"

        PathMove { x: width * 0.5; y: height }
        PathLine {
            x: width * 0.5 + (width * 0.5) * selectedHexBorder.t
            y: height - (height * 0.25) * selectedHexBorder.t
        }
    }

    ShapePath {
        strokeWidth: isSelected ? 2 : 1.125
        strokeColor: Colors.primary
        fillColor: "transparent"

        PathMove { x: 0; y: height * 0.25 }
        PathLine {
            x: 0
            y: height * (0.25 + 0.5 * selectedHexBorder.tt)
        }
    }

    ShapePath {
        strokeWidth: isSelected ? 2 : 1.125
        strokeColor: Colors.primary
        fillColor: "transparent"

        PathMove { x: width; y: height * 0.75 }
        PathLine {
            x: width
            y: height * (0.75 - 0.5 * selectedHexBorder.tt)
        }
    }
}

    Shape {
        id: selectedDefaultBorder
        z: 10
        opacity: _inView ? 1 : 0
        // opacity: 
        // _inView && isSelected ? 1 : 0
        // visible: _inView && isSelected
        // visible: false

        width: container.cellWidth - 10
        height: container.cellHeight - 10

        x: 0
        y: 0

        scale: visualWrapperRef.visualScale

        Behavior on scale {
            NumberAnimation {
                duration: 350
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
            }
        }

        Behavior on opacity { 
            NumberAnimation { 
                duration: 350; 
                easing.type: Easing.InOutQuad 
            } 
        }
        
        preferredRendererType: Shape.CurveRenderer
        antialiasing: true
        ShapePath {
            strokeWidth: 1.125
            
            fillColor: "transparent"
            strokeColor: "#4d4d4d"
            PathMove { x: width * 0.5; y: 0 }
            PathLine { x: width; y: height * 0.25 }
            PathLine { x: width; y: height * 0.75 }
            PathLine { x: width * 0.5; y: height }
            PathLine { x: 0; y: height * 0.75 }
            PathLine { x: 0; y: height * 0.25 }
            PathLine { x: width * 0.5; y: 0 }
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
  // property real fadeOpacity: inView ? 1 : 0
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
        Item {
        id: visualWrapper
  
        width: parent.width
        height: parent.height
         
        property alias flipAnim: flipAnim

     
      
        property real visualScale: isSelected ? 1.125 : 1

        scale: visualScale

        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
            }
        }

    property real wave: 0
    property real wavePhase: 0

    transform: [

     
        Rotation {
            id: yRotation
            origin.x: visualWrapper.width / 2
            origin.y: visualWrapper.height / 2
            axis { x: 0; y: 1; z: 0 }
            angle: visualWrapper.flipAngle
        },

        // Rotation {
        //     origin.x: width/2
        //     origin.y: height/2
        //     angle:
        //         Math.sin(visualWrapper.wavePhase * Math.PI * 2) * 3 +
        //         Math.sin(visualWrapper.wavePhase * Math.PI * 4) * 1.2
        // },

        // Scale {
        //     xScale: 1 + visualWrapper.wave * 0.03 + Math.sin(visualWrapper.wavePhase * Math.PI * 6) * 0.005
        //     yScale: 1 - visualWrapper.wave * 0.015 + Math.sin(visualWrapper.wavePhase * Math.PI * 6) * 0.005
        // }
    ]
 
        property real flipAngle: 0


        NumberAnimation {
            id: flipAnim
            target: visualWrapper
            property: "flipAngle"
            duration: 350
            easing.type: Easing.InOutQuad
        }

    // property bool thumbLoaded: false
    // Connections {
    //     target: WatcherService

    //     function onThumbsGeneratedChanged() {
    //         let source = "file://" 
    //             + Config.cacheDir + "/" + thumbImage.thumbName
    //         if (WallpaperCacheService.thumbData[thumbName] || WatcherService.thumbsGenerated) {
    //             thumbImage.source = source
    //         }

    //         console.log("thumb  status:", WatcherService.thumbsGenerated,
    //         "source: ", source)
    //     }
    // }
    // Connections {
    //     target: WallpaperCacheService

    //     function onThumbVersionChanged() {
    //         let thumbName = thumbImage.thumbName
    //         let source = "file://" 
    //             + Config.cacheDir + "/" + thumbName
    //         thumbImage.source = source
     
    //         console.log("thumb  status:", WatcherService.thumbsGenerated,
    //         "source: ", source)
    //     }
    // }

        // anchors.centerIn: parent
    Image {
        id: thumbImage

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop

        opacity: inView ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        asynchronous: true

        sourceSize.width: width
        sourceSize.height: height

        property string thumbName:
            WallpaperCacheService.thumbnailPaths[itemData] || ""

        property bool isSelected:
            wallpaperController.currentIndex === itemIndex

        source: WatcherService.thumbsGenerated
            ? "file://" + Config.cacheDir + "/" + thumbName
            : ""

        // ZOOM EFFECT
        scale: isSelected ? 1.1 : 1.0
        transformOrigin: Item.Center

        Behavior on scale {
            NumberAnimation {
                duration: 350
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.22, 1.0, 0.36, 1.0]
        
            }
        }

        smooth: !isSelected

        layer.enabled: true
        layer.effect: MultiEffect {
        blurEnabled: true

        blur: wallpaperController.currentIndex === itemIndex &&
              wallpaperController.blurTransition ? 1 : 0

        blurMax: 32

        Behavior on blur {
            NumberAnimation {
                duration: 150
                easing.type: Easing.InOutQuad
            }
        }
    }
}
        // source: "file://" + Config.cacheDir + "/" + thumbName
    //    source: {
    //         WallpaperCacheService.thumbVersion   // MUST be used

    //         let name = WallpaperCacheService.thumbnailPaths[itemData]
    //         if (!name) return ""

    //         return "file://" + Config.cacheDir + "/" + name
    //     }
        // source: "file://" + Config.cacheDir + "/" + thumbName
        // source: {
        //     let v = WallpaperCacheService.thumbVersion   // MUST be used

        //     let name = WallpaperCacheService.thumbnailPaths[itemData]
        //     if (!name) return ""

        //     return "file://" + Config.cacheDir + "/" + name + "?v=" + v
        // }

        
        // source: {
        //     WallpaperCacheService.thumbVersion

        //     return "file://" +
        //         Config.cacheDir + "/" +
        //         thumbName +
        //         "?v=" + WallpaperCacheService.thumbVersion
        // }

        // source: ""
        // source: {
        //     WallpaperCacheService.thumbVersion

        //     return "file://" +
        //         Config.cacheDir + "/" +
        //         thumbName +
        //         "?v=" + WallpaperCacheService.thumbVersion
        // }
        // source: {
        //     let name = thumbName
        //     if (!name) return ""

        //     // immediate check (already cached)
        //     if (WatcherService.thumbModel && WatcherService.thumbModel.count > 0) {

        //         for (let i = 0; i < WatcherService.thumbModel.count; i++) {
        //             let n = WatcherService.thumbModel.get(i, "fileName")
        //             if (n === name) {
        //                 return "file://" + Config.cacheDir + "/" + name
        //             }
        //         }
        //     }

        //     // fallback → wait for generation
        //     if (WallpaperCacheService.thumbData[name]) {
        //         return "file://" + Config.cacheDir + "/" + name
        //     }

        //     return ""
        // }
       
        // source: (WallpaperCacheService.thumbData && WallpaperCacheService.thumbData[thumbName])
        // ? "file://" + Config.cacheDir + "/" + thumbName
        // : ""

        // source: (WallpaperCacheService.thumbData && WallpaperCacheService.thumbData[thumbName])
        //         ? ("file://" + Config.cacheDir + "/" + thumbName)
        //         : ""
        //  source: (WallpaperCacheService.thumbData && WallpaperCacheService.thumbData[thumbName])
        //         ? ("file://" + Config.cacheDir + "/" + thumbName)
        //         : ""
        // source: thumbName !== ""
        // ? ("file://" + Config.cacheDir + "/" + thumbName)
        // : ""


  

        
        Rectangle {
            anchors.fill: parent
            visible: hexItem.controller.cardVisible && !fadeInAnim.running
            color: "#000000"
            opacity: isSelected
            ? 0.6: 0
            Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }
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
  
    
    // Connections {
    //     target: wallpaperController

    //     function onCurrentIndexChanged() {
    //         anim.restart()
        
    //     }
    // }


    // SequentialAnimation {
    //     id: waveAnim

    //     NumberAnimation {
    //         target: visualWrapper
    //         property: "wavePhase"
    //         from: 0
    //         to: 2
    //         duration: 250
    //     }
    //     NumberAnimation {
    //         target: visualWrapper
    //         property: "wave"
    //         from: 1
    //         to: 0
    //         duration: 600
    //     }
    // }
//   Connections {
//     target: wallpaperController

//     function onCurrentIndexChanged() {

//         var prev = controller.currentItem
//         var curr = hexItem

//         if (!isSelected)
//             return

//         controller.previousItem = prev
//         controller.currentItem = curr

//        controller.flipHex()
//     }
// }
  
	function flipHex() {

		var wSelected = controller.currentItem
		var wPrevious = controller.previousItem

		if (!wSelected?.visualWrapperRef || !wPrevious?.visualWrapperRef)
			return

		var cx = wSelected.mapToItem(null, 0, 0).x
		var px = wPrevious.mapToItem(null, 0, 0).x

		var dir = (cx > px) ? 1 : -1
        var vPrev = wPrevious.visualWrapperRef
        var v = wSelected.visualWrapperRef
        Qt.callLater(() => {

            if (wPrevious?.visualWrapperRef) {
			

			vPrev.flipAnim.stop()
			vPrev.flipAnim.from = 180 * dir
			vPrev.flipAnim.to = 0
			vPrev.flipAnim.start()
            }

            if(wSelected?.visualWrapperRef) {
                
			v.flipAnim.stop()
			v.flipAnim.from = 0
			v.flipAnim.to = -180 * dir
			v.flipAnim.start()
            }
		})
	}
    property bool _flipLock: false
    property bool _flipQueued: false
    // function triggerFlip() {

    //     if (_flipLock) {
    //         _flipQueued = true
    //         return
    //     }

    //     _flipLock = true

    //     Qt.callLater(() => flipHex())
    // }
    // NumberAnimation {
    //     id: anim
    //     target: selectedHexBorder
    //     property: "t"
    //     from: 0
    //     to: 1
    //     duration: 350
    //     // loops: Animation.Infinite
        // easing.type: Easing.BezierSpline
        // easing.bezierCurve: [0.22, 1.0, 0.36, 1.0]
    // }
    // property string hash: WallpaperCacheService.hashPath(itemData)
    // property string thumbFile: Config.cacheDir + "/" + hash + ".png"
    property string hash: ""
    property string thumbFile: ""
    Component.onCompleted: {

        Qt.callLater(() => {
        console.log("hexitem ",  
        itemIndex + " " + Config.cacheDir + "/"
        + WallpaperCacheService.thumbnailPaths[itemData]) 
        })
        console.log("thumbversion: ", WallpaperCacheService.thumbVersion)
            // console.log("testhexitem:",  WallpaperCacheService.thumbnailPaths[itemData])
         if (itemIndex === 0) {
            
            controller.previousItem = hexItem
            controller.currentItem = hexItem
        }

        anim.restart()
    }
        Timer {
        interval: 350
        running: isSelected
        repeat: true
        onTriggered: flipColor = !flipColor
    }
    property bool flipColor: false
    onIsSelectedChanged: {
        if (!isSelected) return
            anim.restart()
            
            controller.previousItem = controller.currentItem
            controller.currentItem = hexItem        
            Qt.callLater(() => {
                // flipHex()
            })
            container.updateGridFocusOffset() 
    }
            // console.log("previous: ", controller.previousItem.itemIndex)
            // console.log("item: ", controller.currentItem.itemIndex)
    // property Item currentItem: null
    // property Item previousItem: null
    // Connections {
    //     target: wallpaperController

    //     function onCurrentIndexChanged() {
    //         anim.restart()
    //         if (!isSelected) return
    //         controller.previousItem = controller.currentItem
    //         controller.currentItem = hexItem        
    //         console.log("previous: ", controller.previousItem.itemIndex)
    //         console.log("item: ", controller.currentItem.itemIndex)
    //         Qt.callLater(() => {
    //             flipHex()
    //         })
    //     }
    // }

    MouseArea {
        anchors.fill: parent

        // DEBUGGING VERSIONS
        // onWheel: (wheel) => {

        //     if (flick.atYEnd && wheel.angleDelta.y < 0) return
        //     if (flick.atYBeginning && wheel.angleDelta.y > 0) return

        //     flick.flick(0, wheel.angleDelta.y * 12)
        //     wheel.accepted = true
        // }

        // onWheel: (wheel) => {

        //     const atTop = flick.contentY <= 0
        //     const atBottom = flick.contentY >= flick.contentHeight - flick.height

        //     if (atBottom && wheel.angleDelta.y < 0) return
        //     if (atTop && wheel.angleDelta.y > 0) return

        //     flick.flick(0, wheel.angleDelta.y * 12)
        //     wheel.accepted = true
        // }
        // onWheel: (wheel) => {
        //     const maxY = flick.contentHeight - flick.height

        //     const atTop = flick.contentY <= 0
        //     const atBottom = flick.contentY >= maxY - 0.5

        //     if (atBottom && wheel.angleDelta.y < 0) return
        //     if (atTop && wheel.angleDelta.y > 0) return

        //     flick.flick(0, wheel.angleDelta.y * 12)
        //     wheel.accepted = true
        // }
        onClicked: {
            if(!inView) {
                flick.forceActiveFocus() 
                return
            }
            controller.previousIndex = controller.currentIndex
            controller.currentIndex = itemIndex
            flick.forceActiveFocus() 
            // Qt.callLater(() => flickRef.forceActiveFocus())
        }

        onDoubleClicked: {
            if(!inView) return
            WallpaperApplyService.applyWallpaper(itemData)
        }
    }
}