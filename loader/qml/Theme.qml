pragma Singleton
import QtQuick

QtObject {
    property color bg: "#08090F"
    property color surface: "#13141D"
    property color surfaceHover: "#1B1C28"
    property color border: "#262838"
    property color borderLight: "#31334A"

    property color textPrimary: "#F2F1F8"
    property color textSecondary: "#8B8D9B"
    property color textTertiary: "#5A5C6E"

    readonly property color accent: "#A78BFA"
    readonly property color accentHover: "#B9A2FF"
    readonly property color accentGlow: Qt.rgba(0.65, 0.54, 0.98, 0.35)
    readonly property color success: "#4ADE80"
    readonly property color error: "#F87171"
    readonly property color warning: "#FBBF24"

    readonly property int radiusSmall: 8
    readonly property int radius: 12
    readonly property int radiusLarge: 16
    readonly property int radiusXl: 22

    readonly property int spaceS: 8
    readonly property int spaceM: 16
    readonly property int spaceL: 24
    readonly property int spaceXl: 32

    readonly property string fontFamily: "Segoe UI"
    readonly property string iconFamily: "Segoe Fluent Icons"
    readonly property int fontH1: 28
    readonly property int fontH2: 20
    readonly property int fontH3: 14
    readonly property int fontBody: 13
    readonly property int fontSmall: 11
    readonly property int fontTiny: 10

    readonly property int animFast: 150
    readonly property int animNormal: 250
}