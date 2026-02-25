"""
Ежедневный отчёт о состоянии системы Bubble Tea
Отправляется в Telegram каждый день
"""

import psycopg2
import os
from pathlib import Path
from datetime import datetime, timedelta
import shutil
from telegram_notifier import get_notifier


def get_db_connection():
    """Получить соединение с базой данных"""
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        port=os.getenv('DB_PORT', '5432'),
        user=os.getenv('DB_USER', 'postgres'),
        password=os.getenv('DB_PASSWORD', 'your_password'),
        database=os.getenv('DB_NAME', 'bibabobabebe')
    )


def get_backup_stats():
    """Статистика резервного копирования"""
    backup_dir_logical = Path(__file__).parent / 'backups' / 'logical'
    backup_dir_physical = Path(__file__).parent / 'backups' / 'physical'
    
    stats = {
        'total_backups': 0,
        'logical_count': 0,
        'physical_count': 0,
        'total_size': 0,
        'last_backup': None
    }
    
    # Подсчёт logical backups
    if backup_dir_logical.exists():
        logical_files = list(backup_dir_logical.glob('*.backup')) + list(backup_dir_logical.glob('*.sql'))
        stats['logical_count'] = len(logical_files)
        
        for file in logical_files:
            stats['total_size'] += file.stat().st_size
        
        if logical_files:
            latest = max(logical_files, key=lambda x: x.stat().st_mtime)
            stats['last_backup'] = datetime.fromtimestamp(latest.stat().st_mtime).strftime('%Y-%m-%d %H:%M:%S')
    
    # Подсчёт physical backups
    if backup_dir_physical.exists():
        physical_dirs = [d for d in backup_dir_physical.iterdir() if d.is_dir()]
        stats['physical_count'] = len(physical_dirs)
        
        for dir in physical_dirs:
            for file in dir.rglob('*'):
                if file.is_file():
                    stats['total_size'] += file.stat().st_size
    
    stats['total_backups'] = stats['logical_count'] + stats['physical_count']
    
    # Форматирование размера
    size_bytes = stats['total_size']
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size_bytes < 1024.0:
            stats['total_size'] = f"{size_bytes:.2f} {unit}"
            break
        size_bytes /= 1024.0
    else:
        stats['total_size'] = f"{size_bytes:.2f} TB"
    
    return stats


def get_database_stats():
    """Статистика базы данных"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    stats = {}
    
    # Количество заказов
    cursor.execute("SELECT COUNT(*) FROM orders;")
    stats['total_orders'] = cursor.fetchone()[0]
    
    # Количество клиентов
    cursor.execute("SELECT COUNT(*) FROM customers;")
    stats['total_customers'] = cursor.fetchone()[0]
    
    # Количество товаров
    cursor.execute("SELECT COUNT(*) FROM products;")
    stats['total_products'] = cursor.fetchone()[0]
    
    # Количество пользователей
    cursor.execute("SELECT COUNT(*) FROM users;")
    stats['total_users'] = cursor.fetchone()[0]
    
    # Размер базы данных
    cursor.execute("SELECT pg_size_pretty(pg_database_size(current_database()));")
    stats['db_size'] = cursor.fetchone()[0]
    
    # Заказы за последние 24 часа
    cursor.execute("""
        SELECT COUNT(*) FROM orders 
        WHERE order_date >= NOW() - INTERVAL '24 hours';
    """)
    stats['orders_24h'] = cursor.fetchone()[0]
    
    # Выручка за последние 24 часа
    cursor.execute("""
        SELECT COALESCE(SUM(total_amount), 0) FROM orders 
        WHERE order_date >= NOW() - INTERVAL '24 hours' 
        AND status = 'completed';
    """)
    stats['revenue_24h'] = float(cursor.fetchone()[0])
    
    # Топ 3 товара за последние 24 часа
    cursor.execute("""
        SELECT p.product_name, SUM(oi.quantity) as total_qty
        FROM order_items oi
        JOIN products p ON oi.product_id = p.product_id
        JOIN orders o ON oi.order_id = o.order_id
        WHERE o.order_date >= NOW() - INTERVAL '24 hours'
        GROUP BY p.product_name
        ORDER BY total_qty DESC
        LIMIT 3;
    """)
    stats['top_products'] = cursor.fetchall()
    
    # Ингредиенты с низким остатком
    cursor.execute("""
        SELECT COUNT(*) FROM ingredients 
        WHERE stock_quantity <= min_quantity;
    """)
    stats['low_stock_items'] = cursor.fetchone()[0]
    
    cursor.close()
    conn.close()
    
    return stats


def get_performance_stats():
    """Статистика производительности"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    stats = {}
    
    # Количество активных соединений
    cursor.execute("""
        SELECT COUNT(*) FROM pg_stat_activity 
        WHERE state = 'active' AND pid != pg_backend_pid();
    """)
    stats['active_connections'] = cursor.fetchone()[0]
    
    # Общее количество соединений
    cursor.execute("SELECT COUNT(*) FROM pg_stat_activity;")
    stats['total_connections'] = cursor.fetchone()[0]
    
    # Статистика кэша
    cursor.execute("""
        SELECT 
            ROUND(100.0 * sum(blks_hit) / NULLIF(sum(blks_hit) + sum(blks_read), 0), 2) as cache_hit_ratio
        FROM pg_stat_database 
        WHERE datname = current_database();
    """)
    result = cursor.fetchone()
    stats['cache_hit_ratio'] = f"{result[0]:.2f}%" if result[0] else "N/A"
    
    # Размер WAL
    cursor.execute("""
        SELECT pg_size_pretty(sum(size)) 
        FROM pg_ls_waldir();
    """)
    stats['wal_size'] = cursor.fetchone()[0]
    
    # Статистика архивирования WAL
    cursor.execute("""
        SELECT archived_count, failed_count, 
               last_archived_time
        FROM pg_stat_archiver;
    """)
    archived, failed, last_time = cursor.fetchone()
    stats['wal_archived'] = archived
    stats['wal_failed'] = failed
    stats['last_archived'] = last_time.strftime('%Y-%m-%d %H:%M:%S') if last_time else 'N/A'
    
    cursor.close()
    conn.close()
    
    return stats


def get_disk_usage():
    """Использование дискового пространства"""
    # Получаем информацию о диске где находится проект
    project_dir = Path(__file__).parent
    
    try:
        total, used, free = shutil.disk_usage(project_dir)
        
        def format_bytes(bytes):
            for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
                if bytes < 1024.0:
                    return f"{bytes:.2f} {unit}"
                bytes /= 1024.0
            return f"{bytes:.2f} PB"
        
        return {
            'total': format_bytes(total),
            'used': format_bytes(used),
            'free': format_bytes(free),
            'percent': (used / total) * 100
        }
    except:
        return {
            'total': 'N/A',
            'used': 'N/A',
            'free': 'N/A',
            'percent': 0
        }


def generate_daily_report():
    """Генерация и отправка ежедневного отчёта"""
    print("=" * 70)
    print("  Генерация ежедневного отчёта - Bubble Tea System")
    print("=" * 70)
    print()
    
    try:
        # Собираем статистику
        print("📊 Сбор статистики...")
        backup_stats = get_backup_stats()
        db_stats = get_database_stats()
        perf_stats = get_performance_stats()
        disk_stats = get_disk_usage()
        
        # Формируем отчёт
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        report = f"""
📊 <b>Ежедневный отчёт системы Bubble Tea</b>

📅 <b>Дата:</b> {timestamp}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

<b>💾 РЕЗЕРВНОЕ КОПИРОВАНИЕ</b>
• Всего бэкапов: {backup_stats['total_backups']}
• Logical backups: {backup_stats['logical_count']}
• Physical backups: {backup_stats['physical_count']}
• Общий размер: {backup_stats['total_size']}
• Последний бэкап: {backup_stats['last_backup'] or 'N/A'}

<b>🗄 БАЗА ДАННЫХ</b>
• Размер БД: {db_stats['db_size']}
• Заказов (всего): {db_stats['total_orders']}
• Заказов (24ч): {db_stats['orders_24h']}
• Выручка (24ч): ${db_stats['revenue_24h']:.2f}
• Клиентов: {db_stats['total_customers']}
• Товаров: {db_stats['total_products']}
• Пользователей: {db_stats['total_users']}
"""

        # Топ товары
        if db_stats['top_products']:
            report += "\n<b>🏆 ТОП-3 ТОВАРА (24ч)</b>\n"
            for i, (name, qty) in enumerate(db_stats['top_products'], 1):
                report += f"  {i}. {name}: {qty} шт.\n"
        
        # Предупреждение о низком остатке
        if db_stats['low_stock_items'] > 0:
            report += f"\n⚠️ <b>Низкий остаток:</b> {db_stats['low_stock_items']} ингредиентов\n"
        
        report += f"""
<b>⚡ ПРОИЗВОДИТЕЛЬНОСТЬ</b>
• Активные соединения: {perf_stats['active_connections']}
• Всего соединений: {perf_stats['total_connections']}
• Cache hit ratio: {perf_stats['cache_hit_ratio']}
• Размер WAL: {perf_stats['wal_size']}
• WAL архивировано: {perf_stats['wal_archived']}
• WAL ошибки: {perf_stats['wal_failed']}
"""

        if perf_stats['wal_failed'] > 0:
            report += f"⚠️ <b>Внимание:</b> Обнаружены ошибки архивирования WAL!\n"
        
        report += f"""
<b>💿 ДИСКОВОЕ ПРОСТРАНСТВО</b>
• Всего: {disk_stats['total']}
• Использовано: {disk_stats['used']} ({disk_stats['percent']:.1f}%)
• Свободно: {disk_stats['free']}
"""

        # Предупреждение о месте на диске
        if disk_stats['percent'] > 80:
            report += f"\n⚠️ <b>Внимание:</b> Диск заполнен более чем на 80%!\n"
        
        report += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        
        # Общий статус
        if (db_stats['low_stock_items'] == 0 and 
            perf_stats['wal_failed'] == 0 and 
            disk_stats['percent'] < 80):
            report += "✅ <b>Система работает нормально</b>"
        else:
            report += "⚠️ <b>Требуется внимание</b>"
        
        # Отправляем отчёт в Telegram
        print("📤 Отправка отчёта в Telegram...")
        notifier = get_notifier()
        result = notifier.send_message(report)
        
        if result.get("ok"):
            print("✅ Отчёт успешно отправлен!")
        else:
            print(f"❌ Ошибка отправки: {result.get('error')}")
        
        # Сохраняем отчёт в файл
        report_dir = Path(__file__).parent / "reports"
        report_dir.mkdir(exist_ok=True)
        
        report_file = report_dir / f"daily_report_{datetime.now().strftime('%Y%m%d')}.txt"
        
        # Очищаем HTML теги для текстового файла
        import re
        clean_report = re.sub(r'<[^>]+>', '', report)
        
        with open(report_file, "w", encoding="utf-8") as f:
            f.write(clean_report)
        
        print(f"💾 Отчёт сохранён: {report_file}")
        print()
        print("=" * 70)
        print("  Генерация отчёта завершена успешно!")
        print("=" * 70)
        
    except Exception as e:
        print(f"❌ ОШИБКА: {e}")
        
        # Отправляем уведомление об ошибке
        try:
            notifier = get_notifier()
            notifier.send_message(
                f"❌ <b>Ошибка генерации ежедневного отчёта</b>\n\n"
                f"⏰ Время: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
                f"❌ Ошибка: {str(e)[:200]}"
            )
        except:
            pass
        
        raise


if __name__ == "__main__":
    try:
        generate_daily_report()
    except KeyboardInterrupt:
        print("\n⚠️ Прервано пользователем")
    except Exception as e:
        print(f"\n❌ КРИТИЧЕСКАЯ ОШИБКА: {e}")
        import traceback
        traceback.print_exc()

