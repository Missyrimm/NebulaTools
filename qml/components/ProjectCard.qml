import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Nebula 1.0

Rectangle {
    id: card
    radius: Theme.radius
    color: Theme.surface
    border.width: 1
    border.color: Theme.border

    property string fileName: "Файл не выбран"
    property string fileKind: ""
    property real fileSize: 0
    property string sourceVersion: "—"

    property int samplesCount: 0
    property int audioCount: 0
    property int otherCount: 0
    property bool hasData: false

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceM
        spacing: Theme.spaceM

        // ---- Head ----
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceM

            Rectangle {
                width: 44; height: 44
                radius: 12
                color: Qt.rgba(1.0, 0.478, 0.102, 0.12)
                Text {
                    anchors.centerIn: parent
                    text: "\uE7C3"
                    color: Theme.accent
                    font.family: Theme.iconFamily
                    font.pixelSize: 20
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: card.fileName
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontH3
                    font.weight: Font.DemiBold
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
                Text {
                    text: card.hasData
                          ? card.fileSize.toFixed(1) + " MB · " +
                            (card.fileKind === "zip" ? "Архив проекта" : "FL Studio Project")
                          : "—"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                }
            }

            Rectangle {
                visible: card.hasData
                width: badgeText.width + 20
                height: 24
                radius: 12
                color: Qt.rgba(0.239, 0.863, 0.518, 0.15)

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: "✓ Загружен"
                    color: Theme.success
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.weight: Font.DemiBold
                }
            }
        }

        // ---- Details rows ----
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: [
                    { label: "FLP файл",            value: card.fileName,        ok: true,  show: card.hasData },
                    { label: "Папка с сэмплами",    value: card.samplesCount,    ok: card.samplesCount > 0, show: card.fileKind === "zip" },
                    { label: "Аудио файлы",         value: card.audioCount,      ok: card.audioCount > 0,   show: card.fileKind === "zip" },
                    { label: "Доп. файлы",          value: card.otherCount,      ok: card.otherCount > 0,   show: card.fileKind === "zip" }
                ]
                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    visible: modelData.show
                    Layout.fillWidth: true
                    height: 34
                    radius: Theme.radiusSmall
                    color: Qt.rgba(1, 1, 1, 0.02)

                    // Cascade reveal
                    opacity: 0
                    x: -8
                    Component.onCompleted: {
                        revealAnim.start()
                    }
                    SequentialAnimation {
                        id: revealAnim
                        PauseAnimation { duration: 60 * index }
                        ParallelAnimation {
                            NumberAnimation { target: parent; property: "opacity"; to: 1; duration: 240; easing.type: Easing.OutCubic }
                            NumberAnimation { target: parent; property: "x"; to: 0; duration: 240; easing.type: Easing.OutCubic }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: "\uE7C3"
                            color: Theme.accent
                            font.family: Theme.iconFamily
                            font.pixelSize: 12
                        }
                        Text {
                            text: modelData.label
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: typeof modelData.value === "number"
                                  ? (modelData.ok ? "✓  " + modelData.value : "×  " + modelData.value)
                                  : (modelData.value || "—")
                            color: modelData.ok ? Theme.success : Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            font.weight: Font.DemiBold
                            elide: Text.ElideMiddle
                            Layout.maximumWidth: 260
                        }
                    }
                }
            }
        }
    }
}