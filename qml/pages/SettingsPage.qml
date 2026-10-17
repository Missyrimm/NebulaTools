import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Nebula 1.0
import "../components"

Item {
    id: page
    property string outputDir: "C:\\Users\\Public\\Desktop"

    ScrollView {
        id: sv
        anchors.fill: parent
        anchors.margins: Theme.spaceL
        clip: true

        ColumnLayout {
            width: sv.availableWidth
            spacing: Theme.spaceL

            Text {
                text: "Настройки"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontH1
                font.weight: Font.Bold
            }

            Text {
                text: "Внешний вид и поведение конвертера"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: col1.implicitHeight + Theme.spaceL * 2
                radius: Theme.radius
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

                    Text {
                        text: "Внешний вид"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontH3
                        font.weight: Font.DemiBold
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
                                if (index === 0) {
                                    Theme.applyDark()
                                    backend.setTheme("dark")
                                } else {
                                    Theme.applyLight()
                                    backend.setTheme("light")
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: col2.implicitHeight + Theme.spaceL * 2
                radius: Theme.radius
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

                    Text {
                        text: "Вывод файлов"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontH3
                        font.weight: Font.DemiBold
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
                            text: backend.savedOutputDir
                            onEditingFinished: {
                                page.outputDir = text
                                backend.setOutputDir(text)
                            }
                        }

                        Rectangle {
                            width: 40; height: 40
                            radius: Theme.radiusSmall
                            color: pickHov.hovered ? Theme.accentHover : Theme.surfaceHover
                            border.color: Theme.border
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

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
                radius: Theme.radius
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

                    Text {
                        text: "Поведение"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontH3
                        font.weight: Font.DemiBold
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

            Item { Layout.fillHeight: true }
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