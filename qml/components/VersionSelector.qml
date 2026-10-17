import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nebula 1.0

RowLayout {
    id: root
    spacing: Theme.spaceM

    property string sourceVersion: "—"
    property string targetVersion: "24.1.0.4225"

    readonly property var targets: [
        "21.0.0.0000", "21.2.2.0000", "21.2.3.4004",
        "24.0.0.0000", "24.1.0.4225", "24.1.2.4463", "24.2.2.4597",
        "25.0.0.0000", "25.1.0.4868", "25.2.5.5319",
        "26.0.0.0000", "26.1.0.5530", "26.1.4.5589"
    ]

    // ---------- SOURCE ----------
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 64
        radius: Theme.radiusSmall
        color: Theme.surface

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                text: "Исходная версия"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
            }
            Text {
                text: root.sourceVersion
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                font.weight: Font.DemiBold
            }
        }
    }

    // ---------- ARROW (только текст, без круга) ----------
    Item {
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32

        Text {
            anchors.centerIn: parent
            text: "\uE72A"
            color: Theme.accent
            font.family: Theme.iconFamily
            font.pixelSize: 18

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: root.Window.window.visibility !== Window.Minimized
                NumberAnimation { to: 0.5; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
            }
        }
    }

    // ---------- TARGET ----------
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 64
        radius: Theme.radiusSmall
        color: Theme.surface

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                text: "Целевая версия"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
            }

            ComboBox {
                id: combo
                width: parent.width
                height: 24
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                model: root.targets
                currentIndex: Math.max(0, root.targets.indexOf(root.targetVersion))

                contentItem: Text {
                    leftPadding: 0
                    text: combo.displayText
                    color: Theme.accent
                    font.family: combo.font.family
                    font.pixelSize: combo.font.pixelSize
                    font.weight: Font.DemiBold
                    verticalAlignment: Text.AlignVCenter
                }

                indicator: Text {
                    x: combo.width - width
                    y: combo.height / 2 - height / 2
                    text: "\uE70D"
                    color: Theme.accent
                    font.family: Theme.iconFamily
                    font.pixelSize: 10
                }

                background: Rectangle {
                    color: "transparent"
                }

                popup: Popup {
                    y: combo.height + 4
                    width: combo.width + 60
                    implicitHeight: Math.min(contentItem.implicitHeight + 8, 260)
                    padding: 4

                    background: Rectangle {
                        color: Theme.surfaceHover
                        radius: Theme.radiusSmall
                        border.color: Theme.border
                        border.width: 1
                    }

                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: combo.delegateModel
                        currentIndex: combo.highlightedIndex
                        boundsBehavior: Flickable.StopAtBounds
                    }
                }

                delegate: ItemDelegate {
                    width: combo.popup.width - 8
                    height: 28
                    contentItem: Text {
                        text: modelData
                        color: combo.highlightedIndex === index ? Theme.accent : Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 8
                    }
                    background: Rectangle {
                        color: parent.hovered ? Theme.surface : "transparent"
                        radius: 4
                    }
                }

                onActivated: function(idx) {
                    root.targetVersion = root.targets[idx]
                }
            }
        }
    }
}