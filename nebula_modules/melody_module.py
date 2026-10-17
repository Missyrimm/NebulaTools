"""
melody_module — генератор MIDI с реальными различиями по жанрам.
Каждый жанр — свои ритмы, плотность нот, скорость баса, аккордовые расширения.
"""
import io
import random
import hashlib
import time
from pathlib import Path
from mido import Message, MidiFile, MidiTrack, MetaMessage


SCALES = {
    "major":          [0, 2, 4, 5, 7, 9, 11],
    "minor":          [0, 2, 3, 5, 7, 8, 10],
    "dorian":         [0, 2, 3, 5, 7, 9, 10],
    "phrygian":       [0, 1, 3, 5, 7, 8, 10],
    "lydian":         [0, 2, 4, 6, 7, 9, 11],
    "mixolydian":     [0, 2, 4, 5, 7, 9, 10],
    "harmonic_minor": [0, 2, 3, 5, 7, 8, 11],
    "pentatonic":     [0, 3, 5, 7, 10],
    "blues":          [0, 3, 5, 6, 7, 10],
    "whole_tone":     [0, 2, 4, 6, 8, 10],
}

KEY_NAMES = ["C", "C#", "D", "D#", "E", "F",
             "F#", "G", "G#", "A", "A#", "B"]

# Каждый жанр: свои настройки ритма, плотности, баса, аккордов
GENRES = {
    "pop":        {"density": 0.7, "durations": [0.5, 1.0, 1.5], "pause": 0.2, "bass": "root", "vel": (70, 100), "chord_ext": 0.1},
    "hip-hop":    {"density": 0.5, "durations": [0.5, 1.0, 2.0], "pause": 0.3, "bass": "root5", "vel": (60, 95), "chord_ext": 0.15},
    "trap":       {"density": 1.4, "durations": [0.25, 0.25, 0.5, 1.0], "pause": 0.1, "bass": "808", "vel": (50, 85), "chord_ext": 0.2},
    "drill":      {"density": 1.3, "durations": [0.25, 0.5, 1.0], "pause": 0.15, "bass": "slide", "vel": (55, 90), "chord_ext": 0.15},
    "phonk":      {"density": 0.9, "durations": [0.25, 0.5, 1.0], "pause": 0.2, "bass": "808", "vel": (60, 90), "chord_ext": 0.1},
    "lofi":       {"density": 0.5, "durations": [0.5, 0.75, 1.0, 1.5], "pause": 0.35, "bass": "root", "vel": (55, 80), "chord_ext": 0.4},
    "chill":      {"density": 0.4, "durations": [1.0, 1.5, 2.0], "pause": 0.4, "bass": "root", "vel": (55, 80), "chord_ext": 0.35},
    "ambient":    {"density": 0.2, "durations": [2.0, 3.0, 4.0], "pause": 0.6, "bass": "root", "vel": (40, 65), "chord_ext": 0.5},
    "jazz":       {"density": 0.8, "durations": [0.25, 0.5, 1.0, 2.0], "pause": 0.15, "bass": "walking", "vel": (55, 90), "chord_ext": 0.8},
    "blues":      {"density": 0.7, "durations": [0.5, 0.75, 1.0, 1.5], "pause": 0.2, "bass": "shuffle", "vel": (65, 95), "chord_ext": 0.4},
    "funk":       {"density": 1.2, "durations": [0.25, 0.25, 0.5, 1.0], "pause": 0.1, "bass": "syncopated", "vel": (70, 105), "chord_ext": 0.3},
    "rnb":        {"density": 0.6, "durations": [0.5, 1.0, 1.5], "pause": 0.25, "bass": "root", "vel": (55, 85), "chord_ext": 0.7},
    "gospel":     {"density": 0.8, "durations": [0.5, 1.0, 1.5], "pause": 0.2, "bass": "root", "vel": (60, 95), "chord_ext": 0.9},
    "edm":        {"density": 1.0, "durations": [0.25, 0.5, 1.0], "pause": 0.15, "bass": "root8", "vel": (75, 105), "chord_ext": 0.15},
    "house":      {"density": 0.8, "durations": [0.5, 1.0], "pause": 0.2, "bass": "root5", "vel": (75, 100), "chord_ext": 0.25},
    "techno":     {"density": 1.0, "durations": [0.25, 0.5, 1.0], "pause": 0.2, "bass": "root", "vel": (75, 100), "chord_ext": 0.1},
    "dnb":        {"density": 1.5, "durations": [0.125, 0.25, 0.5], "pause": 0.1, "bass": "reese", "vel": (70, 100), "chord_ext": 0.15},
    "riddim":     {"density": 1.3, "durations": [0.25, 0.5, 1.0], "pause": 0.15, "bass": "wobble", "vel": (80, 110), "chord_ext": 0.05},
    "epic":       {"density": 0.6, "durations": [1.0, 2.0, 3.0], "pause": 0.3, "bass": "root8", "vel": (75, 105), "chord_ext": 0.6},
    "cinematic":  {"density": 0.4, "durations": [1.0, 2.0, 4.0], "pause": 0.4, "bass": "root", "vel": (60, 95), "chord_ext": 0.7},
}

_HISTORY = []
_MAX_HISTORY = 50


def _note_signature(mid):
    parts = []
    for track in mid.tracks:
        for msg in track:
            if msg.type == "note_on" and msg.velocity > 0:
                parts.append(f"{msg.note}:{msg.velocity}:{msg.time}")
    return hashlib.md5("|".join(parts).encode()).hexdigest()


def _scale_note(base_midi, scale, degree):
    octave, idx = divmod(degree, len(scale))
    return base_midi + scale[idx] + 12 * octave


def _make_progression(bars, rng, genre):
    """Строит прогрессию в зависимости от жанра."""
    if genre == "blues":
        base = [0, 0, 0, 0, 3, 3, 0, 0, 4, 4, 0, 0, 3, 4, 0, 0]
        return [base[i % len(base)] for i in range(bars)]
    if genre in ("jazz", "rnb", "gospel"):
        # ii-V-I или I-vi-IV-V
        patterns = [
            [1, 4, 0, 5], [0, 5, 3, 4], [1, 4, 0, 0]
        ]
        pat = rng.choice(patterns)
        return [pat[i % len(pat)] for i in range(bars)]
    if genre in ("edm", "house", "techno"):
        # Простые: I-V-vi-IV
        pat = [0, 4, 5, 3]
        return [pat[i % len(pat)] for i in range(bars)]
    # Все остальные — рандом с тяготением к I и V
    weights = [4, 1, 2, 4, 2, 3, 1]
    return [rng.choices(range(7), weights=weights)[0] for _ in range(bars)]


def _build_melody(key, scale, genre, bars, bpm, rng):
    if key not in KEY_NAMES:
        key = rng.choice(KEY_NAMES)
    if scale not in SCALES:
        scale = rng.choice(list(SCALES.keys()))
    if genre not in GENRES:
        genre = rng.choice(list(GENRES.keys()))

    cfg = GENRES[genre]
    key_idx = KEY_NAMES.index(key)
    base = 60 + key_idx
    scale_notes = SCALES[scale]

    progression = _make_progression(bars, rng, genre)

    # Модуляция
    if rng.random() < 0.15 and bars >= 4:
        mod_point = bars // 2
        mod_shift = rng.choice([-5, -2, 2, 5, 7])
    else:
        mod_point = bars + 1
        mod_shift = 0

    mid = MidiFile()
    mel_track = MidiTrack()
    bass_track = MidiTrack()
    chord_track = MidiTrack()
    mid.tracks.extend([mel_track, bass_track, chord_track])

    unique_tag = f"NT-{int(time.time_ns())}-{rng.randint(1000, 9999)}"
    for track, name in zip(
        (mel_track, bass_track, chord_track),
        ("Melody", "Bass", "Chords"),
    ):
        track.append(MetaMessage("track_name", name=f"{name}-{unique_tag}", time=0))

    ticks_per_beat = mid.ticks_per_beat
    beats_per_bar = 4
    total_beats = bars * beats_per_bar

    # ---------- МЕЛОДИЯ ----------
    melody_octave = rng.choices([0, 12, 24], weights=[2, 3, 1])[0]
    range_top = rng.choices(
        [len(scale_notes) - 1, len(scale_notes), len(scale_notes) * 2 - 1],
        weights=[2, 3, 2]
    )[0]

    # Плотность нот из конфига жанра
    density = cfg["density"]
    durations = cfg["durations"]
    pause_prob = cfg["pause"]
    vel_lo, vel_hi = cfg["vel"]

    beats_used = 0.0
    while beats_used < total_beats - 0.25:
        # Чем выше density, тем чаще генерируем ноту
        if rng.random() > min(1.0, density):
            # Пропускаем долю (пауза)
            skip = rng.choice(durations) * 0.5
            beats_used += skip
            continue

        degree = rng.randint(0, range_top)
        current_base = base + 12 + melody_octave

        if beats_used >= mod_point * beats_per_bar:
            current_base += mod_shift

        note = _scale_note(current_base, scale_notes, degree)

        dur_beats = rng.choice(durations)
        dur_ticks = int(dur_beats * ticks_per_beat)

        pause_beats = 0 if rng.random() > pause_prob else rng.choice([0.25, 0.5])
        pause_ticks = int(pause_beats * ticks_per_beat)

        vel = rng.randint(vel_lo, vel_hi)

        mel_track.append(Message("note_on", note=note, velocity=vel, time=pause_ticks))
        mel_track.append(Message("note_off", note=note, velocity=0, time=dur_ticks))

        beats_used += dur_beats + pause_beats

    # ---------- АККОРДЫ ----------
    for bar in range(bars):
        root_degree = progression[bar]
        cur_base = base
        if bar >= mod_point:
            cur_base += mod_shift

        root = _scale_note(cur_base, scale_notes, root_degree)
        third = _scale_note(cur_base, scale_notes, root_degree + 2)
        fifth = _scale_note(cur_base, scale_notes, root_degree + 4)

        notes = [root, third, fifth]

        # Расширения в зависимости от жанра
        if rng.random() < cfg["chord_ext"]:
            notes.append(_scale_note(cur_base, scale_notes, root_degree + 6))
        if rng.random() < cfg["chord_ext"] * 0.5:
            notes.append(_scale_note(cur_base, scale_notes, root_degree + 8))

        # Арпеджио для некоторых жанров
        arp = genre in ("house", "techno", "edm") and rng.random() < 0.5
        if arp:
            step_ticks = (ticks_per_beat * beats_per_bar) // len(notes)
            for i, n in enumerate(notes):
                chord_track.append(Message("note_on", note=n,
                                           velocity=rng.randint(vel_lo, vel_hi),
                                           time=0))
                chord_track.append(Message("note_off", note=n,
                                           velocity=0, time=step_ticks))
        else:
            vel = rng.randint(vel_lo, vel_hi)
            for n in notes:
                chord_track.append(Message("note_on", note=n, velocity=vel, time=0))
            for n in notes:
                chord_track.append(Message("note_off", note=n, velocity=0,
                                           time=ticks_per_beat * beats_per_bar))

    # ---------- БАС ----------
    bass_octave = -24 if genre in ("trap", "drill", "phonk", "edm", "riddim") else rng.choice([-24, -12])
    bass_style = cfg["bass"]

    for bar in range(bars):
        root_degree = progression[bar]
        cur_base = base
        if bar >= mod_point:
            cur_base += mod_shift

        root = _scale_note(cur_base + bass_octave, scale_notes, root_degree)

        if bass_style == "808":
            # Долгие 808-ноты с редкими сменами
            for _ in range(2):
                play_note = root
                if rng.random() < 0.3:
                    play_note = _scale_note(cur_base + bass_octave, scale_notes, root_degree + 3)
                chord_track.append(Message("note_on", note=play_note,
                                           velocity=rng.randint(vel_lo, vel_hi), time=0))
                bass_track.append(Message("note_on", note=play_note,
                                          velocity=rng.randint(vel_lo, vel_hi), time=0))
                bass_track.append(Message("note_off", note=play_note,
                                          velocity=0, time=ticks_per_beat * 2))
        elif bass_style == "walking":
            # Джазовый walking bass — четверти с шагом
            step = rng.choice([2, 3, 4])
            for i in range(4):
                play_note = _scale_note(cur_base + bass_octave, scale_notes,
                                        root_degree + (i * step) % 7)
                bass_track.append(Message("note_on", note=play_note,
                                          velocity=rng.randint(vel_lo, vel_hi),
                                          time=0))
                bass_track.append(Message("note_off", note=play_note,
                                          velocity=0, time=ticks_per_beat - 5))
        elif bass_style == "syncopated":
            # Синкопы — короткие ноты со сдвигом
            rhythm = [0.5, 0.25, 0.25, 0.75, 0.25, 2.0]
            for length in rhythm:
                play_note = root
                if rng.random() < 0.3:
                    play_note = _scale_note(cur_base + bass_octave, scale_notes, root_degree + 4)
                ticks = int(length * ticks_per_beat)
                bass_track.append(Message("note_on", note=play_note,
                                          velocity=rng.randint(vel_lo, vel_hi), time=0))
                bass_track.append(Message("note_off", note=play_note,
                                          velocity=0, time=ticks))
        elif bass_style == "root8":
            # Октавы — 8-е ноты
            for i in range(8):
                play_note = root if i % 2 == 0 else root + 12
                ticks = ticks_per_beat // 2
                bass_track.append(Message("note_on", note=play_note,
                                          velocity=rng.randint(vel_lo, vel_hi), time=0))
                bass_track.append(Message("note_off", note=play_note,
                                          velocity=0, time=ticks))
        elif bass_style in ("root5", "reese", "wobble", "slide"):
            # Долгие ноты с редкими переходами
            rhythm = [1.0, 1.0, 2.0] if rng.random() < 0.5 else [2.0, 2.0]
            for length in rhythm:
                play_note = root
                if bass_style == "root5" and rng.random() < 0.3:
                    play_note = _scale_note(cur_base + bass_octave, scale_notes, root_degree + 4)
                if bass_style == "slide" and rng.random() < 0.4:
                    play_note = _scale_note(cur_base + bass_octave, scale_notes, root_degree + 2)
                ticks = int(length * ticks_per_beat)
                bass_track.append(Message("note_on", note=play_note,
                                          velocity=rng.randint(vel_lo, vel_hi), time=0))
                bass_track.append(Message("note_off", note=play_note,
                                          velocity=0, time=ticks))
        else:
            # "root" — простые четверти/половины
            rhythm = [1.0, 1.0, 1.0, 1.0] if rng.random() < 0.5 else [2.0, 2.0]
            for length in rhythm:
                ticks = int(length * ticks_per_beat)
                bass_track.append(Message("note_on", note=root,
                                          velocity=rng.randint(vel_lo, vel_hi), time=0))
                bass_track.append(Message("note_off", note=root,
                                          velocity=0, time=ticks))

    buf = io.BytesIO()
    mid.save(file=buf)
    return buf.getvalue(), mid


def generate_melody(key=None, scale=None, genre=None, bars=4, bpm=120,
                    output="melody.mid", seed=None):
    if seed is None:
        seed = time.time_ns() ^ random.randint(0, 2**31 - 1)

    result_bytes = None
    signature = None

    for attempt in range(15):
        rng = random.Random(seed + attempt * 7919)
        data, mid = _build_melody(key, scale, genre, bars, bpm, rng)
        sig = _note_signature(mid)
        if sig not in _HISTORY:
            result_bytes = data
            signature = sig
            break
        if attempt == 14:
            result_bytes = data
            signature = sig

    _HISTORY.append(signature)
    if len(_HISTORY) > _MAX_HISTORY:
        _HISTORY.pop(0)

    Path(output).parent.mkdir(parents=True, exist_ok=True)
    Path(output).write_bytes(result_bytes)
    return output


def list_genres():
    return list(GENRES.keys())


def clear_history():
    _HISTORY.clear()