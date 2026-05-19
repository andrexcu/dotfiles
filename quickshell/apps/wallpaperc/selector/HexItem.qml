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
    property int clampDirX
    property int clampDirY
    property real hArcOffset
    property real vArcOffset
    // property real targetX
    // property real targetY
   
    property bool inView
    property bool isHovered: controller.hoveredIndex === itemIndex
    property bool isHoveredPrevious: controller.previousHoveredIndex === itemIndex
    property bool isSelected: flick.currentIndex === itemIndex
    property bool isPrevious: controller.previousIndex === itemIndex

    property real hexDir: controller.isHorizontal ? 1 : 0
    
    Behavior on hexDir { 
        NumberAnimation { duration: Style.animFast
        easing.type: Easing.OutCubic
        }
    }

  


    property real padding: container.cellWidth * 0.04

    width: container.cellWidth - padding
								
    height: container.cellHeight - padding
    
//     property real breakT: 1 - _hexScale

// Behavior on breakT {
//     NumberAnimation {
//         duration: Style.animExpand
//         easing.type: Easing.OutCubic
//     }
// }

// property real seed: index * 91.17

// property real cx: width * 0.5
// property real cy: height * 0.5

// function n(i) {
//     var s = seed + i * 13.13
//     var x = Math.sin(s) * 43758.5453
//     return x - Math.floor(x)
// }

    // function px(i) {
    //     switch(i) {
    //     case 0: return [0.5, 0.0]
    //     case 1: return [1.0, 0.25]
    //     case 2: return [1.0, 0.75]
    //     case 3: return [0.5, 1.0]
    //     case 4: return [0.0, 0.75]
    //     case 5: return [0.0, 0.25]
    //     }
    // }

    // function toWorld(p) {
    //     return hexItem.hexDir
    //         ? [p[1] * width, p[0] * height]
    //         : [p[0] * width, p[1] * height]
    // }

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
    property bool entering: scale < 1 && inView
    
    
    property real dirX: clampDirX
    property real dirY: clampDirY

    property bool nearLeft: false
    property bool nearTop: false

    property real phaseDirX:
        entering ? dirX : dirX

    property real phaseDirY:
        entering ? dirY : -dirY

    property real hDir: nearLeft ? -1 : -1
    property real vDir: nearTop ? -1 : -1

    // property real layoutX: controller.isHorizontal
    //     ? clamp(dx) * 36 * enterT * phaseDirX * hDir
    //     : 0

    // property real layoutY: !controller.isHorizontal
    //     ? clamp(dy) * 36 * enterT * phaseDirY * vDir
    //     : 0
    property real layoutX: 0
    property real layoutY: 0

    property bool hoverBlocked:
    controller.hoveredIndex === flick.currentIndex

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
    property real rx: mix(verticalRippleX, horizontalRippleX, t)
    property real ry: mix(verticalRippleY, horizontalRippleY, t)

    function mix(a,b,t) {
        return a*(1-t) + b*t
    }
    
    property real targetX: viewX + layoutX + (entering ? 0 : rx)
      
    property real targetY: viewY + layoutY + (entering ? 0 : ry)
       
    
    // property real animX: targetX
    // property real animY: targetY

    x: targetX + vArcOffset + shiftX
    y: targetY + hArcOffset + shiftY

    property bool allowAnim: true
    property bool snapHex: flick.listViewShown
    
    Behavior on targetX {
        enabled: snapHex && allowAnim
        NumberAnimation {
            duration: Style.animExpand
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
            
        }
    }

    Behavior on targetY {
        enabled: snapHex && allowAnim
        NumberAnimation {
            duration: Style.animExpand
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
        }
    }

    // property real rx: horizontalRippleX * t + verticalRippleX * (1 - t)
    // property real ry: horizontalRippleY * t + verticalRippleY * (1 - t)
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


  

    // property bool hexAnimating: animX.running || animY.running
    // Connections {
	// 	target: Config.options.orientation
	// 	function oncontroller.isHorizontalChanged() {
	// 		flick.currentIndex = 0
			
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
        visible: false
        // opacity: _inView && (isPrevious || isSelected || isHovered)
        //     ? Math.min(1, selectedHexBorder.t * 1.2)
        //     : 0
        property bool showBorder:
        inView && (isSelected || isPrevious)

        opacity: showBorder ? Math.min(1, tt * 1.2) : 0
        
        scale: visualWrapperRef.visualScale

        Behavior on scale {
            NumberAnimation {
                duration: Style.animExpand
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
            }
        }
        width: hexItem.width
        height: hexItem.height

        z: 9999

        property real t: 0
        property real tt: Math.min(1, selectedHexBorder.t * 1.2)

        property bool active:showBorder
        property bool leaving: (isPrevious) && !isSelected

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
        animOut.from = 0
        animOut.to = 0
        animOut.restart()
    }

        // ======================
        // PATHS (ALL USE SELECTEDHEX)
        // ======================
    ShapePath {
        strokeWidth: isSelected ? 2 : 1.125
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
        strokeWidth: (isSelected) ? 2 : 1.125
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



        // opacity: borderShown && inView ? 1 : 0
        // anchors.fill: parent
        // opacity: 
        // _inView && (isHovered || isSelected)? 1 : 0
        // visible: _inView && isSelected
        // visible: false
    Shape {
        id: selectedDefaultBorder
        z: 10
        // visible: inView ? 1 : 0
        visible: false
     

        width: hexItem.width
        height: hexItem.height

        x: 0
        y: 0

        scale: visualWrapperRef.visualScale

        Behavior on scale {
            NumberAnimation {
                duration: Style.animExpand
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
            }
        }

        Behavior on opacity { 
            NumberAnimation { 
                duration: Style.animNormal; 
                easing.type: Easing.OutCubic 
            } 
        }
        
        preferredRendererType: Shape.CurveRenderer
        antialiasing: true

        //  ShapePath {

        //     fillColor: "transparent"
        //     strokeColor: "#4d4d4d"
        //     strokeWidth: 1.5

        //     PathMove {
        //         x: width * (0.5 - 0.25 * hexItem.hexDir)
        //            + (hexItem.n0 - 0.5) * hexItem.breakT * hexItem.crackStrength
        //         y: 0
        //            + (hexItem.n1 - 0.5) * hexItem.breakT * hexItem.crackStrength
        //     }

        //     PathLine {
        //         x: width * (1 - 0.25 * hexItem.hexDir)
        //            + (hexItem.n2 - 0.5) * hexItem.breakT * hexItem.crackStrength
        //         y: height * (0.25 - 0.25 * hexItem.hexDir)
        //            + (hexItem.n3 - 0.5) * hexItem.breakT * hexItem.crackStrength
        //     }

        //     PathLine {
        //         x: width
        //            + (hexItem.n4 - 0.5) * hexItem.breakT * hexItem.crackStrength
        //         y: height * (0.75 - 0.25 * hexItem.hexDir)
        //            + (hexItem.n5 - 0.5) * hexItem.breakT * hexItem.crackStrength
        //     }

        //     PathLine {
        //         x: width * (0.5 + 0.25 * hexItem.hexDir)
        //            + (hexItem.n6 - 0.5) * hexItem.breakT * hexItem.crackStrength
        //         y: height
        //            + (hexItem.n7 - 0.5) * hexItem.breakT * hexItem.crackStrength
        //     }

        //     PathLine {
        //         x: width * (0.25 * hexItem.hexDir)
        //            + (hexItem.n8 - 0.5) * hexItem.breakT * hexItem.crackStrength
        //         y: height * (0.75 + 0.25 * hexItem.hexDir)
        //            + (hexItem.n9 - 0.5) * hexItem.breakT * hexItem.crackStrength
        //     }

        //     PathLine {
        //         x: 0
        //            + (hexItem.n10 - 0.5) * hexItem.breakT * hexItem.crackStrength
        //         y: height * (0.25 + 0.25 * hexItem.hexDir)
        //            + (hexItem.n11 - 0.5) * hexItem.breakT * hexItem.crackStrength
        //     }

        //   PathLine {
        //         x: width * (0.5 - 0.25 * hexItem.hexDir)
        //         y: 0
        //     }
        // }
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
    //     var selected = flick.currentIndex
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
    //     var selected = flick.currentIndex
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
    //         var selected = flick.currentIndex
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
        clip: true
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
                duration: Style.animNormal
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
            duration: Style.animExpand
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
    //         flick.currentIndex === itemIndex

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

    //         blur: flick.currentIndex === itemIndex &&
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

      
//   Item {
//     anchors.fill: parent
    
//     Image {
//         id: thumbImage
//         // visible: false
//         width: hexItem.width * 1.7
//         height: hexItem.height * 1.7
//         sourceSize.width: Math.ceil(Math.max(container.hCellWidth, container.vCellWidth) * 1.7)
//         sourceSize.height: Math.ceil(Math.max(container.hCellHeight, container.vCellHeight) * 1.7)

        // property real visualX: hexItem.width / 2 - width / 2
        // property real visualY: hexItem.height / 2 - height / 2
        
        // x: inView ? visualX + innerParallaxX : 0
        // y: inView ? visualY + innerParallaxY : 0
        
//         property string thumbName: WallpaperCacheService.thumbnailPaths[itemData] || ""
        
//         source: thumbName && WatcherService.thumbsGenerated
//             ? "file://" + Config.cacheDir + "/" + thumbName
//             : ""

//         fillMode: Image.PreserveAspectCrop
//         smooth: true
//         asynchronous: false
//         cache: false 
        
//         property bool isSelected:
//             flick.currentIndex === itemIndex


//         scale: isSelected ? 1.1 : 1.0

//         Behavior on scale {
//             NumberAnimation {
//                 duration: Style.animExpand
//                 easing.type: Easing.BezierSpline
//                 easing.bezierCurve: [0.22, 1.0, 0.36, 1.0]
//             }
//         }


//         layer.enabled: true
//         layer.effect: MultiEffect {
//             blurEnabled: Config.options.effects.blur
//             blur: (flick.currentIndex === itemIndex &&
//              wallpaperController.blurTransition) ? 1 : 0
//             blurMax: 32

//             Behavior on blur {
//                 NumberAnimation {
//                     duration: Style.animFast
//                     easing.type: Easing.InOutQuad
//                 }
//             }
//         }
//     }

//     // source
//     Image {
//         id: grabImage
//         anchors.fill: parent
//         visible: false
//         fillMode: Image.PreserveAspectCrop
//         source:  thumbImage.thumbName
//             ? "file://" + Config.cacheDir + "/" + thumbImage.thumbName
//             : ""
//     }

//     // PIXEL OVERLAY
//     Canvas {
//         id: pixelCanvas
//         anchors.fill: parent
//         z: 10
//         // visible: thumbImage.isSelected && Config.options.effects.pixel && inView
//         visible: Config.options.effects.pixel
//         opacity: visible && thumbImage.isSelected && Config.options.effects.pixel ? 1 : 0

//         Behavior on opacity { 
//             NumberAnimation { 
//                 duration: Style.animNormal; 
//                 easing.type: Easing.OutCubic 
//             } 
//         }
        
//         property var grabResult: null
//         property real pixelSize: 1

//         Behavior on pixelSize {
//             NumberAnimation {
//                 duration: Style.animEnter
//                 easing.type: Easing.InOutQuad
//             }
//         }

//         onPixelSizeChanged: requestPaint()

//         onOpacityChanged: {
//             if (!visible) {
//                 grabResult = null
//                 pixelSize = 1
//                 return
//             }

//             // NEW: feature OFF → hard stop
//             if (!Config.options.effects.pixel) {
//                 grabResult = null
//                 pixelSize = 1
//                 return
//             }

//             if (grabResult !== null) return
//             if (grabImage.status !== Image.Ready) return

//            grabImage.grabToImage(function(res) {
//                 grabResult = res

//                 pixelSize = 1
//                 requestPaint()

//                 // IMPORTANT: next frame only
//                 Qt.callLater(() => {
//                     pixelSize = 10
//                 })
//             })
//         }

//         onPaint: {
//             if (!grabResult) return

//             var ctx = getContext("2d")
//             var w = width
//             var h = height
//             var pixel = Math.max(1, pixelSize)

//             ctx.clearRect(0, 0, w, h)

//             // downscale
//             ctx.drawImage(grabResult.url, 0, 0, w/pixel, h/pixel)

//             // upscale blocky
//             ctx.imageSmoothingEnabled = false
//             ctx.drawImage(pixelCanvas,
//                 0, 0, w/pixel, h/pixel,
//                 0, 0, w, h)
//         }
//     }
// }
    Item {
        id: hexMask
        width: hexItem.width; height: hexItem.height
        visible: false
        layer.enabled: true
        Shape {
            anchors.fill: parent
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer
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
    
Item {
        id: imageContainer
        anchors.fill: parent
        // opacity: isSelected ? 0.6 : 1
        // Behavior on opacity { NumberAnimation { duration: Style.animFast } }
            Rectangle {
                id: selectedOpacity
                z: 99999
                anchors.fill: parent
                color: "#000000"
                opacity: isSelected ? 0.6 : 0
                Behavior on opacity { NumberAnimation { duration: Style.animFast } }
                // Behavior on opacity { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic  } }
            }

            Rectangle {
                id: hexPlaceholder
                anchors.centerIn: parent
                width: hexItem.width * 1.7
                height: hexItem.height * 1.7
                color: Colors.primary
                opacity: (thumbImage.status === Image.Ready && thumbImage.source != "") ? 0 : 0.08
                Behavior on opacity { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
                visible: opacity > 0

                Text {
                    anchors.centerIn: parent
                    text: "\u{f0553}"
                    font.family: Style.fontFamilyNerdIcons; font.pixelSize: 22
                    color: Qt.rgba(1, 1, 1, 0.1)
                    visible: thumbImage.status !== Image.Ready
                }
            }

            Image {
                id: thumbImage
                width: hexItem.width * 1.7
                height: hexItem.height * 1.7
                property real visualX: hexItem.width / 2 - width / 2
                property real visualY: hexItem.height / 2 - height / 2
                
                x: inView ? visualX + innerParallaxX : 0
                y: inView ? visualY + innerParallaxY : 0
                 property string thumbName: WallpaperCacheService.thumbnailPaths[itemData] || ""
        
                source: thumbName && WatcherService.thumbsGenerated
                    ? "file://" + Config.cacheDir + "/" + thumbName
                    : ""
                // source: hexItem.itemData && hexItem.itemData.thumb ? ImageService.fileUrl(hexItem.itemData.thumb) : ""
                // property string thumbName:
                // (itemData && itemData.filePath)
                // ? WallpaperCacheService.thumbnailPaths[itemData] || ""
                // : ""

                // source: WatcherService.thumbsGenerated
                //     ? "file://" + Config.cacheDir + "/" + thumbName
                //     : ""
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                cache: false
                sourceSize.width: Math.ceil(hexItem.width * 1.3)
                sourceSize.height: Math.ceil(hexItem.height)
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
            }

            layer.enabled: true
            layer.smooth: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: hexMask
                maskThresholdMin: 0.3
                maskSpreadAtMin: 0.3
            }
            
    }

    // Shape {
    //     anchors.fill: parent
    //     visible: hexItem.pulledOut
    //     opacity: hexItem.pulledOut ? 1 : 0
    //     Behavior on opacity { NumberAnimation { duration: Style.animFast } }
    //     antialiasing: true
    //     preferredRendererType: Shape.CurveRenderer
    //     ShapePath {
    //         fillColor: hexItem.colors ? Qt.rgba(hexItem.colors.primary.r, hexItem.colors.primary.g, hexItem.colors.primary.b, 0.08) : Qt.rgba(1,1,1,0.05)
    //         strokeColor: hexItem.colors ? Qt.rgba(hexItem.colors.primary.r, hexItem.colors.primary.g, hexItem.colors.primary.b, 0.4) : Qt.rgba(1,1,1,0.2)
    //         strokeWidth: 2
    //         strokeStyle: ShapePath.DashLine
    //         dashPattern: [4, 4]
    //         startX: hexItem._cx + hexItem._r;                          startY: hexItem._cy
    //         PathLine { x: hexItem._cx + hexItem._r * hexItem._sin30;  y: hexItem._cy - hexItem._r * hexItem._cos30 }
    //         PathLine { x: hexItem._cx - hexItem._r * hexItem._sin30;  y: hexItem._cy - hexItem._r * hexItem._cos30 }
    //         PathLine { x: hexItem._cx - hexItem._r;                   y: hexItem._cy }
    //         PathLine { x: hexItem._cx - hexItem._r * hexItem._sin30;  y: hexItem._cy + hexItem._r * hexItem._cos30 }
    //         PathLine { x: hexItem._cx + hexItem._r * hexItem._sin30;  y: hexItem._cy + hexItem._r * hexItem._cos30 }
    //         PathLine { x: hexItem._cx + hexItem._r;                   y: hexItem._cy }
    //     }
    // }

    Shape {
        id: hexBorder
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: "transparent"
                 strokeColor: hexItem.isSelected
                ? Colors.primary
                : Qt.rgba(0, 0, 0, 0.5)
            strokeWidth: hexItem.isSelected ? 3 : 1.5

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
        // ShapePath {
        //     fillColor: "transparent"
            // strokeColor: hexItem.isSelected
            //     ? (hexItem.colors ? hexItem.colors.primary : Style.fallbackAccent)
            //     : Qt.rgba(0, 0, 0, 0.5)
        //     Behavior on strokeColor { ColorAnimation { duration: Style.animFast } }
        //     strokeWidth: hexItem.isSelected ? 3 : 1.5
        //     startX: hexItem._cx + hexItem._r;                          startY: hexItem._cy
        //     PathLine { x: hexItem._cx + hexItem._r * hexItem._sin30;  y: hexItem._cy - hexItem._r * hexItem._cos30 }
        //     PathLine { x: hexItem._cx - hexItem._r * hexItem._sin30;  y: hexItem._cy - hexItem._r * hexItem._cos30 }
        //     PathLine { x: hexItem._cx - hexItem._r;                   y: hexItem._cy }
        //     PathLine { x: hexItem._cx - hexItem._r * hexItem._sin30;  y: hexItem._cy + hexItem._r * hexItem._cos30 }
        //     PathLine { x: hexItem._cx + hexItem._r * hexItem._sin30;  y: hexItem._cy + hexItem._r * hexItem._cos30 }
        //     PathLine { x: hexItem._cx + hexItem._r;                   y: hexItem._cy }
        // }
    }
  

        
        // Rectangle {
        //     anchors.fill: parent
        //     visible: controller.cardVisible
        //     color: "#000000"
        //     opacity: isSelected ? 0.6 : 0
        //     // visible: false
        //     Behavior on opacity { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic  } }
        // }
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
        // rotation: -visualWrapperRef.rotation
        // anchors.centerIn: parent
       
//        layer.effect: OpacityMask {
//         maskSource: Shape {
//         id: hexShape
        
//         width: hexItem.width
//         height: hexItem.height
//         preferredRendererType: Shape.CurveRenderer
//         antialiasing: true
//         ShapePath {
//                     fillColor: "white"
//                     strokeWidth: 0

//                     // P1
//                     PathMove {
//                         x: width * (0.5 - 0.25 * hexItem.hexDir)
//                         y: 0
//                     }

//                     // P2
//                     PathLine {
//                         x: width * (1 - 0.25 * hexItem.hexDir)
//                         y: height * (0.25 - 0.25 * hexItem.hexDir)
//                     }

//                     // P3
//                     PathLine {
//                         x: width
//                         y: height * (0.75 - 0.25 *hexItem.hexDir)
//                     }

//                     // P4
//                     PathLine {
//                         x: width * (0.5 + 0.25 * hexItem.hexDir)
//                         y: height
//                     }

//                     // P5
//                     PathLine {
//                         x: width * (0.25 * hexItem.hexDir)
//                         y: height * (0.75 + 0.25 * hexItem.hexDir)
//                     }

//                     // P6
//                     PathLine {
//                         x: 0
//                         y: height * (0.25 + 0.25 * hexItem.hexDir)
//                     }

//                     PathLine {
//                         x: width * (0.5 - 0.25 * hexItem.hexDir)
//                         y: 0
//                     }
//                 }

//     }
// }





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

     Timer {
        id: animTimer
        interval: 50
        repeat: false
        running: false
        onTriggered: allowAnim = true
    }

    Component.onCompleted: {
        // allowAnim = false
        // Qt.callLater(() => {
        //     allowAnim = true
        // })
        // console.log(itemIndex)
        animTimer.start()
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
        
        controller.requestFrame()
        // if(controller.isHorizontal) {
        //     container.hOuterParallax() 
        // } else {
        //     container.vOuterParallax() 
        // }
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
        hoverEnabled: flickRef.listViewShown ? true : false
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
            if(!inView || !flickRef.listViewShown) {
                flickRef.forceActiveFocus() 
                return
            }
            
            controller.previousIndex = flick.currentIndex
            flick.currentIndex = itemIndex
            flickRef.forceActiveFocus() 
            // Qt.callLater(() => flickRef.forceActiveFocus())
        }

        onDoubleClicked: {
            if(!!inView || !flickRef.listViewShown) return
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