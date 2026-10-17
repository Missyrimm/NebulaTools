"""
Updater NebulaTools — модуль проверки и установки обновлений.
Импортируется из backend.py для показа баннера в GUI.
"""
import sys
import os
import shutil
import subprocess
import zipfile
import tarfile
from pathlib import Path

try:
    import requests
except ImportError:
    requests = None


GITHUB_REPO = "Missyrimm/NebulaTools"
CURRENT_VERSION = "2.5.0"
APP_NAME = "NebulaTools"

ASSETS = {
    "win32":  f"{APP_NAME}-Windows.zip",
    "darwin": f"{APP_NAME}-macOS.zip",
    "linux":  f"{APP_NAME}-Linux.tar.gz",
}


def log(msg):
    print(f"[updater] {msg}", flush=True)


def _parse_version(v):
    try:
        return tuple(int(x) for x in v.lstrip("v").split("."))
    except Exception:
        return (0, 0, 0)


def _platform_key():
    if sys.platform.startswith("win"):
        return "win32"
    elif sys.platform == "darwin":
        return "darwin"
    return "linux"


def check_for_updates():
    """Возвращает (has_update, download_url, new_version)."""
    if requests is None:
        log("requests не установлен")
        return False, None, None

    try:
        r = requests.get(
            f"https://api.github.com/repos/{GITHUB_REPO}/releases/latest",
            timeout=10,
        )
        r.raise_for_status()
        data = r.json()

        latest = data.get("tag_name", "0.0.0").lstrip("v")
        log(f"Текущая: {CURRENT_VERSION}, доступна: {latest}")

        if _parse_version(latest) <= _parse_version(CURRENT_VERSION):
            return False, None, latest

        asset_name = ASSETS.get(_platform_key())
        for asset in data.get("assets", []):
            if asset["name"] == asset_name:
                return True, asset["browser_download_url"], latest

        return False, None, latest
    except Exception as e:
        log(f"Ошибка проверки: {e}")
        return False, None, None


def download_update(url, progress_callback=None):
    """Скачивает и распаковывает. Возвращает путь к extract_dir."""
    tmp_dir = Path.home() / f".{APP_NAME}_update"
    if tmp_dir.exists():
        shutil.rmtree(tmp_dir)
    tmp_dir.mkdir(parents=True)

    archive = tmp_dir / "update_archive"
    log(f"Скачиваю: {url}")

    r = requests.get(url, stream=True, timeout=120)
    r.raise_for_status()
    total = int(r.headers.get("content-length", 0))
    got = 0

    with open(archive, "wb") as f:
        for chunk in r.iter_content(chunk_size=65536):
            if not chunk:
                continue
            f.write(chunk)
            got += len(chunk)
            if total and progress_callback:
                progress_callback(int(got * 100 / total))

    extract_dir = tmp_dir / "extracted"
    extract_dir.mkdir()

    log(f"Распаковка → {extract_dir}")
    if url.endswith(".zip"):
        with zipfile.ZipFile(archive, "r") as z:
            z.extractall(extract_dir)
    else:
        with tarfile.open(archive, "r:gz") as t:
            t.extractall(extract_dir)

    archive.unlink()
    return extract_dir


def run_update_script(extract_dir):
    """Запускает update.bat / update.sh в отдельном процессе."""
    if getattr(sys, "frozen", False):
        app_dir = Path(sys.executable).parent.resolve()
    else:
        app_dir = Path(__file__).parent.resolve()

    env = os.environ.copy()
    env["NT_APP_DIR"] = str(app_dir)
    env["NT_EXTRACT_DIR"] = str(extract_dir)

    if sys.platform == "win32":
        script = extract_dir / "update.bat"
        if not script.exists():
            raise FileNotFoundError(f"Нет {script}")
        subprocess.Popen(
            ["cmd.exe", "/c", str(script)],
            env=env,
            creationflags=subprocess.CREATE_NEW_CONSOLE,
        )
    else:
        script = extract_dir / "update.sh"
        if not script.exists():
            raise FileNotFoundError(f"Нет {script}")
        subprocess.Popen(
            ["bash", str(script)],
            env=env,
            start_new_session=True,
        )


if __name__ == "__main__":
    has, url, ver = check_for_updates()
    if has:
        print(f"Доступно обновление: {ver}")
        print(f"URL: {url}")
    else:
        print("Обновлений нет")