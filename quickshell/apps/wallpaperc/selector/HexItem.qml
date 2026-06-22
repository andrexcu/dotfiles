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
    property bool currentItem: false
    property bool isSelected: false
    property bool isPrevious: controller.previousIndex === itemIndex

    property real hexDir: controller.isHorizontal ? 1 : 0
    
    Behavior on hexDir { 
        NumberAnimation { duration: Style.animFast
        easing.type: Easing.OutCubic
        }
    }

  


    property real padding: container.cellWidth * 0.04

    width: container._hexW - padding
								
    height: container._hexH - padding
    
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
    
    property bool entering: scale > 0.5 && inView
   
    // function clamp(v) {
    //     return Math.sign(v) * Math.min(Math.abs(v), 2)
    // }
   
    // property real enterT: inView ? 0 : 1
    // property bool entering: false
    // property real enterFactor: inView ? 1 : 0
    // Behavior on enterFactor {
    //     NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    // }
    // onInViewChanged: {
    //     if (inView) entering = true
    //     else entering = false
    // }
    
    // property real dirX: clampDirX
    // property real dirY: clampDirY

    property bool nearLeft: false
    property bool nearTop: false

    // property real visualScale:
    property bool hovered: mouseArea.containsMouse
    // property real realScale:
    // isSelected ? 1.1 :
    // (hovered ? 1.06 : 1)
	property real itemLeft: x
    property real itemRight: x + flick._hexW * 0.6
    
  

    property real realScale:
    isSelected ? 1.125 : 1

    property real _hexScale: _inView ? realScale : 0

    scale: _hexScale
    opacity: scale < 0.01 ? 0 : 1

    Behavior on scale {  NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic }}
    //  Behavior on realScale {					
    //     NumberAnimation {
    //         duration: 250
    //         easing.type: Easing.BezierSpline
    //         easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
            
    //     }

    // }
    // Behavior on scale {					
    //     NumberAnimation {
    //         duration: 250
    //         easing.type: Easing.BezierSpline
    //         easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
            
    //     }

    // }



    property real layoutX: 0
    property real layoutY: 0

    property bool hoverBlocked:
    controller.hoveredIndex === wallpaperController.currentIndex

    property real viewX
    property real viewY

    property real horizontalRippleX: (rippleOffH ? 0 : rippleH.x)
        //  + (hoverRippleOffH || hoverBlocked ? 0 : hoverRippleH.x))
    property real verticalRippleX:(rippleOffV ? 0 : rippleV.x)
        //  + (hoverRippleOffV || hoverBlocked ? 0 : hoverRippleV.x))

    property real horizontalRippleY:(rippleOffH ? 0 : rippleH.y)
        //  + (hoverRippleOffH || hoverBlocked ? 0 : hoverRippleH.y))

    property real verticalRippleY: (rippleOffV ? 0 : rippleV.y)
        //  + (hoverRippleOffV || hoverBlocked ? 0 : hoverRippleV.y))

    property real t: controller.isHorizontal ? 1 : 0
    property real rx: mix(verticalRippleX, horizontalRippleX, t)
    property real ry: mix(verticalRippleY, horizontalRippleY, t)

    function mix(a,b,t) {
        return a*(1-t) + b*t
    }
    
       
    

    // property real baseX: targetX + vArcOffset 
    // property real baseY: targetY + hArcOffset 
    property real targetX: viewX + rx + shiftX
    property real targetY: viewY + ry + shiftY

    x: targetX
    y: targetY
    // property real animX: targetX
    // property real animY: targetY
    
    property bool allowAnim: true
    property bool snapHex: flick.listViewShown
    property bool targetXanim: false
    
    // Behavior on shiftX {
    //     // enabled: snapHex && allowAnim
    //     NumberAnimation {
    //         duration: Style.animNormal
    //         easing.type: Easing.BezierSpline
    //         easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
    //         // onRunningChanged: {
    //         //     hexItem.targetXanim = running
    //         //     console.log(hexItem.targetXanim)
    //         // }

    //     }
    // }

    // Behavior on shiftY {
    //     // enabled: snapHex && allowAnim
    //     NumberAnimation {
    //         duration: Style.animExpand
    //         easing.type: Easing.BezierSpline
    //         easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
    //     }
    // }

    Behavior on x {
        NumberAnimation {
            duration: Style.animSlow
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.22, 1.0, 0.36, 1.0]
            // easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: Style.animSlow
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.22, 1.0, 0.36, 1.0]
            // easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
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

    // property real hexRadius: 90


    // readonly property real _r: hexRadius
    // readonly property real _cx: _r
    // readonly property real _cy: height / 2
    // readonly property real _cos30: 0.866025
    // readonly property real _sin30: 0.5
  
    
  
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
    
    



        // opacity: borderShown && inView ? 1 : 0
        // anchors.fill: parent
        // opacity: 
        // _inView && (isHovered || isSelected)? 1 : 0
        // visible: _inView && isSelected
        // visible: false
    Shape {
        id: selectedDefaultBorder
        z: 10
        // visible: false
        // visible: WatcherService.thumbsGenerated
        width: hexItem.width
        height: hexItem.height

        x: 0
        y: 0

        scale: visualWrapperRef.visualScale

        // opacity: visualWrapperRef.showThumb 

        Behavior on opacity { 
            NumberAnimation { 
                duration: Style.animNormal; 
                easing.type: Easing.OutCubic 
            } 
        }
        
        preferredRendererType: Shape.CurveRenderer
        antialiasing: true

        ShapePath {
            
            fillColor: "transparent"
                strokeColor: Qt.rgba(0, 0, 0, 0.5)

                
            strokeWidth: 1.5
            pathHints: ShapePath.PathLinear
            strokeStyle: ShapePath.SolidLine
            cosmeticStroke: true
            joinStyle: ShapePath.MiterJoin
            simplify: false

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

        property bool _registered: false

   
    
        Item {
        id: visualWrapper
  
        width: parent.width
        height: parent.height
        clip: false
        // rotation: isSelected ? 90:0
        // Behavior on rotation {
        //     NumberAnimation {
        //         duration: 200
        //     }
        // }
        
        // Behavior on width { NumberAnimation { duration: 150; } }
        // Behavior on height { NumberAnimation { duration: 150; } }
        
     

     
    
        property real visualScale: 1
        // property real visualScale:
        // isSelected ? 1.12 :
        // (hovered ? 1.06 : 1)
        // scale: visualScale

        Behavior on visualScale {
            
            NumberAnimation {
                duration: Style.animExpand
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
                // easing.type: Easing.InOutCubic 
            }
        }



 
        property real flipAngle: 0


      

   
    // opacity: (thumbImage.status === Image.Ready && thumbImage.source != "") ? 0 : 0.08
    property bool showThumb: false
   
    // Timer {
    //     id: thumbDelay
    //     interval: Style.animEnter
    //     running: true
    //     repeat: false
    //     onTriggered: {
    //         visualWrapperRef.showThumb = true
    //     }
    // }

    // onVisibleChanged: {
    //     if (visible) {
    //         showThumb = false
    //         thumbDelay.restart()
    //     }
    // }

    Item {
        id: imageContainer
        anchors.fill: parent
        visible: WatcherService.thumbsGenerated
     
            Rectangle {
                anchors.fill: parent
                z: 10
                // visible: 
                color: "#000000"
                // color: Style.fallbackAccent
                opacity: isSelected ? 0.6 : 0
               
                Behavior on opacity { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                id: hexPlaceholder
            
                anchors.centerIn: parent
                width: hexItem.width * 1.5
                height: hexItem.height * 1.5
                color: Style.fallbackAccent
                // opacity: thumbImage.opacity < 0.99 ? 0.15 : 0
                
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
                // visible: false
                width: isSelected 
                ? hexItem.width * 1.5
                : hexItem.width * 1.5
                height: isSelected
                ? hexItem.height * 1.5
                : hexItem.height * 1.5
                // Behavior on width { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }
                // Behavior on height { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }
                
                sourceSize.width: isSelected 
                ? Math.ceil(Math.max(container.hCellWidth, container.vCellWidth) * 1.5)
                : Math.ceil(Math.max(container.hCellWidth, container.vCellWidth) * 1.5)
                sourceSize.height: isSelected 
                ? Math.ceil(Math.max(container.hCellHeight, container.vCellHeight) * 1.5)
                : Math.ceil(Math.max(container.hCellHeight, container.vCellHeight) * 1.5)
           
                property real visualX: hexItem.width / 2 - width / 2
                property real visualY: hexItem.height / 2 - height / 2
                
                x: visualX + innerParallaxX
                y: visualY + innerParallaxY
                Behavior on width { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }
                // Behavior on x {
                //     enabled: allowAnim
                //     NumberAnimation {
                //         duration: Style.animNormal
                //         easing.type: Easing.BezierSpline
                //         easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
                //     }
                // }

                // Behavior on y {
                //     enabled: allowAnim
                //     NumberAnimation {
                //         duration: Style.animExpand
                //         easing.type: Easing.BezierSpline
                //         easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
                //     }
                // }
                // x: visualX
                // y: visualY
                // anchors.centerIn: parent
                // Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                property string thumbName: WallpaperCacheService.thumbnailPaths[itemData] || ""
                
                source: thumbName && WatcherService.thumbsGenerated
                    ? "file://" + Config.cacheDir + "/" + thumbName
                    : ""

                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                cache: false

                scale: isSelected ? 0.85 : 1
                Behavior on scale {  NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic }}

                opacity:
                status === Image.Ready
                ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Style.animEnter; easing.type: Easing.InCubic } }
                
                // layer.enabled: true
                //     layer.effect: MultiEffect {
                        
                //         blurEnabled: true
                //         blur: (isSelected &&
                //         controller.blurTransition) ? 1 : 0
                //         blurMax: 32

                //         Behavior on blur {
                //             NumberAnimation {
                //                 duration: Style.animFast
                //                 easing.type: Easing.OutCubic
                //             }
                //         }
                // }
            }

    }
   
    layer.enabled: true
        layer.smooth: true

        layer.effect: OpacityMask {
        maskSource: Shape {
        id: hexShape
        visible: false
        width: hexItem.width
        height: hexItem.height
        preferredRendererType: Shape.CurveRenderer
        antialiasing: true
        asynchronous: false

        ShapePath {
            fillColor: "white"
            strokeWidth: 0
            pathHints: ShapePath.PathLinear
            simplify: false
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

        property real dirBias: nearLeft ? -1 : 1
       
    }
    
  
    
    property bool _flipLock: false
    property bool _flipQueued: false
   
    property string hash: ""
    property string thumbFile: ""
        // property string thumbName:
        // WallpaperCacheService.thumbnailPaths[itemData] || ""

 

    // Component.onCompleted: {
    //     // wallpaperController.currentIndex = 0
    //     // allowAnim = false
    //     // Qt.callLater(() => {
    //     //     allowAnim = true
    //     // })
    //     // console.log("x:", hexItem.targetX, "y:", hexItem.targetY)
    //     // console.log(itemIndex)
    //     // console.log("hex create", index)
    //     // animTimer.start()
    // }
        // console.log(flatIndex)

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
        // console.log(wallpaperController.currentIndex)
        // var p = flick.contentItem.mapFromItem(flick.currentItem, 0, 0)
        // console.log("item position: ", p.x, p.y)
        //  console.log(flickRef.currentIndex)
        // console.log("current index: ", flick.currentItem.x)
        // "selected col: ", flick._selectedCol)
        // anim.restart()
        controller.previousItem = controller.currentItem
        controller.currentItem = hexItem 
      
        wallpaperController.requestFrame()
    }   
            // console.log("previous: ", controller.previousItem.itemIndex)
            // console.log("item: ", controller.currentItem.itemIndex)
    

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: flickRef.listViewShown ? true : false

    
        onClicked: {
            // if(!inView || !flickRef.listViewShown) {
            //     flickRef.forceActiveFocus() 
            //     return
            // }
            
            // controller.previousIndex = wallpaperController.currentIndex
            flickRef.forceActiveFocus()
            wallpaperController.currentIndex = itemIndex
            // flickRef.forceActiveFocus() 
        }

        onDoubleClicked: {
            if(!inView || !flickRef.listViewShown) return
            WallpaperApplyService.applyWallpaper(itemData)
        }

        // onEntered: {
        //     if(!inView) return
        //     // controller.previousHoveredIndex = controller.hoveredIndex
        //     // controller.hoveredIndex = itemIndex
        // }
        // onExited: {
        //     // if (controller.hoveredIndex === itemIndex)
        //     //     controller.hoveredIndex = -1
        // }
    }
}