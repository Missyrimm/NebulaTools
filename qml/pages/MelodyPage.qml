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

    opacity: 0
    Component.onCompleted: fadeAnim.start()
    onVisibleChanged: if (visible) { opacity = 0; fadeAnim.start() }

    NumberAnimation {
        id: fadeAnim
        target: page
        property: "opacity"
        from: 0
        to: 1
        duration: 300
        easing.type: Easing.OutCubic
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceXxl
        anchors.rightMargin: Theme.spaceXxl
        anchors.topMargin: Theme.spaceXl
        anchors.bottomMargin: Theme.spaceL
        spacing: Theme.spaceL

        PageHeader {
            Layout.fillWidth: true
            label: "NEBULATOOLS · MIDI"
            title: "Генератор MIDI"
            subtitle: "Каждый запуск — новая прогрессия, мелодия и бас. Сохрани в любой файл."
            accentColor: Theme.accentCyan
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spaceL

            CardWithPreview {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 560
                title: "Параметры"
                description: "Настрой тональность, гамму, жанр и длительность."
                previewType: "notes"
                accentColor: Theme.accentCyan

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Theme.spaceM
                    rowSpacing: Theme.spaceM

                    Text { text: "Тональность"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                    AppComboBox {
                        id: keyCombo; Layout.fillWidth: true
                        model: ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
                        currentIndex: 9
                    }
                    Text { text: "Гамма"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                    AppComboBox {
                        id: scaleCombo; Layout.fillWidth: true
                        model: ["major","minor","dorian","phrygian","lydian","mixolydian","harmonic_minor","pentatonic","blues","whole_tone"]
                        currentIndex: 1
                    }
                    Text { text: "Жанр"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                    AppComboBox {
                        id: genreCombo; Layout.fillWidth: true
                        model: [
                            "pop", "hip-hop", "trap", "drill", "phonk",
                            "lofi", "chill", "ambient", "jazz", "blues",
                            "funk", "rnb", "gospel", "edm", "house",
                            "techno", "dnb", "riddim", "epic", "cinematic"
                        ]
                        currentIndex: 5
                    }
                    Text { text: "Тактов"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                    AppSpinBox { id: barsSpin; Layout.fillWidth: true; from: 1; to: 32; value: 4 }
                    Text { text: "BPM"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                    AppSpinBox { id: bpmSpin; Layout.fillWidth: true; from: 60; to: 200; value: 120 }
                }

                Item { Layout.fillHeight: true }
            }

            ColumnLayout {
                Layout.preferredWidth: 400
                Layout.fillHeight: true
                spacing: Theme.spaceL

                CardWithPreview {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    title: "О генераторе"
                    description: "Случайные прогрессии, басы и арпеджио в выбранной гамме. Каждый запуск — уникальная мелодия."
                    previewType: "none"

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spaceS

                        Text {
                            Layout.fillWidth: true
                            text: "• 10 гамм — от мажора до блюза\n" +
                                  "• 6 жанровых прогрессий\n" +
                                  "• Bass + Chords + Lead\n" +
                                  "• Уникальность через время-семя"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            wrapMode: Text.WordWrap
                            lineHeight: 1.5
                        }
                    }
                }

                Rectangle {
                    id: genBtn
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: Theme.radius
                    color: genBtnHov.hovered ? Theme.accentHover : Theme.accent
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Text {
                        anchors.centerIn: parent
                        text: "Сгенерировать MIDI"
                        color: "#FFFFFF"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontH3
                        font.weight: Font.DemiBold
                    }
                    HoverHandler { id: genBtnHov; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: page.askSave() }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: Theme.radiusSmall
                    color: Theme.surfaceHover
                    border.color: Theme.border
                    border.width: 1
                    visible: page.status !== ""
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spaceM
                        anchors.rightMargin: Theme.spaceM
                        spacing: Theme.spaceS
                        Rectangle { width: 8; height: 8; radius: 4; color: page.statusError ? Theme.error : Theme.success }
                        Text {
                            Layout.fillWidth: true
                            text: page.status
                            color: page.statusError ? Theme.error : Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    FileDialog {
        id: saveDialog
        title: "Сохранить MIDI как…"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "mid"
        nameFilters: ["MIDI (*.mid)", "Все файлы (*)"]
        onAccepted: {
            page.status = "Генерация..."
            page.statusError = false
            backend.generateMelodyTo(
                keyCombo.currentText, scaleCombo.currentText, genreCombo.currentText,
                barsSpin.value, bpmSpin.value, selectedFile.toString()
            )
        }
    }

    Connections {
        target: backend
        function onMelodyGenerated(res) {
            page.status = "Сохранено: " + res.path
            page.statusError = false
        }
        function onMelodyError(msg) {
            page.status = "Ошибка: " + msg
            page.statusError = true
        }
    }

    function askSave() {
        var ts = Math.floor(Date.now() / 1000)
        saveDialog.currentFile = "file:///melody_" + keyCombo.currentText + "_" + scaleCombo.currentText + "_" + ts + ".mid"
        saveDialog.open()
    }
}