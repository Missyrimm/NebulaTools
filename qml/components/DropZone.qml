import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nebula 1.0

Rectangle {
    id: dropZone
    radius: Theme.radiusLarge
    color: Theme.surface
    border.width: dragging ? 2 : 1
    border.color: dragging ? Theme.accent : Theme.border

    property bool dragging: false
    signal fileDropped(string path)
    signal browseClicked

    Behavior on border.color { ColorAnimation { duration: Theme.animNormal } }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: parent.radius + 2
        color: "transparent"
        border.width: 2
        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4)
        opacity: dropZone.dragging ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceL
        spacing: 0

        // Визуализация: 2 трека, полоски бегут СТРОГО внутри трека
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 60

            // Верхний трек
            Rectangle {
                x: parent.width * 0.12
                y: parent.height * 0.22
                width: parent.width * 0.32
                height: 3
                radius: 1.5
                color: Theme.borderLight
                clip: true

                Rectangle {
                    width: 30; height: 3; radius: 1.5
                    color: Theme.accent
                    x: -30
                    SequentialAnimation on x {
                        loops: Animation.Infinite
                        running: dropZone.Window.window.visibility !== Window.Minimized
                        NumberAnimation {
                            from: -30
                            to: parent.parent.width
                            duration: 1400
                            easing.type: Easing.InOutQuad
                        }
                        PauseAnimation { duration: 500 }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "\uE72A"
                font.family: Theme.iconFamily
                font.pixelSize: 26
                color: Theme.accent
            }

            // Нижний трек
            Rectangle {
                x: parent.width * 0.56
                y: parent.height * 0.72
                width: parent.width * 0.32
                height: 3
                radius: 1.5
                color: Theme.borderLight
                clip: true

                Rectangle {
                    width: 30; height: 3; radius: 1.5
                    color: Theme.accent
                    x: parent.width
                    SequentialAnimation on x {
                        loops: Animation.Infinite
                        running: dropZone.Window.window.visibility !== Window.Minimized
                        NumberAnimation {
                            from: parent.parent.width
                            to: -30
                            duration: 1400
                            easing.type: Easing.InOutQuad
                        }
                        PauseAnimation { duration: 500 }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

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
            Layout.topMargin: 4
        }

        Item { Layout.preferredHeight: Theme.spaceM }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 180
            height: 40
            radius: Theme.radiusSmall
            color: btnHov.hovered ? Theme.accentHover : Theme.accent

            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    text: "\uE8B7"
                    font.family: Theme.iconFamily
                    font.pixelSize: 14
                    color: "#FFFFFF"
                }
                Text {
                    text: "Выбрать файл"
                    color: "#FFFFFF"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.weight: Font.DemiBold
                }
            }

            HoverHandler { id: btnHov; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: dropZone.browseClicked() }
        }

        Item { Layout.fillHeight: true }
    }

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