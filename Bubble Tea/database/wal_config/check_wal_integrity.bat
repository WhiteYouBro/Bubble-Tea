@echo off
REM ===================================================================
REM Скрипт проверки целостности WAL файлов
REM Проверяет WAL архив на наличие ошибок и пробелов в последовательности
REM ===================================================================

setlocal EnableDelayedExpansion

echo ===================================================================
echo   Проверка целостности WAL файлов - Bubble Tea Database
echo ===================================================================
echo.

REM Настройки
set PGHOST=localhost
set PGPORT=5432
set PGUSER=postgres
set PGPASSWORD=your_password
set PGDATABASE=bibabobabebe

set WAL_ARCHIVE_DIR=%~dp0..\..\backups\wal_archive
set LOG_FILE=%~dp0..\..\reports\wal_integrity_%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%.log
set LOG_FILE=%LOG_FILE: =0%

echo [%date% %time%] Начало проверки целостности WAL >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

REM Проверка наличия WAL архива
if not exist "%WAL_ARCHIVE_DIR%" (
    echo ОШИБКА: WAL архив не найден: %WAL_ARCHIVE_DIR%
    echo [ERROR] WAL архив не найден >> "%LOG_FILE%"
    goto :error
)

echo [1/5] Подсчёт WAL файлов...
echo [STEP 1] Подсчёт WAL файлов >> "%LOG_FILE%"

set /a wal_count=0
for %%f in ("%WAL_ARCHIVE_DIR%\*") do (
    set /a wal_count+=1
)

echo    Найдено WAL файлов: %wal_count%
echo [INFO] Найдено WAL файлов: %wal_count% >> "%LOG_FILE%"

if %wal_count% equ 0 (
    echo ОШИБКА: WAL файлы не найдены
    echo [ERROR] WAL файлы не найдены >> "%LOG_FILE%"
    goto :error
)

REM Проверка размеров файлов
echo.
echo [2/5] Проверка размеров WAL файлов...
echo [STEP 2] Проверка размеров >> "%LOG_FILE%"

set /a suspicious_files=0
for %%f in ("%WAL_ARCHIVE_DIR%\*") do (
    set file_size=%%~zf
    
    REM WAL файлы обычно 16 MB (16777216 bytes)
    REM Проверяем файлы меньше 1 MB (подозрительно маленькие)
    if !file_size! lss 1048576 (
        echo    Подозрительный файл: %%~nxf (размер: !file_size! байт)
        echo [WARNING] Подозрительный файл: %%~nxf >> "%LOG_FILE%"
        set /a suspicious_files+=1
    )
)

if %suspicious_files% gtr 0 (
    echo    Найдено подозрительных файлов: %suspicious_files%
    echo [WARNING] Найдено подозрительных файлов: %suspicious_files% >> "%LOG_FILE%"
) else (
    echo    Все файлы имеют корректный размер
)

REM Проверка текущего состояния WAL
echo.
echo [3/5] Проверка текущего состояния WAL в PostgreSQL...
echo [STEP 3] Проверка состояния WAL >> "%LOG_FILE%"

psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -c "SELECT pg_current_wal_lsn();" >> "%LOG_FILE%" 2>&1

if errorlevel 1 (
    echo ОШИБКА: Не удалось подключиться к PostgreSQL
    echo [ERROR] Не удалось подключиться к PostgreSQL >> "%LOG_FILE%"
    goto :error
)

echo    Готово!

REM Проверка статистики архивирования
echo.
echo [4/5] Проверка статистики архивирования...
echo [STEP 4] Статистика архивирования >> "%LOG_FILE%"

psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -t -c "SELECT 'Archived: ' || archived_count::text || ', Failed: ' || failed_count::text FROM pg_stat_archiver;" >> "%LOG_FILE%" 2>&1

REM Получаем количество неудачных попыток
for /f "tokens=*" %%a in ('psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -t -c "SELECT failed_count FROM pg_stat_archiver;"') do (
    set failed_count=%%a
)

set failed_count=%failed_count: =%

if %failed_count% gtr 0 (
    echo    ВНИМАНИЕ: Обнаружены неудачные попытки архивирования: %failed_count%
    echo [WARNING] Неудачные попытки архивирования: %failed_count% >> "%LOG_FILE%"
    
    REM Отправка Telegram уведомления
    echo [ACTION] Отправка Telegram уведомления >> "%LOG_FILE%"
    python -c "from telegram_notifier import notify_error; notify_error('WAL Archiving', 'Failed attempts: %failed_count%')" 2>> "%LOG_FILE%"
) else (
    echo    Ошибок архивирования не обнаружено
)

REM Детальная проверка последних WAL файлов
echo.
echo [5/5] Проверка последних WAL файлов...
echo [STEP 5] Проверка последних файлов >> "%LOG_FILE%"

psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -c "SELECT name, size, modification FROM pg_ls_waldir() ORDER BY modification DESC LIMIT 10;" >> "%LOG_FILE%" 2>&1

echo    Готово!

REM Итоговая статистика
echo.
echo ===================================================================
echo   Результаты проверки целостности WAL
echo ===================================================================
echo.
echo Всего WAL файлов в архиве: %wal_count%
echo Подозрительных файлов: %suspicious_files%
echo Неудачных попыток архивирования: %failed_count%
echo.
echo Детальный отчёт сохранён в: %LOG_FILE%
echo.

if %suspicious_files% gtr 0 (
    echo РЕКОМЕНДАЦИЯ: Проверьте подозрительные файлы вручную
)

if %failed_count% gtr 0 (
    echo РЕКОМЕНДАЦИЯ: Проверьте настройки archive_command в postgresql.conf
)

echo [SUCCESS] Проверка завершена >> "%LOG_FILE%"
echo [%date% %time%] Завершение проверки >> "%LOG_FILE%"

goto :end

:error
echo.
echo ===================================================================
echo   ОШИБКА при проверке целостности WAL!
echo ===================================================================
echo.
echo Проверьте лог файл: %LOG_FILE%
echo.
echo [ERROR] Проверка завершилась с ошибкой >> "%LOG_FILE%"

REM Отправка Telegram уведомления об ошибке
python -c "from telegram_notifier import notify_error; notify_error('WAL Integrity Check', 'Check failed - see logs')" 2>> "%LOG_FILE%"

pause
exit /b 1

:end
pause
endlocal

