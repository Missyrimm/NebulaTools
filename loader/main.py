import sys
from pathlib import Path

from PySide6.QtCore import Qt, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterSingletonType
from PySide6.QtQuickControls2 import QQuickStyle

from backend import LoaderBackend


def main():
    QQuickStyle.setStyle("Basic")
    QGuiApplication.setHighDpiScaleFactorRoundingPolicy(
        Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
    )

    app = QGuiApplication(sys.argv)
    app.setApplicationName("NebulaTools Setup")

    qml_dir = Path(__file__).parent / "qml"

    qmlRegisterSingletonType(
        QUrl.fromLocalFile(str(qml_dir / "Theme.qml")),
        "Nebula", 1, 0, "Theme"
    )

    engine = QQmlApplicationEngine()

    backend = LoaderBackend()
    engine.rootContext().setContextProperty("backend", backend)

    engine.addImportPath(str(qml_dir))
    engine.load(QUrl.fromLocalFile(str(qml_dir / "Main.qml")))

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()