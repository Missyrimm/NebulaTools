import sys
from pathlib import Path

from PySide6.QtCore import Qt, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterSingletonType
from PySide6.QtQuickControls2 import QQuickStyle

from backend import ConverterBackend


def main():
    # Basic-стиль убирает QML-предупреждения про customization
    QQuickStyle.setStyle("Basic")

    QGuiApplication.setHighDpiScaleFactorRoundingPolicy(
        Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
    )

    app = QGuiApplication(sys.argv)
    app.setApplicationName("NebulaTools")
    app.setOrganizationName("NebulaTools")

    qml_dir = Path(__file__).parent / "qml"

    qmlRegisterSingletonType(
        QUrl.fromLocalFile(str(qml_dir / "Theme.qml")),
        "Nebula", 1, 0, "Theme"
    )

    engine = QQmlApplicationEngine()

    backend = ConverterBackend()
    engine.rootContext().setContextProperty("backend", backend)

    engine.addImportPath(str(qml_dir))

    engine.load(QUrl.fromLocalFile(str(qml_dir / "Main.qml")))

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())


def check_updates_on_startup():
    """Запускает updater.py в фоне. Не блокирует приложение."""
    import subprocess
    from pathlib import Path

    updater = Path(__file__).parent / "updater.py"
    if not updater.exists():
        return

    try:
        # В фоне, чтобы не задерживать запуск
        kwargs = {"creationflags": subprocess.CREATE_NO_WINDOW} if sys.platform == "win32" else {}
        subprocess.Popen([sys.executable, str(updater)], **kwargs)
    except Exception as e:
        print(f"[main] Не удалось запустить updater: {e}")


if __name__ == "__main__":
    main()