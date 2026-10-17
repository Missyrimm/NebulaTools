"""
flp_native — обёртка над flp_native/downgrade.py.
Даёт API как у flp_downgrade_gui.downgrade() — для backend.py.
"""
import sys
from pathlib import Path

# Добавляем папку flp_native в PATH для импорта модулей
_NATIVE_DIR = Path(__file__).parent / "flp_native"
if str(_NATIVE_DIR) not in sys.path:
    sys.path.insert(0, str(_NATIVE_DIR))

from flp_events import Flp, FlpError  # noqa: E402
from downgrade import downgrade as _downgrade  # noqa: E402
from versions import VERSIONS  # noqa: E402


def _parse_version(target_version: str):
    """
    '24.1.0.4225'  -> ('24.1', 4225)
    '24.1.2.4430'  -> ('24.1.2', 4430)
    '25.2.5.5319'  -> ('25.2.5', 5319)
    """
    parts = target_version.split(".")
    if len(parts) < 3:
        raise ValueError(f"Неправильный формат версии: {target_version}")

    # Последняя часть — build
    try:
        build = int(parts[-1])
    except ValueError:
        raise ValueError(f"Build должен быть числом: {target_version}")

    ver_parts = parts[:-1]

    # Отрезаем хвостовые ".0" (24.1.0 -> 24.1)
    while len(ver_parts) > 2 and ver_parts[-1] == "0":
        ver_parts = ver_parts[:-1]

    ver_short = ".".join(ver_parts)
    return ver_short, build


def convert_native(input_flp, target_version, output_flp=None,
                   progress_callback=None):
    """
    Конвертирует FLP через нативный парсер.
    Возвращает путь к результату.
    """
    def _report(p):
        if progress_callback:
            try:
                progress_callback(p)
            except Exception:
                pass

    input_path = Path(input_flp).resolve()
    if not input_path.exists():
        raise FileNotFoundError(f"Файл не найден: {input_path}")

    if output_flp is None:
        output_flp = input_path.parent / f"{input_path.stem}_native.flp"
    else:
        output_flp = Path(output_flp).resolve()

    ver_short, build = _parse_version(target_version)

    if ver_short not in VERSIONS:
        raise ValueError(
            f"Версия {ver_short} не поддерживается нативным парсером. "
            f"Доступные: {', '.join(sorted(VERSIONS.keys(), reverse=True)[:10])}..."
        )

    _report(10)

    data = input_path.read_bytes()
    _report(25)

    flp = Flp.parse(data)
    _report(40)

    result, report = _downgrade(flp, ver_short, build)
    _report(75)

    out_bytes = result.to_bytes()
    _report(90)

    output_flp.write_bytes(out_bytes)
    _report(100)

    print(f"[native] Удалено EQ2: {report.get('removed_eq2', 0)}", flush=True)
    unresolved = report.get("unresolved", [])
    if unresolved:
        for u in unresolved:
            print(f"[native] ⚠ Не решено: {u}", flush=True)

    return str(output_flp)


def is_version_supported(target_version: str) -> bool:
    """Проверяет, поддерживает ли нативный парсер версию."""
    try:
        ver_short, _ = _parse_version(target_version)
        return ver_short in VERSIONS
    except Exception:
        return False


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Использование: flp_native.py input.flp 24.1.0.4225 [output.flp]")
        sys.exit(1)

    try:
        out = convert_native(
            sys.argv[1], sys.argv[2],
            sys.argv[3] if len(sys.argv) > 3 else None
        )
        print(f"\nГотово: {out}")
    except Exception as e:
        print(f"\n✗ Ошибка: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)