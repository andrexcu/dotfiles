import qs.services
import qs.modules.common.components
import qs.modules.config

StyledTextAnim {
    property real fill
    property int grade: -25

    font.family: AppearanceHelper.font.family.material
    font.pointSize: AppearanceHelper.font.size.large
    font.variableAxes: ({
            FILL: fill.toFixed(1),
            GRAD: grade,
            opsz: fontInfo.pixelSize,
            wght: fontInfo.weight
        })
}
