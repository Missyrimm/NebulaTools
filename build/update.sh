#!/bin/bash
echo "[update] Ждём закрытия NebulaTools..."

while pgrep -x "NebulaTools" > /dev/null; do
    sleep 1
done

echo "[update] Приложение закрыто, копирую файлы..."
cp -R "$NT_EXTRACT_DIR"/* "$NT_APP_DIR/"

# Права на исполнение для бинарника
if [ -f "$NT_APP_DIR/NebulaTools" ]; then
    chmod +x "$NT_APP_DIR/NebulaTools"
fi

echo "[update] Запускаю обновлённый NebulaTools..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    open "$NT_APP_DIR/NebulaTools.app" 2>/dev/null || "$NT_APP_DIR/NebulaTools" &
else
    "$NT_APP_DIR/NebulaTools" &
fi

echo "[update] Чищу временные файлы..."
rm -rf "$NT_EXTRACT_DIR"

exit 0