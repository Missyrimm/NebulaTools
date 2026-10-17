import QtQuick
import QtQuick.Controls
import Nebula 1.0

SpinBox {
    id: control
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontBody
    implicitHeight: 40
    editable: true

    contentItem: TextInput {
        z: 2
        text: control.textFromValue(control.value, control.locale)
        font: control.font
        color: Theme.textPrimary
        selectionColor: Theme.accent
        selectedTextColor: "#FFFFFF"
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        readOnly: !control.editable
        validator: control.validator
        inputMethodHints: control.inputMethodHints
    }

    up.indicator: Rectangle {
        x: control.width - width
        height: parent.height
        width: 34
        color: upHandler.hovered ? Qt.rgba(1.0, 0.478, 0.102, 0.2) : "transparent"
        radius: Theme.radiusSmall

        HoverHandler { id: upHandler; cursorShape: Qt.PointingHandCursor }

        Text {
            anchors.centerIn: parent
            text: "+"
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: 18
            font.weight: Font.DemiBold
        }
    }

    down.indicator: Rectangle {
        x: 0
        height: parent.height
        width: 34
        color: downHandler.hovered ? Qt.rgba(1.0, 0.478, 0.102, 0.2) : "transparent"
        radius: Theme.radiusSmall

        HoverHandler { id: downHandler; cursorShape: Qt.PointingHandCursor }

        Text {
            anchors.centerIn: parent
            text: "\u2212"
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: 18
            font.weight: Font.DemiBold
        }
    }

    background: Rectangle {
        implicitWidth: 140
        color: Theme.surfaceHover
        border.color: Theme.border
        border.width: 1
        radius: Theme.radiusSmall
    }
}