import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nebula 1.0
import "../components"

Item {
    id: page

    opacity: 0
    Component.onCompleted: fadeAnim.start()
    onVisibleChanged: if (visible) { opacity = 0; fadeAnim.start() }

    NumberAnimation {
        id: fadeAnim
        target: page
        property: "opacity"
        from: 0
        to: 1
        duration: 300
        easing.type: Easing.OutCubic
    }

    ScrollView {
        id: sv
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceXxl
        anchors.rightMargin: Theme.spaceXxl
        anchors.topMargin: Theme.spaceXl
        anchors.bottomMargin: Theme.spaceL
        clip: true

        ColumnLayout {
            width: sv.availableWidth
            spacing: Theme.spaceL

            PageHeader {
                Layout.fillWidth: true
                label: "NEBULATOOLS · ABOUT"
                title: "О программе"
                subtitle: "Версия, автор и инструкция."
            }

            // ═══════════ ЛОГО + НАЗВАНИЕ ═══════════
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 152
                radius: Theme.radiusLarge
                color: Theme.surface
                border.color: Theme.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spaceL
                    spacing: Theme.spaceL

                    Image {
                        source: "../../assets/icons/logo.png"
                        sourceSize.width: 100
                        sourceSize.height: 100
                        fillMode: Image.PreserveAspectFit
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 6

                        Text {
                            text: "NebulaTools"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontH1
                            font.weight: Font.Bold
                        }
                        Text {
                            text: "Версия " + backend.appVersion
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                        }
                        Text {
                            text: "MUSIC PRODUCTION TOOLKIT"
                            color: Theme.textTertiary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontTiny
                            font.weight: Font.Bold
                            font.letterSpacing: 1.5
                        }
                    }

                    Item { Layout.fillWidth: true }
                }
            }

            // ═══════════ АВТОР И КАНАЛ ═══════════
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: authorsCol.implicitHeight + Theme.spaceL * 2
                radius: Theme.radiusLarge
                color: Theme.surface
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    id: authorsCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spaceL
                    spacing: Theme.spaceM

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spaceS
                        Rectangle { width: 4; height: 14; radius: 2; color: Theme.accent }
                        Text {
                            text: "Автор и канал"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontH3
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                        }
                    }

                    // @youngweepo
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spaceM
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "@youngweepo"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: "Автор и разработчик"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                            }
                        }
                        Rectangle {
                            width: 120; height: 34
                            radius: Theme.radiusSmall
                            color: authorBtn.pressed ? Theme.accentHover : Theme.accent
                            Text {
                                anchors.centerIn: parent
                                text: "Открыть"
                                color: "#FFFFFF"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                font.weight: Font.DemiBold
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler { id: authorBtn; onTapped: Qt.openUrlExternally("https://t.me/youngweepo") }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                    // @nebulatools
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spaceM
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "@nebulatools"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: "Телеграм-канал проекта"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                            }
                        }
                        Rectangle {
                            width: 120; height: 34
                            radius: Theme.radiusSmall
                            color: channelBtn.pressed ? Theme.accentHover : Theme.accent
                            Text {
                                anchors.centerIn: parent
                                text: "Открыть"
                                color: "#FFFFFF"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                font.weight: Font.DemiBold
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler { id: channelBtn; onTapped: Qt.openUrlExternally("https://t.me/nebulatools") }
                        }
                    }
                }
            }

            // ═══════════ ИНСТРУКЦИЯ ═══════════
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: helpCol.implicitHeight + Theme.spaceL * 2
                radius: Theme.radiusLarge
                color: Theme.surface
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    id: helpCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spaceL
                    spacing: Theme.spaceM

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spaceS
                        Rectangle { width: 4; height: 14; radius: 2; color: Theme.accentCyan }
                        Text {
                            text: "Как пользоваться"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontH3
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "1. Выбери инструмент в боковом меню или на главной странице.\n" +
                              "2. Конвертер: перетащи .flp или .zip, выбери версию, нажми «Конвертировать».\n" +
                              "3. Сэмплы: введи запрос, слушай превью и скачивай понравившиеся.\n" +
                              "4. Генератор MIDI: настрой параметры и сохрани мелодию.\n" +
                              "5. Нарезка: выбери аудио, Analyze Audio, затем — Сгенерировать бит.\n" +
                              "6. Стемы: загрузи трек и выбери модель разделения."
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        wrapMode: Text.WordWrap
                        lineHeight: 1.5
                    }
                }
            }

            Item { Layout.preferredHeight: 24 }
        }
    }
}