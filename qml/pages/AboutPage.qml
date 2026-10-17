import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nebula 1.0
import "../components"

Item {
    id: page

    ScrollView {
        anchors.fill: parent
        anchors.margins: Theme.spaceL
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: Theme.spaceL

            RowLayout {
                spacing: Theme.spaceL
                Text {
                    text: "🥕"
                    font.pixelSize: 64
                }
                ColumnLayout {
                    spacing: 4
                    Text {
                        text: "FLP Converter"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 28
                        font.weight: Font.Bold
                    }
                    Text {
                        text: "Версия " + backend.appVersion
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                    }
                    Text {
                        text: "PROJECT COMPATIBILITY TOOL · FL STUDIO"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.weight: Font.DemiBold
                    }
                }
            }

            // ---- Authors ----
            Text {
                text: "Автор и канал"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontH3
                font.weight: Font.DemiBold
            }

            Repeater {
                model: [
                    { name: "YoungWeepo",  url: backend.authorUrl },
                    { name: "NebulaTools", url: backend.channelUrl }
                ]
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    height: 56
                    radius: Theme.radiusSmall
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spaceM
                        anchors.rightMargin: Theme.spaceM

                        Text {
                            text: modelData.name
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: 90; height: 30
                            radius: Theme.radiusSmall
                            color: "transparent"
                            border.color: Theme.accent
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "Открыть"
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                font.weight: Font.DemiBold
                            }

                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: Qt.openUrlExternally(modelData.url)
                            }
                        }
                    }
                }
            }

            // ---- Instructions ----
            Text {
                text: "Как пользоваться"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontH3
                font.weight: Font.DemiBold
                Layout.topMargin: 8
            }

            Text {
                Layout.fillWidth: true
                text: "1. Перетащи .flp или .zip в окно (или нажми «Выбрать файл»).\n" +
                      "2. Программа автоматически определит исходную версию проекта.\n" +
                      "3. Выбери целевую версию FL Studio из выпадающего списка.\n" +
                      "4. Настрой дополнительные опции при необходимости.\n" +
                      "5. Нажми «Конвертировать» — рядом появится готовый файл.\n\n" +
                      "Оригинальный файл никогда не изменяется."
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                wrapMode: Text.WordWrap
                lineHeight: 1.5
            }

            Item { Layout.fillHeight: true }
        }
    }
}