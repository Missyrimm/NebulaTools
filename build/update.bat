@echo off
chcp 65001 >nul
title NebulaTools Updater

echo.
echo ============================================
echo   NebulaTools — Установка обновления
echo ============================================
echo.

echo [update] Ждём закрытия NebulaTools...
:waitloop
tasklist /FI "IMAGENAME eq NebulaTools.exe" 2>NUL | find /I "NebulaTools.exe" >NUL
if "%ERRORLEVEL%"=="0" (
    timeout /t 1 /nobreak >nul
    goto waitloop
)

echo [update] Копирую файлы...
:: /MIR (Mirror) удаляет файлы в приёмнике, которых нет в источнике
robocopy "%NT_EXTRACT_DIR%" "%NT_APP_DIR%" /E /MIR /NFL /NDL /NJH /NJS /nc /ns /np >nul

echo [update] Запускаю NebulaTools...
start "" "%NT_APP_DIR%\NebulaTools.exe"

echo [update] Чищу временные файлы...
timeout /t 2 /nobreak >nul
rmdir /S /Q "%NT_EXTRACT_DIR%" 2>nul

echo [update] Готово!
exit