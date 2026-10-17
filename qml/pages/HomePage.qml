import QtQuick
import QtQuick.Layouts
import Nebula 1.0
import "../components"

Item {
    id: page

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceXxl
        anchors.rightMargin: Theme.spaceXxl
        anchors.topMargin: Theme.spaceXl
        anchors.bottomMargin: Theme.spaceL
        spacing: 0

        // ═══════════ ЗАГОЛОВОК ═══════════
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceS

            RowLayout {
                spacing: Theme.spaceS

                Rectangle {
                    width: 8; height: 8
                    radius: 4
                    color: Theme.accent
                }

                Text {
                    text: "NEBULATOOLS · STUDIO"
                    color: Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontTiny
                    font.weight: Font.Bold
                    font.letterSpacing: 2
                }
            }

            Text {
                text: "Все инструменты для создания музыки"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontDisplay
                font.weight: Font.Bold
                font.letterSpacing: -0.5
                Layout.topMargin: Theme.spaceS
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Text {
                text: "Собраны в одном приложении — конвертация, сэмплы, MIDI, стемы."
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                Layout.topMargin: 2
            }
        }

        Item { Layout.preferredHeight: Theme.spaceXl }

        // ═══════════ СЕТКА КАРТОЧЕК ═══════════
        GridLayout {
            id: grid
            Layout.fillWidth: true
            columns: 3
            columnSpacing: Theme.spaceL
            rowSpacing: Theme.spaceL

            opacity: 0
            Component.onCompleted: appearAnim.start()

            NumberAnimation {
                id: appearAnim
                target: grid
                property: "opacity"
                from: 0
                to: 1
                duration: 500
                easing.type: Easing.OutCubic
            }

            ToolCard {
                icon: "\uE8AB"
                title: "FLP Converter"
                description: "Конвертация проектов между версиями FL Studio."
                accentColor: Theme.accentOrange
                visualization: "converter"
                onClicked: sidebar.currentIndex = 1
            }

            ToolCard {
                icon: "\uE8D6"
                title: "Samples"
                description: "Библиотека случайных сэмплов с Freesound."
                accentColor: Theme.accent
                visualization: "samples"
                onClicked: sidebar.currentIndex = 2
            }

            ToolCard {
                icon: "\uE7F4"
                title: "MIDI Generator"
                description: "Генерация уникальных MIDI-партий и аккордов."
                accentColor: Theme.accentCyan
                visualization: "midi"
                onClicked: sidebar.currentIndex = 3
            }

            ToolCard {
                icon: "\uE768"
                title: "Sample Slicer"
                description: "Случайная нарезка сэмплов по битам."
                accentColor: Theme.accent
                visualization: "slicer"
                onClicked: sidebar.currentIndex = 4
            }

            ToolCard {
                icon: "\uE8F1"
                title: "Stem Separator"
                description: "Разделение трека на вокал, драм и бас."
                accentColor: Theme.accentCyan
                visualization: "stems"
                onClicked: sidebar.currentIndex = 5
            }
        }

        Item { Layout.fillHeight: true }
    }
}