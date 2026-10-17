from pydub import AudioSegment
from pydub.silence import detect_nonsilent
import librosa
import random
from pathlib import Path


def detect_bpm(file_path: str) -> float:
    """Определяет BPM файла через librosa."""
    y, sr = librosa.load(file_path, sr=None, mono=True)
    tempo, _ = librosa.beat.beat_track(y=y, sr=sr)
    try:
        return float(tempo)
    except Exception:
        return float(tempo[0])


def detect_key(file_path: str) -> tuple:
    """
    Определяет тональность через chroma features + профили Krumhansl-Schmuckler.
    Возвращает (key_name, mode, score):
        key_name: "C", "C#", ... "B"
        mode: "major" / "minor"
        score: коэффициент корреляции (0..1, чем ближе к 1 — тем увереннее)
    """
    import numpy as np

    y, sr = librosa.load(file_path, sr=None, mono=True)
    chroma = librosa.feature.chroma_cqt(y=y, sr=sr)
    chroma_mean = chroma.mean(axis=1)

    # Профили тональностей (Krumhansl-Schmuckler)
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
        major_rot = np.roll(major_profile, i)
        minor_rot = np.roll(minor_profile, i)

        corr_major = float(np.corrcoef(chroma_mean, major_rot)[0, 1])
        corr_minor = float(np.corrcoef(chroma_mean, minor_rot)[0, 1])

        if corr_major > best_score:
            best_score = corr_major
            best_key = key_names[i]
            best_mode = "major"

        if corr_minor > best_score:
            best_score = corr_minor
            best_key = key_names[i]
            best_mode = "minor"

    return best_key, best_mode, best_score


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