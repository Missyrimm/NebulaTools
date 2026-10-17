import QtQuick
import QtQuick.Controls
import Nebula 1.0

TextField {
    id: control
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontBody
    color: Theme.textPrimary
    placeholderTextColor: Theme.textSecondary
    selectionColor: Theme.accent
    selectedTextColor: "#FFFFFF"
    implicitHeight: 40
    leftPadding: 12
    rightPadding: 12

    background: Rectangle {
        color: Theme.surfaceHover
        border.color: control.activeFocus ? Theme.accent : Theme.border
        border.width: 1
        radius: Theme.radiusSmall

        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
    }
}