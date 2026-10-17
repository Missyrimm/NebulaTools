import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Nebula 1.0
import "../components"

Item {
    id: page
    property var options: ({
        "make_backup": true,
        "check_plugins": true,
        "keep_structure": true,
        "make_report": false
    })

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
            label: "NEBULATOOLS · CONVERTER"
            title: "FLP Converter"
            subtitle: "Конвертация проектов между версиями FL Studio. Перетащи .FLP или .ZIP."
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

                DropZone {
                    id: dropZone
                    Layout.fillWidth: true
                    Layout.preferredHeight: 240
                    onBrowseClicked: fileDialog.open()
                    onFileDropped: (path) => page.loadFile(path)
                }

                ProjectCard {
                    id: projectCard
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    fileKind: ""
                }
            }

            ColumnLayout {
                Layout.preferredWidth: 400
                Layout.fillHeight: true
                spacing: Theme.spaceL

                // Версии
                CardWithPreview {
                    Layout.fillWidth: true
                    title: "Версии"
                    accentColor: Theme.accent

                    VersionSelector {
                        id: versionSelector
                        Layout.fillWidth: true
                        sourceVersion: projectCard.sourceVersion
                        onTargetVersionChanged: backend.setTargetVersion(targetVersion)
                    }
                }

                // Опции
                CardWithPreview {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    title: "Опции"

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: [
                                { key: "make_backup",    label: "Сохранить оригинал (.bak)",  tip: "Создаёт копию перед конвертацией",     checked: true  },
                                { key: "check_plugins",  label: "Проверить плагины",          tip: "Сканирует список каналов и VST",       checked: true  },
                                { key: "keep_structure", label: "Сохранить структуру ZIP",    tip: "Сохраняет подпапки внутри архива",     checked: true  },
                                { key: "make_report",    label: "Создать отчёт (.txt)",       tip: "Пишет отчёт о конвертации рядом",       checked: false }
                            ]
                            delegate: RowLayout {
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "\uE946"
                                    color: Theme.textSecondary
                                    font.family: Theme.iconFamily
                                    font.pixelSize: 12
                                }
                                Text {
                                    text: modelData.label
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    Layout.fillWidth: true
                                    ToolTip.visible: hov.hovered
                                    ToolTip.delay: 300
                                    ToolTip.text: modelData.tip
                                    HoverHandler { id: hov }
                                }
                                ToggleSwitch {
                                    id: sw
                                    checked: modelData.checked
                                    property string optKey: modelData.key
                                    onToggled: (v) => page.options[optKey] = v
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }

                ConvertButton {
                    id: convertBtn
                    Layout.fillWidth: true
                    onClicked: page.startConversion()
                }
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: "Выберите FLP или ZIP"
        nameFilters: ["FL Studio / ZIP (*.flp *.zip)", "Все файлы (*)"]
        onAccepted: page.loadFile(selectedFile.toString())
    }

    Timer {
        id: successTimer
        interval: 2000
        onTriggered: convertBtn.success = false
    }

    Timer {
        id: failTimer
        interval: 800
        onTriggered: convertBtn.failed = false
    }

    function loadFile(pathOrUrl) {
        var info = backend.analyzeFile(pathOrUrl)
        if (!info.ok) return
        projectCard.fileName      = info.name
        projectCard.fileKind      = info.kind
        projectCard.fileSize      = info.size_mb
        projectCard.sourceVersion = info.version
        projectCard.samplesCount  = info.samples || 0
        projectCard.audioCount    = info.audio   || 0
        projectCard.otherCount    = info.other   || 0
        projectCard.hasData       = true
    }

    function startConversion() {
        convertBtn.busy = true
        convertBtn.progress = 0
        convertBtn.success = false
        convertBtn.failed = false
        backend.startConvert(page.options)
    }

    Connections {
        target: backend
        function onProgress(v) { convertBtn.progress = v }
        function onFinished(path) {
            convertBtn.busy = false
            convertBtn.success = true
            successTimer.start()
        }
        function onError(msg) {
            convertBtn.busy = false
            convertBtn.failed = true
            failTimer.start()
        }
        function onCancelled() {
            convertBtn.busy = false
            convertBtn.progress = 0
        }
    }
}