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
    property bool processing: false
    property var stemsResult: ({})
    property string format: "wav"
    property int progressPercent: 0

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
            label: "NEBULATOOLS · STEMS"
            title: "Разделение стемов"
            subtitle: "UVR / Demucs. Вокал, драм, бас, другой. Локально."
            accentColor: Theme.accent
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
                    Layout.preferredHeight: 200
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
                            Layout.preferredHeight: 60
                            Column {
                                anchors.centerIn: parent
                                spacing: 6
                                Repeater {
                                    model: 4
                                    Rectangle {
                                        required property int index
                                        property real baseWidth: 160 + (index % 2 === 0 ? 20 : -10)
                                        
                                        width: baseWidth
                                        height: 5
                                        radius: 2.5
                                        color: index % 2 === 0 ? Theme.accent : Theme.accentHover
                                        opacity: page.audioPath !== "" ? 0.9 : 0.5
                                        anchors.horizontalCenter: parent.horizontalCenter

                                        SequentialAnimation on width {
                                            loops: Animation.Infinite
                                            running: true
                                            NumberAnimation { to: baseWidth + 20; duration: 800 + (index * 150); easing.type: Easing.InOutSine }
                                            NumberAnimation { to: baseWidth - 10; duration: 800 + (index * 150); easing.type: Easing.InOutSine }
                                        }
                                        
                                        SequentialAnimation on opacity {
                                            loops: Animation.Infinite
                                            running: true
                                            NumberAnimation { to: 0.3; duration: 800 + (index * 150); easing.type: Easing.InOutSine }
                                            NumberAnimation { to: 0.9; duration: 800 + (index * 150); easing.type: Easing.InOutSine }
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

                        Item { Layout.preferredHeight: 12 }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 180
                            height: 40
                            radius: Theme.radiusSmall
                            color: pickHover.hovered ? Theme.accentHover : Theme.accent
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            Text {
                                anchors.centerIn: parent
                                text: "Выбрать файл"
                                color: "#FFFFFF"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                font.weight: Font.DemiBold
                            }
                            HoverHandler { id: pickHover; cursorShape: Qt.PointingHandCursor }
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
                                page.stemsResult = {}
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    visible: page.processing || page.status !== ""
                    implicitHeight: 60
                    radius: Theme.radius
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spaceM
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Rectangle {
                                width: 8; height: 8; radius: 4
                                color: page.processing ? Theme.accent : (page.statusError ? Theme.error : Theme.success)
                            }
                            Text {
                                Layout.fillWidth: true
                                text: page.processing ? page.status + " (" + page.progressPercent + "%)" : page.status
                                color: page.processing ? Theme.accent : (page.statusError ? Theme.error : Theme.textPrimary)
                                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 4
                            radius: 2
                            color: Theme.surfaceHover
                            visible: page.processing
                            clip: true

                            Rectangle {
                                width: parent.width * (page.progressPercent / 100.0)
                                height: parent.height
                                radius: 2
                                color: Theme.accent
                                Behavior on width { NumberAnimation { duration: 200 } }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    visible: Object.keys(page.stemsResult).length > 0
                    implicitHeight: stemsCol.implicitHeight + Theme.spaceL * 2
                    radius: Theme.radiusLarge
                    color: Theme.surface
                    border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
                    border.width: 1

                    ColumnLayout {
                        id: stemsCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Theme.spaceL
                        spacing: Theme.spaceS
                        RowLayout {
                            spacing: Theme.spaceS
                            Rectangle { width: 4; height: 14; radius: 2; color: Theme.accent }
                            Text { text: "Готово! Сохранённые стемы:"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontH3; font.weight: Font.DemiBold }
                        }
                        Repeater {
                            model: Object.keys(page.stemsResult)
                            delegate: Text {
                                required property string modelData
                                text: "  " + modelData + ": " + page.stemsResult[modelData]
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                            }
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
                    Layout.fillHeight: true
                    title: "Параметры"
                    description: "Модель + формат. Файлы сохранятся в выбранную папку."
                    previewType: "tracks"
                    accentColor: Theme.accent

                    AppComboBox {
                        id: modelCombo
                        Layout.fillWidth: true
                        model: [
                            "2 стема: вокал + инструментал (HQ)",
                            "Только вокал (быстро)",
                            "4 стема: вокал, драм, бас, другой (Demucs FT)",
                            "4 стема: вокал, драм, бас, другой (Demucs)",
                            "6 стемов: вокал, драм, бас, гитара, пиано, другой"
                        ]
                        currentIndex: 0
                        readonly property var modelIds: [
                            "UVR-MDX-NET-Inst_HQ_3.onnx",
                            "UVR-MDX-NET-Voc_FT.onnx",
                            "htdemucs_ft.yaml",
                            "htdemucs.yaml",
                            "htdemucs_6s.yaml"
                        ]
                        function currentModelId() { return modelIds[currentIndex] }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spaceS

                        Text {
                            text: "Формат:"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                        }

                        AppComboBox {
                            id: formatCombo
                            Layout.fillWidth: true
                            model: ["WAV", "MP3"]
                            currentIndex: 0
                        }
                    }
                }

                Rectangle {
                    id: splitBtn
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: Theme.radius
                    color: page.processing ? "#5A4B8C" : (splitHover.hovered ? Theme.accentHover : Theme.accent)
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Text { anchors.centerIn: parent; text: page.processing ? "Обработка..." : "Разделить на стемы"; color: "#FFFFFF"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontH3; font.weight: Font.DemiBold }
                    HoverHandler { id: splitHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { 
                        onTapped: { 
                            if (!page.processing) page.askSave() 
                        } 
                    }
                }
            }
        }
    }

    FileDialog {
        id: audioDialog
        title: "Аудио для разделения"
        nameFilters: ["Аудио (*.wav *.mp3 *.ogg *.flac *.m4a)", "Все файлы (*)"]
        onAccepted: {
            page.audioPath = selectedFile.toString()
            page.audioName = page.audioPath.split("/").pop()
            page.stemsResult = {}
        }
    }

    FolderDialog {
        id: outputFolderDialog
        title: "Куда сохранить стемы (выбери папку)"
        onAccepted: page.doProcess(selectedFolder.toString())
    }

    Connections {
        target: backend
        function onStemsProgress(msg) {
            if (msg !== "") page.status = msg
        }
        function onStemsProgressPercent(pct) {
            page.progressPercent = pct
        }
        function onStemsSeparated(res) {
            page.processing = false
            page.progressPercent = 100
            page.stemsResult = res.stems
            page.status = "Готово! Стемов: " + Object.keys(res.stems).length
            page.statusError = false
        }
        function onStemsError(msg) {
            page.processing = false
            page.progressPercent = 0
            page.status = "Ошибка: " + msg
            page.statusError = true
        }
    }

    function askSave() {
        if (!page.audioPath) { 
            page.status = "Сначала выбери файл"
            page.statusError = true
            return 
        }
        outputFolderDialog.open()
    }

    function doProcess(targetDir) {
        var outDir = targetDir.replace("file:///", "").replace("file://", "")
        page.processing = true
        page.progressPercent = 0
        page.status = "Загрузка модели и обработка..."
        page.statusError = false

        var fmt = formatCombo.currentText.toLowerCase()
        backend.separateStems(page.audioPath, outDir, modelCombo.currentModelId(), fmt)
    }
}