"""
melody_module — 20 жанров, каждый со своей ритмической и гармонической логикой.
Прогрессии, бас-паттерны, длительности, октавы — всё различается.
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

# ============================================================
#  КОНФИГУРАЦИЯ ЖАНРОВ
# ============================================================
# progressions — список прогрессий (0-indexed ступени)
# rhythm — базовые длительности нот (в долях)
# density — вероятность появления ноты в слоте
# bass_style — паттерн баса
# bass_octave — октава баса относительно тоники
# melody_octave — октава мелодии
# chord_ext — вероятность расширений (7-я, 9-я)
# swing — отклонение чётных нот (для свинга)
GENRES = {
    "pop": {
        "progressions": [[0, 4, 5, 3], [0, 5, 3, 4], [0, 3, 4, 4]],
        "rhythm": [0.5, 1.0, 1.0, 0.5],
        "density": 0.8,
        "bass_style": "root5",
        "bass_octave": -12,
        "melody_octave": 12,
        "chord_ext": 0.2,
        "swing": 0,
    },
    "hip-hop": {
        "progressions": [[0, 5, 3, 4], [0, 3, 5, 4], [0, 2, 5, 4]],
        "rhythm": [0.5, 1.0, 1.5],
        "density": 0.6,
        "bass_style": "root",
        "bass_octave": -24,
        "melody_octave": 0,
        "chord_ext": 0.3,
        "swing": 0.1,
    },
    "trap": {
        "progressions": [[0, 5, 3, 4], [0, 5, 4, 3], [0, 3, 5, 4]],
        "rhythm": [0.25, 0.25, 0.5, 1.0],
        "density": 1.3,
        "bass_style": "808",
        "bass_octave": -24,
        "melody_octave": 12,
        "chord_ext": 0.15,
        "swing": 0,
    },
    "drill": {
        "progressions": [[0, 3, 5, 4], [0, 5, 3, 4]],
        "rhythm": [0.25, 0.25, 0.5, 0.5],
        "density": 1.4,
        "bass_style": "slide",
        "bass_octave": -24,
        "melody_octave": 12,
        "chord_ext": 0.2,
        "swing": 0,
    },
    "phonk": {
        "progressions": [[0, 3, 5, 4], [0, 5, 4, 3]],
        "rhythm": [0.25, 0.5, 0.5, 1.0],
        "density": 1.0,
        "bass_style": "808",
        "bass_octave": -24,
        "melody_octave": 0,
        "chord_ext": 0.2,
        "swing": 0.15,
    },
    "lofi": {
        "progressions": [[0, 3, 5, 4], [1, 4, 0, 0], [0, 5, 3, 4]],
        "rhythm": [0.5, 0.75, 1.0, 1.5],
        "density": 0.6,
        "bass_style": "root",
        "bass_octave": -12,
        "melody_octave": 12,
        "chord_ext": 0.5,
        "swing": 0.2,
    },
    "chill": {
        "progressions": [[0, 5, 3, 4], [0, 3, 5, 4]],
        "rhythm": [0.75, 1.0, 1.5, 2.0],
        "density": 0.4,
        "bass_style": "root",
        "bass_octave": -12,
        "melody_octave": 12,
        "chord_ext": 0.4,
        "swing": 0.1,
    },
    "ambient": {
        "progressions": [[0, 0, 0, 0], [0, 3, 0, 3], [0, 5, 3, 0]],
        "rhythm": [2.0, 3.0, 4.0],
        "density": 0.25,
        "bass_style": "root",
        "bass_octave": -12,
        "melody_octave": 12,
        "chord_ext": 0.7,
        "swing": 0,
    },
    "jazz": {
        "progressions": [[1, 4, 0, 5], [0, 3, 4, 1], [1, 4, 0, 0]],
        "rhythm": [0.25, 0.5, 0.75, 1.0],
        "density": 0.8,
        "bass_style": "walking",
        "bass_octave": -12,
        "melody_octave": 12,
        "chord_ext": 0.9,
        "swing": 0.3,
    },
    "blues": {
        "progressions": [[0, 0, 0, 0], [3, 3, 0, 0], [4, 4, 0, 0]],
        "rhythm": [0.5, 0.75, 1.0],
        "density": 0.7,
        "bass_style": "shuffle",
        "bass_octave": -12,
        "melody_octave": 0,
        "chord_ext": 0.4,
        "swing": 0.25,
    },
    "funk": {
        "progressions": [[0, 0, 0, 0], [0, 3, 0, 4], [0, 4, 0, 3]],
        "rhythm": [0.25, 0.25, 0.5, 1.0],
        "density": 1.2,
        "bass_style": "syncopated",
        "bass_octave": -12,
        "melody_octave": 0,
        "chord_ext": 0.5,
        "swing": 0.15,
    },
    "rnb": {
        "progressions": [[0, 5, 3, 4], [1, 4, 0, 0], [0, 3, 5, 4]],
        "rhythm": [0.5, 0.75, 1.0, 1.5],
        "density": 0.6,
        "bass_style": "root",
        "bass_octave": -12,
        "melody_octave": 12,
        "chord_ext": 0.8,
        "swing": 0.1,
    },
    "gospel": {
        "progressions": [[0, 3, 4, 5], [1, 4, 0, 0], [0, 4, 5, 3]],
        "rhythm": [0.5, 0.75, 1.0],
        "density": 0.7,
        "bass_style": "walking",
        "bass_octave": -12,
        "melody_octave": 12,
        "chord_ext": 1.0,
        "swing": 0.15,
    },
    "edm": {
        "progressions": [[0, 4, 5, 3], [5, 3, 0, 4], [0, 5, 3, 4]],
        "rhythm": [0.25, 0.5, 1.0],
        "density": 1.0,
        "bass_style": "root8",
        "bass_octave": -24,
        "melody_octave": 12,
        "chord_ext": 0.2,
        "swing": 0,
    },
    "house": {
        "progressions": [[0, 5, 3, 4], [0, 3, 5, 4]],
        "rhythm": [0.5, 1.0],
        "density": 0.9,
        "bass_style": "root8",
        "bass_octave": -24,
        "melody_octave": 12,
        "chord_ext": 0.3,
        "swing": 0,
    },
    "techno": {
        "progressions": [[0, 0, 0, 0], [0, 3, 0, 5]],
        "rhythm": [0.25, 0.5, 1.0],
        "density": 0.9,
        "bass_style": "root",
        "bass_octave": -24,
        "melody_octave": 12,
        "chord_ext": 0.15,
        "swing": 0,
    },
    "dnb": {
        "progressions": [[0, 5, 3, 4], [0, 3, 5, 4]],
        "rhythm": [0.125, 0.25, 0.5],
        "density": 1.5,
        "bass_style": "reese",
        "bass_octave": -24,
        "melody_octave": 12,
        "chord_ext": 0.2,
        "swing": 0,
    },
    "riddim": {
        "progressions": [[0, 0, 0, 0], [0, 1, 0, 1]],
        "rhythm": [0.25, 0.5, 0.5],
        "density": 1.3,
        "bass_style": "wobble",
        "bass_octave": -24,
        "melody_octave": 0,
        "chord_ext": 0.1,
        "swing": 0,
    },
    "epic": {
        "progressions": [[0, 5, 3, 4], [0, 4, 5, 3]],
        "rhythm": [1.0, 2.0, 2.0],
        "density": 0.5,
        "bass_style": "root5",
        "bass_octave": -12,
        "melody_octave": 12,
        "chord_ext": 0.6,
        "swing": 0,
    },
    "cinematic": {
        "progressions": [[0, 5, 3, 0], [0, 4, 5, 3]],
        "rhythm": [1.0, 2.0, 4.0],
        "density": 0.35,
        "bass_style": "root5",
        "bass_octave": -12,
        "melody_octave": 24,
        "chord_ext": 0.7,
        "swing": 0,
    },
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

    # Выбираем прогрессию из списка жанра
    progression = rng.choice(cfg["progressions"])
    progression = [progression[i % len(progression)] for i in range(bars)]

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

    # Свинг (для jazz, lofi, blues, hip-hop)
    swing = cfg["swing"]

    # ---------- МЕЛОДИЯ ----------
    mel_oct = base + cfg["melody_octave"]
    rhythm_choices = cfg["rhythm"]
    density = cfg["density"]

    beats_used = 0.0
    slot = 0
    while beats_used < total_beats - 0.125:
        # Решаем, ставить ноту или паузу
        if rng.random() > min(1.0, density):
            beats_used += rng.choice(rhythm_choices) * 0.5
            continue

        # Ступень (с тяготением к устойчивым для мелодии)
        degrees = [0, 2, 4, 5, 7, 9, 11, 12, 14]
        degree = rng.choice(degrees)
        note = _scale_note(mel_oct, scale_notes, degree)

        dur = rng.choice(rhythm_choices)

        # Свинг: чётные слоты короче, нечётные длиннее
        if swing > 0 and slot % 2 == 1:
            dur *= (1 + swing)

        vel = rng.randint(65, 105)

        mel_track.append(Message("note_on", note=note, velocity=vel, time=0))
        mel_track.append(Message("note_off", note=note, velocity=0,
                                 time=int(dur * ticks_per_beat)))
        beats_used += dur
        slot += 1

    # ---------- АККОРДЫ ----------
    for bar in range(bars):
        root_degree = progression[bar]
        cur_base = base

        root = _scale_note(cur_base, scale_notes, root_degree)
        third = _scale_note(cur_base, scale_notes, root_degree + 2)
        fifth = _scale_note(cur_base, scale_notes, root_degree + 4)
        notes = [root, third, fifth]

        # Расширения в зависимости от жанра (jazz/rnb/gospel — много, techno — нет)
        if rng.random() < cfg["chord_ext"]:
            notes.append(_scale_note(cur_base, scale_notes, root_degree + 6))
        if rng.random() < cfg["chord_ext"] * 0.6:
            notes.append(_scale_note(cur_base, scale_notes, root_degree + 8))

        # Длительность аккорда — весь такт
        bar_ticks = ticks_per_beat * beats_per_bar
        vel = rng.randint(50, 75)

        for n in notes:
            chord_track.append(Message("note_on", note=n, velocity=vel, time=0))
        for n in notes:
            chord_track.append(Message("note_off", note=n, velocity=0, time=bar_ticks))

    # ---------- БАС ----------
    bass_oct = base + cfg["bass_octave"]
    bass_style = cfg["bass_style"]

    for bar in range(bars):
        root_degree = progression[bar]
        root = _scale_note(bass_oct, scale_notes, root_degree)

        if bass_style == "808":
            # 808-стиль: долгие редкие ноты + изредка октава/квинта
            for _ in range(rng.randint(1, 2)):
                play_note = root
                if rng.random() < 0.3:
                    play_note = _scale_note(bass_oct, scale_notes, root_degree + 3)
                dur = rng.choice([1.0, 2.0])
                vel = rng.randint(60, 90)
                bass_track.append(Message("note_on", note=play_note, velocity=vel, time=0))
                bass_track.append(Message("note_off", note=play_note, velocity=0,
                                          time=int(dur * ticks_per_beat)))

        elif bass_style == "walking":
            # Walking bass: каждая четверть — новая нота, движение по гамме
            steps = [0, 3, 2, 5] if rng.random() < 0.5 else [0, 2, 4, 3]
            for i in range(4):
                play_note = _scale_note(bass_oct, scale_notes, root_degree + steps[i])
                vel = rng.randint(70, 95)
                bass_track.append(Message("note_on", note=play_note, velocity=vel, time=0))
                bass_track.append(Message("note_off", note=play_note, velocity=0,
                                          time=ticks_per_beat - 10))

        elif bass_style == "syncopated":
            # Синкопы: 0.25, 0.25, 0.5, 1.0, 2.0
            pattern = [0.5, 0.25, 0.25, 0.75, 0.25, 1.0, 1.0]
            for length in pattern:
                play_note = root
                if rng.random() < 0.3:
                    play_note = _scale_note(bass_oct, scale_notes, root_degree + 2)
                ticks = int(length * ticks_per_beat)
                vel = rng.randint(75, 105)
                bass_track.append(Message("note_on", note=play_note, velocity=vel, time=0))
                bass_track.append(Message("note_off", note=play_note, velocity=0, time=ticks))

        elif bass_style == "root8":
            # 8-е ноты: тоника, тоника+12 (октава)
            for i in range(8):
                play_note = root if i % 2 == 0 else root + 12
                ticks = ticks_per_beat // 2
                vel = rng.randint(70, 100)
                bass_track.append(Message("note_on", note=play_note, velocity=vel, time=0))
                bass_track.append(Message("note_off", note=play_note, velocity=0, time=ticks))

        elif bass_style == "slide":
            # Слайды: длинные ноты с переходами на +2/+3
            play_note = root
            if rng.random() < 0.4:
                play_note = _scale_note(bass_oct, scale_notes, root_degree + 3)
            dur = rng.choice([1.5, 2.5])
            vel = rng.randint(70, 95)
            bass_track.append(Message("note_on", note=play_note, velocity=vel, time=0))
            bass_track.append(Message("note_off", note=play_note, velocity=0,
                                      time=int(dur * ticks_per_beat)))

        elif bass_style == "reese":
            # DnB: длинные низкие тоники
            dur = 4.0
            vel = rng.randint(75, 100)
            bass_track.append(Message("note_on", note=root, velocity=vel, time=0))
            bass_track.append(Message("note_off", note=root, velocity=0,
                                      time=int(dur * ticks_per_beat)))

        elif bass_style == "wobble":
            # Riddim: быстрые короткие ноты с частыми повторами
            for _ in range(8):
                play_note = root
                if rng.random() < 0.3:
                    play_note = _scale_note(bass_oct, scale_notes, root_degree + 1)
                ticks = ticks_per_beat // 4
                vel = rng.randint(80, 110)
                bass_track.append(Message("note_on", note=play_note, velocity=vel, time=0))
                bass_track.append(Message("note_off", note=play_note, velocity=0, time=ticks))

        elif bass_style == "shuffle":
            # Blues shuffle: длинная-короткая
            for _ in range(4):
                play_note = root if rng.random() < 0.7 else root + 7
                long_ticks = int(ticks_per_beat * 0.75)
                short_ticks = int(ticks_per_beat * 0.25)
                vel = rng.randint(70, 95)
                bass_track.append(Message("note_on", note=play_note, velocity=vel, time=0))
                bass_track.append(Message("note_off", note=play_note, velocity=0,
                                          time=long_ticks))
                bass_track.append(Message("note_on", note=play_note, velocity=vel - 10, time=0))
                bass_track.append(Message("note_off", note=play_note, velocity=0,
                                          time=short_ticks))

        else:  # "root" или "root5"
            # Простые длинные ноты
            pattern = [2.0, 2.0] if rng.random() < 0.5 else [1.0, 1.0, 1.0, 1.0]
            for length in pattern:
                play_note = root
                if bass_style == "root5" and rng.random() < 0.4:
                    play_note = _scale_note(bass_oct, scale_notes, root_degree + 4)
                ticks = int(length * ticks_per_beat)
                vel = rng.randint(70, 95)
                bass_track.append(Message("note_on", note=play_note, velocity=vel, time=0))
                bass_track.append(Message("note_off", note=play_note, velocity=0, time=ticks))

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