-- ================================================================
-- pgAgent Jobs для автоматического резервного копирования
-- BibaBobaBebe Database - Bubble Tea Project
-- ================================================================
-- 
-- ИНСТРУКЦИЯ:
-- 1. Откройте pgAdmin 4
-- 2. Подключитесь к PostgreSQL 17
-- 3. Откройте Query Tool для базы 'postgres'
-- 4. Выполните весь этот скрипт
-- 5. Проверьте создание jobs в: pgAgent Jobs
--
-- ================================================================

-- Проверка существования pgAgent extension
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgagent') THEN
        RAISE EXCEPTION 'pgAgent extension not installed! Run: CREATE EXTENSION pgagent;';
    END IF;
END $$;

-- ================================================================
-- 1. ЕЖЕДНЕВНЫЙ ЛОГИЧЕСКИЙ BACKUP (2:00 AM)
-- ================================================================

DO $$
DECLARE
    v_jobid INTEGER;
    v_stepid INTEGER;
    v_schedid INTEGER;
BEGIN
    -- Удаляем существующий job если есть
    DELETE FROM pgagent.pga_job WHERE jobname = 'BubbleTea Daily Logical Backup';
    
    -- Получаем ID класса "Routine Maintenance" (или создаем если нет)
    INSERT INTO pgagent.pga_jobclass (jclname)
    SELECT 'Routine Maintenance'
    WHERE NOT EXISTS (SELECT 1 FROM pgagent.pga_jobclass WHERE jclname = 'Routine Maintenance');
    
    -- Создаем новый Job
    INSERT INTO pgagent.pga_job (
        jobjclid,
        jobname,
        jobdesc,
        jobenabled,
        jobhostagent
    ) VALUES (
        (SELECT jclid FROM pgagent.pga_jobclass WHERE jclname = 'Routine Maintenance'),
        'BubbleTea Daily Logical Backup',
        'Daily logical backup (pg_dump) of BibaBobaBebe database at 2:00 AM. Retention: 30 days.',
        true,
        ''
    ) RETURNING jobid INTO v_jobid;
    
    RAISE NOTICE 'Created Job: BubbleTea Daily Logical Backup (ID: %)', v_jobid;
    
    -- Создаем Step (шаг выполнения backup)
    INSERT INTO pgagent.pga_jobstep (
        jstjobid,
        jstname,
        jstenabled,
        jstkind,
        jstcode,
        jstconnstr,
        jstdbname,
        jstonerror
    ) VALUES (
        v_jobid,
        'Execute pg_dump backup script',
        true,
        'b',  -- 'b' = batch (Windows command)
        'cd /d "D:\POProject\Bubble Tea\database\backup_scripts" && pg_dump_backup.bat',
        '',
        '',
        'f'  -- 'f' = fail on error
    ) RETURNING jstid INTO v_stepid;
    
    RAISE NOTICE 'Created Step: Execute pg_dump backup script (ID: %)', v_stepid;
    
    -- Создаем Schedule (ежедневно в 2:00 AM)
    INSERT INTO pgagent.pga_schedule (
        jscjobid,
        jscname,
        jscenabled,
        jscstart,
        jscend,
        jscminutes,
        jschours,
        jscweekdays,
        jscmonthdays,
        jscmonths
    ) VALUES (
        v_jobid,
        'Daily at 2:00 AM',
        true,
        CURRENT_TIMESTAMP,  -- Начать с текущей даты
        NULL,  -- Без даты окончания
        ARRAY[false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false]::boolean[],  -- Минуты: 00
        ARRAY[false,false,true,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false]::boolean[],  -- Часы: 02:00
        ARRAY[true,true,true,true,true,true,true]::boolean[],  -- Все дни недели (Пн-Вс)
        ARRAY[true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true]::boolean[],  -- Все дни месяца
        ARRAY[true,true,true,true,true,true,true,true,true,true,true,true]::boolean[]  -- Все месяцы
    ) RETURNING jscid INTO v_schedid;
    
    RAISE NOTICE 'Created Schedule: Daily at 2:00 AM (ID: %)', v_schedid;
    RAISE NOTICE '✅ Daily Logical Backup Job created successfully!';
    RAISE NOTICE '';
END $$;

-- ================================================================
-- 2. ЕЖЕНЕДЕЛЬНЫЙ ФИЗИЧЕСКИЙ BACKUP (Воскресенье 3:00 AM)
-- ================================================================

DO $$
DECLARE
    v_jobid INTEGER;
    v_stepid INTEGER;
    v_schedid INTEGER;
BEGIN
    -- Удаляем существующий job если есть
    DELETE FROM pgagent.pga_job WHERE jobname = 'BubbleTea Weekly Physical Backup';
    
    -- Получаем ID класса (уже создан выше)
    -- Создаем новый Job
    INSERT INTO pgagent.pga_job (
        jobjclid,
        jobname,
        jobdesc,
        jobenabled,
        jobhostagent
    ) VALUES (
        (SELECT jclid FROM pgagent.pga_jobclass WHERE jclname = 'Routine Maintenance'),
        'BubbleTea Weekly Physical Backup',
        'Weekly physical backup (pg_basebackup) every Sunday at 3:00 AM. Retention: 7 days.',
        true,
        ''
    ) RETURNING jobid INTO v_jobid;
    
    RAISE NOTICE 'Created Job: BubbleTea Weekly Physical Backup (ID: %)', v_jobid;
    
    -- Создаем Step (шаг выполнения backup)
    INSERT INTO pgagent.pga_jobstep (
        jstjobid,
        jstname,
        jstenabled,
        jstkind,
        jstcode,
        jstconnstr,
        jstdbname,
        jstonerror
    ) VALUES (
        v_jobid,
        'Execute pg_basebackup script',
        true,
        'b',  -- 'b' = batch (Windows command)
        'cd /d "D:\POProject\Bubble Tea\database\backup_scripts" && pg_basebackup.bat',
        '',
        '',
        'f'  -- 'f' = fail on error
    ) RETURNING jstid INTO v_stepid;
    
    RAISE NOTICE 'Created Step: Execute pg_basebackup script (ID: %)', v_stepid;
    
    -- Создаем Schedule (каждое воскресенье в 3:00 AM)
    INSERT INTO pgagent.pga_schedule (
        jscjobid,
        jscname,
        jscenabled,
        jscstart,
        jscend,
        jscminutes,
        jschours,
        jscweekdays,
        jscmonthdays,
        jscmonths
    ) VALUES (
        v_jobid,
        'Weekly Sunday at 3:00 AM',
        true,
        CURRENT_TIMESTAMP,
        NULL,
        ARRAY[false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false]::boolean[],  -- Минуты: 00
        ARRAY[false,false,false,true,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false]::boolean[],  -- Часы: 03:00
        ARRAY[true,false,false,false,false,false,false]::boolean[],  -- Только воскресенье
        ARRAY[true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true]::boolean[],  -- Все дни месяца
        ARRAY[true,true,true,true,true,true,true,true,true,true,true,true]::boolean[]  -- Все месяцы
    ) RETURNING jscid INTO v_schedid;
    
    RAISE NOTICE 'Created Schedule: Weekly Sunday at 3:00 AM (ID: %)', v_schedid;
    RAISE NOTICE '✅ Weekly Physical Backup Job created successfully!';
    RAISE NOTICE '';
END $$;

-- ================================================================
-- ПРОВЕРКА СОЗДАННЫХ JOBS
-- ================================================================

SELECT 
    '=== Created pgAgent Jobs ===' AS info,
    jobid,
    jobname,
    jobenabled AS enabled,
    jobdesc AS description
FROM pgagent.pga_job
WHERE jobname LIKE 'BubbleTea%'
ORDER BY jobid;

-- ================================================================
-- ПОЛЕЗНЫЕ ЗАПРОСЫ ДЛЯ МОНИТОРИНГА
-- ================================================================

-- Просмотр расписаний:
-- SELECT j.jobname, s.jscname, s.jscenabled 
-- FROM pgagent.pga_schedule s
-- JOIN pgagent.pga_job j ON j.jobid = s.jscjobid
-- WHERE j.jobname LIKE 'BubbleTea%';

-- Просмотр истории выполнения:
-- SELECT j.jobname, l.jlgstart, l.jlgduration, l.jlgstatus
-- FROM pgagent.pga_joblog l
-- JOIN pgagent.pga_job j ON j.jobid = l.jlgjobid
-- WHERE j.jobname LIKE 'BubbleTea%'
-- ORDER BY l.jlgstart DESC LIMIT 10;

-- Ручной запуск job для теста:
-- UPDATE pgagent.pga_job SET jobnextrun = NOW() 
-- WHERE jobname = 'BubbleTea Daily Logical Backup';

-- ================================================================
-- ЗАВЕРШЕНИЕ
-- ================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ pgAgent Jobs Setup Complete!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Created Jobs:';
    RAISE NOTICE '  1. BubbleTea Daily Logical Backup';
    RAISE NOTICE '     Schedule: Every day at 2:00 AM';
    RAISE NOTICE '     Retention: 30 days';
    RAISE NOTICE '';
    RAISE NOTICE '  2. BubbleTea Weekly Physical Backup';
    RAISE NOTICE '     Schedule: Every Sunday at 3:00 AM';
    RAISE NOTICE '     Retention: 7 days';
    RAISE NOTICE '';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '  1. Check pgAgent service is running:';
    RAISE NOTICE '     sc query pgAgent';
    RAISE NOTICE '';
    RAISE NOTICE '  2. Test job manually in pgAdmin:';
    RAISE NOTICE '     pgAgent Jobs → Right click → Run now';
    RAISE NOTICE '';
    RAISE NOTICE '  3. Monitor in web interface:';
    RAISE NOTICE '     http://localhost:5000/backup';
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
END $$;

