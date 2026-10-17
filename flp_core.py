"""
flp_core — ядро конвертации FL Studio проектов между версиями.
Работает с .flp и .zip.
Меняет версию в заголовке FLP-файла (ASCII + UTF-16, если есть).
"""
import re
import zipfile
import tempfile
from pathlib import Path


VERSION_ASCII_RE = re.compile(rb"\b\d{1,2}\.\d{1,2}\.\d{1,4}(?:\.\d{1,6})?\b")


def find_all(data, needle):
    out, start = [], 0
    while True:
        i = data.find(needle, start)
        if i == -1:
            return out
        out.append(i)
        start = i + 1


def detect_version_bytes(data: bytes) -> str:
    m = VERSION_ASCII_RE.search(data[:100])
    return m.group(0).decode("ascii") if m else "?"


def detect_version_flp(path) -> str:
    return detect_version_bytes(Path(path).read_bytes())


def detect_version_zip(path) -> str:
    with zipfile.ZipFile(path, "r") as z:
        flp = next((n for n in z.namelist() if n.lower().endswith(".flp")), None)
        if not flp:
            return "?"
        with z.open(flp) as f:
            return detect_version_bytes(f.read(100))


def convert_flp_bytes(data: bytearray, target_version: str) -> bytes:
    if data[0:4] != b"FLhd":
        raise ValueError("Это не FLP-файл: нет сигнатуры FLhd")

    m = VERSION_ASCII_RE.search(bytes(data[:100]))
    if not m:
        raise ValueError("Не нашёл версию в заголовке")

    old_ascii = m.group(0)
    old_str = old_ascii.decode("ascii")

    if len(target_version) != len(old_str):
        raise ValueError(
            f"Длина целевой версии ({len(target_version)}) должна быть "
            f"{len(old_str)} символов. Исходная: {old_str}"
        )

    # Замена ASCII-версии во всех местах
    new_ascii = target_version.encode("ascii")
    for p in find_all(data, old_ascii):
        data[p:p + len(old_ascii)] = new_ascii

    # Замена UTF-16 версии (опционально — PyFLP сохраняет без неё)
    prefix = "FL Studio ".encode("utf-16le")
    pos = data.find(prefix)
    if pos != -1:
        i = pos + len(prefix)
        while i + 2 <= len(data):
            lo, hi = data[i], data[i + 1]
            if hi != 0 or not (48 <= lo <= 57 or lo == 46):
                break
            i += 2

        old_full = bytes(data[pos:i])
        if old_full:
            old_full_str = old_full.decode("utf-16le")
            tail = old_full_str[len("FL Studio "):][len(old_str):]
            new_full = ("FL Studio " + target_version + tail).encode("utf-16le")
            if len(new_full) == len(old_full):
                for p in find_all(data, old_full):
                    data[p:p + len(old_full)] = new_full

    return bytes(data)


def convert_flp_file(src, dst, target_version: str):
    src, dst = Path(src), Path(dst)
    data = bytearray(src.read_bytes())
    new_data = convert_flp_bytes(data, target_version)
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_bytes(new_data)
    return dst


def convert_zip(src, dst, target_version: str):
    src, dst = Path(src), Path(dst)
    dst.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        with zipfile.ZipFile(src, "r") as z:
            z.extractall(tmp_path)

        flps = list(tmp_path.rglob("*.flp"))
        if not flps:
            raise ValueError("В архиве нет .flp-файла")

        for flp in flps:
            data = bytearray(flp.read_bytes())
            flp.write_bytes(convert_flp_bytes(data, target_version))

        with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as z:
            for f in tmp_path.rglob("*"):
                if f.is_file():
                    z.write(f, f.relative_to(tmp_path))

    return dst