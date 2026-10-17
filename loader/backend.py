import sys
import os
import shutil
import subprocess
import time
import threading
import tarfile
import zipfile
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor

import requests
from PySide6.QtCore import QObject, Signal, Slot, QSettings, Property

GITHUB_REPO = "Missyrimm/NebulaTools"
APP_NAME = "NebulaTools"

# Папка установки для текущей ОС
if sys.platform == "win32":
    INSTALL_DIR = Path(os.environ.get("LOCALAPPDATA", Path.home())) / APP_NAME
elif sys.platform == "darwin":
    INSTALL_DIR = Path.home() / "Applications" / APP_NAME
else:
    INSTALL_DIR = Path.home() / ".local" / "share" / APP_NAME

ASSETS = {
    "win32":  f"{APP_NAME}-Windows.zip",
    "darwin": f"{APP_NAME}-macOS.zip",
    "linux":  f"{APP_NAME}-Linux.tar.gz",
}

VERSION_FILE = INSTALL_DIR / "version.txt"

def log(msg):
    print(f"[loader] {msg}", flush=True)

class LoaderBackend(QObject):
    checking = Signal()
    ready = Signal(str)               
    noInstall = Signal(str)           
    updateAvailable = Signal(str, str)
    downloadStarted = Signal(str)     
    downloadProgress = Signal(int, float)
    extracting = Signal()
    extractProgress = Signal(int)
    launched = Signal()
    errorOccurred = Signal(str)
    
    targetOsChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._remote_version = ""
        self._download_url = ""
        
        # Автоопределение текущей ОС
        if sys.platform.startswith("win"):
            self._target_os = "win32"
        elif sys.platform == "darwin":
            self._target_os = "darwin"
        else:
            self._target_os = "linux"

    @Property(str, notify=targetOsChanged)
    def targetOs(self):
        return self._target_os

    @Slot(str)
    def setTargetOs(self, os_key):
        if self._target_os != os_key:
            self._target_os = os_key
            self.targetOsChanged.emit()
            self.checkInstallation()  # Перепроверяем при смене ОС

    def _is_current_os(self):
        current = "win32" if sys.platform.startswith("win") else ("darwin" if sys.platform == "darwin" else "linux")
        return self._target_os == current

    @Slot()
    def checkInstallation(self):
        def _do():
            self.checking.emit()
            try:
                # 1. Локальная версия (только если выбрана текущая ОС)
                local = ""
                if self._is_current_os() and VERSION_FILE.exists():
                    try:
                        local = VERSION_FILE.read_text(encoding="utf-8").strip()
                    except Exception:
                        pass

                # 2. Remote версия
                r = requests.get(
                    f"https://api.github.com/repos/{GITHUB_REPO}/releases/latest",
                    timeout=10,
                )
                if r.status_code == 404:
                    self.errorOccurred.emit("Релизы ещё не опубликованы")
                    return
                r.raise_for_status()
                data = r.json()
                remote = data.get("tag_name", "").lstrip("v")

                if not remote:
                    self.errorOccurred.emit("Не удалось получить версию")
                    return

                self._remote_version = remote

                # URL ассета на основе выбранной ОС
                asset_name = ASSETS.get(self._target_os)
                for asset in data.get("assets", []):
                    if asset["name"] == asset_name:
                        self._download_url = asset["browser_download_url"]
                        break

                if not self._download_url:
                    self.errorOccurred.emit(f"Ассет {asset_name} не найден в релизе")
                    return

                # 3. Сравнение (если текущая ОС)
                if not self._is_current_os():
                    # Если выбрана другая ОС — просто предлагаем скачать
                    self.noInstall.emit(remote)
                elif not local:
                    self.noInstall.emit(remote)
                elif self._parse_version(local) >= self._parse_version(remote):
                    self.ready.emit(local)
                else:
                    self.updateAvailable.emit(local, remote)

            except Exception as e:
                log(f"Ошибка проверки: {e}")
                self.errorOccurred.emit(f"Ошибка: {e}")

        threading.Thread(target=_do, daemon=True).start()

    @Slot()
    def downloadAndInstall(self):
        def _do():
            try:
                if not self._download_url:
                    self.errorOccurred.emit("Нет URL для скачивания")
                    return

                is_cross = not self._is_current_os()
                base_dir = Path.home() / "Downloads" if is_cross else INSTALL_DIR
                folder_name = f"{APP_NAME}-{self._target_os}" if is_cross else "_update_tmp"
                
                tmp_dir = base_dir / folder_name
                
                # Очищаем папку перед скачиванием
                if tmp_dir.exists():
                    shutil.rmtree(tmp_dir)
                tmp_dir.mkdir(parents=True, exist_ok=True)

                archive = tmp_dir / "archive.bin"

                # 1. HEAD
                head = requests.head(self._download_url, allow_redirects=True, timeout=15)
                total_size = int(head.headers.get("content-length", 0))
                total_mb = total_size / 1024 / 1024 if total_size else 0
                self.downloadStarted.emit(f"{total_mb:.1f}")

                # 2. Скачивание
                if total_size > 1024 * 1024 and total_size < 500 * 1024 * 1024:
                    self._multithread_download(self._download_url, archive, total_size)
                else:
                    self._simple_download(self._download_url, archive)

                # 3. Распаковка
                self.extracting.emit()
                extract_dir = tmp_dir / "extracted"
                extract_dir.mkdir()
                self._extract(archive, extract_dir)

                if is_cross:
                    # Если это другая ОС — просто оставляем в Загрузках
                    self.extractProgress.emit(100)
                    if sys.platform == "win32":
                        subprocess.Popen(["explorer", str(tmp_dir)])
                    elif sys.platform == "darwin":
                        subprocess.Popen(["open", str(tmp_dir)])
                    else:
                        subprocess.Popen(["xdg-open", str(tmp_dir)])
                    
                    from PySide6.QtWidgets import QApplication
                    from PySide6.QtCore import QMetaObject, Qt
                    QMetaObject.invokeMethod(QApplication.instance(), "quit", Qt.QueuedConnection)
                    return

                # 4. Копируем в INSTALL_DIR (только для текущей ОС)
                INSTALL_DIR.mkdir(parents=True, exist_ok=True)
                total_files = sum(1 for _ in extract_dir.rglob("*") if _.is_file())
                done = 0
                for src_file in extract_dir.rglob("*"):
                    if src_file.is_file():
                        rel = src_file.relative_to(extract_dir)
                        dst = INSTALL_DIR / rel
                        dst.parent.mkdir(parents=True, exist_ok=True)
                        try:
                            shutil.copy2(src_file, dst)
                        except Exception as e:
                            log(f"Ошибка копирования {rel}: {e}")
                        done += 1
                        if total_files > 0:
                            self.extractProgress.emit(int(done * 100 / total_files))

                # 5. Запись версии
                VERSION_FILE.write_text(self._remote_version, encoding="utf-8")

                # 6. Чистка
                shutil.rmtree(tmp_dir, ignore_errors=True)

                # 7. Запуск
                self.launched.emit()
                time.sleep(0.5)
                self._launch_app()

                time.sleep(1.5)
                from PySide6.QtWidgets import QApplication
                from PySide6.QtCore import QMetaObject, Qt
                QMetaObject.invokeMethod(QApplication.instance(), "quit", Qt.QueuedConnection)

            except Exception as e:
                log(f"Ошибка установки: {e}")
                import traceback
                traceback.print_exc()
                self.errorOccurred.emit(str(e))

        threading.Thread(target=_do, daemon=True).start()

    @Slot()
    def launchApp(self):
        self._launch_app()
        time.sleep(0.3)
        from PySide6.QtWidgets import QApplication
        from PySide6.QtCore import QMetaObject, Qt
        QMetaObject.invokeMethod(QApplication.instance(), "quit", Qt.QueuedConnection)

    @Slot()
    def openInstallFolder(self):
        try:
            path_to_open = INSTALL_DIR if self._is_current_os() else Path.home() / "Downloads"
            if sys.platform == "win32":
                subprocess.Popen(["explorer", str(path_to_open)])
            elif sys.platform == "darwin":
                subprocess.Popen(["open", str(path_to_open)])
            else:
                subprocess.Popen(["xdg-open", str(path_to_open)])
        except Exception as e:
            log(f"openInstallFolder: {e}")

    def _parse_version(self, v):
        try:
            return tuple(int(x) for x in v.split("."))
        except Exception:
            return (0, 0, 0)

    def _multithread_download(self, url, dest, total_size):
        NUM_THREADS = 8
        chunk_size = total_size // NUM_THREADS + 1
        chunks = [(i * chunk_size, min((i + 1) * chunk_size - 1, total_size - 1))
                  for i in range(NUM_THREADS)]
        chunks = [(s, e) for s, e in chunks if s <= e]

        with open(dest, "wb") as f:
            f.truncate(total_size)

        progress_lock = threading.Lock()
        done = [0]
        start_time = time.time()

        def download_chunk(idx, start, end):
            headers = {"Range": f"bytes={start}-{end}"}
            for attempt in range(3):
                try:
                    r = requests.get(url, headers=headers, stream=True, timeout=180)
                    r.raise_for_status()
                    with open(dest, "r+b") as f:
                        f.seek(start)
                        for chunk in r.iter_content(65536):
                            if not chunk:
                                continue
                            f.write(chunk)
                            with progress_lock:
                                done[0] += len(chunk)
                                pct = int(done[0] * 100 / total_size)
                                elapsed = time.time() - start_time
                                speed = (done[0] / 1024 / 1024) / max(elapsed, 0.01)
                                self.downloadProgress.emit(pct, speed)
                    return
                except Exception as e:
                    log(f"chunk {idx} attempt {attempt + 1}: {e}")
                    time.sleep(1)
            raise RuntimeError(f"Не удалось скачать chunk {idx}")

        with ThreadPoolExecutor(max_workers=NUM_THREADS) as pool:
            futures = [pool.submit(download_chunk, i, s, e)
                       for i, (s, e) in enumerate(chunks)]
            for f in futures:
                f.result()

    def _simple_download(self, url, dest):
        r = requests.get(url, stream=True, timeout=180)
        r.raise_for_status()
        total = int(r.headers.get("content-length", 0))
        done = 0
        start = time.time()
        with open(dest, "wb") as f:
            for chunk in r.iter_content(65536):
                if not chunk:
                    continue
                f.write(chunk)
                done += len(chunk)
                if total:
                    pct = int(done * 100 / total)
                    elapsed = time.time() - start
                    speed = (done / 1024 / 1024) / max(elapsed, 0.01)
                    self.downloadProgress.emit(pct, speed)

    def _extract(self, archive, extract_dir):
        url = self._download_url
        if url.endswith(".zip"):
            with zipfile.ZipFile(archive, "r") as z:
                z.extractall(extract_dir)
        elif url.endswith(".7z"):
            import py7zr
            with py7zr.SevenZipFile(archive, "r") as z:
                z.extractall(extract_dir)
        elif url.endswith((".tar.gz", ".tgz")):
            with tarfile.open(archive, "r:gz") as t:
                t.extractall(extract_dir)

    def _launch_app(self):
        try:
            if sys.platform == "win32":
                exe = INSTALL_DIR / f"{APP_NAME}.exe"
                if not exe.exists():
                    self.errorOccurred.emit(f"Файл не найден: {exe}")
                    return
                subprocess.Popen([str(exe)], cwd=str(INSTALL_DIR),
                                 creationflags=subprocess.DETACHED_PROCESS | subprocess.CREATE_NEW_PROCESS_GROUP)
            elif sys.platform == "darwin":
                app = INSTALL_DIR / f"{APP_NAME}.app"
                subprocess.Popen(["open", str(app)])
            else:
                exe = INSTALL_DIR / APP_NAME
                if exe.exists():
                    exe.chmod(0o755)
                subprocess.Popen([str(exe)], cwd=str(INSTALL_DIR), start_new_session=True)
        except Exception as e:
            log(f"launch: {e}")
            self.errorOccurred.emit(f"Не удалось запустить: {e}")