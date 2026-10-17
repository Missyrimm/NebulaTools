import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nebula 1.0

Rectangle {
    id: sidebar
    width: 240
    color: Theme.bgSecondary

    property int currentIndex: 0

    // Правая разделительная линия
    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: Theme.border
    }

    // ═══════ ЛОГО + НАЗВАНИЕ ═══════
    Rectangle {
        id: logoBox
        width: parent.width
        height: 72
        color: "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spaceL
            anchors.rightMargin: Theme.spaceL
            spacing: Theme.spaceS

            Rectangle {
                width: 32; height: 32
                radius: 8
                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)

                Text {
                    anchors.centerIn: parent
                    text: "\uE8AB"
                    font.family: Theme.iconFamily
                    font.pixelSize: 15
                    color: Theme.accent
                }
            }

            Text {
                text: "NebulaTools"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontH3
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
        }
    }

    // ═══════ НАВИГАЦИЯ ═══════
    readonly property var items: [
        { label: "Главная",             glyph: "\uE80F", accent: Theme.accent },
        { label: "FLP Converter",       glyph: "\uE8AB", accent: Theme.accent },
        { label: "Сэмплы",              glyph: "\uE8D6", accent: Theme.accent },
        { label: "Генератор MIDI",      glyph: "\uE7F4", accent: Theme.accent },
        { label: "Рандомная нарезка",   glyph: "\uE768", accent: Theme.accent },
        { label: "Разделение стемов",   glyph: "\uE8F1", accent: Theme.accent }
    ]

    readonly property var bottomItems: [
        { label: "Настройки",           glyph: "\uE713" },
        { label: "О программе",         glyph: "\uE946" }
    ]

    readonly property int btnHeight: 42
    readonly property int btnSpacing: 2
    readonly property int topMargin: 8

    // Активный индикатор — вертикальная полоска
    Rectangle {
        id: indicator
        width: 3
        height: 22
        radius: 1.5
        color: sidebar.items[currentIndex] ? sidebar.items[currentIndex].accent : Theme.accent
        x: 0
        y: logoBox.height + topMargin + currentIndex * (btnHeight + btnSpacing)
           + (btnHeight - height) / 2

        Behavior on y {
            NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
        }
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    // Основные пункты
    Column {
        id: navColumn
        anchors.top: logoBox.bottom
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
                    ? Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.10)
                    : (hov.hovered ? Theme.surfaceHover : "transparent")
                radius: Theme.radiusSmall

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spaceL
                    anchors.rightMargin: Theme.spaceM
                    spacing: Theme.spaceS

                    Text {
                        text: modelData.glyph
                        color: sidebar.currentIndex === index
                            ? modelData.accent
                            : Theme.textSecondary
                        font.family: Theme.iconFamily
                        font.pixelSize: 15
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.label
                        color: sidebar.currentIndex === index
                            ? Theme.textPrimary
                            : Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        font.weight: sidebar.currentIndex === index
                            ? Font.DemiBold
                            : Font.Normal
                        elide: Text.ElideRight
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }
                }

                HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: sidebar.currentIndex = navItem.index }
            }
        }
    }

    // Нижние пункты
    Column {
        id: bottomColumn
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.spaceL
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: sidebar.btnSpacing

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.border
            anchors.bottomMargin: Theme.spaceS
        }

        Repeater {
            model: sidebar.bottomItems
            delegate: Rectangle {
                id: bottomItem
                required property var modelData
                required property int index
                readonly property int globalIndex: sidebar.items.length + index

                width: parent.width
                height: sidebar.btnHeight
                color: sidebar.currentIndex === globalIndex
                    ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.10)
                    : (hovB.hovered ? Theme.surfaceHover : "transparent")
                radius: Theme.radiusSmall

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spaceL
                    anchors.rightMargin: Theme.spaceM
                    spacing: Theme.spaceS

                    Text {
                        text: modelData.glyph
                        color: sidebar.currentIndex === globalIndex
                            ? Theme.accent
                            : Theme.textSecondary
                        font.family: Theme.iconFamily
                        font.pixelSize: 15
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.label
                        color: sidebar.currentIndex === globalIndex
                            ? Theme.textPrimary
                            : Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        elide: Text.ElideRight
                    }
                }

                HoverHandler { id: hovB; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: sidebar.currentIndex = bottomItem.globalIndex }
            }
        }
    }
}