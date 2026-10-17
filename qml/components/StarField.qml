import QtQuick
import Nebula 1.0

Item {
    id: root
    anchors.fill: parent
    z: -2

    property int tick: 0

    Timer {
        interval: 8000
        running: true
        repeat: true
        onTriggered: root.tick++
    }

    Repeater {
        model: 45
        delegate: Item {
            id: star
            required property int index

            property real baseSize: 1.2 + ((index * 37) % 15) / 10.0

            width: baseSize
            height: baseSize

            Component.onCompleted: {
                x = 40 + Math.random() * Math.max(100, root.width - 80)
                y = 40 + Math.random() * Math.max(100, root.height - 80)
            }

            Behavior on x { NumberAnimation { duration: 8500; easing.type: Easing.InOutSine } }
            Behavior on y { NumberAnimation { duration: 8500; easing.type: Easing.InOutSine } }

            Connections {
                target: root
                function onTickChanged() {
                    star.x = 40 + Math.random() * Math.max(100, root.width - 80)
                    star.y = 40 + Math.random() * Math.max(100, root.height - 80)
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: index % 3 === 0 ? Theme.accentCyan : Theme.accent
                opacity: 0.25

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.03
                        duration: 2000 + ((index * 173) % 3500)
                    }
                    NumberAnimation {
                        to: 0.5
                        duration: 2000 + ((index * 173) % 3500)
                    }
                }
            }
        }
    }
}