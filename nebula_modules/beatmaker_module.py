"""
beatmaker_module — усиленный BPM и Key через librosa (multi-method voting).
"""
import numpy as np
import librosa
import soundfile as sf
from pydub import AudioSegment
from pydub.silence import detect_nonsilent
import random
from pathlib import Path


def _load_mono(file_path):
    y, sr = sf.read(file_path)
    if y.ndim > 1:
        y = y.mean(axis=1)
    return y.astype(np.float32), sr


# ============================================================
#  BPM — multi-method voting
# ============================================================
def _autocorr_bpm(y, sr):
    hop = 512
    n_frames = len(y) // hop
    if n_frames < 8:
        return None
    energy = np.array([np.sum(y[i*hop:(i+1)*hop]**2) for i in range(n_frames)], dtype=np.float32)
    onset = np.diff(energy)
    onset[onset < 0] = 0
    onset = onset - np.mean(onset)
    if np.max(np.abs(onset)) < 1e-6:
        return None
    corr = np.correlate(onset, onset, mode="full")
    corr = corr[len(corr)//2:]
    corr = corr / (np.max(corr) + 1e-6)
    min_lag = max(1, int(sr/hop*60/220))
    max_lag = int(sr/hop*60/50)
    if max_lag >= len(corr):
        max_lag = len(corr) - 1
    seg = corr[min_lag:max_lag]
    peaks = [(float(seg[i]), i+min_lag) for i in range(1, len(seg)-1)
             if seg[i] > seg[i-1] and seg[i] > seg[i+1]]
    if not peaks:
        return None
    peaks.sort(reverse=True)
    _, lag = peaks[0]
    return 60.0 * sr / (lag * hop)


def detect_bpm(file_path: str) -> float:
    """
    Multi-method BPM:
    1. librosa.beat.beat_track (default)
    2. librosa.feature.tempo (onset envelope)
    3. autocorrelation
    Затем медиана + пост-обработка.
    """
    print(f"\n[bpm] Анализ: {Path(file_path).name}", flush=True)

    candidates = []

    try:
        y, sr = librosa.load(file_path, sr=22050, mono=True, duration=120)
    except Exception as e:
        print(f"[bpm] librosa.load ошибка: {e}", flush=True)
        return 120.0

    # Method 1: beat_track
    try:
        tempo1, _ = librosa.beat.beat_track(y=y, sr=sr)
        bpm1 = float(tempo1[0] if isinstance(tempo1, np.ndarray) else tempo1)
        if 30 < bpm1 < 300:
            candidates.append(bpm1)
            print(f"[bpm] beat_track: {bpm1:.1f}", flush=True)
    except Exception as e:
        print(f"[bpm] beat_track ошибка: {e}", flush=True)

    # Method 2: onset + tempo
    try:
        onset_env = librosa.onset.onset_strength(y=y, sr=sr)
        tempo2 = librosa.feature.tempo(onset_envelope=onset_env, sr=sr)
        bpm2 = float(tempo2[0] if isinstance(tempo2, np.ndarray) else tempo2)
        if 30 < bpm2 < 300:
            candidates.append(bpm2)
            print(f"[bpm] tempo feature: {bpm2:.1f}", flush=True)
    except Exception as e:
        print(f"[bpm] tempo feature ошибка: {e}", flush=True)

    # Method 3: autocorrelation
    try:
        bpm3 = _autocorr_bpm(y, sr)
        if bpm3 and 30 < bpm3 < 300:
            candidates.append(bpm3)
            print(f"[bpm] autocorr: {bpm3:.1f}", flush=True)
    except Exception as e:
        print(f"[bpm] autocorr ошибка: {e}", flush=True)

    if not candidates:
        print("[bpm] ни один метод не сработал, дефолт 120", flush=True)
        return 120.0

    # Нормализуем все в 60-180
    normalized = []
    for b in candidates:
        while b < 60: b *= 2
        while b > 180: b /= 2
        normalized.append(b)

    # Медиана
    bpm = float(np.median(normalized))
    print(f"[bpm] нормализованные: {[round(x,1) for x in normalized]}, медиана: {bpm:.1f}", flush=True)

    # Onset density для проверки
    density = 0.0
    try:
        onsets = librosa.onset.onset_detect(y=y, sr=sr)
        duration = len(y) / sr
        density = len(onsets) / duration if duration > 0 else 0
        print(f"[bpm] onset density: {density:.1f}/сек", flush=True)
    except Exception:
        pass

    # --- Строгая логика x2 и /2 (без x1.5) ---
    if bpm < 80 and density > 4:
        bpm *= 2
        print(f"[bpm] half-time fix: x2 → {bpm:.1f}", flush=True)
    elif bpm > 160:
        bpm /= 2
        print(f"[bpm] double-time fix: /2 → {bpm:.1f}", flush=True)
    # --- Конец логики ---

    bpm = round(bpm, 1)
    print(f"[bpm] ✓ ИТОГО: {bpm}", flush=True)
    return bpm


# ============================================================
#  KEY — ensemble Krumhansl + Temperley + bass weighting
# ============================================================
KEY_NAMES = ["C", "C#", "D", "D#", "E", "F",
             "F#", "G", "G#", "A", "A#", "B"]


def detect_key(file_path: str) -> tuple:
    print(f"\n[key] Анализ тональности", flush=True)

    try:
        y, sr = librosa.load(file_path, sr=22050, mono=True, duration=60)
    except Exception as e:
        print(f"[key] librosa.load ошибка: {e}", flush=True)
        return "C", "major", 0.0

    # Полный chroma
    try:
        chroma = librosa.feature.chroma_cqt(y=y, sr=sr)
        chroma_mean = chroma.mean(axis=1)
    except Exception as e:
        print(f"[key] chroma ошибка: {e}", flush=True)
        return "C", "major", 0.0

    # Bass chroma (низкие частоты весят больше — там тоника)
    try:
        from scipy.signal import butter, filtfilt
        sos = butter(4, 300, btype="low", fs=sr, output="sos")
        y_bass = filtfilt(sos, y) if len(y) > 30 else y
        chroma_bass = librosa.feature.chroma_cqt(y=y_bass, sr=sr)
        chroma_bass_mean = chroma_bass.mean(axis=1)
    except Exception:
        chroma_bass_mean = chroma_mean

    # Комбинируем: bass x 2 + full x 1
    if chroma_bass_mean.sum() > 0:
        chroma_bass_mean = chroma_bass_mean / chroma_bass_mean.sum()
    if chroma_mean.sum() > 0:
        chroma_mean = chroma_mean / chroma_mean.sum()

    combined = chroma_bass_mean * 2.0 + chroma_mean * 1.0
    if combined.sum() == 0:
        return "C", "major", 0.0
    combined = combined / combined.sum()

    # Профили
    major_k = np.array([6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88])
    minor_k = np.array([6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17])
    major_t = np.array([5.0, 2.0, 3.5, 2.0, 4.5, 4.0, 2.0, 4.5, 2.0, 3.5, 1.5, 4.0])
    minor_t = np.array([5.0, 2.0, 3.5, 4.5, 2.0, 4.0, 2.0, 4.5, 3.5, 2.0, 1.5, 4.0])

    scores = []
    for i in range(12):
        for mode, mp, tprofile in [("major", major_k, major_t), ("minor", minor_k, minor_t)]:
            try:
                sk = float(np.corrcoef(combined, np.roll(mp, i))[0, 1])
                st = float(np.corrcoef(combined, np.roll(tprofile, i))[0, 1])
                score = (sk + st) / 2
                scores.append((score, KEY_NAMES[i], mode))
            except Exception:
                pass

    if not scores:
        return "C", "major", 0.0

    scores.sort(reverse=True, key=lambda x: x[0])
    print(f"[key] топ-3:", flush=True)
    for score, k, m in scores[:3]:
        print(f"[key]   {k} {m}: {score:.3f}", flush=True)

    best_score, best_key, best_mode = scores[0]
    norm = min(1.0, max(0.0, best_score))
    print(f"[key] ✓ ИТОГО: {best_key} {best_mode}", flush=True)
    return best_key, best_mode, norm


def key_to_camelot(key: str, mode: str) -> str:
    """Конвертация в Camelot."""
    major_map = {
        "C": "8B", "C#": "3B", "D": "10B", "D#": "5B", "E": "12B", "F": "7B",
        "F#": "2B", "G": "9B", "G#": "4B", "A": "11B", "A#": "6B", "B": "1B"
    }
    minor_map = {
        "C": "5A", "C#": "12A", "D": "7A", "D#": "2A", "E": "9A", "F": "4A",
        "F#": "11A", "G": "6A", "G#": "1A", "A": "8A", "A#": "3A", "B": "10A"
    }
    m = major_map if mode == "major" else minor_map
    return m.get(key, "")


# ============================================================
#  Beat maker
# ============================================================
def chop_by_beats(file_path: str, divisions: int = 4) -> tuple:
    bpm = detect_bpm(file_path)
    audio = AudioSegment.from_file(file_path)
    total_ms = len(audio)
    beat_ms = 60000 / bpm
    slice_ms = beat_ms / divisions
    chunks = []
    pos = 0
    while pos + slice_ms <= total_ms:
        chunks.append(audio[pos:pos+slice_ms])
        pos += slice_ms
    return chunks, bpm


def chop_by_silence(file_path: str, silence_thresh: int = -40,
                    min_silence_len: int = 100) -> list:
    audio = AudioSegment.from_file(file_path)
    ranges = detect_nonsilent(audio, min_silence_len=min_silence_len,
                              silence_thresh=silence_thresh)
    return [audio[s:e] for s, e in ranges]


def shuffle_beat(file_path: str, divisions: int = 4, repeats: int = 2,
                 output_path: str = None) -> str:
    chunks, bpm = chop_by_beats(file_path, divisions)
    if len(chunks) < 4:
        raise ValueError("Файл слишком короткий для нарезки.")
    loop = [random.choice(chunks) for _ in range(16)]
    result = AudioSegment.empty()
    for _ in range(repeats):
        for chunk in loop:
            result += chunk
    if output_path is None:
        p = Path(file_path)
        output_path = str(p.parent / f"{p.stem}_beat.wav")
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    result.export(output_path, format="wav")
    return output_path


def generate_from_samples(sample_paths: list, bars: int = 4,
                          output_path: str = "generated_beat.wav") -> str:
    loaded = [AudioSegment.from_file(p) for p in sample_paths]
    if not loaded:
        raise ValueError("Нет сэмплов для генерации.")
    total_slices = bars * 16
    slice_ms = 125
    track = AudioSegment.silent(duration=total_slices * slice_ms)
    for i in range(total_slices):
        if random.random() < 0.25:
            s = random.choice(loaded)[:slice_ms]
            track = track.overlay(s, position=i*slice_ms)
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    track.export(output_path, format="wav")
    return output_path