import QtQuick
import QtQuick.Controls
import Nebula 1.0

Item {
    id: root
    width: 44
    height: 24

    property bool checked: false
    signal toggled(bool value)

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked
               ? Qt.rgba(1.0, 0.478, 0.102, 0.85)
               : Theme.surfaceHover
        border.width: root.checked ? 0 : 1
        border.color: Theme.border

        Behavior on color { ColorAnimation { duration: Theme.animNormal } }
    }

    Rectangle {
        id: knob
        width: 18; height: 18
        radius: 9
        color: "#FFFFFF"
        y: 3
        x: root.checked ? root.width - width - 3 : 3

        Behavior on x {
            SpringAnimation {
                spring: 3.5
                damping: 0.35
                epsilon: 0.1
            }
        }
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
    TapHandler {
        onTapped: {
            root.checked = !root.checked
            root.toggled(root.checked)
        }
    }
}