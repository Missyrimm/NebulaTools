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

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceL
        spacing: Theme.spaceL

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 560
            spacing: Theme.spaceL

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: searchCol.implicitHeight + Theme.spaceL * 2
                radius: Theme.radius
                color: Theme.surface
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    id: searchCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spaceL
                    spacing: Theme.spaceM

                    Text {
                        text: "Сэмплы · Freesound"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontH2
                        font.weight: Font.DemiBold
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spaceS

                        AppTextField {
                            id: queryInput
                            Layout.fillWidth: true
                            text: "lofi kick"
                            Keys.onReturnPressed: page.doSearch()
                        }

                        Rectangle {
                            width: 100
                            height: 40
                            radius: Theme.radiusSmall
                            color: searchBtn.pressed ? Theme.accentHover : Theme.accent
                            Text {
                                anchors.centerIn: parent
                                text: "Искать"
                                color: "#FFFFFF"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler { id: searchBtn; onTapped: page.doSearch() }
                        }

                        Rectangle {
                            width: 120
                            height: 40
                            radius: Theme.radiusSmall
                            color: randomBtn.pressed ? Theme.accentHover : Theme.surfaceHover
                            border.color: Theme.border
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: "\uE7C3"
                                    color: Theme.accent
                                    font.family: Theme.iconFamily
                                    font.pixelSize: 14
                                }
                                Text {
                                    text: "Рандом"
                                    color: Theme.accent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    font.weight: Font.DemiBold
                                }
                            }

                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler { id: randomBtn; onTapped: page.doRandom() }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radius
                color: Theme.surface
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spaceM
                    spacing: Theme.spaceS

                    Text {
                        text: page.results.length > 0
                            ? "Найдено: " + page.results.length
                            : "Нажми «Искать» или «Рандом»"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }

                    ListView {
                        id: listView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        model: page.results

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: listView.width
                            height: 56
                            radius: Theme.radiusSmall
                            color: itemHover.hovered ? Theme.surfaceHover : "transparent"

                            HoverHandler { id: itemHover }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: Theme.spaceS

                                Rectangle {
                                    width: 40
                                    height: 40
                                    radius: 20
                                    color: {
                                        if (page.playingUrl === modelData.preview_url)
                                            return Theme.accent
                                        return playBtn.hovered ? Theme.accentHover : Theme.surfaceHover
                                    }
                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: page.playingUrl === modelData.preview_url
                                            ? "\uE769"
                                            : "\uE768"
                                        color: page.playingUrl === modelData.preview_url
                                            ? "#FFFFFF" : Theme.accent
                                        font.family: Theme.iconFamily
                                        font.pixelSize: 14
                                    }

                                    HoverHandler { id: playBtn; cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: page.togglePlay(modelData.preview_url, modelData.name)
                                    }
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
                                    width: 90
                                    height: 32
                                    radius: Theme.radiusSmall
                                    color: dlBtn.pressed ? Theme.accentHover : Theme.accent
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Скачать"
                                        color: "#FFFFFF"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSmall
                                        font.weight: Font.DemiBold
                                    }
                                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        id: dlBtn
                                        onTapped: page.askSave(modelData.preview_url, modelData.name)
                                    }
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
                radius: Theme.radius
                color: Theme.surface
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spaceL
                    spacing: Theme.spaceM

                    Text {
                        text: "О сэмплах"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontH3
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Сэмплы берутся с Freesound.org — база бесплатных звуков. Все результаты — CC0 / CC-BY, можно использовать в любых треках."
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        wrapMode: Text.WordWrap
                        lineHeight: 1.4
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                    Text {
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

    FileDialog {
        id: saveDialog
        title: "Сохранить сэмпл как…"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "mp3"
        nameFilters: ["MP3 (*.mp3)", "Все файлы (*)"]
        onAccepted: {
            var path = selectedFile.toString()
            var r = backend.downloadSampleTo(page.pendingUrl, path)
            if (r.ok) page.lastDownloaded = r.path
            else page.lastDownloaded = "Ошибка: " + r.error
        }
    }

    function doSearch() {
        if (!queryInput.text.trim()) return
        page.loading = true
        page.results = []
        page.playingUrl = ""
        var r = backend.searchSamples(queryInput.text.trim(), 20)
        page.results = r
        page.loading = false
    }

    function doRandom() {
        var q = queryInput.text.trim()
        if (!q) q = "sample"
        var r = backend.searchSamples(q, 50)
        if (r.length === 0) {
            page.results = []
            return
        }
        var shuffled = r.slice()
        for (var i = shuffled.length - 1; i > 0; i--) {
            var j = Math.floor(Math.random() * (i + 1))
            var tmp = shuffled[i]
            shuffled[i] = shuffled[j]
            shuffled[j] = tmp
        }
        page.results = shuffled.slice(0, 5)
    }

    function togglePlay(url, name) {
        if (page.playingUrl === url) {
            backend.stopPreview()
            page.playingUrl = ""
        } else {
            backend.stopPreview()
            var r = backend.previewSample(url, name)
            if (r.ok) page.playingUrl = url
        }
    }

    function askSave(url, name) {
        page.pendingUrl = url
        page.pendingName = name
        var safe = name.replace(/[^\w\s-]/g, "").substring(0, 40).trim()
        if (!safe) safe = "sample"
        saveDialog.currentFile = "file:///" + safe + ".mp3"
        saveDialog.open()
    }
}