import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"

Rectangle {
    id: titleBar
    height: 44
    color: "transparent"

    signal closeClicked

    MouseArea {
        anchors.fill: parent
        onPressed: titleBar.Window.window.startSystemMove()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 8
        spacing: 8

        Rectangle {
            width: 22; height: 22
            radius: 6
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
            Layout.alignment: Qt.AlignVCenter
            Text {
                anchors.centerIn: parent
                text: "\uE8AB"
                font.family: Theme.iconFamily
                font.pixelSize: 11
                color: Theme.accent
            }
        }

        Text {
            text: "NebulaTools · Setup"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontH3
            font.weight: Font.DemiBold
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            width: 36; height: 30
            radius: Theme.radiusSmall
            Layout.alignment: Qt.AlignVCenter
            color: closeHov.hovered ? "#E81123" : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            Text {
                anchors.centerIn: parent
                text: "\uE8BB"
                font.family: Theme.iconFamily
                font.pixelSize: 10
                color: closeHov.hovered ? "#FFFFFF" : Theme.textSecondary
            }
            HoverHandler { id: closeHov; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: titleBar.closeClicked() }
        }
    }
}