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
        "Конвертер", "Сэмплы", "Генератор MIDI", "Рандомная нарезка сэмплов", "Настройки", "О программе"
    ]

    Component.onCompleted: {
        // Применяем сохранённую тему при старте
        if (backend.savedTheme === "light") {
            Theme.applyLight()
        } else {
            Theme.applyDark()
        }
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
}