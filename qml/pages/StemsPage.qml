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
            subtitle: "Разделяет трек на вокал, барабаны, бас и инструментал. Работает локально."
            accentColor: Theme.accent
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spaceL

            // Левая: dropzone + результат
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
                            Column {
                                anchors.centerIn: parent
                                spacing: 6
                                Repeater {
                                    model: 4
                                    Rectangle {
                                        required property int index
                                        width: 160 + (index % 2 === 0 ? 20 : -10)
                                        height: 5
                                        radius: 2.5
                                        color: index % 2 === 0 ? Theme.accent : Theme.accentHover
                                        opacity: page.audioPath !== "" ? 0.9 : 0.5
                                        SequentialAnimation on opacity {
                                            loops: Animation.Infinite
                                            running: page.audioPath === ""
                                            PauseAnimation { duration: index * 200 }
                                            NumberAnimation { to: 0.9; duration: 400 }
                                            NumberAnimation { to: 0.4; duration: 400 }
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
                            id: pickBtn
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

            // Правая: параметры + кнопка
            ColumnLayout {
                Layout.preferredWidth: 400
                Layout.fillHeight: true
                spacing: Theme.spaceL

                CardWithPreview {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    title: "Параметры разделения"
                    description: "Выбери модель. Стемы сохранятся как отдельные WAV."
                    previewType: "tracks"
                    accentColor: Theme.accent

                    AppComboBox {
                        id: modelCombo
                        Layout.fillWidth: true
                        model: [
                            "2 стема: вокал + инструментал (HQ)",
                            "Только вокал (быстро)",
                            "Караоке (вокал + инструментал)"
                        ]
                        currentIndex: 0
                        readonly property var modelIds: [
                            "UVR-MDX-NET-Inst_HQ_3.onnx",
                            "UVR-MDX-NET-Voc_FT.onnx",
                            "UVR_MDXNET_KARA_2.onnx"
                        ]
                        function currentModelId() { return modelIds[currentIndex] }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text { Layout.fillWidth: true; text: "• Vocals — вокал"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                        Text { Layout.fillWidth: true; text: "• Instrumental — инструментал"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                        Text { Layout.fillWidth: true; text: "• Drums/Bass — при 4-стемовой модели"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                    }
                }

                Rectangle {
                    id: splitBtn
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: Theme.radius
                    color: page.processing ? "#5A4B8C"
                        : (splitHover.hovered ? Theme.accentHover : Theme.accent)
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Text {
                        anchors.centerIn: parent
                        text: page.processing ? "Обработка..." : "Разделить на стемы"
                        color: "#FFFFFF"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontH3
                        font.weight: Font.DemiBold
                    }
                    HoverHandler { id: splitHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: if (!page.processing) page.askSave() }
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
        title: "Аудио для разделения"
        nameFilters: ["Аудио (*.wav *.mp3 *.ogg *.flac *.m4a)", "Все файлы (*)"]
        onAccepted: {
            page.audioPath = selectedFile.toString()
            page.audioName = page.audioPath.split("/").pop()
            page.stemsResult = {}
        }
    }

    FileDialog {
        id: outputDialog
        title: "Куда сохранить стемы"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "wav"
        nameFilters: ["Все файлы (*)"]
        onAccepted: page.doProcess(selectedFile.toString())
    }

    function askSave() {
        if (!page.audioPath) { page.status = "Сначала выбери файл"; page.statusError = true; return }
        var baseName = page.audioName.replace(/\.[^.]+$/, "") + "_stems"
        outputDialog.currentFile = "file:///" + baseName
        outputDialog.open()
    }

    function doProcess(targetPath) {
        var outDir = targetPath.replace("file:///", "").replace(/\/[^\/]+$/, "")
        page.processing = true
        page.status = "Загрузка модели и обработка..."; page.statusError = false
        var result = backend.separateStems(page.audioPath, outDir, modelCombo.currentModelId())
        page.processing = false
        if (result.ok) {
            page.stemsResult = result.stems
            page.status = "Готово! Стемов: " + Object.keys(result.stems).length
            page.statusError = false
        } else {
            page.status = "Ошибка: " + result.error
            page.statusError = true
        }
    }
}