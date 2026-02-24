// @ pragma UseQApplication

import Quickshell
import QtQuick
// import "./modules/bar"
import "./modules/wallpaper"
import "./colors/"

ShellRoot {
    id: root

    // Instantiate your Colors object
    Colors {
        id: colors
    }

    Selector {}


}

// ShellRoot {
//     id: root

//     // Instantiate your Colors object
//     Colors {
//         id: colors
//     }

//     Loader {
//         id: barLoader  
//         active: true
//         sourceComponent: Bar {}
//     }

//     Component.onCompleted: {
//         console.log("Color JSON text:", colors.colorFile.text())
//         console.log("Parsed colorData:", colors.colorData)
        
//         if (barLoader.item) {
//             barLoader.item.colorsPalette = colors
//         }
//     }
// }