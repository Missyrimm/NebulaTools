import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Nebula 1.0
import "../components"

Item {
    id: page
    property string audioPath: ""
    property string audioName: ""
    property string status: ""
    property bool statusError: false

    property bool analyzed: false
    property real detectedBpm: 0
    property string detectedKey: ""
    property real detectedConfidence: 0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceL
        spacing: Theme.spaceL

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.radius
            color: Theme.surface
            border.color: Theme.border
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spaceL
                spacing: Theme.spaceL

                Text {
                    text: "Рандомная нарезка сэмплов"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontH2
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "Нарезает аудио по битам и собирает новый бит"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 140
                    radius: Theme.radiusSmall
                    color: Theme.surfaceHover
                    border.color: dropArea.containsDrag ? Theme.accent : Theme.border
                    border.width: dropArea.containsDrag ? 2 : 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: page.audioPath ? "✓ " + page.audioName : "Перетащи аудио сюда"
                            color: page.audioPath ? Theme.success : Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.weight: Font.DemiBold
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 140
                            height: 32
                            radius: Theme.radiusSmall
                            color: Theme.accent
                            Text {
                                anchors.centerIn: parent
                                text: "Выбрать файл"
                                color: "#FFFFFF"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                font.weight: Font.DemiBold
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: audioDialog.open() }
                        }
                    }

                    DropArea {
                        id: dropArea
                        anchors.fill: parent
                        onDropped: (drop) => {
                            if (drop.hasUrls && drop.urls.length > 0) {
                                page.audioPath = drop.urls[0].toString()
                                page.audioName = page.audioPath.split("/").pop()
                                page.analyzed = false
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spaceM
                    Text { text: "Тактов:"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                    AppSpinBox { id: barsSpin; from: 1; to: 16; value: 4; Layout.preferredWidth: 140 }
                    Text { text: "BPM:"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                    AppSpinBox { id: bpmSpin; from: 60; to: 200; value: 120; Layout.preferredWidth: 140 }
                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 170; height: 40
                        radius: Theme.radiusSmall
                        color: analyzeBtn.pressed ? Theme.accentHover : Theme.surfaceHover
                        border.color: Theme.border
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "\uE9D9"
                                color: Theme.accent
                                font.family: Theme.iconFamily
                                font.pixelSize: 13
                            }
                            Text {
                                text: "Analyze Audio"
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                font.weight: Font.DemiBold
                            }
                        }

                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler { id: analyzeBtn; onTapped: page.analyze() }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    visible: page.analyzed
                    implicitHeight: resultCol.implicitHeight + Theme.spaceM * 2
                    radius: Theme.radiusSmall
                    color: Qt.rgba(1.0, 0.478, 0.102, 0.08)
                    border.color: Qt.rgba(1.0, 0.478, 0.102, 0.3)
                    border.width: 1

                    ColumnLayout {
                        id: resultCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Theme.spaceM
                        spacing: 8

                        Text {
                            text: "Результаты анализа"
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            font.weight: Font.DemiBold
                        }

                        RowLayout {
                            spacing: Theme.spaceL

                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: "BPM"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                }
                                Text {
                                    text: page.detectedBpm.toFixed(1)
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 22
                                    font.weight: Font.Bold
                                }
                            }

                            Rectangle { width: 1; height: 40; color: Theme.border }

                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: "Тональность"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                }
                                Text {
                                    text: page.detectedKey
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 22
                                    font.weight: Font.Bold
                                }
                            }

                            Rectangle { width: 1; height: 40; color: Theme.border }

                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: "Уверенность"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                }
                                Text {
                                    text: Math.round(page.detectedConfidence * 100) + "%"
                                    color: page.detectedConfidence > 0.7 ? Theme.success
                                         : (page.detectedConfidence > 0.4 ? Theme.accent : Theme.error)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 22
                                    font.weight: Font.Bold
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }
                    }
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
                        text: "Сгенерировать бит"
                        color: "#FFFFFF"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontH3
                        font.weight: Font.DemiBold
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: page.askSave() }
                }
            }
        }

        // Статус-бар
        Rectangle {
            Layout.fillWidth: true
            height: 36
            radius: Theme.radiusSmall
            color: Theme.surface
            border.color: Theme.border
            border.width: 1
            visible: page.status !== ""

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spaceM
                anchors.rightMargin: Theme.spaceM
                spacing: Theme.spaceS

                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: page.statusError ? Theme.error : Theme.success
                }

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

    FileDialog {
        id: audioDialog
        title: "Аудио файл"
        nameFilters: ["Аудио (*.wav *.mp3 *.ogg *.flac)", "Все файлы (*)"]
        onAccepted: {
            page.audioPath = selectedFile.toString()
            page.audioName = page.audioPath.split("/").pop()
            page.analyzed = false
        }
    }

    FileDialog {
        id: saveBeatDialog
        title: "Сохранить бит как…"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "wav"
        nameFilters: ["WAV (*.wav)", "Все файлы (*)"]
        onAccepted: page.doGenerate(selectedFile.toString())
    }

    function analyze() {
        if (!page.audioPath) {
            page.status = "Сначала выбери файл"
            page.statusError = true
            return
        }
        page.status = "Анализирую..."
        page.statusError = false
        var r = backend.analyzeAudio(page.audioPath)
        if (r.ok) {
            page.detectedBpm = r.bpm
            page.detectedKey = r.key
            page.detectedConfidence = r.confidence
            page.analyzed = true
            bpmSpin.value = Math.round(r.bpm)
            page.status = "BPM: " + r.bpm.toFixed(1) + " · Тональность: " + r.key
            page.statusError = false
        } else {
            page.status = "Ошибка анализа: " + r.error
            page.statusError = true
            page.analyzed = false
        }
    }

    function askSave() {
        if (!page.audioPath) {
            page.status = "Сначала выбери файл"
            page.statusError = true
            return
        }
        var ts = Math.floor(Date.now() / 1000)
        saveBeatDialog.currentFile = "file:///beat_" + ts + ".wav"
        saveBeatDialog.open()
    }

    function doGenerate(path) {
        var r = backend.generateBeatTo(page.audioPath, barsSpin.value, bpmSpin.value, path)
        if (r.ok) {
            page.status = "Сохранено: " + r.path
            page.statusError = false
        } else {
            page.status = "Ошибка: " + r.error
            page.statusError = true
        }
    }
}