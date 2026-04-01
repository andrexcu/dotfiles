pragma ComponentBehavior: Bound

import qs.services
import qs.modules.config
import QtQuick

Text {
    id: root

    property bool animate: false
    property bool slideText: false
    property string animateProp: "scale"
    property real animateFrom: 0
    property real animateTo: 1
    property int animateDuration: AppearanceHelper.anim.durations.normal
    
    renderType: Text.NativeRendering
    textFormat: Text.PlainText
    color: Colours.palette.m3onSurface
    // property string sans: "Rubik"
    // property string mono: "CaskaydiaCove NF"
    font.family: AppearanceHelper.font.family.sans
    font.pointSize: AppearanceHelper.font.size.smaller

    Behavior on color {
        CAnim {}
    }

    Behavior on text {
        enabled: root.animate

        SequentialAnimation {
            Anim {
                to: root.animateFrom
                easing.bezierCurve: AppearanceHelper.anim.curves.standardAccel
            }
            PropertyAction {}
            Anim {
                to: root.animateTo
                easing.bezierCurve: AppearanceHelper.anim.curves.standardDecel
            }
        }
    }

    component Anim: NumberAnimation {
        target: root
        property: root.animateProp
        duration: root.animateDuration / 2
        easing.type: Easing.BezierSpline
    }
}
