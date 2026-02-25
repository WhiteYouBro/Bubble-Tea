"""
Централизованная система логирования для операций резервного копирования
Логирование с ротацией файлов, уровнями важности и интеграцией с Telegram
"""

import logging
import logging.handlers
from pathlib import Path
from datetime import datetime
from typing import Optional
import json
import os

try:
    from telegram_notifier import get_notifier
    TELEGRAM_AVAILABLE = True
except ImportError:
    TELEGRAM_AVAILABLE = False


class BackupLogger:
    """Централизованный логгер для операций с базой данных"""
    
    # Уровни логирования для Telegram (только критичные события)
    TELEGRAM_LEVELS = {
        logging.ERROR,
        logging.CRITICAL
    }
    
    def __init__(self, name: str = "backup_system", 
                 log_dir: Optional[Path] = None,
                 enable_telegram: bool = True):
        """
        Инициализация логгера
        
        Args:
            name: Имя логгера
            log_dir: Директория для лог-файлов
            enable_telegram: Включить Telegram уведомления
        """
        self.name = name
        self.log_dir = log_dir or Path(__file__).parent / "logs"
        self.log_dir.mkdir(exist_ok=True)
        
        self.enable_telegram = enable_telegram and TELEGRAM_AVAILABLE
        
        # Создаём основной логгер
        self.logger = logging.getLogger(name)
        self.logger.setLevel(logging.DEBUG)
        
        # Удаляем существующие хэндлеры если есть
        self.logger.handlers = []
        
        # Добавляем хэндлеры
        self._setup_file_handlers()
        self._setup_console_handler()
        
        # Статистика
        self.stats = {
            'debug': 0,
            'info': 0,
            'warning': 0,
            'error': 0,
            'critical': 0
        }
    
    def _setup_file_handlers(self):
        """Настройка файловых хэндлеров с ротацией"""
        # Основной лог файл (все уровни)
        main_log = self.log_dir / f"{self.name}.log"
        main_handler = logging.handlers.RotatingFileHandler(
            main_log,
            maxBytes=10*1024*1024,  # 10 MB
            backupCount=10,
            encoding='utf-8'
        )
        main_handler.setLevel(logging.DEBUG)
        main_handler.setFormatter(self._get_formatter())
        self.logger.addHandler(main_handler)
        
        # Отдельный файл для ошибок
        error_log = self.log_dir / f"{self.name}_errors.log"
        error_handler = logging.handlers.RotatingFileHandler(
            error_log,
            maxBytes=5*1024*1024,  # 5 MB
            backupCount=5,
            encoding='utf-8'
        )
        error_handler.setLevel(logging.ERROR)
        error_handler.setFormatter(self._get_formatter())
        self.logger.addHandler(error_handler)
        
        # JSON лог для машинной обработки
        json_log = self.log_dir / f"{self.name}.json"
        json_handler = logging.handlers.RotatingFileHandler(
            json_log,
            maxBytes=10*1024*1024,  # 10 MB
            backupCount=5,
            encoding='utf-8'
        )
        json_handler.setLevel(logging.INFO)
        json_handler.setFormatter(self._get_json_formatter())
        self.logger.addHandler(json_handler)
    
    def _setup_console_handler(self):
        """Настройка консольного хэндлера"""
        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.INFO)
        console_handler.setFormatter(self._get_colored_formatter())
        self.logger.addHandler(console_handler)
    
    def _get_formatter(self):
        """Стандартный форматтер"""
        return logging.Formatter(
            '[%(asctime)s] [%(levelname)-8s] [%(name)s] %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
    
    def _get_colored_formatter(self):
        """Форматтер с цветами для консоли"""
        # Цветовые коды ANSI
        COLORS = {
            'DEBUG': '\033[36m',      # Cyan
            'INFO': '\033[32m',       # Green
            'WARNING': '\033[33m',    # Yellow
            'ERROR': '\033[31m',      # Red
            'CRITICAL': '\033[35m',   # Magenta
            'RESET': '\033[0m'
        }
        
        class ColoredFormatter(logging.Formatter):
            def format(self, record):
                levelname = record.levelname
                if levelname in COLORS:
                    record.levelname = f"{COLORS[levelname]}{levelname}{COLORS['RESET']}"
                return super().format(record)
        
        return ColoredFormatter(
            '[%(asctime)s] [%(levelname)s] %(message)s',
            datefmt='%H:%M:%S'
        )
    
    def _get_json_formatter(self):
        """JSON форматтер"""
        class JsonFormatter(logging.Formatter):
            def format(self, record):
                log_data = {
                    'timestamp': datetime.now().isoformat(),
                    'level': record.levelname,
                    'logger': record.name,
                    'message': record.getMessage(),
                    'module': record.module,
                    'function': record.funcName,
                    'line': record.lineno
                }
                
                if record.exc_info:
                    log_data['exception'] = self.formatException(record.exc_info)
                
                return json.dumps(log_data, ensure_ascii=False)
        
        return JsonFormatter()
    
    def _send_telegram(self, level: str, message: str):
        """Отправка уведомления в Telegram"""
        if not self.enable_telegram:
            return
        
        try:
            notifier = get_notifier()
            
            emoji_map = {
                'ERROR': '❌',
                'CRITICAL': '🚨',
                'WARNING': '⚠️'
            }
            
            emoji = emoji_map.get(level, '📝')
            timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            
            telegram_msg = f"""
{emoji} <b>{level}</b>

⏰ {timestamp}
🔧 {self.name}

📝 {message}
"""
            
            notifier.send_message(telegram_msg)
        except Exception as e:
            self.logger.error(f"Не удалось отправить Telegram уведомление: {e}")
    
    def debug(self, message: str):
        """Debug уровень"""
        self.stats['debug'] += 1
        self.logger.debug(message)
    
    def info(self, message: str):
        """Info уровень"""
        self.stats['info'] += 1
        self.logger.info(message)
    
    def warning(self, message: str, send_telegram: bool = False):
        """Warning уровень"""
        self.stats['warning'] += 1
        self.logger.warning(message)
        
        if send_telegram:
            self._send_telegram('WARNING', message)
    
    def error(self, message: str, send_telegram: bool = True):
        """Error уровень"""
        self.stats['error'] += 1
        self.logger.error(message)
        
        if send_telegram:
            self._send_telegram('ERROR', message)
    
    def critical(self, message: str, send_telegram: bool = True):
        """Critical уровень"""
        self.stats['critical'] += 1
        self.logger.critical(message)
        
        if send_telegram:
            self._send_telegram('CRITICAL', message)
    
    def log_operation(self, operation: str, status: str, 
                     duration: Optional[float] = None,
                     details: Optional[dict] = None):
        """
        Логирование операции с деталями
        
        Args:
            operation: Название операции (backup, restore, etc.)
            status: Статус (SUCCESS, FAILED, WARNING)
            duration: Длительность операции в секундах
            details: Дополнительные детали
        """
        details = details or {}
        
        message_parts = [f"Operation: {operation}", f"Status: {status}"]
        
        if duration is not None:
            message_parts.append(f"Duration: {duration:.2f}s")
        
        for key, value in details.items():
            message_parts.append(f"{key}: {value}")
        
        message = " | ".join(message_parts)
        
        if status == "SUCCESS":
            self.info(message)
        elif status == "FAILED":
            self.error(message, send_telegram=True)
        elif status == "WARNING":
            self.warning(message, send_telegram=True)
        else:
            self.info(message)
    
    def get_stats(self) -> dict:
        """Получить статистику логирования"""
        return self.stats.copy()
    
    def get_recent_logs(self, level: str = None, limit: int = 100) -> list:
        """
        Получить последние записи из лог-файла
        
        Args:
            level: Уровень логирования (опционально)
            limit: Максимальное количество записей
        
        Returns:
            Список строк логов
        """
        log_file = self.log_dir / f"{self.name}.log"
        
        if not log_file.exists():
            return []
        
        with open(log_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        # Фильтруем по уровню если указан
        if level:
            lines = [l for l in lines if f"[{level}]" in l]
        
        # Возвращаем последние N записей
        return lines[-limit:]


# Глобальные логгеры для разных компонентов
_loggers = {}


def get_logger(component: str = "backup") -> BackupLogger:
    """
    Получить логгер для компонента
    
    Args:
        component: Название компонента (backup, restore, monitoring, etc.)
    
    Returns:
        BackupLogger instance
    """
    if component not in _loggers:
        _loggers[component] = BackupLogger(name=component)
    
    return _loggers[component]


if __name__ == "__main__":
    """Тестирование системы логирования"""
    print("=" * 70)
    print("  Тестирование системы логирования")
    print("=" * 70)
    print()
    
    # Создаём тестовый логгер
    logger = get_logger("test_backup")
    
    # Тестируем разные уровни
    logger.debug("Это debug сообщение")
    logger.info("Это info сообщение")
    logger.warning("Это warning сообщение")
    logger.error("Это error сообщение (будет отправлено в Telegram)")
    
    # Тестируем логирование операций
    logger.log_operation(
        operation="backup_test",
        status="SUCCESS",
        duration=45.3,
        details={
            'type': 'logical',
            'size': '15.3 MB',
            'filename': 'test_backup.sql'
        }
    )
    
    logger.log_operation(
        operation="restore_test",
        status="FAILED",
        duration=12.1,
        details={
            'error': 'Connection timeout'
        }
    )
    
    # Показываем статистику
    print()
    print("=" * 70)
    print("  Статистика логирования:")
    print("=" * 70)
    stats = logger.get_stats()
    for level, count in stats.items():
        print(f"  {level.upper()}: {count}")
    
    print()
    print("=" * 70)
    print("  Тестирование завершено!")
    print(f"  Лог файлы сохранены в: {logger.log_dir}")
    print("=" * 70)

