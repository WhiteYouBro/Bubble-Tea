@echo off
REM Запуск Alertmanager Webhook сервера для Telegram уведомлений

echo ===================================================================
echo   Alertmanager Webhook Server для Telegram
echo ===================================================================
echo.

REM Активация venv если есть
if exist venv\Scripts\activate.bat (
    echo Activating virtual environment...
    call venv\Scripts\activate.bat
)

REM Запуск сервера
echo Starting webhook server on port 5001...
echo.
python alertmanager_webhook.py

pause

