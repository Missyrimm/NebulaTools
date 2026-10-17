"""
Updater NebulaTools — многопоточная загрузка + 7z распаковка.
"""
import sys
import os
import shutil
import subprocess
import zipfile
import tarfile
import threading
import time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor

try:
    import requests
except ImportError:
    requests = None


GITHUB_REPO = "Missyrimm/NebulaTools"
CURRENT_VERSION = "2.7.0"
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
        if r.status_code == 404:
            log("Релизов ещё нет на GitHub")
            return False, None, None
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

        log(f"Ассет {asset_name} не найден в релизе")
        return False, None, latest
    except Exception as e:
        log(f"Ошибка проверки: {e}")
        return False, None, None


def _extract(archive, url, tmp_dir, progress_callback=None):
    """Распаковка архива с прогрессом."""
    extract_dir = tmp_dir / "extracted"
    extract_dir.mkdir(exist_ok=True)
    log(f"Распаковка → {extract_dir}")

    if progress_callback:
        progress_callback(90)

    try:
        if url.endswith(".zip"):
            import zipfile
            with zipfile.ZipFile(archive, "r") as z:
                z.extractall(extract_dir)
        elif url.endswith(".7z"):
            import py7zr
            with py7zr.SevenZipFile(archive, "r") as z:
                z.extractall(extract_dir)
        else:
            import tarfile
            with tarfile.open(archive, "r:gz") as t:
                # filter='data' добавлен в Python 3.11.4+, для старых версий игнорируем
                try:
                    t.extractall(extract_dir, filter='data')
                except TypeError:
                    t.extractall(extract_dir)
    except Exception as e:
        log(f"Ошибка распаковки: {e}")
        raise

    if progress_callback:
        progress_callback(100)

    archive.unlink()
    return extract_dir


def download_update(url, progress_callback=None):
    """Многопоточная загрузка (8 потоков) + распаковка."""
    tmp_dir = Path.home() / f".{APP_NAME}_update"
    if tmp_dir.exists():
        shutil.rmtree(tmp_dir)
    tmp_dir.mkdir(parents=True)

    archive = tmp_dir / "update_archive"

    # HEAD — узнаём размер
    try:
        head = requests.head(url, allow_redirects=True, timeout=15)
        total_size = int(head.headers.get("content-length", 0))
    except Exception as e:
        log(f"HEAD failed: {e}, fallback")
        total_size = 0

    log(f"Скачиваю: {url}")
    log(f"Размер: {total_size / 1024 / 1024:.1f} МБ")

    if total_size == 0 or total_size < 1024 * 1024:
        # Fallback на однопоточную
        r = requests.get(url, stream=True, timeout=180)
        r.raise_for_status()
        done = 0
        with open(archive, "wb") as f:
            for chunk in r.iter_content(65536):
                if chunk:
                    f.write(chunk)
                    done += len(chunk)
                    if progress_callback and total_size > 0:
                        pct = int(done * 100 / total_size)
                        progress_callback(min(99, pct))
    else:
        # Многопоточная загрузка
        NUM_THREADS = 8
        chunk_size = total_size // NUM_THREADS + 1
        chunks = [(i * chunk_size, min((i + 1) * chunk_size - 1, total_size - 1))
                  for i in range(NUM_THREADS)]
        chunks = [(s, e) for s, e in chunks if s <= e]

        with open(archive, "wb") as f:
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
                    with open(archive, "r+b") as f:
                        f.seek(start)
                        for chunk in r.iter_content(65536):
                            if not chunk:
                                continue
                            f.write(chunk)
                            with progress_lock:
                                done[0] += len(chunk)
                                if progress_callback and total_size > 0:
                                    pct = int(done[0] * 100 / total_size)
                                    progress_callback(min(99, pct))
                    return
                except Exception as e:
                    log(f"  чанк {idx} попытка {attempt + 1}: {e}")
                    time.sleep(1)
            raise RuntimeError(f"Не удалось скачать чанк {idx}")

        with ThreadPoolExecutor(max_workers=NUM_THREADS) as pool:
            futures = [pool.submit(download_chunk, i, s, e)
                       for i, (s, e) in enumerate(chunks)]
            for f in futures:
                f.result()

        elapsed = time.time() - start_time
        speed = total_size / elapsed / 1024 / 1024 if elapsed > 0 else 0
        log(f"Скачано {total_size / 1024 / 1024:.1f} МБ за {elapsed:.1f}с "
            f"({speed:.1f} МБ/с)")

    # После загрузки — распаковка с прогрессом 70-100%
    def unpack_progress(p):
        if progress_callback:
            progress_callback(70 + int(p * 0.3))

    return _extract(archive, url, tmp_dir, progress_callback=unpack_progress)


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