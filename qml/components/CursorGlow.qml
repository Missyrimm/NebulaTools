import QtQuick
import QtQuick.Effects
import Nebula 1.0

Item {
    id: root
    anchors.fill: parent
    // ФИКС: z-index убран, управляется из Main.qml

    Rectangle {
        id: blobA
        width: 700
        height: 700
        radius: 350
        color: Theme.accent
        opacity: 0.06
        x: root.width * 0.25 - width / 2
        y: root.height * 0.3 - height / 2

        Behavior on x { NumberAnimation { duration: 9000; easing.type: Easing.InOutSine } }
        Behavior on y { NumberAnimation { duration: 9000; easing.type: Easing.InOutSine } }

        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 250 }
    }

    Rectangle {
        id: blobB
        width: 550
        height: 550
        radius: 275
        color: Theme.accentCyan
        opacity: 0.05
        x: root.width * 0.7 - width / 2
        y: root.height * 0.65 - height / 2

        Behavior on x { NumberAnimation { duration: 11000; easing.type: Easing.InOutSine } }
        Behavior on y { NumberAnimation { duration: 11000; easing.type: Easing.InOutSine } }

        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 250 }
    }

    Timer {
        interval: 7000
        running: true
        repeat: true
        onTriggered: {
            blobA.x = 100 + Math.random() * Math.max(200, root.width - 400) - blobA.width / 2
            blobA.y = 100 + Math.random() * Math.max(200, root.height - 400) - blobA.height / 2
        }
    }

    Timer {
        interval: 9500
        running: true
        repeat: true
        onTriggered: {
            blobB.x = 100 + Math.random() * Math.max(200, root.width - 400) - blobB.width / 2
            blobB.y = 100 + Math.random() * Math.max(200, root.height - 400) - blobB.height / 2
        }
    }
}