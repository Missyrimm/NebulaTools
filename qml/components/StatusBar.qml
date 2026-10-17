import QtQuick
import QtQuick.Layouts
import Nebula 1.0
import QtQuick.Controls

Rectangle {
    id: root
    height: 40
    color: "transparent"

    property string text: "Готов к работе"
    property color dotColor: Theme.success

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceL
        anchors.rightMargin: Theme.spaceL
        spacing: Theme.spaceS

        // Статус
        Rectangle {
            width: 8; height: 8
            radius: 4
            color: root.dotColor

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: root.Window.window.visibility !== Window.Minimized
                NumberAnimation { to: 0.4; duration: 1400; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 1400; easing.type: Easing.InOutSine }
            }
        }

        Text {
            text: root.text
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }

        Item { Layout.fillWidth: true }

        // Соцфутер
        RowLayout {
            spacing: 0

            Text {
                text: "by "
                color: Theme.textTertiary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
            }

            Text {
                id: authorLink
                text: "@youngweepo"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.weight: Font.DemiBold

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: authorLink.font.underline = hovered
                }
                TapHandler {
                    onTapped: Qt.openUrlExternally("https://t.me/youngweepo")
                }
            }

            // Разделитель
            Rectangle {
                width: 4; height: 4
                radius: 2
                color: Theme.textTertiary
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                id: channelLink
                text: "@nebulatools"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.weight: Font.DemiBold

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: channelLink.font.underline = hovered
                }
                TapHandler {
                    onTapped: Qt.openUrlExternally("https://t.me/nebulatools")
                }
            }
        }
    }
}