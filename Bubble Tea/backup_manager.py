"""
Backup Manager - Flask Blueprint
Web interface for database backup and restore management
ADMIN ONLY - requires administrator privileges
"""

from flask import Blueprint, render_template, request, jsonify, flash, redirect, url_for, current_app
from flask_login import login_required, current_user
from functools import wraps
import os
import subprocess
from datetime import datetime
import glob
from pathlib import Path
import time


def _create_backup_notification(title, message, level='info'):
    """Создать уведомление о бэкапе в БД (безопасно, без краша при ошибке)"""
    try:
        from app import db, Notification
        notif = Notification(
            title=title, message=message,
            category='backup', level=level,
            created_by=current_user.username if current_user.is_authenticated else 'system'
        )
        db.session.add(notif)
        db.session.commit()
    except Exception as e:
        print(f"⚠️ Backup notification failed: {e}")

# Telegram notifications
try:
    from telegram_notifier import get_notifier
    TELEGRAM_AVAILABLE = True
    print("✅ Telegram notifier loaded successfully")
except ImportError as e:
    print(f"⚠️ Warning: Telegram notifier not available: {e}")
    TELEGRAM_AVAILABLE = False

bp = Blueprint('backup', __name__, url_prefix='/backup')

# Admin required decorator
def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated or current_user.role != 'admin':
            flash('⛔ Access denied! Administrator privileges required.', 'danger')
            return redirect(url_for('index'))
        return f(*args, **kwargs)
    return decorated_function

# Пути к директориям backup
BASE_DIR = Path(__file__).resolve().parent
BACKUP_DIR_LOGICAL = BASE_DIR / 'backups' / 'logical'
BACKUP_DIR_PHYSICAL = BASE_DIR / 'backups' / 'physical'
BACKUP_DIR_WAL = BASE_DIR / 'backups' / 'wal_archive'

# Пути к скриптам
SCRIPT_DIR = BASE_DIR / 'database' / 'backup_scripts'
SCRIPT_PG_DUMP = SCRIPT_DIR / 'pg_dump_backup.bat'
SCRIPT_PG_BASEBACKUP = SCRIPT_DIR / 'pg_basebackup.bat'
SCRIPT_RESTORE = SCRIPT_DIR / 'restore_from_dump.bat'

# Создаем директории если не существуют
for dir in [BACKUP_DIR_LOGICAL, BACKUP_DIR_PHYSICAL, BACKUP_DIR_WAL]:
    dir.mkdir(parents=True, exist_ok=True)


def get_file_size(file_path):
    """Get file size in human readable format"""
    size = os.path.getsize(file_path)
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size < 1024.0:
            return f"{size:.2f} {unit}"
        size /= 1024.0
    return f"{size:.2f} TB"


def get_backup_list(backup_type='logical'):
    """Get list of backup files"""
    backups = []
    
    if backup_type == 'logical':
        directory = BACKUP_DIR_LOGICAL
        extensions = ['*.backup', '*.sql']
        
        for ext in extensions:
            files = glob.glob(str(directory / ext))
            for file in files:
                file_path = Path(file)
                stat = file_path.stat()
                backups.append({
                    'filename': file_path.name,
                    'path': str(file_path),
                    'size': get_file_size(file),
                    'size_bytes': stat.st_size,
                    'modified': datetime.fromtimestamp(stat.st_mtime).strftime('%Y-%m-%d %H:%M:%S'),
                    'modified_timestamp': stat.st_mtime,
                    'type': backup_type
                })
    else:
        # Physical backups are stored in directories (timestamp folders)
        directory = BACKUP_DIR_PHYSICAL
        
        # Get all subdirectories (backup folders)
        if directory.exists():
            for backup_dir in directory.iterdir():
                if backup_dir.is_dir():
                    # Calculate total size of directory
                    total_size = sum(f.stat().st_size for f in backup_dir.rglob('*') if f.is_file())
                    stat = backup_dir.stat()
                    
                    backups.append({
                        'filename': backup_dir.name,
                        'path': str(backup_dir),
                        'size': get_file_size_from_bytes(total_size),
                        'size_bytes': total_size,
                        'modified': datetime.fromtimestamp(stat.st_mtime).strftime('%Y-%m-%d %H:%M:%S'),
                        'modified_timestamp': stat.st_mtime,
                        'type': backup_type
                    })
    
    # Sort by modification date (newest first)
    backups.sort(key=lambda x: x['modified_timestamp'], reverse=True)
    return backups


def get_backup_stats():
    """Get backup statistics"""
    logical_backups = get_backup_list('logical')
    physical_backups = get_backup_list('physical')
    
    total_logical_size = sum(b['size_bytes'] for b in logical_backups)
    total_physical_size = sum(b['size_bytes'] for b in physical_backups)
    
    # Last successful backup
    last_backup = None
    if logical_backups:
        last_backup = logical_backups[0]
    
    return {
        'total_backups': len(logical_backups) + len(physical_backups),
        'logical_count': len(logical_backups),
        'physical_count': len(physical_backups),
        'total_logical_size': get_file_size_from_bytes(total_logical_size),
        'total_physical_size': get_file_size_from_bytes(total_physical_size),
        'last_backup': last_backup
    }


def get_file_size_from_bytes(size):
    """Convert bytes to human readable format"""
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size < 1024.0:
            return f"{size:.2f} {unit}"
        size /= 1024.0
    return f"{size:.2f} TB"


@bp.route('/')
@login_required
@admin_required
def index():
    """Backup dashboard main page - ADMIN ONLY"""
    stats = get_backup_stats()
    logical_backups = get_backup_list('logical')[:5]  # Last 5
    physical_backups = get_backup_list('physical')[:5]
    
    return render_template('backup/index.html',
                         stats=stats,
                         logical_backups=logical_backups,
                         physical_backups=physical_backups)


@bp.route('/list')
@login_required
@admin_required
def backup_list():
    """Page with list of all backups - ADMIN ONLY"""
    backup_type = request.args.get('type', 'logical')
    backups = get_backup_list(backup_type)
    
    return render_template('backup/list.html',
                         backups=backups,
                         backup_type=backup_type)


@bp.route('/create', methods=['GET', 'POST'])
@login_required
@admin_required
def create_backup():
    """Create new backup - ADMIN ONLY"""
    if request.method == 'POST':
        backup_type = request.form.get('backup_type', 'logical')
        
        try:
            # Запускаем бэкап в фоне (не блокируем редирект)
            if backup_type == 'logical':
                script = SCRIPT_PG_DUMP
            else:
                script = SCRIPT_PG_BASEBACKUP
            
            # Используем Popen для фонового запуска (shell=False — защита от command injection)
            subprocess.Popen(
                [str(script)],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                shell=False
            )
            
            flash(f'✅ Бэкап запущен в фоне! ({backup_type})', 'success')
            print(f"🔄 Started {backup_type} backup in background")
            _create_backup_notification(
                title=f'💾 Бэкап запущен ({backup_type})',
                message=f'Начато {backup_type} резервное копирование базы данных',
                level='info'
            )
                    
        except Exception as e:
            error_msg = str(e)
            flash(f'❌ Ошибка запуска бэкапа: {error_msg}', 'error')
            print(f"❌ Backup start error: {error_msg}")
            _create_backup_notification(
                title=f'❌ Ошибка запуска бэкапа',
                message=f'Не удалось запустить {backup_type} бэкап: {error_msg}',
                level='error'
            )
        
        # Немедленный редирект
        return redirect(url_for('backup.index'))
    
    return render_template('backup/create.html')


@bp.route('/restore', methods=['GET', 'POST'])
@login_required
@admin_required
def restore_backup():
    """Restore from backup - COMMAND LINE ONLY - ADMIN ONLY
    
    Web restore is disabled because it would terminate all DB connections,
    causing Flask to crash with OperationalError.
    This page only shows instructions for command line restore.
    """
    if request.method == 'POST':
        # Restore via web interface is disabled - too dangerous
        flash('❌ Web restore is disabled! The app would crash when DB connections are terminated.', 'error')
        flash('ℹ️ Use command line restore instead. See instructions below.', 'info')
        return redirect(url_for('backup.restore_backup'))
    
    # GET request - show instructions and list available backups
    backups = get_backup_list('logical')
    return render_template('backup/restore.html', backups=backups)


@bp.route('/api/create', methods=['POST'])
@login_required
@admin_required
def api_create_backup():
    """API for creating backup (AJAX) - ADMIN ONLY"""
    data = request.get_json()
    backup_type = data.get('type', 'logical')
    
    try:
        if backup_type == 'logical':
            script = SCRIPT_PG_DUMP
        else:
            script = SCRIPT_PG_BASEBACKUP
        
        # Run in background
        process = subprocess.Popen([str(script)],
                                  stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE,
                                  encoding='utf-8',  # Force UTF-8 encoding
                                  errors='replace')  # Replace invalid characters
        
        _create_backup_notification(
            title=f'💾 Бэкап запущен через API ({backup_type})',
            message=f'{backup_type.capitalize()} резервное копирование запущено (PID: {process.pid})',
            level='info'
        )
        
        return jsonify({
            'status': 'started',
            'message': f'{backup_type.capitalize()} backup started',
            'pid': process.pid
        })
        
    except Exception as e:
        _create_backup_notification(
            title='❌ Ошибка API бэкапа',
            message=f'Не удалось запустить {backup_type} бэкап: {str(e)}',
            level='error'
        )
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500


@bp.route('/api/list')
@login_required
@admin_required
def api_backup_list():
    """API for getting backup list (AJAX) - ADMIN ONLY"""
    backup_type = request.args.get('type', 'logical')
    backups = get_backup_list(backup_type)
    
    return jsonify({
        'status': 'success',
        'backups': backups
    })


@bp.route('/api/stats')
@login_required
@admin_required
def api_stats():
    """API for getting statistics (AJAX) - ADMIN ONLY"""
    stats = get_backup_stats()
    return jsonify({
        'status': 'success',
        'stats': stats
    })


@bp.route('/delete/<path:filename>', methods=['POST'])
@login_required
@admin_required
def delete_backup(filename):
    """Delete backup file - ADMIN ONLY"""
    # resolve() нейтрализует path traversal (../, ../../ и т.д.)
    file_path = Path(filename).resolve()
    allowed_logical = BACKUP_DIR_LOGICAL.resolve()
    allowed_physical = BACKUP_DIR_PHYSICAL.resolve()

    try:
        file_path.relative_to(allowed_logical)
        in_allowed = True
    except ValueError:
        try:
            file_path.relative_to(allowed_physical)
            in_allowed = True
        except ValueError:
            in_allowed = False

    if not in_allowed:
        flash('❌ Недопустимый путь к файлу', 'error')
        return redirect(url_for('backup.index'))
    
    try:
        if file_path.exists():
            os.remove(file_path)
            flash(f'✅ Бэкап удалён: {file_path.name}', 'success')
        else:
            flash(f'❌ Файл не найден: {file_path.name}', 'error')
    except Exception as e:
        flash(f'❌ Ошибка удаления: {str(e)}', 'error')
    
    return redirect(url_for('backup.backup_list'))

