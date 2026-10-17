"""
Updater NebulaTools — проверка и установка обновлений с GitHub Releases.
Запускается отдельным процессом из main.py.
"""
import sys
import os
import shutil
import subprocess
import zipfile
import tarfile
from pathlib import Path

import requests


# ============================================================
#  НАСТРОЙКИ — ЗАМЕНИ "Missyrimm/NebulaTools" на свой репозиторий
# ============================================================
GITHUB_REPO = "youngweepo/NebulaTools"
CURRENT_VERSION = "2.6.0"     # должна совпадать с APP_VERSION в backend.py
APP_NAME = "NebulaTools"

ASSETS = {
    "win32":  f"{APP_NAME}-Windows.zip",
    "darwin": f"{APP_NAME}-macOS.zip",
    "linux":  f"{APP_NAME}-Linux.tar.gz",
}


def log(msg):
    print(f"[updater] {msg}", flush=True)


def parse_version(v):
    """'2.6.0' -> (2, 6, 0), чтобы корректно сравнить."""
    try:
        parts = v.lstrip("v").split(".")
        return tuple(int(x) for x in parts)
    except Exception:
        return (0, 0, 0)


def get_platform_key():
    if sys.platform.startswith("win"):
        return "win32"
    elif sys.platform == "darwin":
        return "darwin"
    else:
        return "linux"


def check_for_updates():
    """Возвращает (has_update, download_url, new_version)."""
    api_url = f"https://api.github.com/repos/{GITHUB_REPO}/releases/latest"
    log(f"Проверяю: {api_url}")

    try:
        r = requests.get(api_url, timeout=10)
        r.raise_for_status()
        data = r.json()

        latest_version = data.get("tag_name", "0.0.0").lstrip("v")
        log(f"Текущая: {CURRENT_VERSION}, последняя на GitHub: {latest_version}")

        if parse_version(latest_version) <= parse_version(CURRENT_VERSION):
            log("Обновлений нет")
            return False, None, latest_version

        platform_key = get_platform_key()
        asset_name = ASSETS.get(platform_key)
        log(f"Ищу ассет: {asset_name}")

        for asset in data.get("assets", []):
            if asset["name"] == asset_name:
                log(f"Найдено обновление: {latest_version}")
                return True, asset["browser_download_url"], latest_version

        log(f"⚠ Ассет '{asset_name}' не найден в релизе")
        return False, None, latest_version

    except Exception as e:
        log(f"Ошибка проверки: {e}")
        return False, None, None


def download_update(url):
    """Скачивает и распаковывает архив обновления."""
    tmp_dir = Path.home() / f".{APP_NAME}_update"
    if tmp_dir.exists():
        shutil.rmtree(tmp_dir)
    tmp_dir.mkdir(parents=True)

    archive_path = tmp_dir / "update_archive"
    log(f"Скачиваю: {url}")

    r = requests.get(url, stream=True, timeout=120)
    r.raise_for_status()
    total = int(r.headers.get("content-length", 0))
    downloaded = 0

    with open(archive_path, "wb") as f:
        for chunk in r.iter_content(chunk_size=65536):
            if chunk:
                f.write(chunk)
                downloaded += len(chunk)
                if total > 0:
                    pct = int(downloaded * 100 / total)
                    print(f"\r[updater] Загрузка: {pct}%", end="", flush=True)

    print()  # newline после прогресса

    extract_dir = tmp_dir / "extracted"
    extract_dir.mkdir()

    log(f"Распаковываю в: {extract_dir}")
    if url.endswith(".zip"):
        with zipfile.ZipFile(archive_path, "r") as z:
            z.extractall(extract_dir)
    elif url.endswith((".tar.gz", ".tgz")):
        with tarfile.open(archive_path, "r:gz") as t:
            t.extractall(extract_dir)

    archive_path.unlink()
    return extract_dir


def run_update_script(extract_dir):
    """Запускает платформо-зависимый скрипт замены файлов."""
    app_dir = Path(sys.executable if getattr(sys, "frozen", False) else __file__).parent.resolve()

    if sys.platform == "win32":
        script = extract_dir / "update.bat"
        if not script.exists():
            log(f"⚠ Не найден {script}")
            return
        # Передаём путь к папке приложения через переменную
        env = os.environ.copy()
        env["NT_APP_DIR"] = str(app_dir)
        env["NT_EXTRACT_DIR"] = str(extract_dir)
        subprocess.Popen(
            ["cmd.exe", "/c", str(script)],
            env=env,
            creationflags=subprocess.CREATE_NEW_CONSOLE,
        )
    else:
        script = extract_dir / "update.sh"
        if not script.exists():
            log(f"⚠ Не найден {script}")
            return
        env = os.environ.copy()
        env["NT_APP_DIR"] = str(app_dir)
        env["NT_EXTRACT_DIR"] = str(extract_dir)
        subprocess.Popen(
            ["bash", str(script)],
            env=env,
            start_new_session=True,
        )


if __name__ == "__main__":
    # Если запущен с флагом --check-only — только проверить (для тестов)
    check_only = "--check-only" in sys.argv

    has_update, url, new_ver = check_for_updates()

    if not has_update:
        log("Обновления не требуются")
        sys.exit(0)

    if check_only:
        log(f"Доступно обновление до {new_ver}: {url}")
        sys.exit(0)

    log(f"Скачиваю обновление {new_ver}...")
    extract_dir = download_update(url)
    log("Запускаю установку...")
    run_update_script(extract_dir)
    log("Готово, приложение будет перезапущено")