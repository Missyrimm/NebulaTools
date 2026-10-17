import QtQuick
import QtQuick.Layouts
import Nebula 1.0

ColumnLayout {
    id: root
    spacing: Theme.spaceS

    property string label: "NEBULATOOLS"
    property string title: ""
    property string subtitle: ""
    property color accentColor: Theme.accent

    // Верхняя метка с точкой
    RowLayout {
        spacing: Theme.spaceS

        Rectangle {
            width: 8; height: 8
            radius: 4
            color: root.accentColor
        }

        Text {
            text: root.label.toUpperCase()
            color: Theme.textTertiary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontTiny
            font.weight: Font.Bold
            font.letterSpacing: 2
        }
    }

    // Крупный заголовок
    Text {
        Layout.fillWidth: true
        text: root.title
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontH1
        font.weight: Font.Bold
        font.letterSpacing: -0.5
        Layout.topMargin: Theme.spaceS
        wrapMode: Text.WordWrap
    }

    // Подзаголовок
    Text {
        Layout.fillWidth: true
        text: root.subtitle
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontBody
        Layout.topMargin: 2
        wrapMode: Text.WordWrap
        visible: root.subtitle !== ""
    }
}