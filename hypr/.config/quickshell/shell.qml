// @ pragma UseQApplication

import Quickshell
import QtQuick
import qs.modules.bar
// import qs.colors

// import QtQuick


ShellRoot {
    id: root
    Bar {}
}
// ShellRoot {
//     id: root

//     // Invisible Item to catch key presses
//     Item {
//         id: keyCatcher
//         anchors.fill: parent
//         focus: true        // must have focus for Keys to work
//         Keys.onPressed: {
//             if (event.key === Qt.Key_B && (event.modifiers & Qt.AltModifier)) {
//                 if (!bar) {
//                     // lazy-load the bar
//                     barLoader.active = true
//                 } else {
//                     bar.visible = !bar.visible
//                 }
//                 event.accepted = true
//             }
//         }
//     }

//     Loader {
//         id: barLoader
//         active: false      // start hidden
//         sourceComponent: Bar {}
//         onLoaded: {
//             bar = item
//         }
//     }

//     property var bar: null   // reference to the loaded Bar
// }