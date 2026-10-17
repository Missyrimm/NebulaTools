import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nebula 1.0

Rectangle {
    id: dropZone
    radius: Theme.radius
    color: Theme.surface
    border.width: dragging ? 2 : 1
    border.color: dragging ? Theme.accent : Theme.border

    property bool dragging: false
    property var fileInfo: null

    signal fileDropped(string path)
    signal browseClicked

    Behavior on border.color { ColorAnimation { duration: Theme.animNormal } }
    Behavior on color        { ColorAnimation { duration: Theme.animNormal } }

    // ---- Accent glow when dragging ----
    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: parent.radius + 2
        color: "transparent"
        border.width: 2
        border.color: Theme.accentGlow
        opacity: dropZone.dragging ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.spaceM

        // Breathing arrow
        Text {
            id: arrow
            Layout.alignment: Qt.AlignHCenter
            text: "\uE896"
            color: Theme.accent
            font.family: Theme.iconFamily
            font.pixelSize: 44

            SequentialAnimation on scale {
                loops: Animation.Infinite
                running: dropZone.Window.window.visibility !== Window.Minimized
                NumberAnimation { to: 1.08; duration: 1200; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.00; duration: 1200; easing.type: Easing.InOutSine }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Перетащите .FLP или .ZIP сюда"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontH3
            font.weight: Font.DemiBold
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "или нажмите, чтобы выбрать"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            width: 160; height: 34
            radius: Theme.radiusSmall
            color: btnHov.hovered ? Theme.surfaceHover : "transparent"
            border.width: 1
            border.color: Theme.accent

            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            Text {
                anchors.centerIn: parent
                text: "Выбрать файл"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                font.weight: Font.Medium
            }

            HoverHandler { id: btnHov; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: dropZone.browseClicked() }
        }
    }

    // ---- Drag & drop ----
    DropArea {
        anchors.fill: parent
        onEntered: (drag) => {
            if (drag.hasUrls) {
                dropZone.dragging = true
                drag.accept(Qt.CopyAction)
            }
        }
        onExited: dropZone.dragging = false
        onDropped: (drop) => {
            dropZone.dragging = false
            if (drop.hasUrls && drop.urls.length > 0) {
                dropZone.fileDropped(drop.urls[0].toString())
            }
        }
    }
}