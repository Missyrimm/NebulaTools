import QtQuick
import QtQuick.Layouts
import Nebula 1.0

Rectangle {
    id: root

    property string title: ""
    property string description: ""
    property color accentColor: Theme.accent
    property string previewType: "none"

    default property alias content: contentColumn.data

    Layout.fillWidth: true
    implicitHeight: layoutCol.implicitHeight
    radius: Theme.radiusLarge
    color: Theme.surface
    border.color: Theme.border
    border.width: 1

    ColumnLayout {
        id: layoutCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 0

        // Превью-визуализация
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: previewType === "none" ? 0 : 80
            visible: previewType !== "none"
            color: "transparent"
            clip: true

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.06)
                radius: Theme.radiusLarge
            }

            Item {
                anchors.centerIn: parent
                width: 180
                height: 50

                // CONVERTER — волны + стрелка
                Item {
                    anchors.fill: parent
                    visible: root.previewType === "converter"

                    Rectangle {
                        x: 10; y: 12; width: 70; height: 3; radius: 1.5
                        color: Theme.borderLight
                        Rectangle {
                            width: 24; height: 3; radius: 1.5
                            color: root.accentColor
                            x: -24
                            SequentialAnimation on x {
                                loops: Animation.Infinite
                                NumberAnimation { from: -24; to: 70; duration: 1400; easing.type: Easing.InOutQuad }
                                PauseAnimation { duration: 400 }
                            }
                        }
                    }
                    Rectangle {
                        x: 100; y: 34; width: 70; height: 3; radius: 1.5
                        color: Theme.borderLight
                        Rectangle {
                            width: 24; height: 3; radius: 1.5
                            color: root.accentColor
                            x: 70
                            SequentialAnimation on x {
                                loops: Animation.Infinite
                                NumberAnimation { from: 70; to: -24; duration: 1400; easing.type: Easing.InOutQuad }
                                PauseAnimation { duration: 400 }
                            }
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "\uE72A"
                        font.family: Theme.iconFamily
                        font.pixelSize: 20
                        color: root.accentColor
                        opacity: 0.85
                    }
                }

                // WAVEFORM — полоски
                Item {
                    anchors.fill: parent
                    visible: root.previewType === "waveform"
                    Row {
                        anchors.centerIn: parent
                        spacing: 3
                        Repeater {
                            model: 14
                            Rectangle {
                                required property int index
                                width: 4
                                height: 8 + Math.abs(Math.sin(index * 1.3)) * 30
                                radius: 2
                                color: root.accentColor
                                opacity: 0.5
                                anchors.verticalCenter: parent.verticalCenter
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    PauseAnimation { duration: index * 80 }
                                    NumberAnimation { to: 1.0; duration: 250 }
                                    NumberAnimation { to: 0.5; duration: 250 }
                                    PauseAnimation { duration: 900 }
                                }
                            }
                        }
                    }
                }

                // NOTES — MIDI-ноты
                Item {
                    anchors.fill: parent
                    visible: root.previewType === "notes"
                    Row {
                        anchors.centerIn: parent
                        spacing: 5
                        Repeater {
                            model: 8
                            Rectangle {
                                required property int index
                                width: 8
                                height: 12 + (index % 4) * 6
                                radius: 2
                                color: root.accentColor
                                opacity: 0.6
                                anchors.verticalCenter: parent.verticalCenter
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    PauseAnimation { duration: index * 120 }
                                    NumberAnimation { to: 1.0; duration: 300 }
                                    NumberAnimation { to: 0.6; duration: 300 }
                                    PauseAnimation { duration: 1200 }
                                }
                            }
                        }
                    }
                }

                // TRACKS — 4 полоски (стемы)
                Item {
                    anchors.fill: parent
                    visible: root.previewType === "tracks"
                    Column {
                        anchors.centerIn: parent
                        spacing: 5
                        Repeater {
                            model: 4
                            Rectangle {
                                required property int index
                                width: 140 + (index % 2 === 0 ? 16 : -8)
                                height: 5
                                radius: 2.5
                                color: [
                                    Theme.accentOrange, Theme.accentCyan,
                                    Theme.accent, Theme.accentCyan
                                ][index]
                                opacity: 0.6
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    PauseAnimation { duration: index * 180 }
                                    NumberAnimation { to: 1.0; duration: 380 }
                                    NumberAnimation { to: 0.6; duration: 380 }
                                    PauseAnimation { duration: 1400 }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Контент
        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.spaceL
            spacing: Theme.spaceM

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spaceS
                visible: root.title !== ""

                Rectangle {
                    width: 4
                    height: 14
                    radius: 2
                    color: root.accentColor
                }

                Text {
                    text: root.title
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontH3
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.description
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.WordWrap
                visible: root.description !== ""
            }

            ColumnLayout {
                id: contentColumn
                Layout.fillWidth: true
                spacing: Theme.spaceM
            }
        }
    }
}