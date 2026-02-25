@echo off
REM ===================================================================
REM Настройка автоматического ежедневного отчёта в Task Scheduler
REM ===================================================================

echo ===================================================================
echo   Настройка автоматического ежедневного отчёта
echo ===================================================================
echo.

REM Проверка прав администратора
net session >nul 2>&1
if errorlevel 1 (
    echo ОШИБКА: Требуются права администратора!
    echo Запустите этот скрипт от имени администратора.
    pause
    exit /b 1
)

set TASK_NAME=BubbleTeaDailyReport
set SCRIPT_PATH=%~dp0daily_report_task.bat

echo Создание задачи в Task Scheduler...
echo Имя задачи: %TASK_NAME%
echo Скрипт: %SCRIPT_PATH%
echo.

REM Удаляем существующую задачу если есть
schtasks /query /tn "%TASK_NAME%" >nul 2>&1
if not errorlevel 1 (
    echo Удаление существующей задачи...
    schtasks /delete /tn "%TASK_NAME%" /f
)

REM Создаём новую задачу
REM Запуск каждый день в 09:00
schtasks /create /tn "%TASK_NAME%" /tr "\"%SCRIPT_PATH%\"" /sc daily /st 09:00 /ru SYSTEM /rl HIGHEST /f

if errorlevel 1 (
    echo.
    echo ОШИБКА: Не удалось создать задачу!
    pause
    exit /b 1
)

echo.
echo ===================================================================
echo   Задача успешно создана!
echo ===================================================================
echo.
echo Параметры:
echo   - Имя: %TASK_NAME%
echo   - Расписание: Ежедневно в 09:00
echo   - Пользователь: SYSTEM
echo   - Приоритет: HIGHEST
echo.
echo Для изменения времени запуска:
echo   1. Откройте Task Scheduler (taskschd.msc)
echo   2. Найдите задачу "%TASK_NAME%"
echo   3. Измените триггер на нужное время
echo.
echo Для проверки работы задачи:
echo   schtasks /run /tn "%TASK_NAME%"
echo.

pause

