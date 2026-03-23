import qs.services
import qs.modules.common.components
import qs.modules.config

StyledText {
    property real fill
    property int grade: Colours.light ? 0 : -25

    font.family: Appearance.font.family.material
    font.pointSize: Appearance.font.size.extraLarge
    font.variableAxes: ({
            FILL: fill.toFixed(1),
            GRAD: grade,
            opsz: fontInfo.pixelSize,
            wght: fontInfo.weight
        })
}
