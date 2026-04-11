import qs.components
import QtQuick


NumberAnimation {
    property int animDuration: AnimList.anim.durations.normal
    property var animCurve: AnimList.anim.curves.standard

    duration: animDuration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: animCurve
}

// NumberAnimation {
//     duration: AnimList.anim.durations.normal
//     easing.type: Easing.BezierSpline
//     easing.bezierCurve: AnimList.anim.curves.standard
// }
