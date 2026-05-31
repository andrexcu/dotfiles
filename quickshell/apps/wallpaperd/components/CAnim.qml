
import qs.components
import QtQuick

ColorAnimation {
    duration: AnimList.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: AnimList.anim.curves.standard
}
