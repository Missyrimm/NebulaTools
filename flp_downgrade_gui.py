"""
Автоматический даунгрейд через FL-Downgrader V2 (pywinauto + pyautogui).
"""
import subprocess
import sys
import time
from pathlib import Path

import psutil
import pyautogui
from pywinauto import Desktop
from pywinauto.keyboard import send_keys

pyautogui.FAILSAFE = False

EXE_PATH = r"C:\Users\youngweepo\Downloads\FL-Downgrader V2.exe"
EXE_NAME = "FL-Downgrader V2.exe"


def log(msg):
    print(f"[DG] {msg}", flush=True)


# ============================================================
#  Утилиты
# ============================================================
def kill_existing():
    for proc in psutil.process_iter(["name"]):
        try:
            if proc.info["name"] == EXE_NAME:
                log(f"Убиваю старый процесс PID={proc.info['pid']}")
                proc.kill()
        except Exception:
            pass
    time.sleep(1)


def bring_to_front(win):
    """Принудительно поднимает окно на передний план."""
    try:
        win.set_focus()
    except Exception:
        pass
    try:
        import win32gui
        import win32con
        hwnd = win.handle
        win32gui.ShowWindow(hwnd, win32con.SW_RESTORE)
        win32gui.SetForegroundWindow(hwnd)
    except Exception as e:
        log(f"    SetForegroundWindow: {e}")
    time.sleep(0.5)


def find_main_window(pid, timeout=15):
    end = time.time() + timeout
    while time.time() < end:
        try:
            for w in Desktop(backend="uia").windows(process=pid):
                try:
                    if "DOWNGRADER" in w.window_text().upper():
                        return Desktop(backend="uia").window(handle=w.handle)
                except Exception:
                    continue
        except Exception:
            pass
        time.sleep(0.3)
    return None


def find_any_dialog(timeout=1.0):
    end = time.time() + timeout
    while time.time() < end:
        try:
            for w in Desktop(backend="uia").windows():
                try:
                    title = w.window_text()
                    title_low = title.lower()
                    if not title:
                        continue
                    try:
                        spec = Desktop(backend="uia").window(handle=w.handle)
                    except Exception:
                        continue

                    if ("fruity" in title_low or "parametric" in title_low or
                            "удал" in title_low or "несовмест" in title_low or
                            "warning" in title_low or "предупреж" in title_low):
                        return ("confirm", spec)

                    if w.class_name() == "#32770":
                        if "сохран" in title_low or "save" in title_low:
                            return ("save", spec)
                        if "открыт" in title_low or "open" in title_low:
                            return ("open", spec)
                        try:
                            if spec.child_window(title="Сохранить",
                                                 control_type="Button").exists(timeout=0.2):
                                return ("save", spec)
                            if spec.child_window(title="Открыть",
                                                 control_type="Button").exists(timeout=0.2):
                                return ("open", spec)
                        except Exception:
                            pass
                except Exception:
                    continue
        except Exception:
            pass
        time.sleep(0.2)
    return None


def _get_filename_edit(dlg):
    for auto_id in ("1148", "1001"):
        try:
            combo = dlg.child_window(auto_id=auto_id, control_type="ComboBox")
            if combo.exists(timeout=0.3):
                try:
                    edit = combo.child_window(control_type="Edit")
                    if edit.exists(timeout=0.3):
                        return edit
                except Exception:
                    pass
                return combo
        except Exception:
            pass

    try:
        edits = dlg.descendants(control_type="Edit")
        if edits:
            return edits[-1]
    except Exception:
        pass

    return None


def _fill_filename_field(dlg, file_path):
    path_str = str(file_path)
    edit = _get_filename_edit(dlg)

    if edit is None:
        log("    ⚠ поле 'Имя файла' не найдено")
        return False

    try:
        edit.set_focus()
        time.sleep(0.15)
        edit.set_edit_text(path_str)
        time.sleep(0.4)
        return True
    except Exception as e:
        log(f"    set_edit_text: {e}")

    try:
        import pyperclip
        pyperclip.copy(path_str)
        edit.set_focus()
        time.sleep(0.15)
        edit.click_input()
        time.sleep(0.2)
        send_keys("^a")
        time.sleep(0.1)
        send_keys("^v")
        time.sleep(0.4)
        return True
    except Exception as e:
        log(f"    буфер: {e}")

    return False


def _wait_dialog_closed(dlg, timeout=5):
    end = time.time() + timeout
    while time.time() < end:
        try:
            if not dlg.exists(timeout=0.3):
                return True
        except Exception:
            return True
        time.sleep(0.2)
    return False


def handle_open_dialog(dlg, file_path):
    log(f"  Диалог открытия: {Path(file_path).name}")
    try:
        dlg.set_focus()
        time.sleep(0.3)
    except Exception:
        pass

    if not _fill_filename_field(dlg, file_path):
        log("    ⚠ не удалось ввести путь")
        try:
            send_keys("{ESC}")
        except Exception:
            pass
        return False

    send_keys("{ENTER}")
    time.sleep(1.5)

    if _wait_dialog_closed(dlg, timeout=5):
        log("    диалог закрылся")
        return True

    send_keys("{ENTER}")
    time.sleep(1.5)
    return _wait_dialog_closed(dlg, timeout=3)


def handle_save_dialog(dlg, output_path):
    log(f"  Диалог сохранения: {Path(output_path).name}")
    try:
        dlg.set_focus()
        time.sleep(0.3)
    except Exception:
        pass

    if not _fill_filename_field(dlg, output_path):
        try:
            send_keys("{ESC}")
        except Exception:
            pass
        return False

    clicked = False
    for btn in ("Сохранить", "Save", "OK"):
        try:
            b = dlg.child_window(title=btn, control_type="Button")
            if b.exists(timeout=0.3):
                b.click_input()
                log(f"    Нажал '{btn}'")
                clicked = True
                break
        except Exception:
            continue

    if not clicked:
        send_keys("{ENTER}")
        log("    Нажал Enter")

    time.sleep(1.5)
    return _wait_dialog_closed(dlg, timeout=5)


def handle_confirm_dialog(dlg):
    log("  Диалог подтверждения")
    for btn in ("Да", "Yes", "OK"):
        try:
            b = dlg.child_window(title=btn, control_type="Button")
            if b.exists(timeout=0.3):
                b.click_input()
                log(f"    Нажал '{btn}'")
                time.sleep(0.6)
                return True
        except Exception:
            continue
    try:
        dlg.set_focus()
        time.sleep(0.2)
        send_keys("{ENTER}")
        time.sleep(0.6)
        return True
    except Exception:
        return False


def get_window_texts(win):
    try:
        return [t.window_text() for t in win.descendants(control_type="Text")]
    except Exception:
        return []


def get_numeric_texts(win):
    """Возвращает тексты, содержащие цифры (версии, значения)."""
    texts = get_window_texts(win)
    result = []
    for t in texts:
        if any(c.isdigit() for c in t):
            result.append(t)
    return result


def wait_file_analyzed(win, timeout=30):
    log("Жду анализа файла...")
    end = time.time() + timeout
    while time.time() < end:
        texts = get_numeric_texts(win)
        joined = " ".join(texts)
        import re
        if re.search(r"\d{1,2}\.\d{1,2}\.\d{1,4}(?:\.\d{1,6})?", joined):
            if "Чтение" not in " ".join(get_window_texts(win)):
                log("  Анализ завершён")
                return True
        time.sleep(0.5)
    log("  ⚠ Таймаут анализа")
    return False


def set_combo_value(win, combo_title, value):
    """
    Устанавливает значение в Tauri ComboBox через физический клик.
    Возвращает True если значение появилось в текстах окна.
    """
    log(f"  Устанавливаю '{combo_title}' = {value}...")

    for attempt in range(1, 4):
        log(f"    попытка {attempt}")

        try:
            bring_to_front(win)
            time.sleep(0.3)

            combo = win.child_window(title=combo_title, control_type="ComboBox")
            rect = combo.rectangle()

            # Клик в ЛЕВУЮ часть ComboBox (там input, а не стрелка)
            cx = rect.left + 30
            cy = (rect.top + rect.bottom) // 2

            log(f"    клик в ({cx}, {cy})")
            pyautogui.click(cx, cy)
            time.sleep(0.6)

            # Тройной клик — выделяет всё содержимое input
            pyautogui.tripleClick(cx, cy)
            time.sleep(0.5)

            # Стереть
            send_keys("{BACKSPACE}")
            time.sleep(0.3)

            # Ввести значение посимвольно
            log(f"    ввод: {value}")
            for ch in value:
                if ch == ".":
                    send_keys("{.}")
                else:
                    send_keys(ch)
                time.sleep(0.06)

            time.sleep(0.5)

            # Проверка 1: наше значение в текстах окна
            numeric = get_numeric_texts(win)
            log(f"    числа в окне: {numeric}")

            if value in " ".join(numeric):
                log(f"    ✓ установлено")
                send_keys("{TAB}")
                time.sleep(0.3)
                return True

            # Нажимаем Tab (фиксируем) и проверяем снова
            send_keys("{TAB}")
            time.sleep(0.6)

            numeric = get_numeric_texts(win)
            log(f"    числа после Tab: {numeric}")

            if value in " ".join(numeric):
                log(f"    ✓ установлено после Tab")
                return True

            log(f"    ✗ не установилось")

        except Exception as e:
            log(f"    ошибка: {e}")
            time.sleep(0.5)

    log(f"  ⚠ Не удалось установить '{combo_title}'")
    return False


def _find_file_by_mask(input_path, version, build):
    patterns = [
        f"{input_path.stem}_for-FL-{version}.{build}*{input_path.suffix}",
        f"{input_path.stem}_for-FL-*{input_path.suffix}",
        f"{input_path.stem}_converted*{input_path.suffix}",
    ]
    candidates = []
    for pat in patterns:
        for p in input_path.parent.glob(pat):
            try:
                if p.resolve() != input_path.resolve() and p.stat().st_size > 0:
                    candidates.append(p)
            except Exception:
                continue

    if candidates:
        candidates.sort(key=lambda p: p.stat().st_mtime, reverse=True)
        return candidates[0]
    return None


# ============================================================
#  Основная функция
# ============================================================
def downgrade(input_flp, version, build, output_flp=None, progress_callback=None):
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
        output_flp = input_path.parent / \
            f"{input_path.stem}_for-FL-{version}.{build}{input_path.suffix}"
    else:
        output_flp = Path(output_flp).resolve()

    if output_flp.exists():
        output_flp.unlink()

    log(f"Файл: {input_path.name}")
    log(f"Целевая версия: {version}.{build}")

    _report(2)
    kill_existing()

    log("\n[1/7] Запуск FL-Downgrader...")
    _report(5)
    proc = subprocess.Popen([EXE_PATH])
    pid = proc.pid

    win = find_main_window(pid, timeout=15)
    if not win:
        raise RuntimeError("Главное окно не появилось")
    log(f"  Окно найдено (PID {pid})")
    bring_to_front(win)
    time.sleep(1.5)
    _report(15)

    # ============ Выбор файла ============
    log("\n[2/7] Выбор файла...")
    btn = win.child_window(
        title="Выбрать или перетащить FLP-файл",
        control_type="Button"
    )
    btn.click_input()
    time.sleep(1.5)

    result = None
    end = time.time() + 10
    while time.time() < end:
        result = find_any_dialog(timeout=1.0)
        if result and result[0] == "open":
            break
        time.sleep(0.3)

    if not result or result[0] != "open":
        raise RuntimeError("Диалог открытия не появился")

    if not handle_open_dialog(result[1], input_path):
        raise RuntimeError("Не удалось выбрать файл")
    _report(25)

    # ============ Анализ ============
    log("\n[3/7] Жду анализ...")
    if not wait_file_analyzed(win, timeout=30):
        log("  Продолжаю")
    _report(35)

    # ============ Версия ============
    log("\n[4/7] Устанавливаю версию...")
    version_ok = set_combo_value(win, "Версия FL Studio", version)
    if not version_ok:
        log("  ⚠ Версия не установилась, работаю с дефолтной")
    _report(45)

    # ============ Сборка ============
    log("\n[5/7] Устанавливаю сборку...")
    build_ok = set_combo_value(win, "Сборка", build)
    if not build_ok:
        log("  ⚠ Сборка не установилась, работаю с дефолтной")
    _report(55)

    # ============ Конвертация ============
    log("\n[6/7] Конвертирую...")
    bring_to_front(win)
    time.sleep(0.5)
    conv_btn = win.child_window(title="Конвертировать", control_type="Button")
    conv_btn.click_input()
    time.sleep(1.5)
    _report(65)

    # ============ Ожидание ============
    log("\n[7/7] Ожидаю результат...")
    start = time.time()
    last_size = 0
    stable_ticks = 0
    save_attempts = 0
    last_save_time = 0
    no_dialog_since = time.time()

    while time.time() - start < 120:
        if output_flp.exists():
            try:
                size = output_flp.stat().st_size
                if size > 0 and size == last_size:
                    stable_ticks += 1
                    if stable_ticks >= 2:
                        log(f"  ✓ Файл готов: {output_flp.name} ({size} байт)")
                        break
                else:
                    stable_ticks = 0
                last_size = size
            except Exception:
                pass

        result = find_any_dialog(timeout=0.5)
        if result:
            no_dialog_since = time.time()
            kind, dlg = result
            if kind == "confirm":
                handle_confirm_dialog(dlg)
                _report(75)
            elif kind == "save":
                if time.time() - last_save_time > 2:
                    save_attempts += 1
                    last_save_time = time.time()

                    if save_attempts > 2:
                        log(f"  ⚠ {save_attempts} попыток — ищу по маске")
                        found = _find_file_by_mask(input_path, version, build)
                        if found:
                            log(f"  Нашёл: {found.name}")
                            if found.resolve() != output_flp.resolve():
                                if output_flp.exists():
                                    output_flp.unlink()
                                found.rename(output_flp)
                            break
                        else:
                            try:
                                send_keys("{ESC}")
                            except Exception:
                                pass
                            time.sleep(0.5)
                            if save_attempts > 4:
                                raise RuntimeError("Сохранение не удаётся")
                            continue

                    handle_save_dialog(dlg, output_flp)
                    _report(90)
            elif kind == "open":
                try:
                    send_keys("{ESC}")
                except Exception:
                    pass
                time.sleep(0.5)
        else:
            if time.time() - no_dialog_since > 10 and not output_flp.exists():
                texts = get_window_texts(win)
                if "Чтение" not in " ".join(texts):
                    found = _find_file_by_mask(input_path, version, build)
                    if found:
                        log(f"  Нашёл по маске: {found.name}")
                        if found.resolve() != output_flp.resolve():
                            if output_flp.exists():
                                output_flp.unlink()
                            found.rename(output_flp)
                        break
            time.sleep(0.3)

    if not output_flp.exists():
        found = _find_file_by_mask(input_path, version, build)
        if found:
            log(f"  Финальный поиск: {found.name}")
            if found.resolve() != output_flp.resolve():
                if output_flp.exists():
                    output_flp.unlink()
                found.rename(output_flp)

    if not output_flp.exists():
        raise RuntimeError(f"Файл не создан: {output_flp}")

    log(f"\n✓ Готово: {output_flp.name} ({output_flp.stat().st_size} байт)")
    _report(100)

    try:
        win.child_window(title="Закрыть", control_type="Button").click_input()
    except Exception:
        try:
            win.close()
        except Exception:
            proc.terminate()

    return str(output_flp)


if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Использование: flp_downgrade_gui.py input.flp VERSION BUILD [output.flp]")
        sys.exit(1)

    try:
        result = downgrade(
            sys.argv[1], sys.argv[2], sys.argv[3],
            sys.argv[4] if len(sys.argv) > 4 else None
        )
        print(f"\nРезультат: {result}")
    except Exception as e:
        print(f"\n✗ Ошибка: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)