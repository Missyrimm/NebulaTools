import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Nebula 1.0
import "components"
import "pages"

Window {
    id: root
    width: 1280
    height: 800
    minimumWidth: 1024
    minimumHeight: 640
    visible: true
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint
    title: "NebulaTools — " + pageNames[sidebar.currentIndex]

    readonly property var pageNames: [
        "Конвертер", "Сэмплы", "Генератор MIDI",
        "Рандомная нарезка сэмплов", "Настройки", "О программе"
    ]

    Component.onCompleted: {
        // Применяем сохранённую тему
        if (backend.savedTheme === "light") {
            Theme.applyLight()
        } else {
            Theme.applyDark()
        }
        // Проверка обновлений через 2 секунды
        checkUpdatesTimer.start()
    }

    Timer {
        id: checkUpdatesTimer
        interval: 2000
        onTriggered: backend.checkUpdates()
    }

    Rectangle {
        id: windowRoot
        anchors.fill: parent
        color: Theme.bg
        radius: Theme.radiusLarge
        border.color: Theme.border
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            TitleBar {
                id: titleBar
                Layout.fillWidth: true
                sectionName: pageNames[sidebar.currentIndex]
                onMinimizeClicked: root.showMinimized()
                onMaximizeClicked: root.visibility === Window.Maximized
                    ? root.showNormal() : root.showMaximized()
                onCloseClicked: root.close()
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            // ============ БАННЕР ОБНОВЛЕНИЯ ============
            Rectangle {
                id: updateBanner
                Layout.fillWidth: true
                height: visible ? 52 : 0
                color: Qt.rgba(1.0, 0.478, 0.102, 0.15)
                border.color: Theme.accent
                border.width: 1
                visible: false
                clip: true

                Behavior on height {
                    NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
                }

                property string versionText: ""
                property int downloadProgress: 0
                property bool installing: false

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spaceL
                    anchors.rightMargin: Theme.spaceM
                    spacing: Theme.spaceM

                    Text {
                        text: "🎉"
                        font.pixelSize: 20
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: updateBanner.installing
                                ? "Загрузка обновления " + updateBanner.versionText + "…"
                                : "Доступна новая версия " + updateBanner.versionText
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: updateBanner.installing
                                ? updateBanner.downloadProgress + "%"
                                : "Рекомендуем обновиться для новых функций"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                        }
                    }

                    Rectangle {
                        width: 120
                        height: 36
                        radius: Theme.radiusSmall
                        visible: !updateBanner.installing
                        color: updBtn.pressed ? Theme.accentHover : Theme.accent

                        Text {
                            anchors.centerIn: parent
                            text: "Обновить"
                            color: "#FFFFFF"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            font.weight: Font.DemiBold
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            id: updBtn
                            onTapped: {
                                updateBanner.installing = true
                                backend.installUpdate()
                            }
                        }
                    }

                    Rectangle {
                        width: 90
                        height: 36
                        radius: Theme.radiusSmall
                        visible: !updateBanner.installing
                        color: "transparent"
                        border.color: Theme.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Позже"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: updateBanner.visible = false }
                    }

                    Rectangle {
                        visible: updateBanner.installing
                        width: 200
                        height: 8
                        radius: 4
                        color: Theme.surfaceHover

                        Rectangle {
                            width: parent.width * (updateBanner.downloadProgress / 100.0)
                            height: parent.height
                            radius: 4
                            color: Theme.accent
                            Behavior on width { NumberAnimation { duration: 200 } }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Sidebar {
                    id: sidebar
                    Layout.fillHeight: true
                }

                Item {
                    id: pageHost
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ConverterPage {
                        anchors.fill: parent
                        visible: sidebar.currentIndex === 0
                    }

                    SamplesPage {
                        anchors.fill: parent
                        visible: sidebar.currentIndex === 1
                    }

                    MelodyPage {
                        anchors.fill: parent
                        visible: sidebar.currentIndex === 2
                    }

                    BeatmakerPage {
                        anchors.fill: parent
                        visible: sidebar.currentIndex === 3
                    }

                    SettingsPage {
                        anchors.fill: parent
                        visible: sidebar.currentIndex === 4
                    }

                    AboutPage {
                        anchors.fill: parent
                        visible: sidebar.currentIndex === 5
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            StatusBar {
                id: statusBar
                Layout.fillWidth: true
            }
        }

        component EdgeHandle: MouseArea {
            property int edges: 0
            onPressed: root.startSystemResize(edges)
        }

        EdgeHandle { edges: Qt.LeftEdge;   anchors.left: parent.left;   anchors.top: parent.top; anchors.bottom: parent.bottom; width: 4; cursorShape: Qt.SizeHorCursor }
        EdgeHandle { edges: Qt.RightEdge;  anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 4; cursorShape: Qt.SizeHorCursor }
        EdgeHandle { edges: Qt.TopEdge;    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: 4; cursorShape: Qt.SizeVerCursor }
        EdgeHandle { edges: Qt.BottomEdge; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 4; cursorShape: Qt.SizeVerCursor }
    }

    Connections {
        target: backend

        function onUpdateAvailable(version, url) {
            updateBanner.versionText = version
            updateBanner.visible = true
        }

        function onUpdateProgress(p) {
            updateBanner.downloadProgress = p
        }

        function onUpdateInstalling() {
            updateBanner.installing = true
        }
    }
}