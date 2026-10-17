import QtQuick
import QtQuick.Layouts
import Nebula 1.0

Rectangle {
    id: root
    property string title: ""
    property color accentColor: Theme.accent
    property alias contentColumn: content
    default property alias children: content.data

    Layout.fillWidth: true
    implicitHeight: layoutCol.implicitHeight + Theme.spaceL * 2
    radius: Theme.radiusLarge
    color: Theme.surface
    border.color: Theme.border
    border.width: 1

    ColumnLayout {
        id: layoutCol
        anchors.fill: parent
        anchors.margins: Theme.spaceL
        spacing: Theme.spaceM

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceS
            visible: root.title !== ""

            Rectangle {
                width: 4
                height: 16
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

        ColumnLayout {
            id: content
            Layout.fillWidth: true
            spacing: Theme.spaceM
        }
    }
}