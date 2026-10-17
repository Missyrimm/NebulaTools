import QtQuick
import QtQuick.Layouts
import Nebula 1.0

Rectangle {
    id: root
    height: 34
    color: "transparent"

    property string text: "Готов к работе"
    property color dotColor: Theme.success

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceL
        anchors.rightMargin: Theme.spaceL
        spacing: 8

        Rectangle {
            width: 8; height: 8
            radius: 4
            color: root.dotColor

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: root.Window.window.visibility !== Window.Minimized
                NumberAnimation { to: 0.5; duration: 1400; easing.type: Easing.InOutSine }
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

        Row {
            spacing: 6
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: "by"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
            }

            Text {
                text: backend.authorHandle
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.weight: Font.DemiBold
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally(backend.authorUrl)
                }
            }

            Text {
                text: "·"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
            }

            Text {
                text: backend.channelHandle || backend.channelName
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.weight: Font.DemiBold
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally(backend.channelUrl)
                }
            }
        }
    }
}