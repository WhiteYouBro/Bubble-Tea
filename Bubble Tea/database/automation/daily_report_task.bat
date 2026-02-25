@echo off
REM ===================================================================
REM Автоматический запуск ежедневного отчёта
REM Используется с Task Scheduler для ежедневной отправки отчётов
REM ===================================================================

setlocal

echo ===================================================================
echo   Ежедневный отчёт Bubble Tea - %date% %time%
echo ===================================================================
echo.

REM Путь к Python (измените если Python установлен в другом месте)
set PYTHON_PATH=python

REM Путь к проекту
set PROJECT_DIR=%~dp0..\..

REM Активируем виртуальное окружение если есть
if exist "%PROJECT_DIR%\venv\Scripts\activate.bat" (
    echo Активация виртуального окружения...
    call "%PROJECT_DIR%\venv\Scripts\activate.bat"
)

REM Переходим в директорию проекта
cd /d "%PROJECT_DIR%"

REM Загружаем переменные окружения из .env если есть
if exist ".env" (
    echo Загрузка переменных окружения из .env...
    for /f "usebackq tokens=1,2 delims==" %%a in (".env") do (
        set "%%a=%%b"
    )
)

REM Запускаем скрипт отчёта
echo.
echo Запуск генерации отчёта...
echo.

%PYTHON_PATH% daily_report.py

REM Проверяем результат
if errorlevel 1 (
    echo.
    echo ===================================================================
    echo   ОШИБКА: Не удалось создать отчёт
    echo ===================================================================
    echo.
    
    REM Логируем ошибку
    echo [%date% %time%] ERROR: Daily report failed >> reports\automation.log
    
    exit /b 1
) else (
    echo.
    echo ===================================================================
    echo   Отчёт успешно отправлен!
    echo ===================================================================
    echo.
    
    REM Логируем успех
    echo [%date% %time%] SUCCESS: Daily report sent >> reports\automation.log
)

endlocal

