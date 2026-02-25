"""
Скрипт настройки Telegram уведомлений для Bubble Tea
Помогает получить chat_id и сохранить конфигурацию
"""

import sys
from pathlib import Path
from telegram_notifier import TelegramNotifier

def main():
    print("=" * 70)
    print("  Настройка Telegram уведомлений для системы Bubble Tea")
    print("=" * 70)
    
    # Ваш токен бота
    BOT_TOKEN = "8532707422:AAFMlkLjU7aNzelZQqPq3_UIgqvoSjliwB8"
    
    print(f"\n📱 Токен бота: {BOT_TOKEN}")
    print("\n" + "=" * 70)
    print("  ШАГ 1: Получение Chat ID")
    print("=" * 70)
    print("\nДля получения chat_id вам нужно:")
    print("  1. Открыть Telegram")
    print("  2. Найти вашего бота (используйте токен выше)")
    print("  3. Отправить боту любое сообщение (например: /start)")
    print("  4. Вернуться сюда и нажать Enter")
    
    input("\n👉 Нажмите Enter после отправки сообщения боту...")
    
    # Создаем нотификатор
    notifier = TelegramNotifier(BOT_TOKEN)
    
    # Получаем chat_id
    print("\n🔍 Поиск chat_id...")
    chat_id = notifier.get_chat_id()
    
    if not chat_id:
        print("\n❌ ОШИБКА: Не удалось получить chat_id")
        print("\nВозможные причины:")
        print("  • Вы не отправили сообщение боту")
        print("  • Токен бота неверный")
        print("  • Нет соединения с интернетом")
        print("\nПопробуйте снова!")
        sys.exit(1)
    
    print(f"✅ Chat ID успешно получен: {chat_id}")
    
    # Тестируем отправку
    print("\n" + "=" * 70)
    print("  ШАГ 2: Тестирование отправки сообщений")
    print("=" * 70)
    
    notifier.chat_id = chat_id
    
    tests = [
        {
            'name': 'Успешный бэкап',
            'func': lambda: notifier.send_backup_success(
                backup_type="logical",
                filename="test_bibabobabebe_20240217.backup",
                size="12.5 MB",
                duration=34.7
            )
        },
        {
            'name': 'Ошибка бэкапа',
            'func': lambda: notifier.send_backup_failed(
                backup_type="physical",
                error="Test error: connection timeout"
            )
        },
        {
            'name': 'Предупреждение о месте',
            'func': lambda: notifier.send_low_storage_warning(
                free_space="3.2 GB",
                threshold="5 GB"
            )
        },
        {
            'name': 'Ежедневный отчёт',
            'func': lambda: notifier.send_daily_report({
                'total_backups': 25,
                'logical_count': 15,
                'physical_count': 10,
                'total_size': '2.5 GB',
                'total_orders': 156,
                'total_customers': 78,
                'total_products': 42,
                'avg_response_time': '45ms',
                'db_size': '156 MB'
            })
        }
    ]
    
    print("\n📤 Отправка тестовых уведомлений...")
    print("   Проверьте Telegram - вы должны получить 4 сообщения\n")
    
    for i, test in enumerate(tests, 1):
        print(f"   {i}. {test['name']}...", end=' ')
        result = test['func']()
        
        if result.get("ok"):
            print("✅")
        else:
            print(f"❌ {result.get('error', 'Unknown error')}")
    
    # Сохраняем конфигурацию
    print("\n" + "=" * 70)
    print("  ШАГ 3: Сохранение конфигурации")
    print("=" * 70)
    
    # Сохраняем в .telegram_config
    config_file = Path(__file__).parent / ".telegram_config"
    with open(config_file, "w", encoding="utf-8") as f:
        f.write(f"TELEGRAM_BOT_TOKEN={BOT_TOKEN}\n")
        f.write(f"TELEGRAM_CHAT_ID={chat_id}\n")
    
    print(f"\n✅ Конфигурация сохранена в {config_file.name}")
    
    # Проверяем наличие .env
    env_file = Path(__file__).parent / ".env"
    
    if env_file.exists():
        print(f"\n📝 Обновление {env_file.name}...")
        
        # Читаем существующий .env
        with open(env_file, "r", encoding="utf-8") as f:
            env_content = f.read()
        
        # Проверяем наличие Telegram настроек
        if "TELEGRAM_BOT_TOKEN" not in env_content:
            with open(env_file, "a", encoding="utf-8") as f:
                f.write(f"\n# Telegram уведомления\n")
                f.write(f"TELEGRAM_BOT_TOKEN={BOT_TOKEN}\n")
                f.write(f"TELEGRAM_CHAT_ID={chat_id}\n")
            print("   ✅ Telegram настройки добавлены в .env")
        else:
            print("   ℹ️  Telegram настройки уже есть в .env")
            print("   👉 Обновите их вручную если нужно:")
            print(f"      TELEGRAM_BOT_TOKEN={BOT_TOKEN}")
            print(f"      TELEGRAM_CHAT_ID={chat_id}")
    else:
        print(f"\n⚠️  Файл .env не найден")
        print("   Создайте .env файл и добавьте:")
        print(f"\n   TELEGRAM_BOT_TOKEN={BOT_TOKEN}")
        print(f"   TELEGRAM_CHAT_ID={chat_id}")
    
    # Итоговая информация
    print("\n" + "=" * 70)
    print("  ✅ НАСТРОЙКА ЗАВЕРШЕНА УСПЕШНО!")
    print("=" * 70)
    
    print("\n📋 Что дальше:")
    print("   1. Telegram уведомления теперь активны")
    print("   2. Бэкапы будут автоматически отправлять уведомления")
    print("   3. Ошибки БД будут сообщаться в Telegram")
    print("   4. Можно настроить ежедневные отчёты")
    
    print("\n📚 Использование в коде:")
    print("   from telegram_notifier import get_notifier")
    print("   notifier = get_notifier()")
    print("   notifier.send_backup_success(...)")
    
    print("\n" + "=" * 70)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Прервано пользователем")
        sys.exit(0)
    except Exception as e:
        print(f"\n\n❌ КРИТИЧЕСКАЯ ОШИБКА: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

