import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "components"

Window {
    id: root
    width: 520
    height: 650 // Увеличили высоту из-за добавления ComboBox
    minimumWidth: 520
    minimumHeight: 650
    maximumWidth: 520
    maximumHeight: 650
    visible: true
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint
    title: "NebulaTools Setup"

    // Состояния: idle | checking | no_install | update_available | ready | download | extracting | launching | error
    property string state: "checking"
    property string localVersion: ""
    property string remoteVersion: ""
    property int progress: 0
    property string statusText: "Проверка обновлений..."
    property real downloadSpeed: 0
    property string downloadSize: ""

    Component.onCompleted: backend.checkInstallation()

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        radius: 22
        border.color: Theme.border
        border.width: 1
        clip: true

        BackgroundEffects { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            TitleBar {
                Layout.fillWidth: true
                onCloseClicked: root.close()
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            Item { Layout.fillHeight: true }

            // Центральная карточка
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 48
                Layout.rightMargin: 48
                spacing: 20 // Чуть уменьшили отступ

                // Логотип с кольцом
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    width: 160
                    height: 160

                    ProgressRing {
                        anchors.fill: parent
                        progress: root.progress
                        label: ""
                    }

                    // ИКОНКА ИЗ ПАПКИ ASSETS
                    Image {
                        anchors.centerIn: parent
                        source: "../assets/icons/logo.png"
                        sourceSize.width: 80
                        sourceSize.height: 80
                        fillMode: Image.PreserveAspectFit
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 180
                        height: 180
                        radius: 90
                        color: "transparent"
                        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
                        border.width: 1
                        visible: root.state === "download" || root.state === "extracting" || root.state === "checking"
                        SequentialAnimation on scale {
                            loops: Animation.Infinite
                            NumberAnimation { to: 1.1; duration: 1200; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 1200; easing.type: Easing.InOutSine }
                        }
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.2; duration: 1200; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 0.5; duration: 1200; easing.type: Easing.InOutSine }
                        }
                    }
                }

                // Название
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "NebulaTools"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 32
                    font.weight: Font.Bold
                    font.letterSpacing: -0.5
                }

                // ВЫБОР ОС
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10
                    
                    Text {
                        text: "ОС:"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                    }

                    ComboBox {
                        id: osCombo
                        width: 200
                        height: 36
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        
                        model: [
                            { key: "win32", name: "Windows" },
                            { key: "darwin", name: "macOS" },
                            { key: "linux", name: "Linux" }
                        ]
                        textRole: "name"
                        valueRole: "key"
                        
                        currentIndex: {
                            for (var i = 0; i < model.length; i++) {
                                if (model[i].key === backend.targetOs) return i;
                            }
                            return 0;
                        }

                        onActivated: {
                            backend.setTargetOs(currentValue)
                        }

                        background: Rectangle {
                            color: Theme.surface
                            border.color: Theme.border
                            border.width: 1
                            radius: Theme.radiusSmall
                        }

                        contentItem: Text {
                            leftPadding: 12
                            text: osCombo.displayText
                            color: Theme.textPrimary
                            font: osCombo.font
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        popup: Popup {
                            y: osCombo.height + 4
                            width: osCombo.width
                            padding: 4
                            background: Rectangle { color: Theme.surfaceHover; radius: 8; border.color: Theme.border }
                            contentItem: ListView {
                                clip: true
                                implicitHeight: contentHeight
                                model: osCombo.delegateModel
                            }
                        }
                        
                        delegate: ItemDelegate {
                            width: osCombo.width - 8
                            height: 32
                            contentItem: Text {
                                text: modelData.name
                                color: parent.highlighted ? Theme.accent : Theme.textPrimary
                                font: osCombo.font
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 8
                            }
                            background: Rectangle {
                                color: parent.hovered ? Theme.surface : "transparent"
                                radius: 4
                            }
                        }
                    }
                }

                // Версия
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        if (root.state === "ready") return "Версия " + root.localVersion
                        if (root.state === "update_available") return "Доступна " + root.remoteVersion
                        if (root.remoteVersion !== "") return "Версия " + root.remoteVersion
                        return "MUSIC PRODUCTION TOOLKIT"
                    }
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }

                Item { Layout.preferredHeight: 4 }

                // Прогресс-бар
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    radius: 3
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: 1
                    visible: root.state === "download" || root.state === "extracting"
                    clip: true

                    Rectangle {
                        width: parent.width * (root.progress / 100)
                        height: parent.height
                        radius: 3
                        color: Theme.accent
                        Behavior on width { NumberAnimation { duration: 150 } }
                    }
                }

                // Статус
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    text: root.statusText
                    color: root.state === "error" ? Theme.error
                         : (root.state === "ready" ? Theme.success : Theme.textSecondary)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    visible: root.statusText !== ""
                }

                // Скорость
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.downloadSpeed > 0
                        ? root.downloadSpeed.toFixed(1) + " МБ/с · " + root.downloadSize
                        : ""
                    color: Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontTiny
                    visible: root.state === "download" && root.downloadSpeed > 0
                }

                Item { Layout.preferredHeight: 8 }

                // Кнопка
                Rectangle {
                    id: actionBtn
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    radius: 12
                    color: {
                        if (root.state === "error") return Theme.error
                        if (root.state === "download" || root.state === "extracting" || root.state === "launching" || root.state === "checking")
                            return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
                        if (btnHover.hovered) return Theme.accentHover
                        return Theme.accent
                    }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 10
                        Text {
                            text: {
                                if (root.state === "checking") return "\uE895"
                                if (root.state === "ready") return "\uE768"
                                if (root.state === "no_install") return "\uE896"
                                if (root.state === "update_available") return "\uE896"
                                if (root.state === "download" || root.state === "extracting") return "\uE895"
                                if (root.state === "launching") return "\uE768"
                                if (root.state === "error") return "\uE783"
                                return "\uE768"
                            }
                            color: "#FFFFFF"
                            font.family: Theme.iconFamily
                            font.pixelSize: 16
                        }
                        Text {
                            text: {
                                var is_cross = backend.targetOs !== (Qt.platform.os === "windows" ? "win32" : (Qt.platform.os === "osx" ? "darwin" : "linux"));
                                
                                if (root.state === "checking") return "Проверка..."
                                if (root.state === "ready") return "Запустить NebulaTools"
                                if (root.state === "no_install" || root.state === "update_available") {
                                    if (is_cross) return "Скачать для " + osCombo.currentText;
                                    return (root.state === "update_available") ? "Обновить до " + root.remoteVersion : "Установить";
                                }
                                if (root.state === "download") return "Скачивание " + root.progress + "%"
                                if (root.state === "extracting") return "Распаковка " + root.progress + "%"
                                if (root.state === "launching") return "Запуск..."
                                if (root.state === "error") return "Попробовать снова"
                                return "Установить"
                            }
                            color: "#FFFFFF"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontH3
                            font.weight: Font.DemiBold
                        }
                    }

                    HoverHandler { id: btnHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.onAction() }
                }

                // Кнопка "Открыть папку"
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Открыть папку установки"
                    color: Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    visible: root.state === "ready"
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: backend.openInstallFolder() }
                }
            }

            Item { Layout.fillHeight: true }

            // Соцфутер
            Rectangle {
                Layout.fillWidth: true
                height: 44
                color: "transparent"

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "by"
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }
                    Text {
                        text: "@youngweepo"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.weight: Font.DemiBold
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: Qt.openUrlExternally("https://t.me/youngweepo") }
                    }
                    Rectangle {
                        width: 4; height: 4; radius: 2
                        color: Theme.textTertiary
                    }
                    Text {
                        text: "@nebulatools"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.weight: Font.DemiBold
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: Qt.openUrlExternally("https://t.me/nebulatools") }
                    }
                }
            }
        }

        // Resize handles
        component EdgeHandle: MouseArea {
            property int edges: 0
            onPressed: root.startSystemResize(edges)
        }
        EdgeHandle { edges: Qt.LeftEdge; anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 4; cursorShape: Qt.SizeHorCursor }
        EdgeHandle { edges: Qt.RightEdge; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 4; cursorShape: Qt.SizeHorCursor }
        EdgeHandle { edges: Qt.TopEdge; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: 4; cursorShape: Qt.SizeVerCursor }
        EdgeHandle { edges: Qt.BottomEdge; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 4; cursorShape: Qt.SizeVerCursor }
    }

    function onAction() {
        if (root.state === "ready") {
            backend.launchApp()
        } else if (root.state === "no_install" || root.state === "update_available" || root.state === "error") {
            backend.downloadAndInstall()
        }
    }

    // Обработка сигналов от backend
    Connections {
        target: backend

        function onChecking() {
            root.state = "checking"
            root.statusText = "Проверка обновлений..."
            root.progress = 0
        }

        function onReady(localVer) {
            root.state = "ready"
            root.localVersion = localVer
            root.remoteVersion = localVer
            root.progress = 100
            root.statusText = "Готово к запуску"
        }

        function onNoInstall(remoteVer) {
            root.state = "no_install"
            root.remoteVersion = remoteVer
            root.progress = 0
            
            var is_cross = backend.targetOs !== (Qt.platform.os === "windows" ? "win32" : (Qt.platform.os === "osx" ? "darwin" : "linux"));
            if (is_cross) {
                root.statusText = "Будет скачана версия для " + osCombo.currentText + " (в папку Загрузки)."
            } else {
                root.statusText = "NebulaTools не установлен. Нажми Установить."
            }
        }

        function onUpdateAvailable(localVer, remoteVer) {
            root.state = "update_available"
            root.localVersion = localVer
            root.remoteVersion = remoteVer
            root.progress = 0
            root.statusText = "Доступна новая версия: " + remoteVer
        }

        function onDownloadStarted(totalMB) {
            root.state = "download"
            root.downloadSize = totalMB + " МБ"
            root.progress = 0
            root.statusText = "Скачивание..."
        }

        function onDownloadProgress(p, speed) {
            root.progress = p
            root.downloadSpeed = speed
        }

        function onExtracting() {
            root.state = "extracting"
            root.progress = 0
            root.statusText = "Распаковка..."
        }

        function onExtractProgress(p) {
            root.progress = p
        }

        function onLaunched() {
            root.state = "launching"
            root.statusText = "Запуск..."
        }

        function onErrorOccurred(msg) {
            root.state = "error"
            root.statusText = msg
            root.progress = 0
        }
    }
}