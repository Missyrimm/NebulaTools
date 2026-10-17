import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nebula 1.0

Rectangle {
    id: titleBar
    height: 44
    color: "transparent"

    property string sectionName: "Главная"

    signal minimizeClicked
    signal maximizeClicked
    signal closeClicked

    MouseArea {
        anchors.fill: parent
        onPressed: titleBar.Window.window.startSystemMove()
        onDoubleClicked: {
            var w = titleBar.Window.window
            w.visibility === Window.Maximized ? w.showNormal() : w.showMaximized()
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceL
        anchors.rightMargin: Theme.spaceS
        spacing: Theme.spaceS

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
            text: "NebulaTools"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontH3
            font.weight: Font.DemiBold
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            width: 1
            height: 14
            color: Theme.border
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: titleBar.sectionName
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        Row {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter

            component WinBtn: Rectangle {
                id: btn
                width: 36
                height: 30
                radius: Theme.radiusSmall

                property string glyph: ""
                property color glyphColor: Theme.textSecondary
                property color hoverColor: Theme.surfaceHover
                property bool isClose: false

                signal clicked

                HoverHandler {
                    id: hovHandler
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: btn.clicked()
                }

                color: hovHandler.hovered ? btn.hoverColor : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: btn.glyph
                    color: {
                        if (!hovHandler.hovered) return btn.glyphColor
                        if (btn.isClose) return "#FFFFFF"
                        return btn.glyphColor
                    }
                    font.family: Theme.iconFamily
                    font.pixelSize: 10
                }
            }

            WinBtn {
                glyph: "\uE921"
                onClicked: titleBar.minimizeClicked()
            }

            WinBtn {
                glyph: "\uE922"
                onClicked: titleBar.maximizeClicked()
            }

            WinBtn {
                glyph: "\uE8BB"
                isClose: true
                hoverColor: "#E81123"
                onClicked: titleBar.closeClicked()
            }
        }
    }
}