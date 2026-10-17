import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Nebula 1.0
import "../components"

Item {
    id: page
    property string outputDir: backend.savedOutputDir

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

    ScrollView {
        id: sv
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceXxl
        anchors.rightMargin: Theme.spaceXxl
        anchors.topMargin: Theme.spaceXl
        anchors.bottomMargin: Theme.spaceL
        clip: true

        ColumnLayout {
            width: sv.availableWidth
            spacing: Theme.spaceL

            PageHeader {
                Layout.fillWidth: true
                label: "NEBULATOOLS · SETTINGS"
                title: "Настройки"
                subtitle: "Внешний вид, папка вывода и поведение приложения."
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: col1.implicitHeight + Theme.spaceL * 2
                radius: Theme.radiusLarge
                color: Theme.surface
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    id: col1
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spaceL
                    spacing: Theme.spaceM

                    RowLayout {
                        spacing: Theme.spaceS
                        Rectangle { width: 4; height: 14; radius: 2; color: Theme.accent }
                        Text {
                            text: "Внешний вид"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontH3
                            font.weight: Font.DemiBold
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spaceM
                        Text {
                            text: "Тема"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            Layout.fillWidth: true
                        }
                        AppComboBox {
                            id: themeCombo
                            Layout.preferredWidth: 200
                            model: ["Тёмная", "Светлая"]
                            currentIndex: Theme.currentTheme === "dark" ? 0 : 1
                            onActivated: function(index) {
                                if (index === 0) { Theme.applyDark(); backend.setTheme("dark") }
                                else { Theme.applyLight(); backend.setTheme("light") }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: col2.implicitHeight + Theme.spaceL * 2
                radius: Theme.radiusLarge
                color: Theme.surface
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    id: col2
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spaceL
                    spacing: Theme.spaceM

                    RowLayout {
                        spacing: Theme.spaceS
                        Rectangle { width: 4; height: 14; radius: 2; color: Theme.accentCyan }
                        Text {
                            text: "Вывод файлов"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontH3
                            font.weight: Font.DemiBold
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spaceM
                        Text {
                            text: "Папка вывода"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            Layout.preferredWidth: 140
                        }
                        AppTextField {
                            id: outputField
                            Layout.fillWidth: true
                            text: page.outputDir
                            onEditingFinished: {
                                page.outputDir = text
                                backend.setOutputDir(text)
                            }
                        }
                        Rectangle {
                            width: 40; height: 40
                            radius: Theme.radiusSmall
                            color: pickHov.hovered ? Theme.surfaceHover : Theme.surfaceElevated
                            border.color: Theme.borderLight
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: "\uE8B7"
                                color: Theme.accent
                                font.family: Theme.iconFamily
                                font.pixelSize: 14
                            }
                            HoverHandler { id: pickHov; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: folderDialog.open() }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: col3.implicitHeight + Theme.spaceL * 2
                radius: Theme.radiusLarge
                color: Theme.surface
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    id: col3
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spaceL
                    spacing: Theme.spaceM

                    RowLayout {
                        spacing: Theme.spaceS
                        Rectangle { width: 4; height: 14; radius: 2; color: Theme.accent }
                        Text {
                            text: "Поведение"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontH3
                            font.weight: Font.DemiBold
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Открывать папку после конвертации"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            Layout.fillWidth: true
                        }
                        ToggleSwitch { checked: true }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Drag-and-drop файлов"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            Layout.fillWidth: true
                        }
                        ToggleSwitch { checked: true }
                    }
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignLeft
                width: 200; height: 40
                radius: Theme.radiusSmall
                color: rstHov.hovered ? Theme.surfaceHover : "transparent"
                border.color: Theme.borderLight
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "Сбросить настройки"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
                HoverHandler { id: rstHov; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: { backend.resetSettings(); Theme.applyDark() } }
            }

            Item { Layout.fillHeight: true; Layout.preferredHeight: 24 }
        }
    }

    FolderDialog {
        id: folderDialog
        title: "Выберите папку"
        onAccepted: {
            var p = selectedFolder.toString().replace("file:///", "")
            page.outputDir = p
            outputField.text = p
            backend.setOutputDir(p)
        }
    }
}