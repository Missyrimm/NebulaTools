pragma Singleton
import QtQuick

QtObject {
    // База
    property color bg: "#08090F"
    property color bgSecondary: "#0D0E16"
    property color surface: "#13141D"
    property color surfaceHover: "#1B1C28"
    property color surfaceElevated: "#1E2030"
    property color border: "#262838"
    property color borderLight: "#31334A"

    // Текст
    property color textPrimary: "#F2F1F8"
    property color textSecondary: "#8B8D9B"
    property color textTertiary: "#5A5C6E"

    // Акценты
    readonly property color accent: "#A78BFA"
    readonly property color accentHover: "#B9A2FF"
    readonly property color accentGlow: Qt.rgba(0.65, 0.54, 0.98, 0.15)
    readonly property color accentCyan: "#5CE1E6"
    readonly property color accentCyanHover: "#7BE8EC"
    readonly property color accentOrange: "#FF7A1A"
    readonly property color accentOrangeHover: "#FF9040"

    // Алиасы для обратной совместимости (используются в ConvertButton и других старых компонентах)
    readonly property color accentStart: "#A78BFA"
    readonly property color accentEnd: "#5CE1E6"

    readonly property color success: "#4ADE80"
    readonly property color error: "#F87171"
    readonly property color warning: "#FBBF24"

    // Радиусы
    readonly property int radiusXs: 6
    readonly property int radiusSmall: 8
    readonly property int radius: 12
    readonly property int radiusLarge: 16
    readonly property int radiusXl: 22

    // Отступы
    readonly property int spaceXs: 4
    readonly property int spaceS: 8
    readonly property int spaceM: 16
    readonly property int spaceL: 24
    readonly property int spaceXl: 32
    readonly property int spaceXxl: 48

    // Шрифты
    readonly property string fontFamily: "Segoe UI"
    readonly property string iconFamily: "Segoe Fluent Icons"
    readonly property int fontDisplay: 42
    readonly property int fontH1: 28
    readonly property int fontH2: 20
    readonly property int fontH3: 14
    readonly property int fontBody: 13
    readonly property int fontSmall: 11
    readonly property int fontTiny: 10

    // Анимации
    readonly property int animFast: 150
    readonly property int animNormal: 250
    readonly property int animSlow: 380
    readonly property int animDrift: 7000

    // Тема
    property string currentTheme: "dark"

    function applyDark() {
        bg = "#08090F"
        bgSecondary = "#0D0E16"
        surface = "#13141D"
        surfaceHover = "#1B1C28"
        surfaceElevated = "#1E2030"
        border = "#262838"
        borderLight = "#31334A"
        textPrimary = "#F2F1F8"
        textSecondary = "#8B8D9B"
        textTertiary = "#5A5C6E"
        currentTheme = "dark"
    }

    function applyLight() {
        bg = "#F4F4F7"
        bgSecondary = "#ECECF2"
        surface = "#FFFFFF"
        surfaceHover = "#F2F2F8"
        surfaceElevated = "#FFFFFF"
        border = "#DCDCE3"
        borderLight = "#C8C8D4"
        textPrimary = "#14141A"
        textSecondary = "#5A5A66"
        textTertiary = "#8A8A96"
        currentTheme = "light"
    }

    function toggle() {
        if (currentTheme === "dark") applyLight()
        else applyDark()
    }
}