import pygame
import threading

pygame.mixer.init(frequency=44100, size=-16, channels=2, buffer=512)

_current = None
_lock = threading.Lock()


def play(path):
    """Проигрывает файл. Останавливает предыдущий."""
    global _current
    with _lock:
        pygame.mixer.music.stop()
        try:
            pygame.mixer.music.load(str(path))
            pygame.mixer.music.play()
            _current = str(path)
        except Exception as e:
            print(f"Ошибка воспроизведения: {e}")
            _current = None


def stop():
    with _lock:
        pygame.mixer.music.stop()


def is_playing():
    return pygame.mixer.music.get_busy()