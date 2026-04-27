pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io as Io

QtObject {
    id: notificationService

    property QtObject notifyProcess: Io.Process {
        command: []
    }

    function show(title, msg, id = 0, icon = "", timeout = 3000) {
        let args = ["notify-send"]

        if (id)
            args.push("-r", id)

        if (icon)
            args.push("-i", icon)

        if (timeout > 0)
            args.push("-t", timeout)
        args.push(title, msg)

        notifyProcess.exec(args)
    }
}