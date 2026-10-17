pragma Singleton
import QtQuick

QtObject {
    // Цвета (изменяются через applyDark/applyLight)
    property color bg: "#0B0B0D"
    property color surface: "#141417"
    property color surfaceHover: "#1C1C21"
    property color border: "#222226"
    property color textPrimary: "#F2F2F3"
    property color textSecondary: "#7C7C85"

    // Акценты не меняются
    readonly property color accentStart: "#FF7A1A"
    readonly property color accentEnd: "#FF4D00"
    readonly property color accent: "#FF7A1A"
    readonly property color accentHover: "#FF9040"
    readonly property color accentGlow: Qt.rgba(1.0, 0.478, 0.102, 0.25)
    readonly property color success: "#3DDC84"
    readonly property color error: "#FF5252"

    // Радиусы
    readonly property int radiusSmall: 8
    readonly property int radius: 14
    readonly property int radiusLarge: 20

    // Отступы
    readonly property int spaceXs: 4
    readonly property int spaceS: 8
    readonly property int spaceM: 16
    readonly property int spaceL: 24
    readonly property int spaceXl: 32

    // Шрифты
    readonly property string fontFamily: "Segoe UI"
    readonly property string iconFamily: "Segoe Fluent Icons"
    readonly property int fontH1: 26
    readonly property int fontH2: 18
    readonly property int fontH3: 14
    readonly property int fontBody: 13
    readonly property int fontSmall: 11
    readonly property int fontIcon: 16

    // Анимации
    readonly property int animFast: 150
    readonly property int animNormal: 220
    readonly property int animSlow: 280

    // Текущая тема
    property string currentTheme: "dark"

    function applyDark() {
        bg = "#0B0B0D"
        surface = "#141417"
        surfaceHover = "#1C1C21"
        border = "#222226"
        textPrimary = "#F2F2F3"
        textSecondary = "#7C7C85"
        currentTheme = "dark"
    }

    function applyLight() {
        bg = "#F4F4F7"
        surface = "#FFFFFF"
        surfaceHover = "#EAEAEF"
        border = "#DCDCE3"
        textPrimary = "#14141A"
        textSecondary = "#5A5A66"
        currentTheme = "light"
    }

    function toggle() {
        if (currentTheme === "dark") applyLight()
        else applyDark()
    }
}