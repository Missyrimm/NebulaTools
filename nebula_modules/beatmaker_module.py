"""
beatmaker_module — BPM и тональность через librosa + постобработка субгармоник.
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


def _onset_density(file_path):
    """Плотность онсетов (атак) в секунду — для определения плотности трека."""
    try:
        y, sr = _load_mono(file_path)
        hop = 512
        n_frames = len(y) // hop
        if n_frames < 8:
            return 0
        energy = np.array([
            np.sum(y[i * hop:(i + 1) * hop] ** 2)
            for i in range(n_frames)
        ], dtype=np.float32)
        onset = np.diff(energy)
        onset[onset < 0] = 0
        if np.max(onset) < 1e-6:
            return 0
        threshold = np.max(onset) * 0.3
        peaks = np.sum(onset > threshold)
        duration = len(y) / sr
        return peaks / duration if duration > 0 else 0
    except Exception:
        return 0


def _fix_subharmonic(raw_bpm, density):
    """
    Постобработка BPM.
    Если librosa выдала 100-120, а трек плотный (density > 10) — вероятно, это
    2/3 от реального темпа (триоли трэпа/дрилла). Умножаем на 1.5.
    Если BPM < 80 — вероятно, 1/2, умножаем на 2.
    """
    if raw_bpm is None:
        return None

    print(f"[bpm] пост-обработка: raw={raw_bpm:.1f}, density={density:.1f}/сек", flush=True)

    # BPM < 80 — явно субгармоника
    if raw_bpm < 80:
        candidate = raw_bpm * 2
        if 100 <= candidate <= 200:
            print(f"[bpm] BPM < 80, × 2 → {candidate:.1f}", flush=True)
            return candidate
        return raw_bpm

    # 100-120 + плотный трек — вероятно 2/3
    candidate15 = raw_bpm * 1.5
    if 100 <= raw_bpm <= 120 and density > 10 and 140 <= candidate15 <= 185:
        print(f"[bpm] 100-120 + плотный трек, × 1.5 → {candidate15:.1f}", flush=True)
        return candidate15

    # 80-100 — оставляем (хип-хоп)
    if 80 <= raw_bpm <= 100:
        print(f"[bpm] BPM в 80-100 (хип-хоп), оставляю", flush=True)
        return raw_bpm

    print(f"[bpm] оставляю как есть", flush=True)
    return raw_bpm


def detect_bpm(file_path: str) -> float:
    """
    BPM через librosa + постобработка субгармоник.
    """
    print(f"\n[bpm] === librosa анализ: {Path(file_path).name} ===", flush=True)

    try:
        y, sr = librosa.load(file_path, sr=22050, mono=True, duration=120)
        tempo, _ = librosa.beat.beat_track(y=y, sr=sr)
        if isinstance(tempo, np.ndarray):
            tempo = float(tempo[0])

        print(f"[bpm] librosa raw: {tempo:.1f}", flush=True)

        density = _onset_density(file_path)
        fixed = _fix_subharmonic(tempo, density)

        result = round(float(fixed), 1)
        print(f"[bpm] ✓ ИТОГО: {result}", flush=True)
        return result

    except Exception as e:
        print(f"[bpm] librosa error: {e}, fallback", flush=True)
        return _fallback_bpm(file_path)


def _fallback_bpm(file_path):
    try:
        y, sr = _load_mono(file_path)
        hop = 512
        n_frames = len(y) // hop
        if n_frames < 8:
            return 120.0
        energy = np.array([np.sum(y[i*hop:(i+1)*hop]**2) for i in range(n_frames)], dtype=np.float32)
        onset = np.diff(energy)
        onset[onset < 0] = 0
        onset = onset - np.mean(onset)
        if np.max(np.abs(onset)) < 1e-6:
            return 120.0
        corr = np.correlate(onset, onset, mode="full")
        corr = corr[len(corr)//2:]
        corr = corr / (np.max(corr) + 1e-6)
        min_lag = max(1, int(sr/hop*60/220))
        max_lag = int(sr/hop*60/50)
        if max_lag >= len(corr):
            max_lag = len(corr)-1
        seg = corr[min_lag:max_lag]
        peaks = [(float(seg[i]), i+min_lag) for i in range(1, len(seg)-1)
                 if seg[i] > seg[i-1] and seg[i] > seg[i+1]]
        if not peaks:
            return 120.0
        peaks.sort(reverse=True)
        _, lag = peaks[0]
        bpm = 60.0 * sr / (lag * hop)
        while bpm < 60:
            bpm *= 2
        while bpm > 180:
            bpm /= 2
        return round(float(bpm), 1)
    except Exception as e:
        print(f"[bpm] fallback error: {e}", flush=True)
        return 120.0


# ---- detect_key и остальные функции без изменений ----
def detect_key(file_path: str) -> tuple:
    print(f"\n[key] === librosa анализ тональности ===", flush=True)
    try:
        y, sr = librosa.load(file_path, sr=22050, mono=True, duration=60)
        chroma = librosa.feature.chroma_cqt(y=y, sr=sr)
        chroma_mean = chroma.mean(axis=1)
        major_p = np.array([6.35, 2.23, 3.48, 2.33, 4.38, 4.09,
                            2.52, 5.19, 2.39, 3.66, 2.29, 2.88])
        minor_p = np.array([6.33, 2.68, 3.52, 5.38, 2.60, 3.53,
                            2.54, 4.75, 3.98, 2.69, 3.34, 3.17])
        keys = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        best_key, best_mode, best_score = "C", "major", -1.0
        for i in range(12):
            cm = float(np.dot(chroma_mean, np.roll(major_p, i)))
            cn = float(np.dot(chroma_mean, np.roll(minor_p, i)))
            if cm > best_score:
                best_score, best_key, best_mode = cm, keys[i], "major"
            if cn > best_score:
                best_score, best_key, best_mode = cn, keys[i], "minor"
        norm = min(1.0, best_score / 1.5)
        print(f"[key] librosa: {best_key} {best_mode} (score {norm:.2f})", flush=True)
        return best_key, best_mode, norm
    except Exception as e:
        print(f"[key] librosa error: {e}, fallback", flush=True)
        return _fallback_key(file_path)


def _fallback_key(file_path):
    y, sr = _load_mono(file_path)
    if len(y) > sr * 30:
        start = len(y)//2 - sr*15
        y = y[start:start+sr*30]
    spectrum = np.abs(np.fft.rfft(y))
    freqs = np.fft.rfftfreq(len(y), 1.0/sr)
    chroma = np.zeros(12)
    mask = (freqs > 80) & (freqs < 2000)
    for f, mag in zip(freqs[mask], spectrum[mask]):
        if mag < 1e-3:
            continue
        midi = 12 * np.log2(f/440.0) + 69
        chroma[int(round(midi)) % 12] += mag
    if chroma.sum() == 0:
        return "C", "major", 0.0
    chroma /= chroma.sum()
    major_p = np.array([6.35, 2.23, 3.48, 2.33, 4.38, 4.09,
                        2.52, 5.19, 2.39, 3.66, 2.29, 2.88])
    minor_p = np.array([6.33, 2.68, 3.52, 5.38, 2.60, 3.53,
                        2.54, 4.75, 3.98, 2.69, 3.34, 3.17])
    keys = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    best = ("C", "major", -1.0)
    for i in range(12):
        cm = float(np.dot(chroma, np.roll(major_p, i)))
        cn = float(np.dot(chroma, np.roll(minor_p, i)))
        if cm > best[2]:
            best = (keys[i], "major", cm)
        if cn > best[2]:
            best = (keys[i], "minor", cn)
    return best[0], best[1], min(1.0, best[2]/1.5)


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