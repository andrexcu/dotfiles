import qs.modules.config
import QtQuick

NumberAnimation {
    duration: AppearanceHelper.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: AppearanceHelper.anim.curves.standard
}
