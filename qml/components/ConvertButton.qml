import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nebula 1.0

Item {
    id: root
    height: 52

    property string label: "Конвертировать проект"
    property bool busy: false
    property int progress: 0
    property bool success: false
    property bool failed: false
    property bool hovered: false

    signal clicked

    onFailedChanged: if (failed) shake.start()

    Rectangle {
        id: body
        anchors.fill: parent
        radius: Theme.radius

        color: {
            if (root.failed) return Theme.error
            if (root.hovered) return Theme.accentHover
            return Theme.accent
        }

        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        y: root.hovered && !root.busy ? -2 : 0
        Behavior on y { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuad } }

        scale: tap.pressed && !root.busy ? 0.985 : 1.0
        Behavior on scale { NumberAnimation { duration: 80 } }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: parent.radius + 4
            color: "transparent"
            border.width: 2
            border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5)
            opacity: root.hovered ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 10

            Text {
                text: "\uE768"
                color: "#FFFFFF"
                font.family: Theme.iconFamily
                font.pixelSize: 14
                visible: !root.busy && !root.success
            }

            Text {
                text: root.success ? "Готово" : root.label
                color: "#FFFFFF"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontH3
                font.weight: Font.DemiBold
                visible: !root.busy
            }

            Text {
                visible: root.busy
                text: root.progress + "%"
                color: "#FFFFFF"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontH3
                font.weight: Font.DemiBold
            }
        }

        Rectangle {
            visible: root.busy
            height: parent.height
            width: parent.width * (root.progress / 100.0)
            radius: parent.radius
            color: Qt.rgba(0, 0, 0, 0.25)

            Behavior on width {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
        }

        Text {
            id: check
            anchors.centerIn: parent
            text: "\uE73E"
            color: "#FFFFFF"
            font.family: Theme.iconFamily
            font.pixelSize: 22
            visible: root.success
            scale: root.success ? 1.0 : 0.0
            Behavior on scale {
                NumberAnimation { duration: 350; easing.type: Easing.OutBack }
            }
        }

        HoverHandler {
            id: hoverHandler
            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: root.hovered = hoverHandler.hovered
        }

        TapHandler {
            id: tap
            enabled: !root.busy
            onTapped: root.clicked()
        }
    }

    SequentialAnimation {
        id: shake
        NumberAnimation { target: body; property: "x"; to: -6; duration: 40 }
        NumberAnimation { target: body; property: "x"; to:  6; duration: 40 }
        NumberAnimation { target: body; property: "x"; to: -4; duration: 40 }
        NumberAnimation { target: body; property: "x"; to:  4; duration: 40 }
        NumberAnimation { target: body; property: "x"; to:  0; duration: 40 }
    }
}