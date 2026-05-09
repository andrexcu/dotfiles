import qs.components
import QtQuick


NumberAnimation {
    // property int animDuration: AnimList.durations.normal
    // property var animCurve: AnimList.curves.standard

    // property var emphasized
    // property var emphasizedAccel
    // property var emphasizedDecel

    // property var standard
    // property var standardAccel
    // property var standardDecel

    // property var expressiveFastSpatial
    // property var expressiveDefaultSpatial
    // property var expressiveEffects

    property var animCurve: AnimList.curves.standardDecel
    property int animDuration: AnimList.durations.fast
    duration: animDuration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: animCurve
}

// NumberAnimation {
//     duration: AnimList.anim.durations.normal
//     easing.type: Easing.BezierSpline
//     easing.bezierCurve: AnimList.anim.curves.standard
// }
