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
    property var flickRef
    property var container

    property bool inView
    property bool isSelected: controller.currentIndex === itemIndex
    onIsSelectedChanged: {
        if (isSelected) {
            wallpaperController.currentSelected = hexItem
        }
    }
    property var itemData
    property int itemIndex
    width: flickRef.cellWidth - 10
    height: flickRef.cellHeight - 10
    property real targetX
    property real targetY
    x: targetX
    y: targetY
   
    property bool imageReady: thumbImage.status === Image.Ready && thumbImage.paintedWidth > 0
    property int currentScale
    property bool isHidden: false

    MouseArea {
        anchors.fill: parent
         z: itemIndex
        enabled: true
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
//    property real baseX: flickRef.itemX(itemIndex)
// property real baseY: flickRef.gridY(itemIndex)

// property var ripple: flickRef.ripple(itemIndex)

// property real targetX: baseX + ripple.x
// property real targetY: baseY + flickRef.gridOffsetY() + ripple.y
//  x: targetX

//     y: targetY

     
    // property real targetX: baseX + shiftX
	//  property real targetY: baseY + shiftY
    property real _lastTop: -1
    property real _lastBottom: -1
    

    function computeShiftX() {
        var selIndex = controller.currentIndex
        if (itemIndex === selIndex) return 0

        // If selected hex is scaled to 0 (offscreen), don't give space
        
        if (!controller.selectedVisual || controller.selectedVisual.visualScale < 1) return 0;

        var cols = flickRef.columns
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
   
   

    Connections {
        target: wallpaperController

        function onCurrentIndexChanged() {
            Qt.callLater(() => flick.updateGridFocusOffset())
        }
    }
    
    // Connections {
    //     target: controller.currentSelected
    //             ? controller.currentSelected.visualWrapperRef
    //             : null
                
    //     function onScaleChanged() {
    //         // console.log("test")
    //         // updateShift()
    //         flickRef.updateGridFocusOffset() 
    //     }
    // }
    
   
    function computeShiftY() {
        var selIndex = controller.currentIndex
        if (itemIndex === selIndex) return 0

        // If selected hex is scaled to 0 (offscreen), don't give space
        // var controller.selectedVisual = controller.currentSelected?.visualWrapperRef;
        if (!controller.selectedVisual || controller.selectedVisual.visualScale === 0) return 0;

        var cols = flickRef.columns
        var selRow = Math.floor(selIndex / cols)
        var row = Math.floor(itemIndex / cols)

        if (row < selRow) return -10
        if (row > selRow) return 10
        return 0
    }

   
    
    Behavior on x {
        // enabled: flickRef.firstUpdateDone
        NumberAnimation {
            duration: 400
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]
        }
    }

    Behavior on y {
        // enabled: flickRef.firstUpdateDone
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

    property bool _visibleState: true

    
        Item {
        id: visualWrapper
  
        width: parent.width
        height: parent.height
         
        property alias flipAnim: flipAnim

        //  Component.onCompleted: {
        //       Qt.callLater(() => {
        //            console.log("i=", flatIndex, 
        //             "data=", itemData,
        //             "visualscale=", visualScale)
        //       })
         
          
        // }

        property real fadeOpacity: inView ? 1 : 0
        // property real visualScale: inView ? 1 : 0

        property real _yCenter: y + height * 0.5
        property real _viewTop: flick.contentY
        property real _viewBottom: flick.contentY + flick.height
        property real _fadeZone: flick.height * 0.2

        
        property real visualScale: inView ? (isSelected ? 1.12 : 1) : 0
         scale: visualScale	
        opacity: fadeOpacity
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
            duration: 350
            easing.type: Easing.InOutQuad
        }

    Image {
        id: thumbImage
        fillMode: Image.PreserveAspectCrop
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

        Rectangle {
            anchors.fill: parent
            visible: true
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
    

}