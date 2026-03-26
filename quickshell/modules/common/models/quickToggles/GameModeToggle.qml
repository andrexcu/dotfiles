
import qs.modules.common.models.hyprland
import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    id: root
    name: Translation.tr("Game mode")
    icon: "sports_esports"

    // THIS is your state
    // no need to redefine it

    mainAction: () => {
        const next = !root.toggled
        root.toggled = next

        if (next) {
            Quickshell.execDetached(["hyprctl", "--batch",
                "keyword animations:enabled 0;" +
                "keyword decoration:shadow:enabled 0;" +
                "keyword decoration:blur:enabled 0;" +
                "keyword general:gaps_in 0;" +
                "keyword general:gaps_out 0;" +
                "keyword general:border_size 1;" +
                "keyword decoration:rounding 0;" +
                "keyword general:allow_tearing 1"
            ])
        } else {
            Quickshell.execDetached(["hyprctl", "--batch",
                "keyword animations:enabled 1;" +
                "keyword decoration:shadow:enabled 1;" +
                "keyword decoration:blur:enabled 1;" +
                "keyword general:gaps_in 5;" +
                "keyword general:gaps_out 10;" +
                "keyword general:border_size 2;" +
                "keyword decoration:rounding 8;" +
                "keyword general:allow_tearing 0"
            ])
        }
    }

    tooltipText: Translation.tr("Game mode")
}