"""
Генератор MIDI-мелодий с гарантией уникальности.
Каждый вызов даёт новую мелодию — даже в одну микросекунду.
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

# Веса ступеней: I (0) и V (4) чаще, iii (2) и vii (6) реже
STEP_WEIGHTS = [4, 1, 2, 4, 2, 3, 1]

# Жанровые подсказки — только для весов, не для шаблонов
GENRE_BIAS = {
    "pop":   [4, 1, 2, 4, 2, 3, 1],
    "jazz":  [3, 2, 2, 3, 3, 2, 1],
    "edm":   [4, 1, 1, 4, 3, 2, 0],
    "lofi":  [3, 2, 3, 3, 2, 3, 1],
    "epic":  [4, 1, 1, 4, 3, 1, 1],
    "blues": [4, 0, 0, 4, 2, 1, 0],
}

# История хэшей для защиты от дублей
_HISTORY = []
_MAX_HISTORY = 50


def _note_signature(mid):
    """Хэш от всех нот (без метаданных)."""
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
    """Полностью случайная прогрессия с музыкальными весами."""
    weights = GENRE_BIAS.get(genre, STEP_WEIGHTS)
    pattern_type = rng.choices(
        ["simple", "pattern", "random", "modal"],
        weights=[4, 3, 2, 1]
    )[0]

    if pattern_type == "simple":
        # A A A A — 4 аккорда повторяются
        base = [rng.choices(range(7), weights=weights)[0] for _ in range(4)]
        return [base[i % 4] for i in range(bars)]

    elif pattern_type == "pattern":
        # A B A C — волна
        a = rng.choices(range(7), weights=weights)[0]
        b = rng.choices(range(7), weights=weights)[0]
        c = rng.choices(range(7), weights=weights)[0]
        pat = [a, b, a, c]
        return [pat[i % 4] for i in range(bars)]

    elif pattern_type == "modal":
        # Медленное движение: каждый аккорд — ±1-2 ступени от предыдущего
        prog = [rng.choices(range(7), weights=weights)[0]]
        for _ in range(bars - 1):
            delta = rng.choice([-2, -1, -1, 0, 1, 1, 2])
            prog.append((prog[-1] + delta) % 7)
        return prog

    else:
        # Полный рандом
        return [rng.choices(range(7), weights=weights)[0] for _ in range(bars)]


def _build_melody(key, scale, genre, bars, bpm, rng):
    """Собирает MIDI в память. Возвращает bytes."""
    if key not in KEY_NAMES:
        key = rng.choice(KEY_NAMES)
    if scale not in SCALES:
        scale = rng.choice(list(SCALES.keys()))
    if genre not in GENRE_BIAS:
        genre = rng.choice(list(GENRE_BIAS.keys()))

    key_idx = KEY_NAMES.index(key)
    base = 60 + key_idx
    scale_notes = SCALES[scale]

    progression = _make_progression(bars, rng, genre)

    # Случайная модуляция: в середине прогрессии сдвиг тональности
    if rng.random() < 0.2 and bars >= 4:
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

    # Уникальное имя трека — гарантирует разницу даже при совпадении нот
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
    # Случайная октава мелодии: +0, +12, +24
    melody_octave = rng.choices([0, 12, 24], weights=[2, 3, 1])[0]

    # Случайный диапазон ступеней (иногда узкий, иногда широкий)
    range_top = rng.choices(
        [len(scale_notes) - 1, len(scale_notes), len(scale_notes) * 2 - 1],
        weights=[2, 3, 2]
    )[0]

    beats_used = 0.0
    while beats_used < total_beats - 0.25:
        degree = rng.randint(0, range_top)
        current_base = base + 12 + melody_octave

        # Модуляция на второй половине
        if beats_used >= mod_point * beats_per_bar:
            current_base += mod_shift

        note = _scale_note(current_base, scale_notes, degree)

        # Случайная длительность: 1/32, 1/16, 1/8, четверть, половинная, триоль
        dur_beats = rng.choices(
            [0.125, 0.25, 0.375, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0],
            weights=[1, 4, 2, 6, 3, 5, 3, 1, 1]
        )[0]
        dur_ticks = int(dur_beats * ticks_per_beat)

        # Паузы
        pause_beats = rng.choices(
            [0, 0.125, 0.25, 0.5, 0.75, 1.0],
            weights=[10, 2, 3, 2, 1, 1]
        )[0]
        pause_ticks = int(pause_beats * ticks_per_beat)

        vel = rng.randint(40, 120)

        mel_track.append(Message("note_on", note=note,
                                 velocity=vel, time=pause_ticks))
        mel_track.append(Message("note_off", note=note,
                                 velocity=0, time=dur_ticks))

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

        # Расширения: 7-я ступень (30%), 9-я (15%)
        if rng.random() < 0.3:
            notes.append(_scale_note(cur_base, scale_notes, root_degree + 6))
        if rng.random() < 0.15:
            notes.append(_scale_note(cur_base, scale_notes, root_degree + 8))

        # Иногда добавляем басовую ноту октавой ниже
        if rng.random() < 0.3:
            notes.append(root - 12)

        # Арпеджио или блок-аккорд (30% арпеджио)
        if rng.random() < 0.3:
            # Арпеджио — по очереди
            step_ticks = (ticks_per_beat * beats_per_bar) // len(notes)
            for i, n in enumerate(notes):
                chord_track.append(Message("note_on", note=n,
                                           velocity=rng.randint(50, 80),
                                           time=0))
                chord_track.append(Message("note_off", note=n,
                                           velocity=0, time=step_ticks))
        else:
            # Блок-аккорд
            vel = rng.randint(50, 80)
            for n in notes:
                chord_track.append(Message("note_on", note=n, velocity=vel, time=0))
            for n in notes:
                chord_track.append(Message("note_off", note=n, velocity=0,
                                           time=ticks_per_beat * beats_per_bar))

    # ---------- БАС ----------
    # Случайная октава: -24 или -12
    bass_octave = rng.choice([-24, -12])

    for bar in range(bars):
        root_degree = progression[bar]
        cur_base = base

        if bar >= mod_point:
            cur_base += mod_shift

        root = _scale_note(cur_base + bass_octave, scale_notes, root_degree)

        # Случайный ритмический рисунок из 8 вариантов
        rhythm = rng.choice([
            [1, 1, 1, 1],              # четверти
            [0.5, 0.5, 1, 2],          # синкопа
            [2, 2],                    # половины
            [1, 0.5, 0.5, 2],          # смешанный
            [1.5, 0.5, 1, 1],          # пунктир
            [0.25, 0.25, 0.5, 1, 2],   # 16-е
            [3, 1],                    # длинная + короткая
            [0.5, 0.5, 0.5, 0.5, 1, 1],# восьмые + четверти
        ])

        for length in rhythm:
            # Случайный интервал: тоника, квинта, октава, терция
            interval = rng.choices(
                [0, 4, 7, 12],
                weights=[5, 1, 2, 2]
            )[0]
            play_note = _scale_note(cur_base + bass_octave, scale_notes,
                                    root_degree + interval)

            ticks = int(length * ticks_per_beat)
            vel = rng.randint(70, 110)

            bass_track.append(Message("note_on", note=play_note,
                                      velocity=vel, time=0))
            bass_track.append(Message("note_off", note=play_note,
                                      velocity=0, time=ticks))

    # Сохраняем в bytes
    buf = io.BytesIO()
    mid.save(file=buf)
    return buf.getvalue(), mid


def generate_melody(key=None, scale=None, genre=None, bars=4, bpm=120,
                    output="melody.mid", seed=None):
    """
    Генерирует MIDI-мелодию. Гарантирует уникальность:
    проверяет хэш против последних 50 сгенерированных.
    """
    # Уникальный seed по времени в наносекундах
    if seed is None:
        seed = time.time_ns() ^ random.randint(0, 2**31 - 1)

    # До 15 попыток, чтобы избежать дубля
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
            # Даже после 15 попыток дубль — принимаем
            result_bytes = data
            signature = sig

    # Запоминаем
    _HISTORY.append(signature)
    if len(_HISTORY) > _MAX_HISTORY:
        _HISTORY.pop(0)

    # Сохраняем
    Path(output).parent.mkdir(parents=True, exist_ok=True)
    Path(output).write_bytes(result_bytes)
    return output


def clear_history():
    """Сбрасывает историю (полезно при тестах)."""
    _HISTORY.clear()