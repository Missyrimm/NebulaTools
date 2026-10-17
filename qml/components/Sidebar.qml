import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nebula 1.0

Rectangle {
    id: sidebar
    width: collapsed ? 64 : 260
    color: Theme.surface

    property int currentIndex: 0
    property bool collapsed: false

    Behavior on width {
        NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic }
    }

    readonly property var items: [
        { label: "Конвертер",                  glyph: "\uE8AB", tip: "Перетащи .FLP или .ZIP" },
        { label: "Сэмплы",                     glyph: "\uE8D6", tip: "Рандомные сэмплы с Freesound" },
        { label: "Генератор MIDI",             glyph: "\uE7F4", tip: "Генератор MIDI-мелодий" },
        { label: "Рандомная нарезка сэмплов",  glyph: "\uE768", tip: "Нарезка и перемешивание аудио" },
        { label: "Настройки",                  glyph: "\uE713", tip: "Внешний вид и поведение" },
        { label: "О программе",                glyph: "\uE946", tip: "Версия и авторы" }
    ]

    readonly property int btnHeight: 42
    readonly property int btnSpacing: 4
    readonly property int topMargin: 20

    Rectangle {
        id: indicator
        width: 3
        height: 22
        radius: 2
        color: Theme.accent
        x: 0
        y: topMargin + sidebar.currentIndex * (btnHeight + btnSpacing)
           + (btnHeight - height) / 2

        Behavior on y {
            NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
        }
    }

    Column {
        id: navColumn
        anchors.top: parent.top
        anchors.topMargin: sidebar.topMargin
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: sidebar.btnSpacing

        Repeater {
            model: sidebar.items
            delegate: Rectangle {
                id: navItem
                required property var modelData
                required property int index

                width: parent.width
                height: sidebar.btnHeight
                color: sidebar.currentIndex === index
                       ? Theme.surfaceHover
                       : (hov.hovered ? Theme.surfaceHover : "transparent")
                radius: Theme.radiusSmall

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14

                    Text {
                        text: modelData.glyph
                        color: sidebar.currentIndex === index
                               ? Theme.accent : Theme.textSecondary
                        font.family: Theme.iconFamily
                        font.pixelSize: 16
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }

                    Text {
                        text: modelData.label
                        color: sidebar.currentIndex === index
                               ? Theme.textPrimary : Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody - 1
                        font.weight: sidebar.currentIndex === index ? Font.DemiBold : Font.Normal
                        visible: !sidebar.collapsed
                        opacity: sidebar.collapsed ? 0 : 1
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 50
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                        Behavior on color   { ColorAnimation  { duration: Theme.animFast } }
                    }
                }

                HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: sidebar.currentIndex = navItem.index }
            }
        }
    }

    Rectangle {
        id: collapseBtn
        width: parent.width
        height: 40
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        color: cHov.hovered ? Theme.surfaceHover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        Text {
            anchors.centerIn: parent
            text: sidebar.collapsed ? "\uE76C" : "\uE76B"
            color: Theme.textSecondary
            font.family: Theme.iconFamily
            font.pixelSize: 14
        }

        HoverHandler { id: cHov; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: sidebar.collapsed = !sidebar.collapsed }
    }
}