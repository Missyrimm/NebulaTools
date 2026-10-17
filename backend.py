"""
Backend NebulaTools — мост QML ↔ Python.
"""
import re
import sys
import tempfile
import zipfile
import threading
from pathlib import Path

from PySide6.QtCore import QObject, Signal, Slot, Property, QThread, QUrl, QSettings

APP_NAME = "NebulaTools"
APP_VERSION = "2.7.0"
AUTHOR_HANDLE = "@youngweepo"
AUTHOR_URL = "https://t.me/youngweepo"
CHANNEL_HANDLE = "@nebulatools"
CHANNEL_URL = "https://t.me/nebulatools"

def log(msg):
    print(f"[backend] {msg}", flush=True)

class StreamRedirector:
    """Перехватывает stdout/stderr, ищет проценты и отправляет их в QML."""
    def __init__(self, original_stream, backend):
        self.original_stream = original_stream
        self.backend = backend

    def write(self, text):
        if self.original_stream:
            self.original_stream.write(text)
        # Ищем "19%" или "40%|"
        match = re.search(r'(\d{1,3})%', text)
        if match:
            pct = int(match.group(1))
            if 0 <= pct <= 100:
                self.backend.stemsProgressPercent.emit(pct)

    def flush(self):
        if self.original_stream:
            self.original_stream.flush()

class ConvertWorker(QThread):
    progress = Signal(int)
    finished = Signal(str)
    error = Signal(str)

    def __init__(self, src, dst, target_version, options):
        super().__init__()
        self.src = str(src)
        self.dst = str(dst)
        self.target_version = target_version
        self.options = dict(options)
        self._cancel = False

    def cancel(self):
        self._cancel = True

    def run(self):
        try:
            src = Path(self.src)
            dst = Path(self.dst)
            if not src.exists():
                raise FileNotFoundError(f"Файл не найден: {src}")
            dst.parent.mkdir(parents=True, exist_ok=True)
            self.progress.emit(2)
            if self.options.get("make_backup", True):
                bak = src.with_suffix(src.suffix + ".bak")
                if not bak.exists():
                    bak.write_bytes(src.read_bytes())
            if self._cancel:
                self.error.emit("Отменено пользователем")
                return
            ext = src.suffix.lower()
            if ext == ".zip":
                self._convert_zip(src, dst)
            elif ext == ".flp":
                self._convert_single_flp(src, dst)
            else:
                raise ValueError(f"Неподдерживаемый формат: {ext}")
            
            self.progress.emit(100)
            self.finished.emit(str(dst))
        except Exception as e:
            log(f"Ошибка конвертации: {e}")
            self.error.emit(str(e))

    def _convert_single_flp(self, src, dst):
        try:
            from flp_native import convert_native, is_version_supported
            if is_version_supported(self.target_version):
                convert_native(str(src), self.target_version, str(dst),
                    progress_callback=lambda p: self.progress.emit(p))
                if dst.exists() and dst.stat().st_size > 0:
                    return
                raise RuntimeError("Native создал пустой файл")
        except Exception as e:
            log(f"✗ native упал: {e}")
        from flp_core import convert_flp_file
        self.progress.emit(30)
        convert_flp_file(str(src), str(dst), self.target_version)
        self.progress.emit(90)

    def _convert_zip(self, src, dst):
        def _extract(tmp_path):
            last_err = None
            for enc in ["cp866", "cp1251", None, "utf-8"]:
                try:
                    if enc is None:
                        zf = zipfile.ZipFile(src, "r")
                    else:
                        zf = zipfile.ZipFile(src, "r", metadata_encoding=enc)
                    with zf:
                        flp_names = [n for n in zf.namelist() if n.lower().endswith(".flp")]
                        if not flp_names:
                            continue
                        for member in zf.infolist():
                            target = tmp_path / member.filename
                            try:
                                target.parent.mkdir(parents=True, exist_ok=True)
                                with zf.open(member) as src_f:
                                    target.write_bytes(src_f.read())
                            except Exception:
                                pass
                        if list(tmp_path.rglob("*.flp")):
                            return
                except Exception as e:
                    last_err = e
                    continue
            raise RuntimeError(f"Не удалось распаковать ZIP: {last_err}")

        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            self.progress.emit(5)
            _extract(tmp_path)
            flps = list(tmp_path.rglob("*.flp"))
            if not flps:
                raise ValueError("В архиве нет .flp-файла")
            total = len(flps)
            for i, flp in enumerate(flps):
                if self._cancel:
                    self.error.emit("Отменено")
                    return
                temp_out = flp.with_suffix(".flp.conv")
                lo = 10 + (i * 75) // total
                hi = 10 + ((i + 1) * 75) // total
                success = False
                try:
                    from flp_native import convert_native, is_version_supported
                    if is_version_supported(self.target_version):
                        convert_native(str(flp), self.target_version, str(temp_out),
                            progress_callback=lambda p, _lo=lo, _hi=hi: self.progress.emit(
                                min(85, _lo + int((_hi - _lo) * p / 100))))
                        if temp_out.exists() and temp_out.stat().st_size > 0:
                            success = True
                except Exception as e:
                    log(f"✗ native {flp.name}: {e}")
                if not success:
                    from flp_core import convert_flp_file
                    convert_flp_file(str(flp), str(temp_out), self.target_version)
                    if temp_out.exists() and temp_out.stat().st_size > 0:
                        success = True
                if not success:
                    raise RuntimeError(f"Не удалось конвертировать {flp.name}")
                flp.unlink()
                temp_out.rename(flp)
            self.progress.emit(90)
            with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as z:
                for f in tmp_path.rglob("*"):
                    if f.is_file():
                        z.write(f, f.relative_to(tmp_path))
            self.progress.emit(95)

class ConverterBackend(QObject):
    fileAnalyzed = Signal(str, str, int)
    progress = Signal(int)
    finished = Signal(str)
    error = Signal(str)
    cancelled = Signal()

    themeChanged = Signal()
    targetVersionChanged = Signal()
    outputDirChanged = Signal()

    updateAvailable = Signal(str, str)
    updateProgress = Signal(int)
    updateInstalling = Signal()

    previewReady = Signal(str)
    previewError = Signal(str, str)

    busyChanged = Signal()
    stemsProgress = Signal(str)
    stemsProgressPercent = Signal(int)
    bpmProgress = Signal(str)

    samplesReady = Signal("QVariantList")
    samplesError = Signal(str)
    sampleDownloaded = Signal("QVariantMap")
    sampleDownloadError = Signal(str)

    melodyGenerated = Signal("QVariantMap")
    melodyError = Signal(str)

    beatGenerated = Signal("QVariantMap")
    beatError = Signal(str)

    audioAnalyzed = Signal("QVariantMap")
    audioAnalyzeError = Signal(str)

    bpmKeyAnalyzed = Signal("QVariantMap")
    bpmKeyError = Signal(str)

    stemsSeparated = Signal("QVariantMap")
    stemsError = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._settings = QSettings("NebulaTools", "FLPConverter")
        self._file_path = ""
        self._target_version = self._settings.value("target_version", "24.1.0.4225", type=str)
        self._output_dir = self._settings.value("output_dir", str(Path.home() / "Desktop"), type=str)
        self._theme = self._settings.value("theme", "dark", type=str)
        self._worker = None
        self._preview_token = 0
        self._preview_lock = threading.Lock()
        self._busy = False
        self._update_version = ""
        self._update_url = ""

    @Property(bool, notify=busyChanged)
    def isBusy(self):
        return self._busy

    def _set_busy(self, value):
        if self._busy != value:
            self._busy = value
            self.busyChanged.emit()

    @Property(str, constant=True)
    def appVersion(self): return APP_VERSION

    @Property(str, constant=True)
    def authorHandle(self): return AUTHOR_HANDLE

    @Property(str, constant=True)
    def authorUrl(self): return AUTHOR_URL

    @Property(str, constant=True)
    def channelName(self): return CHANNEL_HANDLE

    @Property(str, constant=True)
    def channelUrl(self): return CHANNEL_URL

    @Property(str, notify=themeChanged)
    def savedTheme(self): return self._theme

    @Property(str, notify=targetVersionChanged)
    def savedTargetVersion(self): return self._target_version

    @Property(str, notify=outputDirChanged)
    def savedOutputDir(self): return self._output_dir

    @Slot(str)
    def setTheme(self, theme):
        if theme not in ("dark", "light"): return
        self._theme = theme
        self._settings.setValue("theme", theme)
        self._settings.sync()
        self.themeChanged.emit()

    @Slot(str)
    def setTargetVersion(self, version):
        self._target_version = version
        self._settings.setValue("target_version", version)
        self._settings.sync()
        self.targetVersionChanged.emit()

    @Slot(str)
    def setOutputDir(self, dir_path):
        self._output_dir = dir_path
        self._settings.setValue("output_dir", dir_path)
        self._settings.sync()
        self.outputDirChanged.emit()

    @Slot()
    def resetSettings(self):
        self._settings.clear()
        self._settings.sync()
        self._target_version = "24.1.0.4225"
        self._output_dir = str(Path.home() / "Desktop")
        self._theme = "dark"
        self.themeChanged.emit()
        self.targetVersionChanged.emit()
        self.outputDirChanged.emit()

    @Slot(str, result="QVariantMap")
    def analyzeFile(self, path_or_url):
        url = QUrl(path_or_url)
        path = url.toLocalFile() if url.isLocalFile() else path_or_url
        p = Path(path)
        if not p.exists():
            return {"ok": False, "error": "Файл не найден"}
        ext = p.suffix.lower()
        if ext not in (".flp", ".zip"):
            return {"ok": False, "error": "Только .flp или .zip"}
        size_mb = p.stat().st_size / (1024 * 1024)
        version = self._read_version(p)
        info = {
            "ok": True, "name": p.name, "path": str(p),
            "size_mb": round(size_mb, 1), "version": version,
            "kind": "zip" if ext == ".zip" else "flp",
        }
        if ext == ".zip":
            info.update(self._inspect_zip(p))
        else:
            info.update({"samples": 0, "audio": 0, "other": 0})
        self._file_path = str(p)
        self.fileAnalyzed.emit(info["name"], version, int(size_mb))
        return info

    @Slot("QVariantMap")
    def startConvert(self, options):
        if not self._file_path:
            self.error.emit("Файл не выбран")
            return
        if self._worker and self._worker.isRunning():
            self.error.emit("Конвертация уже идёт")
            return
        src = Path(self._file_path)
        out_dir = Path(self._output_dir)
        out_dir.mkdir(parents=True, exist_ok=True)
        ext = src.suffix.lower()
        suffix = "_converted.flp" if ext == ".flp" else "_converted.zip"
        dst = out_dir / f"{src.stem}{suffix}"
        self._set_busy(True)
        self._worker = ConvertWorker(str(src), str(dst), self._target_version, dict(options))
        self._worker.progress.connect(self.progress.emit)
        self._worker.finished.connect(self._on_finished)
        self._worker.error.connect(self._on_error)
        self._worker.start()

    @Slot()
    def cancel(self):
        if self._worker and self._worker.isRunning():
            self._worker.cancel()

    @Slot()
    def openOutputFolder(self):
        import subprocess, os
        try:
            if os.name == "nt":
                subprocess.Popen(["explorer", self._output_dir])
            elif sys.platform == "darwin":
                subprocess.Popen(["open", self._output_dir])
            else:
                subprocess.Popen(["xdg-open", self._output_dir])
        except Exception:
            pass

    @Slot(str, int)
    def searchSamples(self, query, limit=20):
        def _do():
            try:
                from nebula_modules import freesound_module as fs
                raw = fs.search_samples(query, limit=limit * 2, min_duration=0.5, max_duration=30.0)
                seen_ids = set()
                result = []
                for s in raw:
                    if s["id"] in seen_ids:
                        continue
                    seen_ids.add(s["id"])
                    lic = s["license"]
                    lic_short = lic.rstrip("/").split("/")[-1] if "/" in lic else lic
                    result.append({
                        "id": s["id"], "name": s["name"], "duration": round(s["duration"], 2),
                        "license": lic_short, "username": s.get("username", ""), "preview_url": s["preview_url"],
                    })
                    if len(result) >= limit:
                        break
                self.samplesReady.emit(result)
            except Exception as e:
                self.samplesError.emit(str(e))
        threading.Thread(target=_do, daemon=True).start()

    @Slot(str, str)
    def downloadSampleTo(self, url, target_path):
        def _do():
            try:
                import urllib.request
                target = target_path.replace("file:///", "").replace("file://", "")
                out_path = Path(target)
                out_path.parent.mkdir(parents=True, exist_ok=True)
                urllib.request.urlretrieve(url, str(out_path))
                self.sampleDownloaded.emit({"ok": True, "path": str(out_path)})
            except Exception as e:
                self.sampleDownloadError.emit(str(e))
        threading.Thread(target=_do, daemon=True).start()

    @Slot(str, str, result="QVariantMap")
    def previewSample(self, url, name):
        try:
            dest = Path(tempfile.gettempdir()) / "NebulaTools" / "preview"
            dest.mkdir(parents=True, exist_ok=True)
            safe_name = "".join(c for c in name[:40] if c.isalnum() or c in " -_") or "sample"
            out_path = dest / f"{safe_name}.mp3"
            with self._preview_lock:
                self._preview_token += 1
                token = self._preview_token
            def _worker():
                try:
                    if not out_path.exists():
                        import requests
                        tmp_path = out_path.with_suffix(".part")
                        r = requests.get(url, timeout=30, stream=True)
                        r.raise_for_status()
                        with open(tmp_path, "wb") as f:
                            for chunk in r.iter_content(65536):
                                if chunk: f.write(chunk)
                        with self._preview_lock:
                            if token != self._preview_token:
                                tmp_path.unlink(missing_ok=True)
                                return
                        tmp_path.rename(out_path)
                    with self._preview_lock:
                        if token != self._preview_token: return
                    from nebula_modules import player
                    player.play(out_path)
                    self.previewReady.emit(url)
                except Exception as e:
                    self.previewError.emit(url, str(e))
            threading.Thread(target=_worker, daemon=True).start()
            return {"ok": True}
        except Exception as e:
            return {"ok": False, "error": str(e)}

    @Slot()
    def stopPreview(self):
        with self._preview_lock:
            self._preview_token += 1
        try:
            from nebula_modules import player
            player.stop()
        except Exception:
            pass

    @Slot(str, str, str, int, int, str)
    def generateMelodyTo(self, key, scale, genre, bars, bpm, target_path):
        def _do():
            self._set_busy(True)
            try:
                from nebula_modules import melody_module as mel
                target = target_path.replace("file:///", "").replace("file://", "")
                out_path = Path(target)
                out_path.parent.mkdir(parents=True, exist_ok=True)
                if out_path.suffix.lower() not in (".mid", ".midi"):
                    out_path = out_path.with_suffix(".mid")
                mel.generate_melody(key=key, scale=scale, genre=genre, bars=int(bars), bpm=int(bpm), output=str(out_path))
                self.melodyGenerated.emit({"ok": True, "path": str(out_path)})
            except Exception as e:
                self.melodyError.emit(str(e))
            finally:
                self._set_busy(False)
        threading.Thread(target=_do, daemon=True).start()

    @Slot(str, int, int, str)
    def generateBeatTo(self, audio_path, bars, bpm, target_path):
        def _do():
            self._set_busy(True)
            try:
                from nebula_modules import beatmaker_module as bm
                src = audio_path.replace("file:///", "").replace("file://", "")
                if not Path(src).exists():
                    self.beatError.emit(f"Файл не найден: {src}")
                    return
                target = target_path.replace("file:///", "").replace("file://", "")
                out_path = Path(target)
                out_path.parent.mkdir(parents=True, exist_ok=True)
                if out_path.suffix.lower() != ".wav":
                    out_path = out_path.with_suffix(".wav")
                result_path = bm.shuffle_beat(src, divisions=4, repeats=2, output_path=str(out_path))
                self.beatGenerated.emit({"ok": True, "path": str(result_path)})
            except Exception as e:
                self.beatError.emit(str(e))
            finally:
                self._set_busy(False)
        threading.Thread(target=_do, daemon=True).start()

    @Slot(str)
    def analyzeAudio(self, audio_path):
        def _do():
            self._set_busy(True)
            self.bpmProgress.emit("Анализ BPM и тональности...")
            try:
                from nebula_modules import beatmaker_module as bm
                src = audio_path.replace("file:///", "").replace("file://", "")
                if not Path(src).exists():
                    self.audioAnalyzeError.emit(f"Файл не найден: {src}")
                    return
                bpm = bm.detect_bpm(src)
                key, mode, conf = bm.detect_key(src)
                self.audioAnalyzed.emit({
                    "ok": True,
                    "bpm": round(bpm, 1),
                    "key": f"{key} {mode}",
                    "confidence": round(conf, 2),
                })
            except Exception as e:
                self.audioAnalyzeError.emit(str(e))
            finally:
                self._set_busy(False)
                self.bpmProgress.emit("")
        threading.Thread(target=_do, daemon=True).start()

    @Slot(str)
    def analyzeBpmKey(self, audio_path):
        def _do():
            self._set_busy(True)
            self.bpmProgress.emit("Извлечение параметров...")
            try:
                src = audio_path.replace("file:///", "").replace("file://", "")
                p = Path(src)
                if not p.exists():
                    self.bpmKeyError.emit(f"Файл не найден: {src}")
                    return
                from nebula_modules import beatmaker_module as bm
                self.bpmProgress.emit("Анализ BPM (3 метода)...")
                bpm = bm.detect_bpm(src)
                self.bpmProgress.emit("Анализ тональности (ensemble)...")
                key, mode, conf = bm.detect_key(src)
                self.bpmProgress.emit("Расчёт Camelot...")
                camelot = bm.key_to_camelot(key, mode)
                self.bpmKeyAnalyzed.emit({
                    "ok": True,
                    "bpm": round(bpm, 1),
                    "key": f"{key} {mode}",
                    "camelot": camelot,
                    "confidence": round(conf, 2),
                    "source": "Ансамбль Krumhansl + Temperley",
                })
            except Exception as e:
                self.bpmKeyError.emit(str(e))
            finally:
                self._set_busy(False)
                self.bpmProgress.emit("")
        threading.Thread(target=_do, daemon=True).start()

    @Slot(str)
    def analyzeBpmKeyAPI(self, audio_path):
        def _do():
            self._set_busy(True)
            self.bpmProgress.emit("Распознавание трека через Songfinder...")
            try:
                from songfinderdev import SongFinder, SongFinderError
                src = audio_path.replace("file:///", "").replace("file://", "")
                p = Path(src)
                if not p.exists():
                    self.bpmKeyError.emit(f"Файл не найден: {src}")
                    return

                sf = SongFinder()
                track = sf.identify_file(src)
                if not track:
                    self.bpmKeyError.emit("Songfinder не смог распознать трек.")
                    return

                title = track.get('title', 'Unknown')
                artist = track.get('artist', 'Unknown')
                isrc = track.get("isrc")
                
                bpm_val = 0.0
                key_val = "Unknown"
                camelot_val = ""
                source_text = f"Songfinder API — {title} by {artist}"

                if isrc:
                    try:
                        detail = sf.detail(isrc)
                        features = detail.get("features", {})
                        bpm_val = features.get("tempo", 0.0)
                        key_info = features.get("key", {})
                        key_val = key_info.get("name", "Unknown")
                        camelot_val = key_info.get("camelot", "")
                    except Exception:
                        pass
                
                # Если API не дал BPM, делаем локальный анализ
                if bpm_val == 0.0:
                    self.bpmProgress.emit("API не дал BPM. Считаю локально...")
                    from nebula_modules import beatmaker_module as bm
                    bpm_val = bm.detect_bpm(src)
                    key, mode, conf = bm.detect_key(src)
                    key_val = f"{key} {mode}"
                    camelot_val = bm.key_to_camelot(key, mode)
                    source_text += " (BPM локально)"

                self.bpmKeyAnalyzed.emit({
                    "ok": True,
                    "bpm": round(float(bpm_val), 1),
                    "key": key_val,
                    "camelot": camelot_val,
                    "confidence": 1.0,
                    "source": source_text
                })
            except Exception as e:
                self.bpmKeyError.emit(f"Ошибка API: {str(e)}")
            finally:
                self._set_busy(False)
                self.bpmProgress.emit("")
        threading.Thread(target=_do, daemon=True).start()

    @Slot(str, str, str, str)
    def separateStems(self, audio_path, output_dir, model, output_format="wav"):
        def _do():
            self._set_busy(True)
            self.stemsProgress.emit("Подготовка...")
            self.stemsProgressPercent.emit(0)
            
            old_stdout = sys.stdout
            old_stderr = sys.stderr
            sys.stdout = StreamRedirector(old_stdout, self)
            sys.stderr = StreamRedirector(old_stderr, self)

            try:
                from nebula_modules import stem_separator as ss
                src = audio_path.replace("file:///", "").replace("file://", "")
                if not Path(src).exists():
                    self.stemsError.emit(f"Файл не найден: {src}")
                    return
                out = output_dir.replace("file:///", "").replace("file://", "")
                out_path = Path(out)
                out_path.mkdir(parents=True, exist_ok=True)

                def cb(msg):
                    self.stemsProgress.emit(msg)

                stems = ss.separate_stems(src, str(out_path), model, output_format, progress_callback=cb)
                self.stemsProgress.emit("Готово")
                self.stemsProgressPercent.emit(100)
                self.stemsSeparated.emit({"ok": True, "stems": stems})
            except Exception as e:
                import traceback
                traceback.print_exc()
                self.stemsError.emit(str(e))
            finally:
                sys.stdout = old_stdout
                sys.stderr = old_stderr
                self._set_busy(False)
        threading.Thread(target=_do, daemon=True).start()

    @Slot()
    def checkUpdates(self):
        def _check():
            try:
                if getattr(sys, "frozen", False): app_dir = Path(sys.executable).parent
                else: app_dir = Path(__file__).parent
                if str(app_dir) not in sys.path: sys.path.insert(0, str(app_dir))
                import importlib
                import updater as upd
                importlib.reload(upd)
                has, url, ver = upd.check_for_updates()
                if has:
                    self._update_version = ver
                    self._update_url = url
                    self.updateAvailable.emit(ver, url)
            except Exception as e:
                log(f"checkUpdates: {e}")
        threading.Thread(target=_check, daemon=True).start()

    @Slot()
    def installUpdate(self):
        if not self._update_url: return
        def _do():
            try:
                if getattr(sys, "frozen", False): app_dir = Path(sys.executable).parent
                else: app_dir = Path(__file__).parent
                if str(app_dir) not in sys.path: sys.path.insert(0, str(app_dir))
                import importlib
                import updater as upd
                importlib.reload(upd)
                self.updateInstalling.emit()
                def progress(p): self.updateProgress.emit(p)
                extract_dir = upd.download_update(self._update_url, progress)
                self.updateProgress.emit(100)
                upd.run_update_script(extract_dir)
                import time
                time.sleep(1.5)
                from PySide6.QtWidgets import QApplication
                from PySide6.QtCore import QMetaObject, Qt
                QMetaObject.invokeMethod(QApplication.instance(), "quit", Qt.QueuedConnection)
            except Exception as e:
                self.error.emit(str(e))
        threading.Thread(target=_do, daemon=True).start()

    def _read_version(self, path: Path) -> str:
        try:
            if path.suffix.lower() == ".zip":
                with zipfile.ZipFile(path) as z:
                    flp = next((n for n in z.namelist() if n.lower().endswith(".flp")), None)
                    if not flp: return "?"
                    with z.open(flp) as f: head = f.read(100)
            else:
                with open(path, "rb") as f: head = f.read(100)
            m = re.search(rb"\b\d{1,2}\.\d{1,2}\.\d{1,4}(?:\.\d{1,6})?\b", head)
            return m.group(0).decode("ascii") if m else "?"
        except Exception:
            return "?"

    def _inspect_zip(self, path: Path) -> dict:
        info = {"samples": 0, "audio": 0, "other": 0}
        try:
            with zipfile.ZipFile(path) as z:
                for n in z.namelist():
                    low = n.lower()
                    if low.endswith((".wav", ".mp3", ".ogg", ".flac", ".aiff", ".aif")): info["audio"] += 1
                    if any(k in low for k in ("sample", "samples", "pack")): info["samples"] += 1
                    if low.endswith((".fst", ".fxp", ".fnv", ".mid")): info["other"] += 1
        except Exception: pass
        return info

    def _on_finished(self, path):
        self._set_busy(False)
        self.progress.emit(100)
        self.finished.emit(path)

    def _on_error(self, msg):
        self._set_busy(False)
        if "Отменено" in msg: self.cancelled.emit()
        else: self.error.emit(msg)