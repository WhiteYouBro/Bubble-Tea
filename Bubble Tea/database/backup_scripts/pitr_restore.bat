@echo off
REM ===================================================================
REM Point-in-Time Recovery (PITR) Script для PostgreSQL
REM Восстановление базы данных на определённый момент времени
REM ===================================================================

setlocal EnableDelayedExpansion

echo ===================================================================
echo   Point-in-Time Recovery (PITR) для Bubble Tea Database
echo ===================================================================
echo.

REM Настройки PostgreSQL
set PGHOST=localhost
set PGPORT=5432
set PGUSER=postgres
set PGPASSWORD=your_password
set PGDATABASE=bibabobabebe

REM Пути
set BASE_BACKUP_DIR=%~dp0..\..\backups\physical
set WAL_ARCHIVE_DIR=%~dp0..\..\backups\wal_archive
set RESTORE_DIR=%~dp0..\..\restore_temp
set LOG_FILE=%~dp0..\..\reports\pitr_restore_%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%.log

REM Очищаем переменные
set LOG_FILE=%LOG_FILE: =0%

echo [%date% %time%] Начало PITR восстановления >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

REM Проверка наличия WAL архива
if not exist "%WAL_ARCHIVE_DIR%" (
    echo ОШИБКА: WAL архив не найден: %WAL_ARCHIVE_DIR%
    echo [ERROR] WAL архив не найден >> "%LOG_FILE%"
    goto :error
)

REM Показываем доступные физические бэкапы
echo Доступные физические бэкапы:
echo.
set /a count=0
for /d %%d in ("%BASE_BACKUP_DIR%\*") do (
    set /a count+=1
    echo !count!. %%~nxd
)

if !count! equ 0 (
    echo ОШИБКА: Физические бэкапы не найдены
    echo [ERROR] Физические бэкапы не найдены >> "%LOG_FILE%"
    goto :error
)

echo.
set /p backup_choice="Выберите номер бэкапа (1-!count!): "

REM Получаем выбранный бэкап
set /a current=0
for /d %%d in ("%BASE_BACKUP_DIR%\*") do (
    set /a current+=1
    if !current! equ %backup_choice% (
        set SELECTED_BACKUP=%%d
    )
)

if not defined SELECTED_BACKUP (
    echo ОШИБКА: Неверный выбор
    goto :error
)

echo.
echo Выбранный бэкап: %SELECTED_BACKUP%
echo [INFO] Выбранный бэкап: %SELECTED_BACKUP% >> "%LOG_FILE%"

REM Запрашиваем целевое время восстановления
echo.
echo Введите целевое время восстановления:
echo Формат: YYYY-MM-DD HH:MM:SS (например: 2024-02-17 14:30:00)
echo Или нажмите Enter для восстановления до последнего доступного момента
echo.
set /p target_time="Целевое время: "

if not defined target_time (
    set recovery_target=latest
    echo [INFO] Восстановление до последнего момента >> "%LOG_FILE%"
) else (
    set recovery_target=%target_time%
    echo [INFO] Целевое время: %target_time% >> "%LOG_FILE%"
)

echo.
echo ВНИМАНИЕ: Эта операция остановит PostgreSQL и заменит текущую БД!
echo.
set /p confirm="Вы уверены? (yes/no): "

if /i not "%confirm%"=="yes" (
    echo Операция отменена пользователем
    echo [INFO] Операция отменена >> "%LOG_FILE%"
    goto :end
)

echo.
echo ===================================================================
echo   Начало восстановления PITR
echo ===================================================================
echo.

REM Шаг 1: Остановка PostgreSQL
echo [1/6] Остановка PostgreSQL...
echo [STEP 1] Остановка PostgreSQL >> "%LOG_FILE%"

net stop postgresql-x64-17 >> "%LOG_FILE%" 2>&1

if errorlevel 1 (
    echo ОШИБКА: Не удалось остановить PostgreSQL
    echo [ERROR] Не удалось остановить PostgreSQL >> "%LOG_FILE%"
    goto :error
)

timeout /t 5 /nobreak > nul
echo    Готово!

REM Шаг 2: Очистка data директории
echo [2/6] Очистка data директории...
echo [STEP 2] Очистка data директории >> "%LOG_FILE%"

set DATA_DIR=C:\Program Files\PostgreSQL\17\data

if exist "%DATA_DIR%" (
    rd /s /q "%DATA_DIR%" >> "%LOG_FILE%" 2>&1
)

mkdir "%DATA_DIR%" >> "%LOG_FILE%" 2>&1
echo    Готово!

REM Шаг 3: Распаковка базового бэкапа
echo [3/6] Распаковка базового бэкапа...
echo [STEP 3] Распаковка бэкапа >> "%LOG_FILE%"

REM Используем tar для распаковки
cd /d "%DATA_DIR%"
tar -xzf "%SELECTED_BACKUP%\base.tar.gz" -C "%DATA_DIR%" >> "%LOG_FILE%" 2>&1

if errorlevel 1 (
    echo ОШИБКА: Не удалось распаковать бэкап
    echo [ERROR] Ошибка распаковки >> "%LOG_FILE%"
    goto :error
)
echo    Готово!

REM Шаг 4: Создание recovery.signal
echo [4/6] Создание recovery.signal...
echo [STEP 4] Создание recovery.signal >> "%LOG_FILE%"

echo. > "%DATA_DIR%\recovery.signal"
echo    Готово!

REM Шаг 5: Настройка postgresql.conf для восстановления
echo [5/6] Настройка recovery параметров...
echo [STEP 5] Настройка recovery параметров >> "%LOG_FILE%"

echo. >> "%DATA_DIR%\postgresql.auto.conf"
echo # Recovery settings for PITR >> "%DATA_DIR%\postgresql.auto.conf"
echo restore_command = 'copy "%WAL_ARCHIVE_DIR%\%%f" "%%p"' >> "%DATA_DIR%\postgresql.auto.conf"

if "%recovery_target%"=="latest" (
    echo recovery_target = 'immediate' >> "%DATA_DIR%\postgresql.auto.conf"
) else (
    echo recovery_target_time = '%recovery_target%' >> "%DATA_DIR%\postgresql.auto.conf"
)

echo recovery_target_action = 'promote' >> "%DATA_DIR%\postgresql.auto.conf"
echo    Готово!

REM Шаг 6: Запуск PostgreSQL
echo [6/6] Запуск PostgreSQL...
echo [STEP 6] Запуск PostgreSQL >> "%LOG_FILE%"

net start postgresql-x64-17 >> "%LOG_FILE%" 2>&1

if errorlevel 1 (
    echo ОШИБКА: Не удалось запустить PostgreSQL
    echo [ERROR] Не удалось запустить PostgreSQL >> "%LOG_FILE%"
    goto :error
)

timeout /t 10 /nobreak > nul
echo    Готово!

echo.
echo ===================================================================
echo   PITR восстановление завершено успешно!
echo ===================================================================
echo.
echo Целевое время: %recovery_target%
echo Лог файл: %LOG_FILE%
echo.
echo PostgreSQL выполнит восстановление WAL файлов при запуске.
echo Проверьте логи PostgreSQL для подтверждения успешного восстановления.
echo.

REM Отправка Telegram уведомления об успехе
echo [SUCCESS] PITR восстановление завершено >> "%LOG_FILE%"

REM Можно добавить вызов Python скрипта для отправки уведомления
REM python -c "from telegram_notifier import notify_restore_success; notify_restore_success('%SELECTED_BACKUP%', 0)"

goto :end

:error
echo.
echo ===================================================================
echo   ОШИБКА при PITR восстановлении!
echo ===================================================================
echo.
echo Проверьте лог файл: %LOG_FILE%
echo.
echo [ERROR] PITR восстановление завершилось с ошибкой >> "%LOG_FILE%"

REM Отправка Telegram уведомления об ошибке
REM python -c "from telegram_notifier import notify_error; notify_error('PITR Restore', 'Recovery failed')"

pause
exit /b 1

:end
echo [%date% %time%] Завершение скрипта >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"
pause
endlocal

