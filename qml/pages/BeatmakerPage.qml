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
            label: "NEBULATOOLS · SLICER"
            title: "Рандомная нарезка сэмплов"
            subtitle: "Анализирует BPM и тональность, нарезает аудио по битам и собирает новый бит."
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spaceL

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 560
                spacing: Theme.spaceL

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 240
                    radius: Theme.radiusLarge
                    color: Theme.surface
                    border.color: dropArea.containsDrag ? Theme.accent : Theme.border
                    border.width: dropArea.containsDrag ? 2 : 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spaceL
                        spacing: 0

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 70
                            Row {
                                anchors.centerIn: parent
                                spacing: 3
                                Repeater {
                                    model: 18
                                    Rectangle {
                                        required property int index
                                        width: 4
                                        height: 8 + Math.abs(Math.sin(index * 1.3)) * 34
                                        radius: 2
                                        color: page.audioPath !== "" ? Theme.accent : Theme.borderLight
                                        opacity: 0.7
                                        anchors.verticalCenter: parent.verticalCenter
                                        SequentialAnimation on opacity {
                                            loops: Animation.Infinite
                                            running: page.audioPath === ""
                                            PauseAnimation { duration: index * 100 }
                                            NumberAnimation { to: 1.0; duration: 300 }
                                            NumberAnimation { to: 0.4; duration: 300 }
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: page.audioPath ? "✓ " + page.audioName : "Перетащи аудио сюда"
                            color: page.audioPath ? Theme.success : Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.weight: Font.DemiBold
                        }

                        Item { Layout.preferredHeight: Theme.spaceM }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 180
                            height: 40
                            radius: Theme.radiusSmall
                            color: Theme.surfaceElevated
                            border.color: Theme.borderLight
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: "Выбрать файл"
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                font.weight: Font.DemiBold
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: audioDialog.open() }
                        }

                        Item { Layout.fillHeight: true }
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

                Rectangle {
                    Layout.fillWidth: true
                    visible: page.analyzed
                    implicitHeight: resultCol.implicitHeight + Theme.spaceL * 2
                    radius: Theme.radiusLarge
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        id: resultCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Theme.spaceL
                        spacing: Theme.spaceM

                        RowLayout {
                            spacing: Theme.spaceS
                            Rectangle { width: 4; height: 14; radius: 2; color: Theme.accent }
                            Text {
                                text: "Результаты анализа"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontH3
                                font.weight: Font.DemiBold
                            }
                        }

                        RowLayout {
                            spacing: Theme.spaceL
                            ColumnLayout {
                                spacing: 2
                                Text { text: "BPM"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontTiny }
                                Text { text: page.detectedBpm.toFixed(1); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 26; font.weight: Font.Bold }
                            }
                            Rectangle { width: 1; height: 50; color: Theme.border }
                            ColumnLayout {
                                spacing: 2
                                Text { text: "Тональность"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontTiny }
                                Text { text: page.detectedKey; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 26; font.weight: Font.Bold }
                            }
                            Rectangle { width: 1; height: 50; color: Theme.border }
                            ColumnLayout {
                                spacing: 2
                                Text { text: "Уверенность"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontTiny }
                                Text {
                                    text: Math.round(page.detectedConfidence * 100) + "%"
                                    color: page.detectedConfidence > 0.7 ? Theme.success
                                         : (page.detectedConfidence > 0.4 ? Theme.accent : Theme.error)
                                    font.family: Theme.fontFamily; font.pixelSize: 26; font.weight: Font.Bold
                                }
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.preferredWidth: 400
                Layout.fillHeight: true
                spacing: Theme.spaceL

                CardWithPreview {
                    Layout.fillWidth: true
                    title: "Параметры"
                    description: "Количество тактов и BPM. После Analyze — обновится автоматически."

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spaceM
                        Text { text: "Тактов:"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                        AppSpinBox { id: barsSpin; from: 1; to: 16; value: 4; Layout.fillWidth: true }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spaceM
                        Text { text: "BPM:"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                        AppSpinBox { id: bpmSpin; from: 60; to: 200; value: 120; Layout.fillWidth: true }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: Theme.radiusSmall
                        color: analyzeBtn.pressed ? Theme.surfaceHover : Theme.surfaceElevated
                        border.color: Theme.borderLight
                        border.width: 1
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "\uE9D9"; color: Theme.accentCyan; font.family: Theme.iconFamily; font.pixelSize: 13 }
                            Text { text: "Analyze Audio"; color: Theme.accentCyan; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall; font.weight: Font.DemiBold }
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler { id: analyzeBtn; onTapped: page.analyze() }
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    id: genBeatBtn
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: Theme.radius
                    color: genBeatHov.hovered ? Theme.accentHover : Theme.accent
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Text {
                        anchors.centerIn: parent
                        text: "Сгенерировать бит"
                        color: "#FFFFFF"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontH3
                        font.weight: Font.DemiBold
                    }
                    HoverHandler { id: genBeatHov; cursorShape: Qt.PointingHandCursor }
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
                            font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall
                            elide: Text.ElideRight
                        }
                    }
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
        onAccepted: {
            page.status = "Генерация..."
            page.statusError = false
            backend.generateBeatTo(page.audioPath, barsSpin.value, bpmSpin.value, selectedFile.toString())
        }
    }

    Connections {
        target: backend
        function onAudioAnalyzed(res) {
            page.detectedBpm = res.bpm
            page.detectedKey = res.key
            page.detectedConfidence = res.confidence
            page.analyzed = true
            bpmSpin.value = Math.round(res.bpm)
            page.status = "BPM: " + res.bpm.toFixed(1) + " · Тональность: " + res.key
            page.statusError = false
        }
        function onAudioAnalyzeError(msg) {
            page.status = "Ошибка анализа: " + msg
            page.statusError = true
            page.analyzed = false
        }
        function onBeatGenerated(res) {
            page.status = "Сохранено: " + res.path
            page.statusError = false
        }
        function onBeatError(msg) {
            page.status = "Ошибка: " + msg
            page.statusError = true
        }
    }

    function analyze() {
        if (!page.audioPath) { page.status = "Сначала выбери файл"; page.statusError = true; return }
        page.status = "Анализирую..."; page.statusError = false
        backend.analyzeAudio(page.audioPath)
    }

    function askSave() {
        if (!page.audioPath) { page.status = "Сначала выбери файл"; page.statusError = true; return }
        var ts = Math.floor(Date.now() / 1000)
        saveBeatDialog.currentFile = "file:///beat_" + ts + ".wav"
        saveBeatDialog.open()
    }
}