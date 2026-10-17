import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Nebula 1.0
import "../components"

Item {
    id: page
    property string status: ""
    property bool statusError: false

    Rectangle {
        anchors.fill: parent
        anchors.margins: Theme.spaceL
        radius: Theme.radius
        color: Theme.surface
        border.color: Theme.border
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spaceL
            spacing: Theme.spaceL

            Text {
                text: "Генератор MIDI-мелодий"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontH2
                font.weight: Font.DemiBold
            }

            Text {
                text: "Каждый запуск — новая прогрессия, мелодия и бас. При генерации выберешь, куда сохранить файл."
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: Theme.spaceM
                rowSpacing: Theme.spaceM

                Text { text: "Тональность"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                AppComboBox {
                    id: keyCombo
                    Layout.fillWidth: true
                    model: ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
                    currentIndex: 9
                }
                Text { text: "Гамма"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                AppComboBox {
                    id: scaleCombo
                    Layout.fillWidth: true
                    model: ["major","minor","dorian","phrygian","lydian","mixolydian","harmonic_minor","pentatonic","blues","whole_tone"]
                    currentIndex: 1
                }

                Text { text: "Жанр"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                AppComboBox {
                    id: genreCombo
                    Layout.fillWidth: true
                    model: ["pop","jazz","edm","lofi","epic","blues"]
                    currentIndex: 3
                }
                Text { text: "Тактов"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                AppSpinBox { id: barsSpin; Layout.fillWidth: true; from: 1; to: 32; value: 4 }

                Text { text: "BPM"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                AppSpinBox { id: bpmSpin; Layout.fillWidth: true; from: 60; to: 200; value: 120 }
                Item { Layout.fillWidth: true }
                Item { Layout.fillWidth: true }
            }

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.fillWidth: true
                height: 52
                radius: Theme.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Theme.accentStart }
                    GradientStop { position: 1.0; color: Theme.accentEnd }
                }
                Text {
                    anchors.centerIn: parent
                    text: "Сгенерировать MIDI"
                    color: "#FFFFFF"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontH3
                    font.weight: Font.DemiBold
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: page.askSave() }
            }

            Text {
                Layout.fillWidth: true
                text: page.status
                color: page.statusError ? Theme.error : Theme.success
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.WordWrap
            }
        }
    }

    FileDialog {
        id: saveDialog
        title: "Сохранить MIDI как…"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "mid"
        nameFilters: ["MIDI (*.mid)", "Все файлы (*)"]
        onAccepted: page.doGenerate(selectedFile.toString())
        onRejected: {
            page.status = "Отменено"
            page.statusError = true
        }
    }

    function askSave() {
        var ts = Math.floor(Date.now() / 1000)
        var baseName = "melody_" + keyCombo.currentText + "_" + scaleCombo.currentText + "_" + ts + ".mid"
        saveDialog.currentFile = "file:///" + baseName
        saveDialog.open()
    }

    function doGenerate(path) {
        var r = backend.generateMelodyTo(
            keyCombo.currentText,
            scaleCombo.currentText,
            genreCombo.currentText,
            barsSpin.value,
            bpmSpin.value,
            path
        )
        if (r.ok) {
            page.status = "Сохранено: " + r.path
            page.statusError = false
        } else {
            page.status = "Ошибка: " + r.error
            page.statusError = true
        }
    }
}