"""
Автоматический Failover для PostgreSQL репликации
Мониторинг мастера и автоматическое переключение на реплику при сбое
"""

import psycopg2
import time
import sys
import os
from pathlib import Path
from datetime import datetime
import subprocess

# Добавляем путь к telegram_notifier
sys.path.append(str(Path(__file__).parent.parent.parent))

try:
    from telegram_notifier import get_notifier
    TELEGRAM_AVAILABLE = True
except ImportError:
    print("⚠️ Telegram notifier не доступен")
    TELEGRAM_AVAILABLE = False


class FailoverManager:
    """Менеджер автоматического failover"""
    
    def __init__(self, master_config: dict, standby_config: dict, 
                 check_interval: int = 30):
        """
        Инициализация менеджера
        
        Args:
            master_config: Настройки подключения к мастеру
            standby_config: Настройки подключения к standby
            check_interval: Интервал проверки в секундах
        """
        self.master_config = master_config
        self.standby_config = standby_config
        self.check_interval = check_interval
        self.master_down_count = 0
        self.max_failures = 3  # Количество неудачных проверок до failover
        self.failover_executed = False
        
        self.log_file = Path(__file__).parent.parent.parent / "reports" / "failover.log"
        self.log_file.parent.mkdir(exist_ok=True)
        
    def log(self, message: str, level: str = "INFO"):
        """Логирование с временной меткой"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_message = f"[{timestamp}] [{level}] {message}"
        print(log_message)
        
        with open(self.log_file, "a", encoding="utf-8") as f:
            f.write(log_message + "\n")
    
    def check_master_health(self) -> bool:
        """
        Проверка здоровья мастера
        
        Returns:
            True если мастер доступен, False если недоступен
        """
        try:
            conn = psycopg2.connect(
                host=self.master_config['host'],
                port=self.master_config['port'],
                user=self.master_config['user'],
                password=self.master_config['password'],
                database=self.master_config['database'],
                connect_timeout=5
            )
            
            cursor = conn.cursor()
            
            # Проверяем что это мастер (не в recovery mode)
            cursor.execute("SELECT pg_is_in_recovery();")
            is_recovery = cursor.fetchone()[0]
            
            if is_recovery:
                self.log("ОШИБКА: Мастер находится в режиме recovery!", "ERROR")
                cursor.close()
                conn.close()
                return False
            
            # Проверяем текущее WAL положение
            cursor.execute("SELECT pg_current_wal_lsn();")
            wal_lsn = cursor.fetchone()[0]
            
            self.log(f"Мастер доступен. WAL LSN: {wal_lsn}", "DEBUG")
            
            cursor.close()
            conn.close()
            return True
            
        except Exception as e:
            self.log(f"Ошибка подключения к мастеру: {e}", "ERROR")
            return False
    
    def check_standby_health(self) -> bool:
        """
        Проверка здоровья standby сервера
        
        Returns:
            True если standby доступен
        """
        try:
            conn = psycopg2.connect(
                host=self.standby_config['host'],
                port=self.standby_config['port'],
                user=self.standby_config['user'],
                password=self.standby_config['password'],
                database=self.standby_config['database'],
                connect_timeout=5
            )
            
            cursor = conn.cursor()
            
            # Проверяем что это standby (в recovery mode)
            cursor.execute("SELECT pg_is_in_recovery();")
            is_recovery = cursor.fetchone()[0]
            
            if not is_recovery and not self.failover_executed:
                self.log("ВНИМАНИЕ: Standby не в режиме recovery!", "WARNING")
            
            # Проверяем отставание репликации
            cursor.execute("""
                SELECT 
                    EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp()))::int 
                AS lag_seconds;
            """)
            
            result = cursor.fetchone()
            lag_seconds = result[0] if result[0] is not None else 0
            
            self.log(f"Standby доступен. Lag: {lag_seconds}s", "DEBUG")
            
            cursor.close()
            conn.close()
            return True
            
        except Exception as e:
            self.log(f"Ошибка подключения к standby: {e}", "ERROR")
            return False
    
    def promote_standby(self) -> bool:
        """
        Повышение standby до мастера
        
        Returns:
            True если успешно, False при ошибке
        """
        try:
            self.log("=" * 70, "INFO")
            self.log("НАЧАЛО ПРОЦЕДУРЫ FAILOVER", "INFO")
            self.log("=" * 70, "INFO")
            
            # Отправка уведомления о начале failover
            if TELEGRAM_AVAILABLE:
                try:
                    notifier = get_notifier()
                    notifier.send_message(
                        "🚨 <b>НАЧАЛО АВТОМАТИЧЕСКОГО FAILOVER</b>\n\n"
                        f"⏰ Время: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
                        f"📍 Мастер недоступен\n"
                        f"🔄 Повышение standby до мастера..."
                    )
                except Exception as e:
                    self.log(f"Не удалось отправить Telegram уведомление: {e}", "WARNING")
            
            # Подключаемся к standby
            conn = psycopg2.connect(
                host=self.standby_config['host'],
                port=self.standby_config['port'],
                user=self.standby_config['user'],
                password=self.standby_config['password'],
                database=self.standby_config['database']
            )
            
            cursor = conn.cursor()
            
            # Выполняем promote
            self.log("Выполнение pg_promote()...", "INFO")
            cursor.execute("SELECT pg_promote();")
            result = cursor.fetchone()[0]
            
            if result:
                self.log("Команда promote выполнена успешно!", "INFO")
                
                # Ждём завершения promote
                self.log("Ожидание завершения promote (до 60 секунд)...", "INFO")
                for i in range(60):
                    time.sleep(1)
                    
                    try:
                        cursor.execute("SELECT pg_is_in_recovery();")
                        is_recovery = cursor.fetchone()[0]
                        
                        if not is_recovery:
                            self.log("✅ Standby успешно повышен до мастера!", "INFO")
                            self.failover_executed = True
                            
                            # Отправка уведомления об успехе
                            if TELEGRAM_AVAILABLE:
                                try:
                                    notifier = get_notifier()
                                    notifier.send_message(
                                        "✅ <b>FAILOVER ЗАВЕРШЁН УСПЕШНО</b>\n\n"
                                        f"⏰ Время: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
                                        f"🎯 Новый мастер: {self.standby_config['host']}:{self.standby_config['port']}\n"
                                        f"✅ Система восстановлена"
                                    )
                                except:
                                    pass
                            
                            cursor.close()
                            conn.close()
                            return True
                    except:
                        pass
                
                self.log("ОШИБКА: Promote не завершился за 60 секунд", "ERROR")
                
            else:
                self.log("ОШИБКА: pg_promote() вернул false", "ERROR")
            
            cursor.close()
            conn.close()
            return False
            
        except Exception as e:
            self.log(f"КРИТИЧЕСКАЯ ОШИБКА при failover: {e}", "ERROR")
            
            # Отправка уведомления об ошибке
            if TELEGRAM_AVAILABLE:
                try:
                    notifier = get_notifier()
                    notifier.send_message(
                        "❌ <b>ОШИБКА FAILOVER</b>\n\n"
                        f"⏰ Время: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
                        f"❌ Ошибка: {str(e)[:100]}\n"
                        f"⚠️ Требуется ручное вмешательство!"
                    )
                except:
                    pass
            
            return False
    
    def run(self):
        """Основной цикл мониторинга"""
        self.log("=" * 70, "INFO")
        self.log("ЗАПУСК АВТОМАТИЧЕСКОГО FAILOVER МЕНЕДЖЕРА", "INFO")
        self.log("=" * 70, "INFO")
        self.log(f"Мастер: {self.master_config['host']}:{self.master_config['port']}", "INFO")
        self.log(f"Standby: {self.standby_config['host']}:{self.standby_config['port']}", "INFO")
        self.log(f"Интервал проверки: {self.check_interval}s", "INFO")
        self.log(f"Порог для failover: {self.max_failures} неудачных проверок", "INFO")
        self.log("=" * 70, "INFO")
        
        # Отправка уведомления о запуске
        if TELEGRAM_AVAILABLE:
            try:
                notifier = get_notifier()
                notifier.send_message(
                    "🟢 <b>Failover Manager запущен</b>\n\n"
                    f"⏰ Время: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
                    f"🖥 Мастер: {self.master_config['host']}:{self.master_config['port']}\n"
                    f"🖥 Standby: {self.standby_config['host']}:{self.standby_config['port']}\n"
                    f"⏱ Интервал: {self.check_interval}s"
                )
            except:
                pass
        
        try:
            while True:
                # Проверяем здоровье мастера
                master_ok = self.check_master_health()
                
                if not master_ok:
                    self.master_down_count += 1
                    self.log(f"Мастер недоступен ({self.master_down_count}/{self.max_failures})", "WARNING")
                    
                    if self.master_down_count >= self.max_failures:
                        self.log("КРИТИЧНО: Достигнут порог неудачных проверок!", "ERROR")
                        
                        # Проверяем standby перед failover
                        standby_ok = self.check_standby_health()
                        
                        if standby_ok:
                            self.log("Standby доступен. Начинаем failover...", "INFO")
                            
                            if self.promote_standby():
                                self.log("FAILOVER УСПЕШНО ЗАВЕРШЁН!", "INFO")
                                self.log("Мониторинг остановлен. Требуется ручная настройка.", "INFO")
                                break
                            else:
                                self.log("FAILOVER НЕ УДАЛСЯ!", "ERROR")
                                self.log("Продолжение мониторинга...", "INFO")
                        else:
                            self.log("КРИТИЧНО: Standby также недоступен!", "ERROR")
                            
                            # Уведомление о критической ситуации
                            if TELEGRAM_AVAILABLE:
                                try:
                                    notifier = get_notifier()
                                    notifier.send_message(
                                        "🔴 <b>КРИТИЧЕСКАЯ СИТУАЦИЯ</b>\n\n"
                                        f"⏰ Время: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
                                        f"❌ Мастер недоступен\n"
                                        f"❌ Standby недоступен\n"
                                        f"⚠️ ТРЕБУЕТСЯ НЕМЕДЛЕННОЕ ВМЕШАТЕЛЬСТВО!"
                                    )
                                except:
                                    pass
                else:
                    # Мастер доступен - сбрасываем счётчик
                    if self.master_down_count > 0:
                        self.log("Мастер восстановлен", "INFO")
                        self.master_down_count = 0
                
                # Ждём до следующей проверки
                time.sleep(self.check_interval)
                
        except KeyboardInterrupt:
            self.log("Остановлено пользователем", "INFO")
        except Exception as e:
            self.log(f"КРИТИЧЕСКАЯ ОШИБКА: {e}", "ERROR")
            raise


if __name__ == "__main__":
    # Конфигурация мастера
    master_config = {
        'host': 'localhost',
        'port': 5432,
        'user': 'postgres',
        'password': 'your_password',
        'database': 'bibabobabebe'
    }
    
    # Конфигурация standby (обычно на другом сервере)
    standby_config = {
        'host': 'localhost',  # В реальности это другой сервер
        'port': 5433,         # Другой порт для standby
        'user': 'postgres',
        'password': 'your_password',
        'database': 'bibabobabebe'
    }
    
    # Создаём и запускаем менеджер
    manager = FailoverManager(
        master_config=master_config,
        standby_config=standby_config,
        check_interval=30  # Проверка каждые 30 секунд
    )
    
    manager.run()

