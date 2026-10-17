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
        if (backend.savedTheme === "light") {
            Theme.applyLight()
        } else {
            Theme.applyDark()
        }
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

        // ============ ОСНОВНОЙ КОНТЕНТ ============
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

                    ConverterPage { anchors.fill: parent; visible: sidebar.currentIndex === 0 }
                    SamplesPage { anchors.fill: parent; visible: sidebar.currentIndex === 1 }
                    MelodyPage { anchors.fill: parent; visible: sidebar.currentIndex === 2 }
                    BeatmakerPage { anchors.fill: parent; visible: sidebar.currentIndex === 3 }
                    SettingsPage { anchors.fill: parent; visible: sidebar.currentIndex === 4 }
                    AboutPage { anchors.fill: parent; visible: sidebar.currentIndex === 5 }
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

        // ============ БАННЕР ОБНОВЛЕНИЯ (OVERLAY ПОВЕРХ ВСЕГО) ============
        Rectangle {
            id: updateBanner
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 44         // высота TitleBar
            anchors.leftMargin: 1
            anchors.rightMargin: 1

            height: visible ? 56 : 0
            opacity: visible ? 1 : 0
            visible: false
            z: 9999
            clip: true

            color: Qt.rgba(0.08, 0.08, 0.10, 0.98)
            border.color: Theme.accent
            border.width: 1

            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            property string versionText: ""
            property int downloadProgress: 0
            property bool installing: false

            // Оранжевая полоска сверху для акцента
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 2
                color: Theme.accent
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spaceL
                anchors.rightMargin: Theme.spaceL
                anchors.topMargin: 4
                anchors.bottomMargin: 4
                spacing: Theme.spaceM

                Text {
                    text: "🎉"
                    font.pixelSize: 22
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
                            ? "Скачано " + updateBanner.downloadProgress + "%. Приложение перезапустится автоматически."
                            : "Рекомендуем обновиться для получения новых функций"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }
                }

                // Прогресс-бар во время установки
                Rectangle {
                    visible: updateBanner.installing
                    width: 180
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

                // Кнопка "Обновить"
                Rectangle {
                    width: 110
                    height: 34
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

                // Кнопка "Позже"
                Rectangle {
                    width: 80
                    height: 34
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
                    TapHandler {
                        onTapped: {
                            updateBanner.visible = false
                        }
                    }
                }
            }
        }

        // Resize handles
        component EdgeHandle: MouseArea {
            property int edges: 0
            onPressed: root.startSystemResize(edges)
        }

        EdgeHandle { edges: Qt.LeftEdge;   anchors.left: parent.left;   anchors.top: parent.top; anchors.bottom: parent.bottom; width: 4; cursorShape: Qt.SizeHorCursor; z: 10000 }
        EdgeHandle { edges: Qt.RightEdge;  anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 4; cursorShape: Qt.SizeHorCursor; z: 10000 }
        EdgeHandle { edges: Qt.TopEdge;    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: 4; cursorShape: Qt.SizeVerCursor; z: 10000 }
        EdgeHandle { edges: Qt.BottomEdge; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 4; cursorShape: Qt.SizeVerCursor; z: 10000 }
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