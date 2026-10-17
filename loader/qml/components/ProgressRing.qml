import QtQuick
import "../"

Item {
    id: root
    width: 160
    height: 160

    property real progress: 0
    property color accentColor: Theme.accent
    property string label: ""

    // Фоновое кольцо
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: 6
        border.color: Theme.border
    }

    // Прогресс-кольцо через Canvas
    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var cx = width / 2
            var cy = height / 2
            var r = width / 2 - 3

            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, 2 * Math.PI)
            ctx.strokeStyle = Theme.border
            ctx.lineWidth = 6
            ctx.stroke()

            if (root.progress > 0) {
                var angle = (root.progress / 100) * 2 * Math.PI - Math.PI / 2
                ctx.beginPath()
                ctx.arc(cx, cy, r, -Math.PI / 2, angle)
                ctx.strokeStyle = root.accentColor
                ctx.lineWidth = 6
                ctx.lineCap = "round"
                ctx.stroke()
            }
        }
        Connections {
            target: root
            function onProgressChanged() { canvas.requestPaint() }
            function onAccentColorChanged() { canvas.requestPaint() }
        }
        Component.onCompleted: requestPaint()
    }

    // Морковка/логотип
    Column {
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "🥕"
            font.pixelSize: 40
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            font.weight: Font.DemiBold
            visible: root.label !== ""
        }
    }
}