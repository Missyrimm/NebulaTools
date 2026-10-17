import QtQuick
import QtQuick.Layouts
import Nebula 1.0

Rectangle {
    id: card

    property string icon: ""
    property string title: ""
    property string description: ""
    property color accentColor: Theme.accent
    property string visualization: "converter"
    property bool hovered: false

    signal clicked

    Layout.preferredWidth: 300
    Layout.preferredHeight: 260
    implicitWidth: 300
    implicitHeight: 260

    radius: Theme.radiusLarge
    color: Theme.surface
    border.color: hovered ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.6) : Theme.border
    border.width: 1
    scale: hovered ? 1.02 : 1.0

    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: parent.radius + 2
        color: "transparent"
        border.color: accentColor
        border.width: 2
        opacity: hovered ? 0.3 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    HoverHandler {
        id: hh
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: card.hovered = hh.hovered
    }

    TapHandler {
        onTapped: {
            card.clicked()
            pressAnim.start()
        }
    }

    SequentialAnimation {
        id: pressAnim
        NumberAnimation { target: card; property: "scale"; to: 0.96; duration: 80 }
        NumberAnimation { target: card; property: "scale"; to: 1.02; duration: 120 }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Превью с визуализацией
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 110
            color: "transparent"
            radius: Theme.radiusLarge
            clip: true

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusLarge
                color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.06)
            }

            Item {
                anchors.centerIn: parent
                width: 200
                height: 70

                // CONVERTER
                Item {
                    anchors.fill: parent
                    visible: card.visualization === "converter"

                    Rectangle {
                        x: 10; y: 18; width: 80; height: 3; radius: 1.5
                        color: Theme.borderLight
                        Rectangle {
                            width: 24; height: 3; radius: 1.5
                            color: Theme.accentOrange
                            x: -24
                            SequentialAnimation on x {
                                loops: Animation.Infinite
                                NumberAnimation { from: -24; to: 80; duration: 1400; easing.type: Easing.InOutQuad }
                                PauseAnimation { duration: 400 }
                            }
                        }
                    }
                    Rectangle {
                        x: 110; y: 48; width: 80; height: 3; radius: 1.5
                        color: Theme.borderLight
                        Rectangle {
                            width: 24; height: 3; radius: 1.5
                            color: Theme.accentOrange
                            x: 80
                            SequentialAnimation on x {
                                loops: Animation.Infinite
                                NumberAnimation { from: 80; to: -24; duration: 1400; easing.type: Easing.InOutQuad }
                                PauseAnimation { duration: 400 }
                            }
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "\uE72A"
                        font.family: Theme.iconFamily
                        font.pixelSize: 22
                        color: Theme.accentOrange
                        opacity: 0.85
                    }
                }

                // SAMPLES
                Item {
                    anchors.fill: parent
                    visible: card.visualization === "samples"
                    Grid {
                        anchors.centerIn: parent
                        columns: 4
                        spacing: 8
                        Repeater {
                            model: 8
                            Rectangle {
                                required property int index
                                width: 22; height: 22; radius: 4
                                color: index % 2 === 0
                                    ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                                    : Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.15)
                                border.color: index % 2 === 0 ? Theme.accent : Theme.accentCyan
                                border.width: 1
                                opacity: 0.5
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    PauseAnimation { duration: index * 220 }
                                    NumberAnimation { to: 1.0; duration: 400 }
                                    NumberAnimation { to: 0.5; duration: 400 }
                                    PauseAnimation { duration: 1600 }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: "\uE8D6"
                                    font.family: Theme.iconFamily
                                    font.pixelSize: 9
                                    color: index % 2 === 0 ? Theme.accent : Theme.accentCyan
                                }
                            }
                        }
                    }
                }

                // MIDI
                Item {
                    anchors.fill: parent
                    visible: card.visualization === "midi"
                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Repeater {
                            model: 8
                            Rectangle {
                                required property int index
                                width: 10
                                height: 20 + (index % 4) * 8
                                radius: 2
                                color: Theme.accentCyan
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

                // SLICER
                Item {
                    anchors.fill: parent
                    visible: card.visualization === "slicer"
                    Row {
                        anchors.centerIn: parent
                        spacing: 3
                        Repeater {
                            model: 16
                            Rectangle {
                                required property int index
                                width: 6
                                height: 14 + Math.abs(Math.sin(index * 1.4)) * 30
                                radius: 2
                                color: Theme.accent
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

                // STEMS
                Item {
                    anchors.fill: parent
                    visible: card.visualization === "stems"
                    Column {
                        anchors.centerIn: parent
                        spacing: 6
                        Repeater {
                            model: 4
                            Rectangle {
                                required property int index
                                width: 160 + (index % 2 === 0 ? 20 : -10)
                                height: 6
                                radius: 3
                                color: [Theme.accentOrange, Theme.accentCyan, Theme.accent, Theme.accentCyan][index]
                                opacity: 0.55
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    PauseAnimation { duration: index * 200 }
                                    NumberAnimation { to: 1.0; duration: 400 }
                                    NumberAnimation { to: 0.55; duration: 400 }
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
            Layout.fillHeight: true
            Layout.margins: Theme.spaceL
            Layout.topMargin: Theme.spaceM
            spacing: Theme.spaceS

            RowLayout {
                spacing: Theme.spaceS
                Rectangle {
                    width: 32; height: 32; radius: 9
                    color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
                    Text {
                        anchors.centerIn: parent
                        text: card.icon
                        font.family: Theme.iconFamily
                        font.pixelSize: 15
                        color: card.accentColor
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: card.title
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontH3
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }

            Text {
                Layout.fillWidth: true
                text: card.description
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.WordWrap
                lineHeight: 1.4
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "Открыть"
                    color: card.hovered ? card.accentColor : Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.weight: Font.DemiBold
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }

                Text {
                    text: "\uE72A"
                    font.family: Theme.iconFamily
                    font.pixelSize: 11
                    color: card.hovered ? card.accentColor : Theme.textTertiary
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    // ФИКС: через transform, не через x
                    transform: Translate {
                        x: card.hovered ? 4 : 0
                        Behavior on x { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }
}