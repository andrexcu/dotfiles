import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.colors
import "."


QtObject {
  property var colorsPalette: Colors{}
 

  //top connectors
  property var topLeft: PanelWindow {
    
    anchors { top: true; left: true }
    margins { top: -2; left: -2 }
    implicitWidth: 15; implicitHeight: 15
    color: "transparent"
    
    Shape {
      anchors.fill: parent
        layer.enabled: true; layer.samples: 8
      antialiasing: true
      ShapePath {
        strokeWidth: 0; 
        strokeColor: "transparent"; 
        fillColor: colorsPalette.backgroundt70   
                  
        startX: 0; startY: 15
        PathLine { x: 0; y: 0 }
        PathLine { x: 15; y: 0 }
        PathQuad { x: 0; y: 15; controlX: 0; controlY: 0 }
      }
              
      ShapePath {
        strokeWidth: 2         
        strokeColor: colorsPalette.primary
        fillColor: colorsPalette.primary
        capStyle: ShapePath.RoundCap 
        
        startX: 15; startY: 0 
        PathLine { x: 15; y: 1 }
        PathQuad { 
          x: 1; y: 15
          controlX: 0; controlY: 0 
        }
        PathLine { x: 0; y: 15 }
        PathQuad { 
          x: 15; y: 0
          controlX: 0; controlY: 0 
        }
      }
    }
  }


 property var topRight: PanelWindow {
    anchors { top: true; right: true } 
    margins { top: -2; right: -2 }
    implicitWidth: 15; implicitHeight: 15
    color: "transparent"

    Shape {
      anchors.fill: parent
      layer.enabled: true; layer.samples: 8
      antialiasing: true
      transform: Scale { origin.x: 7.5; xScale: -1 } 

      ShapePath {
        strokeWidth: 0; 
        strokeColor: "transparent"; 
        fillColor: colorsPalette.backgroundt70            
        startX: 0; startY: 15
        PathLine { x: 0; y: 0 }
        PathLine { x: 15; y: 0 }
        PathQuad { x: 0; y: 15; controlX: 0; controlY: 0 }
      }
      ShapePath {
        strokeWidth: 2         
        strokeColor: colorsPalette.primary
        fillColor: colorsPalette.primary

        capStyle: ShapePath.RoundCap 
        
        startX: 15; startY: 0 
        PathLine { x: 15; y: 1 }
        PathQuad { 
          x: 1; y: 15
          controlX: 0; controlY: 0 
        }
        PathLine { x: 0; y: 15 }
        PathQuad { 
          x: 15; y: 0
          controlX: 0; controlY: 0 
        }
      }
    }
  }

// property var topRight: PanelWindow {
//     anchors { top: true; right: true } 
//     margins { top: -2; right: -2 }
//     implicitWidth: 15  // doubled
//     implicitHeight: 15  // doubled
//     color: "transparent"

//     Shape {
//         anchors.fill: parent
//         layer.enabled: true; 
//         layer.samples: 8
//         antialiasing: true
//         // mirror horizontally like before
//         transform: Scale { origin.x: 7.5; xScale: -1 } 

//         // Main filled shape
//         ShapePath {
//             strokeWidth: 0
//             strokeColor: "transparent"
//             fillColor: colorsPalette.backgroundt70
//             startX: 0; startY: 20   // doubled
//             PathLine { x: 0; y: 0 }
//             PathLine { x: 20; y: 0 } // doubled
//             PathQuad { x: 0; y: 20; controlX: 0; controlY: 0 } // doubled
//         }
        
//         // Border / highlight
//         ShapePath {
//             strokeWidth: 1
//             strokeColor: colorsPalette.primary
//             // fillColor: colorsPalette.primary
//             capStyle: ShapePath.RoundCap 
            
//             startX: 20; startY: 0    // doubled
//             PathLine { x: 20; y: 2 }  // doubled Y thickness
//             PathQuad { 
//                 x: 2; y: 20         // doubled
//                 controlX: 0; controlY: 0 
//             }
//             PathLine { x: 0; y: 20 }  // doubled
//             PathQuad { 
//                 x: 20; y: 0          // doubled
//                 controlX: 0; controlY: 0 
//             }
//         }
//     }
// }

 // bottom connectors 
  property var bottomLeft: PanelWindow {
    anchors { bottom: true; left: true }
    margins { bottom: -2; left: -2 }
    implicitWidth: 15; implicitHeight: 15
    color: "transparent"

    Shape {
      anchors.fill: parent
      layer.enabled: true; 
      layer.samples: 8
      antialiasing: true
      ShapePath {
        strokeWidth: 0; 
        strokeColor: "transparent"; 
        fillColor: colorsPalette.backgroundt70   
        startX: 0; startY: 0
        PathLine { x: 0; y: 15 }
        PathLine { x: 15; y: 15 }
        PathQuad { x: 0; y: 0; controlX: 0; controlY: 15 }
      }
        
      ShapePath {
        strokeWidth: 2         
        strokeColor: colorsPalette.primary
        fillColor: colorsPalette.primary
        capStyle: ShapePath.RoundCap 
        startX: 0; startY: 0 
        PathLine { x: 1; y: 0 }
        PathQuad { x: 15; y: 14; controlX: 0; controlY: 15 }
        PathLine { x: 15; y: 15 }
        PathQuad { x: 0; y: 0; controlX: 0; controlY: 15 }
      }
    }
  }

  property var bottomRight: PanelWindow {
    anchors { bottom: true; right: true }
    margins { bottom: -2; right: -2 }
    implicitWidth: 15; implicitHeight: 15
    color: "transparent"

    Shape {
      anchors.fill: parent
      layer.enabled: true; 
      layer.samples: 8
      antialiasing: true

      transform: Scale { origin.x: 7.5; xScale: -1 } 
      ShapePath {
        strokeWidth: 0; 
        strokeColor: "transparent"; 
        fillColor: colorsPalette.backgroundt70   
        
        startX: 0; startY: 0
        PathLine { x: 0; y: 15 }
        PathLine { x: 15; y: 15 }
        PathQuad { x: 0; y: 0; controlX: 0; controlY: 15 }
      }

      ShapePath {
        strokeWidth: 2         
        strokeColor: colorsPalette.primary
        fillColor: colorsPalette.primary
        capStyle: ShapePath.RoundCap 
        
        startX: 0; startY: 0 
        PathLine { x: 1; y: 0 }
        PathQuad { x: 15; y: 14; controlX: 0; controlY: 15 }
        PathLine { x: 15; y: 15 }
        PathQuad { x: 0; y: 0; controlX: 0; controlY: 15 }
      }
    }
  }
}
