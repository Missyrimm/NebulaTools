"""
beatmaker_module — без librosa.
BPM и тональность через numpy + soundfile (в 10 раз легче).
"""
import numpy as np
import soundfile as sf
from pydub import AudioSegment
from pydub.silence import detect_nonsilent
import random
from pathlib import Path


def _load_mono(file_path):
    """Загружает аудио как моно float32."""
    y, sr = sf.read(file_path)
    if y.ndim > 1:
        y = y.mean(axis=1)
    return y.astype(np.float32), sr


def detect_bpm(file_path: str) -> float:
    """BPM через onset-autocorrelation. Без librosa."""
    y, sr = _load_mono(file_path)

    # Onset envelope через энергию по фреймам
    hop = 512
    n_frames = len(y) // hop
    if n_frames < 8:
        return 120.0

    energy = np.array([
        np.sum(y[i * hop:(i + 1) * hop] ** 2)
        for i in range(n_frames)
    ], dtype=np.float32)

    # Дифференциал — выделяет атаки
    onset = np.diff(energy)
    onset[onset < 0] = 0
    onset = onset - np.mean(onset)

    if np.max(np.abs(onset)) < 1e-6:
        return 120.0

    # Autocorrelation
    corr = np.correlate(onset, onset, mode="full")
    corr = corr[len(corr) // 2:]
    corr = corr / (np.max(corr) + 1e-6)

    # BPM range: 60-180
    min_lag = int(sr / hop * 60 / 180)
    max_lag = int(sr / hop * 60 / 60)

    if max_lag >= len(corr):
        max_lag = len(corr) - 1

    if max_lag <= min_lag:
        return 120.0

    peak_lag = min_lag + int(np.argmax(corr[min_lag:max_lag]))

    if peak_lag == 0:
        return 120.0

    bpm = 60.0 * sr / (peak_lag * hop)

    while bpm < 60:
        bpm *= 2
    while bpm > 180:
        bpm /= 2

    return float(bpm)


def detect_key(file_path: str) -> tuple:
    """Тональность через FFT chroma + Krumhansl profiles. Без librosa."""
    y, sr = _load_mono(file_path)

    # Берём только 10 секунд из середины — быстро и достаточно
    if len(y) > sr * 10:
        start = len(y) // 2 - sr * 5
        y = y[start:start + sr * 10]

    # FFT
    spectrum = np.abs(np.fft.rfft(y))
    freqs = np.fft.rfftfreq(len(y), 1.0 / sr)

    # Chroma — распределяем энергию по 12 полутонам
    chroma = np.zeros(12, dtype=np.float64)
    mask = (freqs > 80) & (freqs < 2000)

    for f, mag in zip(freqs[mask], spectrum[mask]):
        if mag < 1e-3:
            continue
        midi = 12 * np.log2(f / 440.0) + 69
        note = int(round(midi)) % 12
        chroma[note] += mag

    if chroma.sum() == 0:
        return "C", "major", 0.0

    chroma = chroma / chroma.sum()

    # Krumhansl-Schmuckler профили
    major_profile = np.array([6.35, 2.23, 3.48, 2.33, 4.38, 4.09,
                              2.52, 5.19, 2.39, 3.66, 2.29, 2.88])
    minor_profile = np.array([6.33, 2.68, 3.52, 5.38, 2.60, 3.53,
                              2.54, 4.75, 3.98, 2.69, 3.34, 3.17])

    key_names = ["C", "C#", "D", "D#", "E", "F",
                 "F#", "G", "G#", "A", "A#", "B"]

    best_key = "C"
    best_mode = "major"
    best_score = -1.0

    for i in range(12):
        c_maj = float(np.dot(chroma, np.roll(major_profile, i)))
        c_min = float(np.dot(chroma, np.roll(minor_profile, i)))

        if c_maj > best_score:
            best_score = c_maj
            best_key = key_names[i]
            best_mode = "major"
        if c_min > best_score:
            best_score = c_min
            best_key = key_names[i]
            best_mode = "minor"

    # Нормализуем score в 0..1
    norm_score = min(1.0, best_score / 1.5)
    return best_key, best_mode, norm_score


def chop_by_beats(file_path: str, divisions: int = 4) -> tuple:
    bpm = detect_bpm(file_path)
    audio = AudioSegment.from_file(file_path)
    total_ms = len(audio)

    beat_ms = 60000 / bpm
    slice_ms = beat_ms / divisions

    chunks = []
    pos = 0
    while pos + slice_ms <= total_ms:
        chunks.append(audio[pos:pos + slice_ms])
        pos += slice_ms

    return chunks, bpm


def chop_by_silence(file_path: str, silence_thresh: int = -40,
                    min_silence_len: int = 100) -> list:
    audio = AudioSegment.from_file(file_path)
    ranges = detect_nonsilent(audio,
                              min_silence_len=min_silence_len,
                              silence_thresh=silence_thresh)
    chunks = [audio[start:end] for start, end in ranges]
    return chunks


def shuffle_beat(file_path: str, divisions: int = 4,
                 repeats: int = 2, output_path: str = None) -> str:
    chunks, bpm = chop_by_beats(file_path, divisions)
    if len(chunks) < 4:
        raise ValueError("Файл слишком короткий для нарезки.")

    beats_per_loop = 16
    loop = []
    for _ in range(beats_per_loop):
        loop.append(random.choice(chunks))

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
            s = random.choice(loaded)
            s = s[:slice_ms]
            position = i * slice_ms
            track = track.overlay(s, position=position)

    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    track.export(output_path, format="wav")
    return output_path