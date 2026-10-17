import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Nebula 1.0
import "../components"

Item {
    id: page
    property var results: []
    property bool loading: false
    property string lastDownloaded: ""
    property string pendingUrl: ""
    property string pendingName: ""
    property string playingUrl: ""
    property string previewLoadingUrl: ""

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
            label: "NEBULATOOLS · SAMPLES"
            title: "Сэмплы"
            subtitle: "Библиотека случайных сэмплов с Freesound. Поиск, рандом, прослушивание."
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spaceL

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 700
                spacing: Theme.spaceL

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 140
                    radius: Theme.radiusLarge
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spaceL
                        spacing: Theme.spaceM

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spaceS
                            Rectangle { width: 4; height: 14; radius: 2; color: Theme.accent }
                            Text {
                                text: "Поиск"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontH3
                                font.weight: Font.DemiBold
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spaceS

                            AppTextField {
                                id: queryInput
                                Layout.fillWidth: true
                                text: "lofi"
                                Keys.onReturnPressed: page.doSearch()
                            }

                            Rectangle {
                                width: 200
                                height: 40
                                radius: Theme.radiusSmall
                                color: Theme.surfaceElevated
                                border.color: Theme.borderLight
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 6
                                    spacing: 4

                                    Text {
                                        text: "\uE8B7"
                                        font.family: Theme.iconFamily
                                        font.pixelSize: 12
                                        color: Theme.textSecondary
                                    }

                                    AppComboBox {
                                        id: categoryCombo
                                        Layout.fillWidth: true
                                        model: ["Все", "Вокал", "Мелодия", "Драм"]
                                        currentIndex: 0
                                        font.pixelSize: Theme.fontSmall
                                    }
                                }
                            }

                            Rectangle {
                                width: 100; height: 40
                                radius: Theme.radiusSmall
                                color: searchBtn.pressed ? Theme.accentHover : (page.loading ? "#5A4B8C" : Theme.accent)
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                Text {
                                    anchors.centerIn: parent
                                    text: page.loading ? "..." : "Искать"
                                    color: "#FFFFFF"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                    font.weight: Font.DemiBold
                                }
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                                TapHandler { id: searchBtn; onTapped: { if(!page.loading) page.doSearch() } }
                            }

                            Rectangle {
                                width: 130; height: 40
                                radius: Theme.radiusSmall
                                color: randomBtn.pressed ? Theme.accentHover : (page.loading ? "#5A4B8C" : Theme.accent)
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: "\uE7C3"; color: "#FFFFFF"; font.family: Theme.iconFamily; font.pixelSize: 13 }
                                    Text { text: "Рандом"; color: "#FFFFFF"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall; font.weight: Font.DemiBold }
                                }
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                                TapHandler { id: randomBtn; onTapped: { if(!page.loading) page.doRandom() } }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusLarge
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spaceL
                        spacing: Theme.spaceS

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spaceS
                            Rectangle { width: 4; height: 14; radius: 2; color: Theme.accent }
                            Text {
                                text: "Результаты"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontH3
                                font.weight: Font.DemiBold
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: page.results.length > 0
                                    ? "Найдено: " + page.results.length
                                    : (page.loading ? "Загрузка..." : "Пока пусто")
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                            }
                        }

                        ListView {
                            id: listView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 4
                            model: page.results

                            delegate: Rectangle {
                                width: listView.width
                                height: 60
                                radius: Theme.radiusSmall
                                color: itemHover.hovered ? Theme.surfaceHover : "transparent"

                                HoverHandler { id: itemHover }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: Theme.spaceM

                                    Rectangle {
                                        width: 40; height: 40; radius: 20
                                        color: {
                                            if (page.playingUrl === modelData.preview_url)
                                                return Theme.accent
                                            if (page.previewLoadingUrl === modelData.preview_url)
                                                return Theme.accentHover
                                            return playBtn.hovered ? Theme.accentHover : Theme.surfaceElevated
                                        }
                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                        SequentialAnimation on opacity {
                                            running: page.previewLoadingUrl === modelData.preview_url
                                            loops: Animation.Infinite
                                            NumberAnimation { to: 0.5; duration: 500 }
                                            NumberAnimation { to: 1.0; duration: 500 }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: {
                                                if (page.playingUrl === modelData.preview_url)
                                                    return "\uE769"
                                                if (page.previewLoadingUrl === modelData.preview_url)
                                                    return "\uE916"
                                                return "\uE768"
                                            }
                                            color: {
                                                if (page.playingUrl === modelData.preview_url) return "#FFFFFF"
                                                if (page.previewLoadingUrl === modelData.preview_url) return "#FFFFFF"
                                                return Theme.accent
                                            }
                                            font.family: Theme.iconFamily
                                            font.pixelSize: 14
                                        }

                                        HoverHandler { id: playBtn; cursorShape: Qt.PointingHandCursor }
                                        TapHandler { onTapped: page.togglePlay(modelData.preview_url, modelData.name) }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            text: modelData.name
                                            color: Theme.textPrimary
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontBody
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: modelData.duration + "s · " + modelData.username + " · " + modelData.license
                                            color: Theme.textSecondary
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSmall
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    Rectangle {
                                        width: 90; height: 32
                                        radius: Theme.radiusSmall
                                        color: dlBtn.pressed ? Theme.accentHover : Theme.accent
                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                        Text {
                                            anchors.centerIn: parent
                                            text: "Скачать"
                                            color: "#FFFFFF"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSmall
                                            font.weight: Font.DemiBold
                                        }
                                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                                        TapHandler { id: dlBtn; onTapped: page.askSave(modelData.preview_url, modelData.name) }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.preferredWidth: 340
                Layout.fillHeight: true
                spacing: Theme.spaceL

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusLarge
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spaceL
                        spacing: Theme.spaceM

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spaceS
                            Rectangle { width: 4; height: 14; radius: 2; color: Theme.accent }
                            Text {
                                text: "О сэмплах"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontH3
                                font.weight: Font.DemiBold
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Все сэмплы с Freesound — CC0 / CC-BY. Можно использовать в любых треках."
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            wrapMode: Text.WordWrap
                            lineHeight: 1.4
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                        Text {
                            Layout.fillWidth: true
                            text: "Категория для рандома:"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "• Все — любые сэмплы\n" +
                                  "• Вокал — acapella, voice\n" +
                                  "• Мелодия — piano, guitar, synth\n" +
                                  "• Драм — kick, snare, hi-hat, loop"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            wrapMode: Text.WordWrap
                            lineHeight: 1.4
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                        Text {
                            Layout.fillWidth: true
                            text: "Последний скачанный:"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                        }

                        Text {
                            Layout.fillWidth: true
                            text: page.lastDownloaded || "—"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            wrapMode: Text.WrapAnywhere
                            elide: Text.ElideMiddle
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }

    FileDialog {
        id: saveDialog
        title: "Сохранить сэмпл как…"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "mp3"
        nameFilters: ["MP3 (*.mp3)", "Все файлы (*)"]
        onAccepted: {
            backend.downloadSampleTo(page.pendingUrl, selectedFile.toString())
        }
    }

    Connections {
        target: backend

        function onSamplesReady(res) {
            page.results = res
            page.loading = false
        }
        function onSamplesError(msg) {
            page.loading = false
            page.lastDownloaded = "Ошибка поиска: " + msg
        }
        function onSampleDownloaded(res) {
            page.lastDownloaded = "Скачан: " + res.path
        }
        function onSampleDownloadError(msg) {
            page.lastDownloaded = "Ошибка скачивания: " + msg
        }

        function onPreviewReady(url) {
            if (page.previewLoadingUrl === url) {
                page.previewLoadingUrl = ""
                page.playingUrl = url
            }
        }

        function onPreviewError(url, msg) {
            if (page.previewLoadingUrl === url) {
                page.previewLoadingUrl = ""
                page.playingUrl = ""
                page.lastDownloaded = "Ошибка превью: " + msg
            }
        }
    }

    function doSearch() {
        if (!queryInput.text.trim()) return
        page.loading = true
        page.playingUrl = ""
        page.previewLoadingUrl = ""
        backend.searchSamples(queryInput.text.trim(), 20)
    }

    function doRandom() {
        var base = queryInput.text.trim() || ""
        var cat = categoryCombo.currentIndex
        var tag = ""
        if (cat === 1) tag = "vocal"
        else if (cat === 2) tag = "melody"
        else if (cat === 3) tag = "drum"
        var q = (base + " " + tag).trim()
        if (!q) q = "sample"
        
        page.loading = true
        backend.searchSamples(q, 50) // QML теперь не ждет, а ждет сигнала
    }

    function togglePlay(url, name) {
        if (page.previewLoadingUrl === url) {
            backend.stopPreview()
            page.previewLoadingUrl = ""
            page.playingUrl = ""
            return
        }
        if (page.playingUrl === url) {
            backend.stopPreview()
            page.playingUrl = ""
            return
        }
        backend.stopPreview()
        page.playingUrl = ""
        page.previewLoadingUrl = url
        var r = backend.previewSample(url, name)
        if (!r.ok) {
            page.previewLoadingUrl = ""
            page.lastDownloaded = "Ошибка: " + (r.error || "неизвестно")
        }
    }

    function askSave(url, name) {
        page.pendingUrl = url
        page.pendingName = name
        var safe = name.replace(/[^\w\s-]/g, "").substring(0, 40).trim() || "sample"
        saveDialog.currentFile = "file:///" + safe + ".mp3"
        saveDialog.open()
    }
}