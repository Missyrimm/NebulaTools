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

    property bool forceClose: false

    readonly property var pageNames: [
        "Главная", "FLP Converter", "Сэмплы", "Генератор MIDI",
        "Рандомная нарезка", "BPM & Key Finder", "Разделение стемов", "Настройки", "О программе"
    ]

    onClosing: function(close) {
        if (typeof updateBanner !== "undefined" && updateBanner.installing && !forceClose) {
            close.accepted = false
            closeWarningDialog.open()
        }
    }

    Component.onCompleted: {
        if (backend.savedTheme === "light") Theme.applyLight()
        else Theme.applyDark()
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
        color: "transparent" // ФИКС: Делаем прозрачным
        radius: Theme.radiusXl
        border.color: Theme.border
        border.width: 1
        clip: true

        // ФИКС: Непрозрачный фон вынесен назад
        Rectangle {
            anchors.fill: parent
            color: Theme.bg
            radius: Theme.radiusXl
            z: -5
        }

        // ФИКС: Эффекты теперь видны поверх фона
        CursorGlow { id: cursorGlow; z: -2 }
        StarField { id: starField; z: -1 }

        ColumnLayout {
            z: 1 // Контент всегда поверх эффектов
            anchors.fill: parent
            spacing: 0

            TitleBar {
                id: titleBar
                Layout.fillWidth: true
                sectionName: pageNames[sidebar.currentIndex]
                onMinimizeClicked: root.showMinimized()
                onMaximizeClicked: root.visibility === Window.Maximized ? root.showNormal() : root.showMaximized()
                onCloseClicked: root.close()
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

            // Глобальный индикатор занятости
            Rectangle {
                id: busyBar
                Layout.fillWidth: true
                height: backend.isBusy ? 3 : 0
                color: "transparent"
                clip: true

                Behavior on height { NumberAnimation { duration: 150 } }

                Rectangle {
                    width: parent.width * 0.3
                    height: parent.height
                    radius: 1.5
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.5; color: Theme.accent }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    x: -width

                    SequentialAnimation on x {
                        running: backend.isBusy
                        loops: Animation.Infinite
                        NumberAnimation { from: -parent.width * 0.3; to: parent.width; duration: 1200; easing.type: Easing.InOutQuad }
                        PauseAnimation { duration: 200 }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

            Rectangle {
                id: updateBanner
                Layout.fillWidth: true
                height: visible ? 56 : 0
                color: Qt.rgba(0.08, 0.08, 0.10, 0.98)
                border.color: Theme.accent
                border.width: 1
                visible: false
                clip: true
                z: 9998

                Behavior on height { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }

                property string versionText: ""
                property int downloadProgress: 0
                property bool installing: false

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spaceL
                    anchors.rightMargin: Theme.spaceM
                    spacing: Theme.spaceM

                    Text { text: "🎉"; font.pixelSize: 20; Layout.alignment: Qt.AlignVCenter }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: updateBanner.installing ? "Загрузка обновления " + updateBanner.versionText + "…" : "Доступна новая версия " + updateBanner.versionText
                            color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontBody; font.weight: Font.DemiBold
                        }
                        Text {
                            text: updateBanner.installing ? "Скачано " + updateBanner.downloadProgress + "%. Приложение перезапустится." : "Рекомендуем обновиться для новых функций"
                            color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall
                        }
                    }

                    Rectangle {
                        visible: updateBanner.installing
                        width: 180; height: 8; radius: 4; color: Theme.surfaceHover
                        Rectangle {
                            width: parent.width * (updateBanner.downloadProgress / 100.0)
                            height: parent.height; radius: 4; color: Theme.accent
                            Behavior on width { NumberAnimation { duration: 200 } }
                        }
                    }

                    Rectangle {
                        width: 110; height: 34; radius: Theme.radiusSmall
                        visible: !updateBanner.installing
                        color: updBtn.pressed ? Theme.accentHover : Theme.accent
                        Text { anchors.centerIn: parent; text: "Обновить"; color: "#FFFFFF"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall; font.weight: Font.DemiBold }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler { id: updBtn; onTapped: { updateBanner.installing = true; backend.installUpdate() } }
                    }

                    Rectangle {
                        width: 80; height: 34; radius: Theme.radiusSmall
                        visible: !updateBanner.installing
                        color: "transparent"; border.color: Theme.border; border.width: 1
                        Text { anchors.centerIn: parent; text: "Позже"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: updateBanner.visible = false }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

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

                    HomePage { anchors.fill: parent; visible: sidebar.currentIndex === 0 }
                    ConverterPage { anchors.fill: parent; visible: sidebar.currentIndex === 1 }
                    SamplesPage { anchors.fill: parent; visible: sidebar.currentIndex === 2 }
                    MelodyPage { anchors.fill: parent; visible: sidebar.currentIndex === 3 }
                    BeatmakerPage { anchors.fill: parent; visible: sidebar.currentIndex === 4 }
                    BpmKeyPage { anchors.fill: parent; visible: sidebar.currentIndex === 5 }
                    StemsPage { anchors.fill: parent; visible: sidebar.currentIndex === 6 }
                    SettingsPage { anchors.fill: parent; visible: sidebar.currentIndex === 7 }
                    AboutPage { anchors.fill: parent; visible: sidebar.currentIndex === 8 }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

            StatusBar {
                id: statusBar
                Layout.fillWidth: true
            }
        }

        component EdgeHandle: MouseArea {
            property int edges: 0
            onPressed: root.startSystemResize(edges)
        }
        EdgeHandle { edges: Qt.LeftEdge; anchors.left: windowRoot.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 4; cursorShape: Qt.SizeHorCursor; z: 10000 }
        EdgeHandle { edges: Qt.RightEdge; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 4; cursorShape: Qt.SizeHorCursor; z: 10000 }
        EdgeHandle { edges: Qt.TopEdge; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: 4; cursorShape: Qt.SizeVerCursor; z: 10000 }
        EdgeHandle { edges: Qt.BottomEdge; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 4; cursorShape: Qt.SizeVerCursor; z: 10000 }
    }

    Dialog {
        id: closeWarningDialog
        title: "Идёт загрузка обновления"
        modal: true
        anchors.centerIn: parent
        width: 400

        background: Rectangle { color: Theme.surfaceElevated; radius: Theme.radius; border.color: Theme.border; border.width: 1 }

        contentItem: ColumnLayout {
            spacing: Theme.spaceM
            Text {
                Layout.fillWidth: true
                text: "Сейчас скачивается обновление. Если закрыть приложение — загрузка прервётся."
                color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontBody; wrapMode: Text.WordWrap
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight; spacing: Theme.spaceS
                Rectangle {
                    width: 120; height: 36; radius: Theme.radiusSmall; color: "transparent"; border.color: Theme.border; border.width: 1
                    Text { anchors.centerIn: parent; text: "Подождать"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: closeWarningDialog.close() }
                }
                Rectangle {
                    width: 140; height: 36; radius: Theme.radiusSmall; color: Theme.error
                    Text { anchors.centerIn: parent; text: "Всё равно закрыть"; color: "#FFFFFF"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSmall; font.weight: Font.DemiBold }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: { root.forceClose = true; root.close() } }
                }
            }
        }
    }

    Connections {
        target: backend
        function onUpdateAvailable(version, url) { updateBanner.versionText = version; updateBanner.visible = true }
        function onUpdateProgress(p) { updateBanner.downloadProgress = p }
        function onUpdateInstalling() { updateBanner.installing = true }
    }
}