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
    property real resultBpm: 0
    property string resultKey: ""
    property string resultCamelot: ""
    property string resultSource: ""
    property bool hasResult: false
    property bool useAPI: false

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
            label: "NEBULATOOLS · BPM & KEY"
            title: "BPM & Key Finder"
            subtitle: "Определяет BPM и тональность любого трека. Локально или через API."
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
                                    model: 20
                                    Rectangle {
                                        required property int index
                                        width: 3
                                        height: 10
                                        radius: 1.5
                                        color: Theme.accent
                                        opacity: 0.5
                                        anchors.verticalCenter: parent.verticalCenter
                                        
                                        SequentialAnimation on height {
                                            loops: Animation.Infinite
                                            running: page.audioPath === ""
                                            NumberAnimation { 
                                                to: 10 + Math.random() * 40; 
                                                duration: 300 + (index * 20) 
                                            }
                                            NumberAnimation { 
                                                to: 10 + Math.random() * 40; 
                                                duration: 300 + (index * 20) 
                                            }
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
                            width: 180; height: 40
                            radius: Theme.radiusSmall
                            color: Theme.accent
                            Text { anchors.centerIn: parent; text: "Выбрать файл"; color: "#FFFFFF"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall; font.weight: Font.DemiBold }
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
                                page.hasResult = false
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    visible: page.hasResult
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
                            Text { text: "Результаты"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontH3; font.weight: Font.DemiBold }
                        }

                        RowLayout {
                            spacing: Theme.spaceXl
                            
                            ColumnLayout {
                                spacing: 4
                                Text { text: "BPM"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontTiny }
                                Text { text: page.resultBpm > 0 ? page.resultBpm.toFixed(1) : "—"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 32; font.weight: Font.Bold }
                                
                                RowLayout {
                                    Layout.topMargin: 4
                                    spacing: 4
                                    Rectangle {
                                        width: 32; height: 20; radius: 4; color: Theme.surfaceHover
                                        Text { anchors.centerIn: parent; text: "/2"; color: Theme.accent; font.pixelSize: 10; font.bold: true }
                                        TapHandler { onTapped: page.resultBpm = Math.round(page.resultBpm / 2) }
                                    }
                                    Rectangle {
                                        width: 32; height: 20; radius: 4; color: Theme.surfaceHover
                                        Text { anchors.centerIn: parent; text: "x2"; color: Theme.accent; font.pixelSize: 10; font.bold: true }
                                        TapHandler { onTapped: page.resultBpm = Math.round(page.resultBpm * 2) }
                                    }
                                }
                            }
                            
                            Rectangle { width: 1; height: 60; color: Theme.border }
                            ColumnLayout {
                                spacing: 4
                                Text { text: "Тональность"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontTiny }
                                Text { text: page.resultKey || "—"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 32; font.weight: Font.Bold }
                            }
                            Rectangle { width: 1; height: 60; color: Theme.border }
                            ColumnLayout {
                                spacing: 4
                                Text { text: "Camelot"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontTiny }
                                Text { text: page.resultCamelot || "—"; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 32; font.weight: Font.Bold }
                            }
                            Item { Layout.fillWidth: true }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Источник: " + page.resultSource
                            color: Theme.textTertiary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontTiny
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
                    title: "Метод анализа"
                    description: "API (Songfinder) быстрее для известных треков. Локально — работает офлайн."
                    previewType: "none"
                    accentColor: Theme.accent

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spaceM
                        
                        Text { 
                            text: "Использовать API"; 
                            color: Theme.textPrimary; 
                            font.family: Theme.fontFamily; 
                            font.pixelSize: Theme.fontBody; 
                            Layout.fillWidth: true 
                        }
                        ToggleSwitch {
                            checked: page.useAPI
                            onToggled: (v) => page.useAPI = v
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: Theme.radiusSmall
                    color: Theme.surfaceHover
                    border.color: Theme.border
                    border.width: 1
                    visible: page.processing || page.status !== ""
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spaceM
                        anchors.rightMargin: Theme.spaceM
                        spacing: Theme.spaceS
                        Rectangle {
                            width: 8; height: 8; radius: 4
                            color: page.processing ? Theme.accent : (page.statusError ? Theme.error : Theme.success)
                            SequentialAnimation on opacity {
                                running: page.processing
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 500 }
                                NumberAnimation { to: 1.0; duration: 500 }
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: page.processing ? "Анализ... подожди" : page.status
                            color: page.processing ? Theme.accent : (page.statusError ? Theme.error : Theme.textPrimary)
                            font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall
                            elide: Text.ElideRight
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: Theme.radius
                    color: page.processing ? "#5A4B8C" : (analyzeBtn.hovered ? Theme.accentHover : Theme.accent)
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Text { anchors.centerIn: parent; text: page.processing ? "Анализирую..." : "Анализировать трек"; color: "#FFFFFF"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontH3; font.weight: Font.DemiBold }
                    HoverHandler { id: analyzeBtn; cursorShape: Qt.PointingHandCursor }
                    TapHandler { 
                        onTapped: { 
                            if (!page.processing) page.analyze() 
                        } 
                    }
                }
            }
        }
    }

    FileDialog {
        id: audioDialog
        title: "Аудио для анализа"
        nameFilters: ["Аудио (*.wav *.mp3 *.ogg *.flac *.m4a)", "Все файлы (*)"]
        onAccepted: {
            page.audioPath = selectedFile.toString()
            page.audioName = page.audioPath.split("/").pop()
            page.hasResult = false
        }
    }

    Connections {
        target: backend
        function onBpmProgress(msg) {
            if (msg !== "") page.status = msg
        }
        function onBpmKeyAnalyzed(res) {
            page.processing = false
            page.resultBpm = res.bpm || 0
            page.resultKey = res.key || "?"
            page.resultCamelot = res.camelot || ""
            page.resultSource = res.source || "Неизвестно"
            page.hasResult = true
            page.status = "Готово: BPM " + (res.bpm || 0).toFixed(1) + " · " + (res.key || "?")
            page.statusError = false
        }
        function onBpmKeyError(msg) {
            page.processing = false
            page.status = "Ошибка: " + msg
            page.statusError = true
            page.hasResult = false
        }
    }

    function analyze() {
        if (!page.audioPath) { 
            page.status = "Сначала выбери файл"; 
            page.statusError = true; 
            return 
        }
        page.processing = true
        page.status = "Анализирую трек..."
        page.statusError = false
        page.hasResult = false

        if (page.useAPI) {
            backend.analyzeBpmKeyAPI(page.audioPath)
        } else {
            backend.analyzeBpmKey(page.audioPath)
        }
    }
}