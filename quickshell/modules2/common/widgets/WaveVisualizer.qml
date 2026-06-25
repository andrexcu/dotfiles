import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Effects

Canvas { // WaveVisualizer
    id: root
    property list<var> points
    property list<var> smoothPoints
    property real maxVisualizerValue: 1000
    property int smoothing: 2
    property bool live: true
    property bool blurred: true
    property color color: Appearance.m3colors.m3primary
    property bool centered: false   // <-- new property

    onPointsChanged: root.requestPaint()
    anchors.fill: parent

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        var points = root.points;
        var maxVal = root.maxVisualizerValue || 1;
        var h = height;
        var w = width;
        var n = points.length;
        if (n < 2) return;

        // Smoothing: simple moving average (optional)
        var smoothWindow = root.smoothing;
        root.smoothPoints = [];
        for (var i = 0; i < n; ++i) {
            var sum = 0, count = 0;
            for (var j = -smoothWindow; j <= smoothWindow; ++j) {
                var idx = Math.max(0, Math.min(n - 1, i + j));
                sum += points[idx];
                count++;
            }
            root.smoothPoints.push(sum / count);
        }

        if (!root.live) root.smoothPoints.fill(0); // no points if not live

        ctx.beginPath();

        if (root.centered) {
            // Draw waveform centered vertically
            ctx.moveTo(0, h/2);
            for (var i = 0; i < n; ++i) {
                var x = i * w / (n - 1);
                var y = h/2 - (root.smoothPoints[i] / maxVal) * (h/2);
                ctx.lineTo(x, y);
            }
            for (var i = n-1; i >= 0; --i) {
                var x = i * w / (n - 1);
                var y = h/2 + (root.smoothPoints[i] / maxVal) * (h/2);
                ctx.lineTo(x, y);
            }
        } else {
            // Default: draw from bottom
            ctx.moveTo(0, h);
            for (var i = 0; i < n; ++i) {
                var x = i * w / (n - 1);
                var y = h - (root.smoothPoints[i] / maxVal) * h;
                ctx.lineTo(x, y);
            }
            ctx.lineTo(w, h);
        }

        ctx.closePath();

        ctx.fillStyle = Qt.rgba(
            root.color.r,
            root.color.g,
            root.color.b,
            root.blurred ? 0.15 : 0.25
        );
        ctx.fill();
    }

    layer.enabled: blurred
    layer.effect: MultiEffect {
        source: root
        saturation: 0.2
        blurEnabled: true
        blurMax: 7
        blur: 1
    }
}