import QtQuick
import QtQuick.Effects
import "../"

Item {
    anchors.fill: parent
    z: -1

    Rectangle {
        id: blobA
        width: 500
        height: 500
        radius: 250
        color: Theme.accent
        opacity: 0.08
        x: parent.width * 0.3 - width / 2
        y: parent.height * 0.3 - height / 2
        Behavior on x { NumberAnimation { duration: 8000; easing.type: Easing.InOutSine } }
        Behavior on y { NumberAnimation { duration: 8000; easing.type: Easing.InOutSine } }
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 200 }
    }

    Rectangle {
        id: blobB
        width: 400
        height: 400
        radius: 200
        color: "#5CE1E6"
        opacity: 0.05
        x: parent.width * 0.7 - width / 2
        y: parent.height * 0.7 - height / 2
        Behavior on x { NumberAnimation { duration: 10000; easing.type: Easing.InOutSine } }
        Behavior on y { NumberAnimation { duration: 10000; easing.type: Easing.InOutSine } }
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 200 }
    }

    Timer {
        interval: 7000
        running: true
        repeat: true
        onTriggered: {
            blobA.x = 100 + Math.random() * Math.max(100, parent.width - 400) - blobA.width / 2
            blobA.y = 100 + Math.random() * Math.max(100, parent.height - 400) - blobA.height / 2
        }
    }

    Timer {
        interval: 9000
        running: true
        repeat: true
        onTriggered: {
            blobB.x = 100 + Math.random() * Math.max(100, parent.width - 400) - blobB.width / 2
            blobB.y = 100 + Math.random() * Math.max(100, parent.height - 400) - blobB.height / 2
        }
    }

    // Звёзды
    property int tick: 0
    Timer {
        interval: 8000
        running: true
        repeat: true
        onTriggered: parent.tick++
    }

    Repeater {
        model: 30
        delegate: Item {
            id: star
            required property int index
            property real baseSize: 1.2 + ((index * 37) % 15) / 10.0
            width: baseSize; height: baseSize
            Component.onCompleted: {
                x = Math.random() * parent.width
                y = Math.random() * parent.height
            }
            Behavior on x { NumberAnimation { duration: 8500; easing.type: Easing.InOutSine } }
            Behavior on y { NumberAnimation { duration: 8500; easing.type: Easing.InOutSine } }
            Connections {
                target: star.parent
                function onTickChanged() {
                    star.x = Math.random() * star.parent.width
                    star.y = Math.random() * star.parent.height
                }
            }
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: index % 2 === 0 ? Theme.accent : "#5CE1E6"
                opacity: 0.3
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.05; duration: 2000 + (index * 150) % 3000 }
                    NumberAnimation { to: 0.5; duration: 2000 + (index * 150) % 3000 }
                }
            }
        }
    }
}