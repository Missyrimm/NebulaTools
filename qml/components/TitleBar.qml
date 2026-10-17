import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nebula 1.0

Rectangle {
    id: titleBar
    height: 44
    color: "transparent"

    property string sectionName: "Конвертер"

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

        Image {
            id: logoIcon
            source: "../../assets/icons/logo.png"
            sourceSize.width: 20
            sourceSize.height: 20
            fillMode: Image.PreserveAspectFit
            Layout.alignment: Qt.AlignVCenter
            visible: status === Image.Ready
        }

        Text {
            text: "🥕"
            font.pixelSize: 16
            Layout.alignment: Qt.AlignVCenter
            visible: logoIcon.status !== Image.Ready
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

            Behavior on text {
                SequentialAnimation {
                    NumberAnimation { target: titleBar.sectionText; property: "opacity"; to: 0; duration: 100 }
                    NumberAnimation { target: titleBar.sectionText; property: "opacity"; to: 1; duration: 150 }
                }
            }
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
                    color: hovHandler.hovered
                        ? (btn.hoverColor === "#E81123" ? "#FFFFFF" : btn.glyphColor)
                        : btn.glyphColor
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
                hoverColor: "#E81123"
                glyphColor: Theme.textSecondary
                onClicked: titleBar.closeClicked()
            }
        }
    }
}