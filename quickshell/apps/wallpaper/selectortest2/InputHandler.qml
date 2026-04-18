pragma Singleton
import QtQuick
import Quickshell
import QtQuick.Controls
import qs

QtObject {

    // function to traverse the hexagon grid
    function navigate(event, ctx) {

    if (!ctx.size) return false

    let index = ctx.currentIndex
    let row = Math.floor(index / ctx.columns)
    let col = index % ctx.columns

    switch (event.key) {

    case Qt.Key_Right: col++; break
    case Qt.Key_Left:  col--; break
    case Qt.Key_Down:  row++; break
    case Qt.Key_Up:    row--; break

    case Qt.Key_Return:
    case Qt.Key_Enter:
        ctx.onApply(index)
        return true

    default:
        return false
    }

    if (col < 0 || col >= ctx.columns)
        return true

    let target = row * ctx.columns + col

    if (target < 0 || target >= ctx.size)
        return true

    if (ctx.onMove)
        ctx.onMove(target)

    return true
}

    // handles ~ expansion / relative paths / duplicate slashes / .. 
    function normalizePath(p) {
        if (!p) return ""

        p = p.trim()

        // remove file:// prefix
        if (p.startsWith("file://"))
            p = p.slice(7)

        // windows -> unix basic
        p = p.replace(/\\/g, "/")

        // ~ home
        if (p.startsWith("~"))
            p = Config.homeDir + p.slice(1)

        // app shortcuts
        if (p.startsWith("Pictures/") || p.startsWith("/Pictures/"))
            p = Config.homeDir + "/" + p.replace(/^\/?Pictures/, "Pictures")

        // fix missing root but looks absolute
        if (/^[a-zA-Z]:\//.test(p))
            return Config.homeDir

        // relative
        if (!p.startsWith("/"))
            p = Config.homeDir + "/" + p

        // collapse slashes
        p = p.replace(/\/+/g, "/")

        // resolve . and ..
        let parts = p.split("/")
        let stack = []

        for (let part of parts) {
            if (!part || part === ".") continue
            if (part === "..") stack.pop()
            else stack.push(part)
        }

        p = "/" + stack.join("/")
            
        if (p.length > 1 && p.endsWith("/"))
            p = p.slice(0, -1)

        return p
    }
}