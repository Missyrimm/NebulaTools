import QtQuick
import QtQuick.Controls
import Nebula 1.0

ComboBox {
    id: control
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontBody
    implicitHeight: 40

    contentItem: Text {
        leftPadding: 12
        rightPadding: 40
        text: control.displayText
        font: control.font
        color: Theme.textPrimary
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        color: Theme.surfaceHover
        border.color: Theme.border
        border.width: 1
        radius: Theme.radiusSmall
    }

    indicator: Text {
        x: control.width - width - 12
        y: control.topPadding + (control.availableHeight - height) / 2
        text: "\uE70D"
        font.family: Theme.iconFamily
        font.pixelSize: 11
        color: Theme.accent
    }

    popup: Popup {
        y: control.height + 4
        width: control.width
        implicitHeight: Math.min(contentItem.implicitHeight + 8, 300)
        padding: 4

        background: Rectangle {
            color: Theme.surface
            border.color: Theme.border
            border.width: 1
            radius: Theme.radiusSmall
        }

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }
    }

    delegate: ItemDelegate {
        width: control.width - 8
        height: 34

        contentItem: Text {
            text: modelData
            color: parent.highlighted ? Theme.accent : Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            verticalAlignment: Text.AlignVCenter
            leftPadding: 8
        }

        background: Rectangle {
            color: parent.hovered ? Theme.surfaceHover : "transparent"
            radius: 6
        }
    }
}