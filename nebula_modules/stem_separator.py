"""
stem_separator — разделение аудио на стемы через audio-separator (UVR MDX-Net).
"""
import os
from pathlib import Path

MODELS_DIR = Path.home() / ".NebulaTools" / "models"
MODELS_DIR.mkdir(parents=True, exist_ok=True)


def separate_stems(input_file, output_dir, model="UVR-MDX-NET-Inst_HQ_3.onnx",
                   progress_callback=None):
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
            try:
                progress_callback(msg)
            except Exception:
                pass

    log(f"Загрузка модели {model}...")
    sep = Separator(model_file_dir=str(MODELS_DIR),
                    output_dir=str(output_dir),
                    output_format="WAV",
                    use_soundfile=True)
    sep.load_model(model_filename=model)

    log(f"Разделение: {input_file.name}")
    out = sep.separate(str(input_file))
    log(f"Готово, файлов: {len(out)}")

    result = {}
    for p in out:
        p = Path(p)
        n = p.stem.lower()
        if "vocal" in n:
            result["vocals"] = str(p)
        elif "drum" in n:
            result["drums"] = str(p)
        elif "bass" in n:
            result["bass"] = str(p)
        elif "instrumental" in n or "inst" in n:
            result["instrumental"] = str(p)
        else:
            result["other"] = str(p)
    return result


def list_available_models():
    """
    Возвращает список моделей, которые точно поддерживаются audio-separator.
    """
    return [
        {"id": "UVR-MDX-NET-Inst_HQ_3.onnx",
         "name": "2 стема: вокал + инструментал (HQ)"},
        {"id": "UVR-MDX-NET-Voc_FT.onnx",
         "name": "Только вокал (быстро)"},
        {"id": "UVR_MDXNET_KARA_2.onnx",
         "name": "Караоке (вокал + инструментал)"},
    ]