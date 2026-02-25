"""
Telegram Notifier для системы Bubble Tea
Отправка уведомлений о резервном копировании, ошибках и мониторинге
"""

import requests
import json
from datetime import datetime
from typing import Optional, Dict, Any
import os
from pathlib import Path

class TelegramNotifier:
    """Класс для отправки уведомлений в Telegram"""
    
    def __init__(self, bot_token: str, chat_id: Optional[str] = None):
        """
        Инициализация Telegram бота
        
        Args:
            bot_token: Токен Telegram бота
            chat_id: ID чата для отправки сообщений (опционально)
        """
        self.bot_token = bot_token
        self.chat_id = chat_id
        self.api_url = f"https://api.telegram.org/bot{bot_token}"
        
    def send_message(self, message: str, chat_id: Optional[str] = None, 
                    parse_mode: str = "HTML") -> Dict[str, Any]:
        """
        Отправить текстовое сообщение
        
        Args:
            message: Текст сообщения
            chat_id: ID чата (если не указан, использует self.chat_id)
            parse_mode: Режим парсинга (HTML, Markdown)
            
        Returns:
            Ответ от Telegram API
        """
        target_chat_id = chat_id or self.chat_id
        if not target_chat_id:
            raise ValueError("Chat ID не указан")
            
        url = f"{self.api_url}/sendMessage"
        payload = {
            "chat_id": target_chat_id,
            "text": message,
            "parse_mode": parse_mode
        }
        
        try:
            response = requests.post(url, json=payload, timeout=10)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"❌ Ошибка отправки в Telegram: {e}")
            return {"ok": False, "error": str(e)}
    
    def send_backup_success(self, backup_type: str, filename: str, 
                          size: str, duration: Optional[float] = None) -> Dict[str, Any]:
        """
        Уведомление об успешном резервном копировании
        
        Args:
            backup_type: Тип бэкапа (logical/physical)
            filename: Имя файла бэкапа
            size: Размер бэкапа
            duration: Длительность операции в секундах
        """
        emoji = "💾" if backup_type == "logical" else "📦"
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        message = f"""
{emoji} <b>Резервное копирование успешно завершено</b>

📅 <b>Время:</b> {timestamp}
🔧 <b>Тип:</b> {backup_type.upper()}
📄 <b>Файл:</b> {filename}
📊 <b>Размер:</b> {size}
"""
        
        if duration:
            message += f"⏱ <b>Длительность:</b> {duration:.2f} сек\n"
        
        message += f"\n✅ <b>Статус:</b> SUCCESS"
        
        return self.send_message(message)
    
    def send_backup_failed(self, backup_type: str, error: str) -> Dict[str, Any]:
        """
        Уведомление об ошибке резервного копирования
        
        Args:
            backup_type: Тип бэкапа
            error: Описание ошибки
        """
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        message = f"""
🚨 <b>ОШИБКА РЕЗЕРВНОГО КОПИРОВАНИЯ</b>

📅 <b>Время:</b> {timestamp}
🔧 <b>Тип:</b> {backup_type.upper()}
❌ <b>Ошибка:</b> {error}

⚠️ <b>Требуется немедленное внимание!</b>
"""
        
        return self.send_message(message)
    
    def send_restore_success(self, filename: str, 
                           duration: Optional[float] = None) -> Dict[str, Any]:
        """
        Уведомление об успешном восстановлении
        
        Args:
            filename: Имя файла для восстановления
            duration: Длительность операции
        """
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        message = f"""
♻️ <b>Восстановление БД успешно завершено</b>

📅 <b>Время:</b> {timestamp}
📄 <b>Файл:</b> {filename}
"""
        
        if duration:
            message += f"⏱ <b>Длительность:</b> {duration:.2f} сек\n"
        
        message += f"\n✅ <b>Статус:</b> SUCCESS"
        
        return self.send_message(message)
    
    def send_restore_failed(self, filename: str, error: str) -> Dict[str, Any]:
        """
        Уведомление об ошибке восстановления
        """
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        message = f"""
🚨 <b>ОШИБКА ВОССТАНОВЛЕНИЯ БД</b>

📅 <b>Время:</b> {timestamp}
📄 <b>Файл:</b> {filename}
❌ <b>Ошибка:</b> {error}

⚠️ <b>Требуется немедленное внимание!</b>
"""
        
        return self.send_message(message)
    
    def send_low_storage_warning(self, free_space: str, 
                                threshold: str) -> Dict[str, Any]:
        """
        Предупреждение о низком месте на диске
        """
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        message = f"""
⚠️ <b>ПРЕДУПРЕЖДЕНИЕ: Мало места на диске</b>

📅 <b>Время:</b> {timestamp}
💾 <b>Свободно:</b> {free_space}
🎯 <b>Порог:</b> {threshold}

📌 <b>Рекомендация:</b> Очистите старые бэкапы или увеличьте дисковое пространство
"""
        
        return self.send_message(message)
    
    def send_wal_error(self, error_type: str, details: str) -> Dict[str, Any]:
        """
        Уведомление об ошибке WAL
        """
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        message = f"""
🔴 <b>ОШИБКА WAL (журнала транзакций)</b>

📅 <b>Время:</b> {timestamp}
🔧 <b>Тип ошибки:</b> {error_type}
📝 <b>Детали:</b> {details}

⚠️ <b>Требуется проверка целостности БД!</b>
"""
        
        return self.send_message(message)
    
    def send_replication_status(self, status: str, lag: Optional[str] = None,
                               replica_name: Optional[str] = None) -> Dict[str, Any]:
        """
        Уведомление о статусе репликации
        """
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        emoji = "✅" if status == "healthy" else "⚠️"
        
        message = f"""
{emoji} <b>Статус репликации</b>

📅 <b>Время:</b> {timestamp}
"""
        
        if replica_name:
            message += f"🖥 <b>Реплика:</b> {replica_name}\n"
        
        message += f"📊 <b>Статус:</b> {status.upper()}\n"
        
        if lag:
            message += f"⏱ <b>Отставание:</b> {lag}\n"
        
        return self.send_message(message)
    
    def send_database_error(self, error_type: str, error_message: str) -> Dict[str, Any]:
        """
        Уведомление об ошибке базы данных
        """
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        message = f"""
🚨 <b>ОШИБКА БАЗЫ ДАННЫХ</b>

📅 <b>Время:</b> {timestamp}
🔧 <b>Тип:</b> {error_type}
❌ <b>Сообщение:</b> {error_message}

⚠️ <b>Требуется немедленное внимание!</b>
"""
        
        return self.send_message(message)
    
    def send_performance_alert(self, metric: str, value: str, 
                             threshold: str) -> Dict[str, Any]:
        """
        Уведомление о проблемах производительности
        """
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        message = f"""
📈 <b>ПРЕДУПРЕЖДЕНИЕ: Проблемы производительности</b>

📅 <b>Время:</b> {timestamp}
📊 <b>Метрика:</b> {metric}
🔢 <b>Значение:</b> {value}
🎯 <b>Порог:</b> {threshold}

📌 <b>Рекомендация:</b> Проверьте загрузку системы
"""
        
        return self.send_message(message)
    
    def send_daily_report(self, stats: Dict[str, Any]) -> Dict[str, Any]:
        """
        Ежедневный отчёт о состоянии системы
        
        Args:
            stats: Словарь со статистикой системы
        """
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        message = f"""
📊 <b>Ежедневный отчёт системы Bubble Tea</b>

📅 <b>Дата:</b> {timestamp}

<b>Резервное копирование:</b>
💾 Всего бэкапов: {stats.get('total_backups', 0)}
📦 Logical: {stats.get('logical_count', 0)}
📦 Physical: {stats.get('physical_count', 0)}
💽 Размер: {stats.get('total_size', 'N/A')}

<b>База данных:</b>
📄 Заказов: {stats.get('total_orders', 0)}
👥 Клиентов: {stats.get('total_customers', 0)}
🛍 Товаров: {stats.get('total_products', 0)}

<b>Производительность:</b>
⚡ Время отклика: {stats.get('avg_response_time', 'N/A')}
💾 Использование БД: {stats.get('db_size', 'N/A')}

✅ <b>Система работает нормально</b>
"""
        
        return self.send_message(message)
    
    def get_chat_id(self) -> Optional[str]:
        """
        Получить chat_id для текущего бота
        Вызовите эту функцию после отправки сообщения боту
        """
        url = f"{self.api_url}/getUpdates"
        
        try:
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            if data.get("ok") and data.get("result"):
                # Получаем последнее обновление
                updates = data["result"]
                if updates:
                    last_update = updates[-1]
                    chat_id = last_update.get("message", {}).get("chat", {}).get("id")
                    if chat_id:
                        print(f"✅ Chat ID найден: {chat_id}")
                        return str(chat_id)
            
            print("⚠️ Нет сообщений. Отправьте любое сообщение боту и попробуйте снова.")
            return None
            
        except requests.exceptions.RequestException as e:
            print(f"❌ Ошибка получения chat_id: {e}")
            return None


# Глобальный экземпляр нотификатора
_notifier_instance: Optional[TelegramNotifier] = None


def get_notifier(bot_token: Optional[str] = None, 
                chat_id: Optional[str] = None) -> TelegramNotifier:
    """
    Получить глобальный экземпляр нотификатора
    """
    global _notifier_instance
    
    if _notifier_instance is None:
        # Читаем из переменных окружения если не указаны
        token = bot_token or os.getenv('TELEGRAM_BOT_TOKEN')
        chat = chat_id or os.getenv('TELEGRAM_CHAT_ID')
        
        if not token:
            raise ValueError("Telegram bot token не указан")
        
        _notifier_instance = TelegramNotifier(token, chat)
    
    return _notifier_instance


# Удобные функции для быстрого использования
def notify_backup_success(backup_type: str, filename: str, size: str, 
                         duration: Optional[float] = None) -> Dict[str, Any]:
    """Быстрое уведомление об успешном бэкапе"""
    notifier = get_notifier()
    return notifier.send_backup_success(backup_type, filename, size, duration)


def notify_backup_failed(backup_type: str, error: str) -> Dict[str, Any]:
    """Быстрое уведомление об ошибке бэкапа"""
    notifier = get_notifier()
    return notifier.send_backup_failed(backup_type, error)


def notify_error(error_type: str, error_message: str) -> Dict[str, Any]:
    """Быстрое уведомление об ошибке"""
    notifier = get_notifier()
    return notifier.send_database_error(error_type, error_message)


if __name__ == "__main__":
    """
    Тестирование Telegram нотификатора
    """
    import sys
    
    print("=" * 50)
    print("Telegram Notifier Test")
    print("=" * 50)
    
    # Ваш токен
    BOT_TOKEN = "8532707422:AAFMlkLjU7aNzelZQqPq3_UIgqvoSjliwB8"
    
    # Создаем нотификатор
    notifier = TelegramNotifier(BOT_TOKEN)
    
    # Получаем chat_id
    print("\n1️⃣ Получение Chat ID...")
    print("   Отправьте любое сообщение боту в Telegram и нажмите Enter")
    input("   Нажмите Enter после отправки сообщения боту...")
    
    chat_id = notifier.get_chat_id()
    
    if not chat_id:
        print("\n❌ Не удалось получить chat_id")
        print("   Убедитесь что вы отправили сообщение боту")
        sys.exit(1)
    
    # Сохраняем chat_id
    notifier.chat_id = chat_id
    
    # Тестируем отправку
    print(f"\n2️⃣ Тестирование отправки сообщений в chat_id: {chat_id}...")
    
    # Тест 1: Успешный бэкап
    print("\n   📤 Отправка уведомления об успешном бэкапе...")
    result = notifier.send_backup_success(
        backup_type="logical",
        filename="bibabobabebe_20240217_120000.backup",
        size="15.3 MB",
        duration=45.2
    )
    
    if result.get("ok"):
        print("   ✅ Успешно отправлено!")
    else:
        print(f"   ❌ Ошибка: {result.get('error')}")
    
    # Тест 2: Ошибка бэкапа
    print("\n   📤 Отправка уведомления об ошибке бэкапа...")
    result = notifier.send_backup_failed(
        backup_type="physical",
        error="Connection timeout: could not connect to database"
    )
    
    if result.get("ok"):
        print("   ✅ Успешно отправлено!")
    else:
        print(f"   ❌ Ошибка: {result.get('error')}")
    
    # Тест 3: Предупреждение о месте
    print("\n   📤 Отправка предупреждения о месте на диске...")
    result = notifier.send_low_storage_warning(
        free_space="2.5 GB",
        threshold="5 GB"
    )
    
    if result.get("ok"):
        print("   ✅ Успешно отправлено!")
    else:
        print(f"   ❌ Ошибка: {result.get('error')}")
    
    # Сохраняем chat_id в файл
    config_file = Path(__file__).parent / ".telegram_config"
    with open(config_file, "w") as f:
        f.write(f"TELEGRAM_BOT_TOKEN={BOT_TOKEN}\n")
        f.write(f"TELEGRAM_CHAT_ID={chat_id}\n")
    
    print(f"\n✅ Конфигурация сохранена в {config_file}")
    print(f"   Используйте эти значения в .env файле")
    print("\n" + "=" * 50)
    print("Тестирование завершено успешно!")
    print("=" * 50)

