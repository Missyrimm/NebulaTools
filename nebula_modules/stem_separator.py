"""stem_separator — UVR/Demucs через audio-separator."""
from pathlib import Path

MODELS_DIR = Path.home() / ".NebulaTools" / "models"
MODELS_DIR.mkdir(parents=True, exist_ok=True)


def separate_stems(input_file, output_dir, model="UVR-MDX-NET-Inst_HQ_3.onnx",
                   output_format="wav", progress_callback=None):
    try:
        from audio_separator.separator import Separator
    except ImportError as e:
        raise RuntimeError(f"audio-separator не установлен: {e}")

    input_file = Path(input_file)
    if not input_file.exists():
        raise FileNotFoundError(f"Файл не найден: {input_file}")

    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    def log(msg):
        print(f"[stems] {msg}", flush=True)
        if progress_callback:
            try: progress_callback(msg)
            except Exception: pass

    # --- Конвертация входа в WAV для стабильности (опционально) ---
    work_file = input_file
    temp_wav = None
    if input_file.suffix.lower() not in (".wav", ".flac"):
        try:
            from pydub import AudioSegment
            log("Конвертация входного файла в WAV...")
            audio = AudioSegment.from_file(input_file)
            temp_wav = output_dir / f"_tmp_input_{input_file.stem}.wav"
            audio.export(temp_wav, format="wav")
            work_file = temp_wav
        except Exception as e:
            log(f"Не удалось конвертировать в WAV: {e}. Продолжаем с оригиналом.")

    log(f"Загрузка модели {model}...")
    sep = Separator(
        model_file_dir=str(MODELS_DIR),
        output_dir=str(output_dir),
        output_format=output_format.upper(),
        use_soundfile=False,  # КЛЮЧЕВОЕ ИСПРАВЛЕНИЕ: отключаем soundfile
    )
    sep.load_model(model_filename=model)

    log(f"Разделение: {work_file.name}")
    out = sep.separate(str(work_file))
    log(f"Готово, файлов: {len(out)}")

    # Удаляем временный WAV
    if temp_wav and temp_wav.exists():
        try: temp_wav.unlink()
        except Exception: pass

    result = {}
    for p in out:
        p = Path(p)
        n = p.stem.lower()
        if "vocal" in n: result["vocals"] = str(p)
        elif "drum" in n: result["drums"] = str(p)
        elif "bass" in n: result["bass"] = str(p)
        elif "instrumental" in n or "inst" in n: result["instrumental"] = str(p)
        elif "guitar" in n: result["guitar"] = str(p)
        elif "piano" in n: result["piano"] = str(p)
        else: result["other"] = str(p)
    return result


def list_available_models():
    return [
        {"id": "UVR-MDX-NET-Inst_HQ_3.onnx", "name": "2 стема: вокал + инструментал (HQ)"},
        {"id": "UVR-MDX-NET-Voc_FT.onnx", "name": "Только вокал (быстро)"},
        {"id": "UVR_MDXNET_KARA_2.onnx", "name": "Караоке"},
        {"id": "htdemucs_ft.yaml", "name": "4 стема: вокал, драм, бас, другой (Demucs FT)"},
        {"id": "htdemucs.yaml", "name": "4 стема: вокал, драм, бас, другой (Demucs)"},
        {"id": "htdemucs_6s.yaml", "name": "6 стемов: вокал, драм, бас, гитара, пиано, другой"},
    ]