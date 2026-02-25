# 🤖 Автоматические Backup через pgAgent

## 📋 Что такое pgAgent?

**pgAgent** - это планировщик задач для PostgreSQL, который работает как служба Windows и выполняет SQL-скрипты и shell-команды по расписанию.

**Преимущества над Task Scheduler:**
- ✅ Нативная интеграция с PostgreSQL
- ✅ Хранит расписание в БД
- ✅ Логирование выполнения в БД
- ✅ Управление через pgAdmin
- ✅ Работает как служба Windows

---

## 🚀 Установка pgAgent

### 1. Установка через pgAdmin

**A. Откройте pgAdmin 4**

**B. Установите pgAgent:**
1. `File → Preferences → Paths → Binary Paths`
2. Найдите путь к PostgreSQL bin (обычно `C:\Program Files\PostgreSQL\17\bin`)
3. Закройте Preferences

**C. Создайте pgAgent extension:**
1. В pgAdmin откройте сервер → Databases → postgres
2. Правый клик на `postgres` → `Query Tool`
3. Выполните:
```sql
CREATE EXTENSION IF NOT EXISTS pgagent;
```

**D. Регистрация службы pgAgent:**

Откройте **Command Prompt от имени администратора**:

```cmd
cd "C:\Program Files\PostgreSQL\17\bin"

pgagent INSTALL pgAgent -u postgres -p admin1235 hostaddr=127.0.0.1 port=5432 dbname=postgres
```

**E. Запустите службу:**
```cmd
sc start pgAgent
```

Или через Services (`services.msc`):
- Найдите `pgAgent`
- Правый клик → Start
- Правый клик → Properties → Startup type: Automatic

---

## 📝 Создание Job для ежедневного логического backup

### Через pgAdmin GUI:

**1. Откройте pgAdmin → Servers → PostgreSQL 17**

**2. Найдите pgAgent Jobs:**
```
PostgreSQL 17 → pgAgent Jobs (правый клик) → Create → pgAgent Job
```

**3. Вкладка "General":**
- Name: `BubbleTea Daily Logical Backup`
- Enabled: ✅
- Job class: `Routine Maintenance`
- Host agent: (оставить пустым)
- Comment: `Daily logical backup of BibaBobaBebe database at 2:00 AM`

**4. Вкладка "Steps":**

Нажмите `+` (Add) для создания шага:

**Step 1:**
- Name: `Execute Logical Backup Script`
- Enabled: ✅
- Kind: `Batch`
- Code:
```batch
cd /d "D:\POProject\Bubble Tea\database\backup_scripts"
call pg_dump_backup.bat
```
- On error: `Fail`

**5. Вкладка "Schedules":**

Нажмите `+` (Add) для создания расписания:

- Name: `Daily at 2 AM`
- Enabled: ✅
- Start: `2024-11-02 02:00:00` (сегодняшняя дата)
- End: (оставить пустым)
- Days: Выберите все дни недели (Mon-Sun)
- Times: `02:00:00`
- Exceptions: (оставить пустым)

**6. Сохраните:** Нажмите `Save`

---

## 📝 Создание Job для еженедельного физического backup

Повторите те же шаги, но:

**General:**
- Name: `BubbleTea Weekly Physical Backup`
- Comment: `Weekly physical backup every Sunday at 3:00 AM`

**Steps - Code:**
```batch
cd /d "D:\POProject\Bubble Tea\database\backup_scripts"
call pg_basebackup.bat
```

**Schedules:**
- Name: `Weekly Sunday at 3 AM`
- Days: Выберите только `Sunday`
- Times: `03:00:00`

---

## 🗃️ SQL-скрипт для создания Jobs (альтернатива GUI)

Если хотите создать через SQL:

```sql
-- ================================================
-- 1. ЕЖЕДНЕВНЫЙ ЛОГИЧЕСКИЙ BACKUP
-- ================================================

-- Создаем Job
INSERT INTO pgagent.pga_job (
    jobname,
    jobdesc,
    jobenabled,
    jobhostagent
) VALUES (
    'BubbleTea Daily Logical Backup',
    'Daily logical backup of BibaBobaBebe database at 2:00 AM',
    true,
    ''
) RETURNING jobid;

-- Запомните jobid (например, 1)
-- Используйте его ниже вместо <JOBID>

-- Создаем Step (шаг выполнения)
INSERT INTO pgagent.pga_jobstep (
    jstjobid,
    jstname,
    jstenabled,
    jstkind,
    jstcode,
    jstdbname,
    jstonerror
) VALUES (
    <JOBID>,  -- Замените на реальный ID
    'Execute Logical Backup Script',
    true,
    'b',  -- 'b' = batch
    'cd /d "D:\POProject\Bubble Tea\database\backup_scripts"' || E'\n' || 'call pg_dump_backup.bat',
    '',
    'f'  -- 'f' = fail on error
);

-- Создаем Schedule (расписание)
INSERT INTO pgagent.pga_schedule (
    jscjobid,
    jscname,
    jscenabled,
    jscstart,
    jscminutes,
    jschours,
    jscweekdays,
    jscmonthdays,
    jscmonths
) VALUES (
    <JOBID>,  -- Замените на реальный ID
    'Daily at 2 AM',
    true,
    '2024-11-02 02:00:00',  -- Начальная дата
    ARRAY[false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false],  -- Все минуты false
    ARRAY[false,false,true,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false],  -- Час 2 = true
    ARRAY[true,true,true,true,true,true,true],  -- Все дни недели
    ARRAY[true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true],  -- Все дни месяца
    ARRAY[true,true,true,true,true,true,true,true,true,true,true,true]  -- Все месяцы
);

-- ================================================
-- 2. ЕЖЕНЕДЕЛЬНЫЙ ФИЗИЧЕСКИЙ BACKUP
-- ================================================

-- Создаем Job
INSERT INTO pgagent.pga_job (
    jobname,
    jobdesc,
    jobenabled,
    jobhostagent
) VALUES (
    'BubbleTea Weekly Physical Backup',
    'Weekly physical backup every Sunday at 3:00 AM',
    true,
    ''
) RETURNING jobid;

-- Используйте новый jobid для следующих вставок

-- Создаем Step
INSERT INTO pgagent.pga_jobstep (
    jstjobid,
    jstname,
    jstenabled,
    jstkind,
    jstcode,
    jstdbname,
    jstonerror
) VALUES (
    <JOBID2>,  -- Новый ID для физического backup
    'Execute Physical Backup Script',
    true,
    'b',
    'cd /d "D:\POProject\Bubble Tea\database\backup_scripts"' || E'\n' || 'call pg_basebackup.bat',
    '',
    'f'
);

-- Создаем Schedule (только воскресенье)
INSERT INTO pgagent.pga_schedule (
    jscjobid,
    jscname,
    jscenabled,
    jscstart,
    jscminutes,
    jschours,
    jscweekdays,
    jscmonthdays,
    jscmonths
) VALUES (
    <JOBID2>,
    'Weekly Sunday at 3 AM',
    true,
    '2024-11-02 03:00:00',
    ARRAY[false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false],
    ARRAY[false,false,false,true,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false],  -- Час 3 = true
    ARRAY[true,false,false,false,false,false,false],  -- Только воскресенье
    ARRAY[true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true],
    ARRAY[true,true,true,true,true,true,true,true,true,true,true,true]
);
```

---

## 📊 Просмотр Jobs и логов

### Список всех Jobs:
```sql
SELECT 
    jobid,
    jobname,
    jobenabled,
    jobdesc
FROM pgagent.pga_job
ORDER BY jobid;
```

### История выполнения:
```sql
SELECT 
    j.jobname,
    l.jlgstart,
    l.jlgduration,
    l.jlgstatus
FROM pgagent.pga_joblog l
JOIN pgagent.pga_job j ON j.jobid = l.jlgjobid
ORDER BY l.jlgstart DESC
LIMIT 20;
```

### Логи последнего запуска:
```sql
SELECT 
    j.jobname,
    s.jstname AS step_name,
    l.jslstart,
    l.jslduration,
    l.jslstatus,
    l.jslresult,
    l.jsloutput
FROM pgagent.pga_jobsteplog l
JOIN pgagent.pga_jobstep s ON s.jstid = l.jsljstid
JOIN pgagent.pga_job j ON j.jobid = s.jstjobid
ORDER BY l.jslstart DESC
LIMIT 10;
```

---

## ✅ Проверка работы

### 1. Ручной запуск Job для теста:

В pgAdmin:
```
pgAgent Jobs → BubbleTea Daily Logical Backup → Правый клик → Run now
```

### 2. Проверка логов:
```sql
SELECT * FROM pgagent.pga_joblog 
WHERE jlgjobid = (SELECT jobid FROM pgagent.pga_job WHERE jobname = 'BubbleTea Daily Logical Backup')
ORDER BY jlgstart DESC LIMIT 1;
```

### 3. Проверка файлов backup:
```powershell
cd "D:\POProject\Bubble Tea\backups\logical"
dir /o-d
```

---

## 🔧 Решение проблем

### Job не запускается:

**1. Проверьте службу pgAgent:**
```cmd
sc query pgAgent
```

Если не запущена:
```cmd
sc start pgAgent
```

**2. Проверьте логи Windows:**
```
Event Viewer → Windows Logs → Application
Фильтр по источнику: pgAgent
```

**3. Проверьте путь к скриптам:**
```sql
SELECT jstcode FROM pgagent.pga_jobstep 
WHERE jstname = 'Execute Logical Backup Script';
```

### Job запускается, но backup не создается:

**1. Проверьте вывод скрипта:**
```sql
SELECT jsloutput FROM pgagent.pga_jobsteplog 
ORDER BY jslstart DESC LIMIT 1;
```

**2. Запустите скрипт вручную:**
```cmd
cd "D:\POProject\Bubble Tea\database\backup_scripts"
pg_dump_backup.bat
```

**3. Проверьте права доступа:**
- Служба pgAgent должна иметь права на папку `backups/`
- PostgreSQL пользователь должен иметь права на чтение БД

---

## 📧 Email уведомления (опционально)

Создайте дополнительный step для отправки email при ошибке:

```sql
-- Добавьте step после основного
INSERT INTO pgagent.pga_jobstep (
    jstjobid,
    jstname,
    jstenabled,
    jstkind,
    jstcode,
    jstonerror
) VALUES (
    <JOBID>,
    'Send Error Notification',
    true,
    's',  -- 's' = SQL
    $$
    DO $$
    BEGIN
        -- Здесь можно добавить логику отправки email
        -- Например через pg_notify или внешний скрипт
        RAISE NOTICE 'Backup failed! Check logs.';
    END $$;
    $$,
    'f'
);
```

---

## 🎯 Итоговая структура

После настройки у вас будет:

**pgAgent Jobs:**
- ✅ `BubbleTea Daily Logical Backup` - каждый день в 2:00 AM
- ✅ `BubbleTea Weekly Physical Backup` - каждое воскресенье в 3:00 AM

**Автоматическая очистка:**
- ✅ Встроена в .bat скрипты (30 дней / 7 дней)

**Логирование:**
- ✅ Все выполнения записываются в `pgagent.pga_joblog`
- ✅ Детальные логи в `pgagent.pga_jobsteplog`

**Мониторинг:**
- ✅ Через pgAdmin (pgAgent Jobs)
- ✅ Через SQL запросы
- ✅ Через веб-интерфейс (http://localhost:5000/backup)

---

## 📝 Удаление Jobs (если нужно)

```sql
-- Просмотр всех jobs
SELECT jobid, jobname FROM pgagent.pga_job;

-- Удаление job (каскадно удалит steps и schedules)
DELETE FROM pgagent.pga_job WHERE jobid = <JOBID>;
```

---

**✅ pgAgent - профессиональное решение для автоматических backup в PostgreSQL!**

