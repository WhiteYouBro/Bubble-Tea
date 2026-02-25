"""Быстрая проверка Telegram уведомлений"""
import os
from pathlib import Path

# Загрузка .env
env_file = Path(__file__).parent / ".env"
if env_file.exists():
    with open(env_file) as f:
        for line in f:
            if '=' in line and not line.strip().startswith('#'):
                key, value = line.strip().split('=', 1)
                os.environ[key] = value

print("=" * 60)
print("Проверка Telegram конфигурации")
print("=" * 60)

# Проверка токена и chat_id
bot_token = os.getenv('TELEGRAM_BOT_TOKEN')
chat_id = os.getenv('TELEGRAM_CHAT_ID')

print(f"BOT_TOKEN: {'✅ Найден' if bot_token else '❌ НЕ НАЙДЕН'}")
print(f"CHAT_ID: {'✅ Найден' if chat_id else '❌ НЕ НАЙДЕН'}")

if not bot_token:
    print("\n❌ TELEGRAM_BOT_TOKEN не найден в .env")
    print("Добавьте: TELEGRAM_BOT_TOKEN=8532707422:AAFMlkLjU7aNzelZQqPq3_UIgqvoSjliwB8")
    exit(1)

if not chat_id:
    print("\n⚠️ TELEGRAM_CHAT_ID не найден. Запустите:")
    print("   python setup_telegram.py")
    exit(1)

print("\n" + "=" * 60)
print("Отправка тестового сообщения...")
print("=" * 60)

try:
    from telegram_notifier import get_notifier
    
    notifier = get_notifier()
    result = notifier.send_message("🧪 <b>Тест уведомлений Bubble Tea</b>\n\nСистема работает!")
    
    if result.get('ok'):
        print("\n✅ УСПЕХ! Проверьте Telegram")
    else:
        print(f"\n❌ ОШИБКА: {result.get('error', 'Unknown')}")
        
except Exception as e:
    print(f"\n❌ ОШИБКА: {e}")
    import traceback
    traceback.print_exc()

