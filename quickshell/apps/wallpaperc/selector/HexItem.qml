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
    property int clampDir
    property real hArcOffset
    property real vArcOffset
    // property real targetX
    // property real targetY
   
    property bool inView
    property bool isHovered: controller.hoveredIndex === itemIndex
    property bool isHoveredPrevious: controller.previousHoveredIndex === itemIndex
    property bool isSelected: controller.currentIndex === itemIndex
    property bool isPrevious: controller.previousIndex === itemIndex
    property real hexDir: controller.isHorizontal ? 1 : 0
    Behavior on hexDir { 
            NumberAnimation { duration: 150
            easing.type: Easing.OutCubic
			// 								easing.overshoot: 1.4
            // easing.type: Easing.BezierSpline
            // easing.bezierCurve: [0.2, 0.8, 0.2, 1.0]
            // easing.bezierCurve: [0.22, 1.0, 0.36, 1.0]

            }
        }
    property real expand: 0
    property real shrink: 0.05

    width: container.cellWidth - 10 
								
    height: container.cellHeight - 10
    // property real originFixY

    //  Behavior on width { 
    //         NumberAnimation { duration: 0
    //         // easing.type: Easing.OutBack
	// 		// 								easing.overshoot: 1.4
    //         easing.type: Easing.BezierSpline
    //         // easing.bezierCurve: [0.2, 0.8, 0.2, 1.0]
    //         easing.bezierCurve: [0.22, 1.0, 0.36, 1.0]

    //         }
    //     }
    //      Behavior on height { 
    //         NumberAnimation { duration: 0
    //         // easing.type: Easing.OutBack
	// 		// 								easing.overshoot: 1.4
    //         easing.type: Easing.BezierSpline
    //         // easing.bezierCurve: [0.2, 0.8, 0.2, 1.0]
    //         easing.bezierCurve: [0.22, 1.0, 0.36, 1.0]

    //         }
    //     }
    // width: hexRadius * 2
    // height: Math.ceil(hexRadius * 1.73205)
    // property real visualWidth: controller.controller.isHorizontal
    // ? container.hCellWidth - 10 : container.vCellWidth - 10
    
    // property real visualHeight: controller.controller.isHorizontal
    // ? container.hCellHeight - 10 : container.vCellHeight - 10

   
    // Behavior on width { NumberAnimation { duration: 150 } }
    // Behavior on height { NumberAnimation { duration: 150 } }
    // property bool imageReady: thumbImage.status === Image.Ready && thumbImage.paintedWidth > 0
    property int currentScale
    property bool isHidden: false

    
    property var rippleH
    property bool rippleOffH
    property var hoverRippleH
    property bool hoverRippleOffH

    property var rippleV
    property bool rippleOffV
    property var hoverRippleV
    property bool hoverRippleOffV

    property bool hasEntered: false
    // property real rowScale
    property real innerParallaxX: 0
    property real innerParallaxY: 0
    
    function clamp(v) {
        return Math.sign(v) * Math.min(Math.abs(v), 2)
    }
   

    property real enterT: inView ? 0 : 1
    // property bool entering: inView
    property bool entering: scale < 1 && inView
    
    property real dirX: clampDir

    property bool nearLeft: false
    property bool nearTop: false
    property real phaseDir:
        entering ? dirX : -dirX

    property real hDir: nearLeft ? -1 : 1
    property real vDir: nearTop ? -1 : 1

    property real layoutX: controller.isHorizontal ? 
    clamp(dx) * 36 * enterT * phaseDir * hDir : 0
       

    property real layoutY: 0



    property bool hoverBlocked:
    controller.hoveredIndex === controller.currentIndex

    property real viewX
    property real viewY

    property real horizontalRippleX: ((rippleOffH ? 0 : rippleH.x)
         + (hoverRippleOffH || hoverBlocked ? 0 : hoverRippleH.x))
    property real verticalRippleX:((rippleOffV ? 0 : rippleV.x)
         + (hoverRippleOffV || hoverBlocked ? 0 : hoverRippleV.x))

    property real horizontalRippleY:((rippleOffH ? 0 : rippleH.y)
         + (hoverRippleOffH || hoverBlocked ? 0 : hoverRippleH.y))

    property real verticalRippleY: ((rippleOffV ? 0 : rippleV.y)
         + (hoverRippleOffV || hoverBlocked ? 0 : hoverRippleV.y))

    property real t: controller.isHorizontal ? 1 : 0

    property real rx: horizontalRippleX * t + verticalRippleX * (1 - t)
    property real ry: horizontalRippleY * t + verticalRippleY * (1 - t)
    property real targetX:
        viewX + layoutX + (entering ? 0 : rx)

    property real targetY:
        viewY + layoutY + (entering ? 0 : ry)


    x: targetX + vArcOffset + shiftX
    y: targetY + hArcOffset + shiftY

        // property real c: inView ? enterT : (1 - enterT)

    // property real layoutY: entering ? 0 : clamp(dy) * 30 * enterT

    // property real layoutY: 0
    // property real rx:
    // controller.isHorizontal
    //     ? horizontalRippleX
    //     : verticalRippleX

    // property real ry:
    // controller.isHorizontal
    //     ? horizontalRippleY
    //     : verticalRippleY




        // + (entering ? 0 : ry)
        
    // property real targetX:
    // flickRef.baseX(itemIndex)
    // + (entering ? 0 : (hoverRippleOff ? 0 : hoverRipple.x))

    // property real targetY:
    // flickRef.baseY(itemIndex)
    // + (entering ? 0 : (hoverRippleOff ? 0 : hoverRipple.y))

    property real hexRadius: 90


    readonly property real _r: hexRadius
    readonly property real _cx: _r
    readonly property real _cy: height / 2
    readonly property real _cos30: 0.866025
    readonly property real _sin30: 0.5
  
    
  
    // x: targetX + (entering ? 0 : shiftX)
    // y: targetY + (entering ? 0 : shiftY)
    
      //  property real layoutX: 0
    // property real layoutY: 0
    // onXChanged: {
    //     console.log("hexItem X position: ", x)
    // }
    // y: flickRef.baseY(itemIndex) + ripple.y + originFixY * (1 - scale)
    // property real layoutX: 0
    // property real layoutY: 0
    // targetX: !rippleOff ?
    // flickRef.baseX(itemIndex) + layoutX + ripple.x : flickRef.baseX(itemIndex)

    // targetY: !rippleOff ?
    // flickRef.baseY(itemIndex) + layoutY + ripple.y : flickRef.baseY(itemIndex)

   
    // Behavior on scale {
    //     // enabled: flickRef.firstUpdateDone
    //     NumberAnimation {
    //         duration: 400
    //         easing.type: Easing.BezierSpline
    //         easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
    //     }
    // }
    // property bool hexAnimating: false
    property bool allowAnim: true
    property bool snapHex: WatcherService.thumbsGenerated
    

    Behavior on targetX {
        enabled: snapHex && allowAnim
        NumberAnimation {
                id: animX
                duration: 350
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
               
            }
    }

   
    Behavior on targetY {
        enabled: snapHex && allowAnim
        NumberAnimation {
            id: animY
            duration: 350
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
            
        }
    }

    opacity: _hexScale < 0.01 ? 0 : 1
        // opacity: _inView ? 1 : 0
    Behavior on opacity { 
        NumberAnimation { 
            duration: 250; 
            easing.type: Easing.InOutQuad 
            // easing.type: Easing.InOutQuad 
            // easing.type: Easing.InCubic
        } 
    }

    // property bool hexAnimating: animX.running || animY.running
    // Connections {
	// 	target: Config.options.orientation
	// 	function oncontroller.isHorizontalChanged() {
	// 		wallpaperController.currentIndex = 0
			
	// 		// if(controller.isHorizontal) {
	// 		// 	flick.vOuterParallax()
	// 		// } else {
	// 		// 	flick.hOuterParallax()
	// 		// }
	// 	}
	// }
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
            // container.hOuterParallax() 
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
        // visible: false
        // opacity: _inView && (isPrevious || isSelected || isHovered)
        //     ? Math.min(1, selectedHexBorder.t * 1.2)
        //     : 0
        property bool showBorder:
        borderShown && _inView && (isSelected || isHovered || isPrevious || isHoveredPrevious)

        opacity: showBorder ? Math.min(1, tt * 1.2) : 0
        
        scale: visualWrapperRef.visualScale

        Behavior on scale {
            NumberAnimation {
                duration: 350
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
            }
        }
        width: hexItem.width
        height: hexItem.height

        z: 9999

        property real t: 0
        property real tt: Math.min(1, selectedHexBorder.t * 1.2)

        property bool active: isSelected || isHovered
        property bool leaving: (isPrevious || previousHoveredIndex) && !isSelected && !isHovered

        preferredRendererType: Shape.CurveRenderer
        antialiasing: true

        // ======================
        // ANIMATION DRIVER
        // ======================

    NumberAnimation {
        id: animIn
        target: selectedHexBorder
        property: "t"
        duration: 300
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
        }

        NumberAnimation {
            id: animOut
            target: selectedHexBorder
            property: "t"
            duration: 600 // different
            easing.type: Easing.InOutQuad
        }

    onActiveChanged: {
        if (!active) return
        animOut.stop()
        animIn.from = 0
        animIn.to = 1
        animIn.restart()
    }

    onLeavingChanged: {
        if (!leaving) return
        animIn.stop()
        animOut.from = 1
        animOut.to = 0
        animOut.restart()
    }

        // ======================
        // PATHS (ALL USE SELECTEDHEX)
        // ======================
    ShapePath {
        strokeWidth: (isSelected || isHovered) ? 2 : 1.125
        strokeColor: Colors.primary
        fillColor: "transparent"

        PathMove {
            x: controller.isHorizontal ? 0 : width * 0.5
            y: controller.isHorizontal ? height * 0.5 : 0
        }

        PathLine {
            x: controller.isHorizontal
                ? width * (0.25 * selectedHexBorder.tt)
                : width * 0.5 - (width * 0.5) * selectedHexBorder.t

            y: controller.isHorizontal
                ? height * (0.5 - 0.5 * selectedHexBorder.tt)
                : height * (0.25 * selectedHexBorder.t)
        }
    }

    ShapePath {
        strokeWidth: (isSelected || isHovered) ? 2 : 1.125
        strokeColor: Colors.primary
        fillColor: "transparent"

        PathMove {
            x: controller.isHorizontal ? width : width * 0.5
            y: controller.isHorizontal ? height * 0.5 : height
        }

        PathLine {
            x: controller.isHorizontal
                ? width - width * (0.25 * selectedHexBorder.tt)
                : width * 0.5 + (width * 0.5) * selectedHexBorder.t

            y: controller.isHorizontal
                ? height * (0.5 - 0.5 * selectedHexBorder.tt)
                : height - (height * 0.25 * selectedHexBorder.t)
        }
    }

    ShapePath {
        strokeWidth: (isSelected || isHovered) ? 2 : 1.125
        strokeColor: Colors.primary
        fillColor: "transparent"

        PathMove {
            x: controller.isHorizontal ? width * 0.25 : 0
            y: controller.isHorizontal ? 0 : height * 0.25
        }

        PathLine {
            x: controller.isHorizontal
                ? width * (0.25 + 0.5 * selectedHexBorder.t)
                : 0

            y: controller.isHorizontal
                ? 0
                : height * (0.25 + 0.5 * selectedHexBorder.tt)
        }
    }

    ShapePath {
        strokeWidth: (isSelected || isHovered) ? 2 : 1.125
        strokeColor: Colors.primary
        fillColor: "transparent"

        PathMove {
            x: controller.isHorizontal ? width * 0.25 : width
            y: controller.isHorizontal ? height : height * 0.75
        }

        PathLine {
            x: controller.isHorizontal
                ? width * (0.25 + 0.5 * selectedHexBorder.t)
                : width

            y: controller.isHorizontal
                ? height
                : height * (0.75 - 0.5 * selectedHexBorder.tt)
        }
    }

    ShapePath {
    
        strokeWidth: (isSelected || isHovered) ? 2 : 1.125
        strokeColor: controller.isHorizontal ? Colors.primary : "transparent"
        fillColor: "transparent"

        PathMove {
            x: 0
            y: height * 0.5
        }

        PathLine {
            x: width * (0.25 * selectedHexBorder.tt)
            y: height * (0.5 + 0.5 * selectedHexBorder.tt)
        }
    }
    ShapePath {
        
        strokeWidth: (isSelected || isHovered) ? 2 : 1.125
        strokeColor: controller.isHorizontal ? Colors.primary : "transparent"
        fillColor: "transparent"

        PathMove {
            x: width
            y: height * 0.5
        }

        PathLine {
            x: width - width * (0.25 * selectedHexBorder.tt)
            y: height * (0.5 + 0.5 * selectedHexBorder.tt)
        }
    }


    ShapePath {
        strokeWidth: (isSelected || isHovered) ? 2 : 1.125
        strokeColor: !controller.isHorizontal ? Colors.primary : "transparent"
        fillColor: "transparent"

        PathMove {
            x: width * 0.5
            y: 0
        }

        PathLine {
            x: width * 0.5 + (width * 0.5) * selectedHexBorder.t
            y: height * (0.25 * selectedHexBorder.t)
        }
    }

    ShapePath {
        strokeWidth: (isSelected || isHovered) ? 2 : 1.125
        strokeColor: !controller.isHorizontal ? Colors.primary : "transparent"
        fillColor: "transparent"

        PathMove {
            x: width * 0.5
            y: height
        }

        PathLine {
            x: width * 0.5 - (width * 0.5) * selectedHexBorder.t
            y: height - height * (0.25 * selectedHexBorder.t)
        }
    }
    
    // visible: false
    }

    property bool borderShown: 
    controller.filteredWallpapers && snapHex && allowAnim

    Shape {
        id: selectedDefaultBorder
        z: 10
        visible: borderShown && inView ? 1 : 0
     
        // opacity: borderShown && inView ? 1 : 0
        // anchors.fill: parent
        // opacity: 
        // _inView && (isHovered || isSelected)? 1 : 0
        // visible: _inView && isSelected
        // visible: false

        width: hexItem.width
        height: hexItem.height
      
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
                duration: 250; 
                easing.type: Easing.OutQuad 
            } 
        }
        
        preferredRendererType: Shape.CurveRenderer
        antialiasing: true
        ShapePath {
           
            strokeWidth: 1.5
            // strokeWidth: 1.125
            
            fillColor: "transparent"
            strokeColor: "#4d4d4d"
            //  strokeColor: "#AEEFFF"
             PathMove {
                x: width * (0.5 - 0.25 * hexItem.hexDir)
                y: 0
            }

            // P2
            PathLine {
                x: width * (1 - 0.25 * hexItem.hexDir)
                y: height * (0.25 - 0.25 * hexItem.hexDir)
            }

            // P3
            PathLine {
                x: width
                y: height * (0.75 - 0.25 *hexItem.hexDir)
            }

            // P4
            PathLine {
                x: width * (0.5 + 0.25 * hexItem.hexDir)
                y: height
            }

            // P5
            PathLine {
                x: width * (0.25 * hexItem.hexDir)
                y: height * (0.75 + 0.25 * hexItem.hexDir)
            }

            // P6
            PathLine {
                x: 0
                y: height * (0.25 + 0.25 * hexItem.hexDir)
            }

            PathLine {
                x: width * (0.5 - 0.25 * hexItem.hexDir)
                y: 0
            }
        }
            // PathMove { x: width * 0.25; y: 0 }
            // PathLine { x: width * 0.75; y: 0 }
            // PathLine { x: width;        y: height * 0.5 }
            // PathLine { x: width * 0.75; y: height }
            // PathLine { x: width * 0.25; y: height }
            // PathLine { x: 0;            y: height * 0.5 }
            // PathLine { x: width * 0.25; y: 0 }
            //  ShapePath {
            //     fillColor: "white"

            //     // TOP (longer)
               
            // }
        // ShapePath {
        //     strokeWidth: 1.125
            
        //     fillColor: "transparent"
        //     strokeColor: "#4d4d4d"
        //     PathMove { x: width * 0.5; y: 0 }
        //     PathLine { x: width; y: height * 0.25 }
        //     PathLine { x: width; y: height * 0.75 }
        //     PathLine { x: width * 0.5; y: height }
        //     PathLine { x: 0; y: height * 0.75 }
        //     PathLine { x: 0; y: height * 0.25 }
        //     PathLine { x: width * 0.5; y: 0 }
        // }

    
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
  
        width: hexItem.width
        height: hexItem.height

        // rotation: isSelected ? 90:0
        // Behavior on rotation {
        //     NumberAnimation {
        //         duration: 200
        //     }
        // }
        
        // Behavior on width { NumberAnimation { duration: 150; } }
        // Behavior on height { NumberAnimation { duration: 150; } }
        
        property alias flipAnim: flipAnim

     
        property bool hovered: mouseArea.containsMouse

        property real visualScale:
        isSelected ? 1.12 :
        (hovered ? 1.06 : 1)

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
    // Image {
    //     id: thumbImage

    //     anchors.fill: parent
    //     fillMode: Image.PreserveAspectCrop

    //     opacity: inView ? 1 : 0
    //     Behavior on opacity {
    //         NumberAnimation { duration: 200 }
    //     }

    //     asynchronous: true

    //     sourceSize.width: width
    //     sourceSize.height: height

    //     property string thumbName:
    //         WallpaperCacheService.thumbnailPaths[itemData] || ""

    //     property bool isSelected:
    //         wallpaperController.currentIndex === itemIndex

    //     source: WatcherService.thumbsGenerated
    //         ? "file://" + Config.cacheDir + "/" + thumbName
    //         : ""

    //     // ZOOM EFFECT
    //     scale: isSelected ? 1.1 : 1.0
    //     transformOrigin: Item.Center

    //     Behavior on scale {
    //         NumberAnimation {
    //             duration: 350
    //             easing.type: Easing.BezierSpline
    //             easing.bezierCurve: [0.22, 1.0, 0.36, 1.0]
        
    //         }
    //     }

    //     smooth: !isSelected

    //     layer.enabled: true
    //     layer.effect: MultiEffect {
    //         blurEnabled: true

    //         blur: wallpaperController.currentIndex === itemIndex &&
    //             wallpaperController.blurTransition ? 1 : 0

    //         blurMax: 32

    //         Behavior on blur {
    //             NumberAnimation {
    //                 duration: 150
    //                 easing.type: Easing.InOutQuad
    //             }
    //         }
    //     }
    // }


    // thumb image
    // thumb image
        // source: hexItem.itemData && hexItem.itemData.thumb ? ImageService.fileUrl(hexItem.itemData.thumb) : ""
        // anchors.centerIn: parent

      
  Item {
    anchors.fill: parent
    
    Image {
        id: thumbImage
        // visible: false
        width: hexItem.width * 1.7
        height: hexItem.height * 1.7
        sourceSize.width: Math.ceil(Math.max(container.hCellWidth, container.vCellWidth) * 1.7)
        sourceSize.height: Math.ceil(Math.max(container.hCellHeight, container.vCellHeight) * 1.7)

        // sourceSize.width: inView ? Math.ceil(thumbImage.width) : 0
        // sourceSize.height: inView ? Math.ceil(thumbImage.height) : 0
        // sourceSize.width: inView ? Math.ceil(hexItem.width * 1.7) : 0
        // sourceSize.height: inView ? Math.ceil(hexItem.height * 1.7) : 0
        // Behavior on width { NumberAnimation { duration: 150; } }
        // Behavior on height { NumberAnimation { duration: 150 } }

        property real visualX: hexItem.width / 2 - width / 2
        property real visualY: hexItem.height / 2 - height / 2
        
        x: inView ? visualX + innerParallaxX : 0
        y: inView ? visualY + innerParallaxY : 0

        
        // Behavior on visualX {
        //     NumberAnimation {
        //            duration: 150
                    
                
        //         }
        // }

        // Behavior on visualY {
        //     NumberAnimation {
        //        duration: 150
        
        //     }
        // }
        
        property string thumbName: WallpaperCacheService.thumbnailPaths[itemData] || ""
        
        source: thumbName && WatcherService.thumbsGenerated
            ? "file://" + Config.cacheDir + "/" + thumbName
            : ""

        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: false
        cache: false
  
     
       
        
        property bool isSelected:
            wallpaperController.currentIndex === itemIndex


        scale: isSelected ? 1.1 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: 350
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.22, 1.0, 0.36, 1.0]
            }
        }


        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: Config.options.effects.blur
            blur: (wallpaperController.currentIndex === itemIndex &&
             wallpaperController.blurTransition) ? 1 : 0
            blurMax: 32

            Behavior on blur {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    // source
    Image {
        id: grabImage
        anchors.fill: parent
        visible: false
        fillMode: Image.PreserveAspectCrop
        source:  thumbImage.thumbName
            ? "file://" + Config.cacheDir + "/" + thumbImage.thumbName
            : ""
    }

    // PIXEL OVERLAY
    Canvas {
        id: pixelCanvas
        anchors.fill: parent
        z: 10
        // visible: thumbImage.isSelected && Config.options.effects.pixel && inView
        visible: Config.options.effects.pixel
        opacity: visible && thumbImage.isSelected && Config.options.effects.pixel ? 1 : 0

        Behavior on opacity { 
            NumberAnimation { 
                duration: 250; 
                easing.type: Easing.InOutQuad 
            } 
        }
        
        property var grabResult: null
        property real pixelSize: 1

        Behavior on pixelSize {
            NumberAnimation {
                duration: 250
                easing.type: Easing.InOutQuad
            }
        }

        onPixelSizeChanged: requestPaint()

        onOpacityChanged: {
            if (!visible) {
                grabResult = null
                pixelSize = 1
                return
            }

            // NEW: feature OFF → hard stop
            if (!Config.options.effects.pixel) {
                grabResult = null
                pixelSize = 1
                return
            }

            if (grabResult !== null) return
            if (grabImage.status !== Image.Ready) return

           grabImage.grabToImage(function(res) {
                grabResult = res

                pixelSize = 1
                requestPaint()

                // IMPORTANT: next frame only
                Qt.callLater(() => {
                    pixelSize = 10
                })
            })
        }

        onPaint: {
            if (!grabResult) return

            var ctx = getContext("2d")
            var w = width
            var h = height
            var pixel = Math.max(1, pixelSize)

            ctx.clearRect(0, 0, w, h)

            // downscale
            ctx.drawImage(grabResult.url, 0, 0, w/pixel, h/pixel)

            // upscale blocky
            ctx.imageSmoothingEnabled = false
            ctx.drawImage(pixelCanvas,
                0, 0, w/pixel, h/pixel,
                0, 0, w, h)
        }
    }
}

    


  

        
        Rectangle {
            anchors.fill: parent
            // visible: hexItem.controller.cardVisible
            color: "#000000"
            opacity: 0.6
            visible: false
            // Behavior on opacity { NumberAnimation { duration: 50; easing.type: Easing.OutQuad } }
        }
        // Rectangle {
        //     anchors.fill: parent
        //     visible: hexItem.controller.cardVisible
        //     color: "#4D5CA5C8"
        //     opacity: !isSelected
        //     ? 1: 0
          
        //     Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }
        // }
        

        layer.enabled: true
        layer.smooth: true

        // readonly property real _r: container.hexRadius
        // readonly property real _cx: _r
        // readonly property real _cy: container.hCellHeight / 2
        // readonly property real _cos30: 0.866025
        // readonly property real _sin30: 0.5
        // HORIZONTAL HEX
        // layer.effect: OpacityMask {
        //     maskSource: Shape {
        //         anchors.fill: parent
        //         anchors.centerIn: parent
        //         preferredRendererType: Shape.CurveRenderer
        //         antialiasing: true
                
        //         ShapePath {
        //             fillColor: "white"
        //             strokeColor: fillColor
        //             startX: hexItem._cx + hexItem._r;                          
        //             startY: hexItem._cy
        //             PathLine { x: hexItem._cx + hexItem._r * hexItem._sin30;  y: hexItem._cy - hexItem._r * hexItem._cos30 }
        //             PathLine { x: hexItem._cx - hexItem._r * hexItem._sin30;  y: hexItem._cy - hexItem._r * hexItem._cos30 }
        //             PathLine { x: hexItem._cx - hexItem._r;                   y: hexItem._cy }
        //             PathLine { x: hexItem._cx - hexItem._r * hexItem._sin30;  y: hexItem._cy + hexItem._r * hexItem._cos30 }
        //             PathLine { x: hexItem._cx + hexItem._r * hexItem._sin30;  y: hexItem._cy + hexItem._r * hexItem._cos30 }
        //             PathLine { x: hexItem._cx + hexItem._r;                   y: hexItem._cy }
        //         }
        //     }
        // }
        
        property real dirBias: nearLeft ? -1 : 1
        
        // property real t: _colScale
        // Behavior on t { 
        //     NumberAnimation { duration: 150
        //     // easing.type: Easing.OutBack
		// 	// 								easing.overshoot: 1.4
        //     easing.type: Easing.BezierSpline
        //     // easing.bezierCurve: [0.2, 0.8, 0.2, 1.0]
        //     easing.bezierCurve: [0.22, 1.0, 0.36, 1.0]

        //     }
        // }
        layer.effect: OpacityMask {
            maskSource: Shape {
                width: hexItem.width
                height: hexItem.height
                // rotation: -visualWrapperRef.rotation
                // anchors.centerIn: parent
                preferredRendererType: Shape.CurveRenderer
                antialiasing: true
               
                


                ShapePath {
                    fillColor: "white"
                    strokeWidth: 0

                    // P1
                    PathMove {
                        x: width * (0.5 - 0.25 * hexItem.hexDir)
                        y: 0
                    }

                    // P2
                    PathLine {
                        x: width * (1 - 0.25 * hexItem.hexDir)
                        y: height * (0.25 - 0.25 * hexItem.hexDir)
                    }

                    // P3
                    PathLine {
                        x: width
                        y: height * (0.75 - 0.25 *hexItem.hexDir)
                    }

                    // P4
                    PathLine {
                        x: width * (0.5 + 0.25 * hexItem.hexDir)
                        y: height
                    }

                    // P5
                    PathLine {
                        x: width * (0.25 * hexItem.hexDir)
                        y: height * (0.75 + 0.25 * hexItem.hexDir)
                    }

                    // P6
                    PathLine {
                        x: 0
                        y: height * (0.25 + 0.25 * hexItem.hexDir)
                    }

                    PathLine {
                        x: width * (0.5 - 0.25 * hexItem.hexDir)
                        y: 0
                    }
                }
            }
        }
                // ShapePath {
                //     fillColor: "white"
  
                //     PathMove { x: width * 0.25; y: 0 }
                //     PathLine { x: width * 0.75; y: 0 }
                //     PathLine { x: width;        y: height * 0.5 }
                //     PathLine { x: width * 0.75; y: height }
                //     PathLine { x: width * 0.25; y: height }
                //     PathLine { x: 0;            y: height * 0.5 }
                //     PathLine { x: width * 0.25; y: 0 }
                // }

        // VERTICAL HEX
        // layer.effect: OpacityMask {
        //     maskSource: Shape {
        //         width: visualWrapper.width
        //         height: visualWrapper.height
        //         opacity: inView ? 1 : 0
        //         Behavior on opacity { NumberAnimation { duration: 150 } }
        //         anchors.centerIn: parent
        //         preferredRendererType: Shape.CurveRenderer
        //         antialiasing: true
                
                // ShapePath {
                //     fillColor: "white"
                //     strokeColor: fillColor
                //     strokeWidth: 0
                //     PathMove { x: width * 0.5; y: 0 }
                //     PathLine { x: width; y: height * 0.25 }
                //     PathLine { x: width; y: height * 0.75 }
                //     PathLine { x: width * 0.5; y: height }
                //     PathLine { x: 0; y: height * 0.75 }
                //     PathLine { x: 0; y: height * 0.25 }
                //     PathLine { x: width * 0.5; y: 0 }
                // }
        //     }
        // }
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
   
    property string hash: ""
    property string thumbFile: ""
        // property string thumbName:
        // WallpaperCacheService.thumbnailPaths[itemData] || ""

    //  Timer {
    //     id: animTimer
    //     interval: 50
    //     repeat: false
    //     running: false
    //     onTriggered: allowAnim = true
    // }

    Component.onCompleted: {
        allowAnim = false
        Qt.callLater(() => {
            allowAnim = true
        })
        // animTimer.start()
    }

        //  if (itemIndex === 0) {
            
        //     controller.previousItem = hexItem
        //     controller.currentItem = hexItem
        // }
    // Timer {
    //     interval: 350
    //     running: isSelected
    //     repeat: true
    //     onTriggered: flipColor = !flipColor
    // }

    // property bool flipColor: false
    onIsSelectedChanged: {
        if (!isSelected) return
            // anim.restart()
            
            controller.previousItem = controller.currentItem
            controller.currentItem = hexItem 
            if(Config.options.effects.flip) {
                // Qt.callLater(() => {
                    hexItem.flipHex()
                // })

            }     
            if(controller.isHorizontal) {

                container.hOuterParallax() 
            } else {
                 container.vOuterParallax() 
            }
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
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        // DEBUGGING VERSIONS
        // onWheel: (wheel) => {

        //     if (flickRef.atYEnd && wheel.angleDelta.y < 0) return
        //     if (flickRef.atYBeginning && wheel.angleDelta.y > 0) return

        //     flickRef.flickRef(0, wheel.angleDelta.y * 12)
        //     wheel.accepted = true
        // }

        // onWheel: (wheel) => {

        //     const atTop = flickRef.contentY <= 0
        //     const atBottom = flickRef.contentY >= flickRef.contentHeight - flickRef.height

        //     if (atBottom && wheel.angleDelta.y < 0) return
        //     if (atTop && wheel.angleDelta.y > 0) return

        //     flickRef.flickRef(0, wheel.angleDelta.y * 12)
        //     wheel.accepted = true
        // }
        // onWheel: (wheel) => {
        //     const maxY = flickRef.contentHeight - flickRef.height

        //     const atTop = flickRef.contentY <= 0
        //     const atBottom = flickRef.contentY >= maxY - 0.5

        //     if (atBottom && wheel.angleDelta.y < 0) return
        //     if (atTop && wheel.angleDelta.y > 0) return

        //     flickRef.flickRef(0, wheel.angleDelta.y * 12)
        //     wheel.accepted = true
        // }
        
        onClicked: {
            if(!inView) {
                flickRef.forceActiveFocus() 
                return
            }
            controller.previousIndex = controller.currentIndex
            controller.currentIndex = itemIndex
            flickRef.forceActiveFocus() 
            // Qt.callLater(() => flickRef.forceActiveFocus())
        }

        onDoubleClicked: {
            if(!inView) return
            WallpaperApplyService.applyWallpaper(itemData)
        }
        onEntered: {
            if(!inView) return
            controller.previousHoveredIndex = controller.hoveredIndex
            controller.hoveredIndex = itemIndex
        }
        onExited: {
            if (controller.hoveredIndex === itemIndex)
                controller.hoveredIndex = -1
        }
    }
}