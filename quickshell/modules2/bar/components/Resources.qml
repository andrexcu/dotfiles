import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts
import qs.modules.bar
MouseArea {
    id: root
    property bool borderless: Config.options?.bar?.borderless ?? false
    property bool alwaysShowAllResources: true
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: true

    Component.onCompleted: ResourceUsage.ensureRunning()

    RowLayout {
        id: rowLayout

        spacing: 12
        anchors.fill: parent
        anchors.leftMargin: 4
        // anchors.rightMargin: 4

        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            shown: true
            warningThreshold: 90
        }

        Resource {
            iconName: "thermostat"
            percentage: ResourceUsage.tempPercentage
            shown: true
            Layout.leftMargin: shown ? 6 : 0
            cautionThreshold: 65
            warningThreshold: 80
        }

        Resource {
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: true
            // Layout.leftMargin: shown ? 6 : 0
            warningThreshold: 90
        }

        Resource {
            iconName: "memory_alt"
            percentage: ResourceUsage.gpuUsage
            shown: false
            warningThreshold: 90
        }
    }

    ResourcesPopup {
        hoverTarget: root
    }
}
