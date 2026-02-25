"""
Простой webhook сервер для Alertmanager → Telegram
Запускается отдельно от Flask app
"""
import os
from flask import Flask, request, jsonify
from telegram_notifier import get_notifier
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

# Shared secret для защиты webhook от несанкционированных запросов.
# Устанавливается в .env → WEBHOOK_SECRET=<ваш секрет>
WEBHOOK_SECRET = os.getenv('WEBHOOK_SECRET', '')


def _verify_secret():
    """Проверяет X-Webhook-Secret заголовок, если секрет задан."""
    if not WEBHOOK_SECRET:
        return True  # Секрет не настроен — разрешить (backward compat)
    token = request.headers.get('X-Webhook-Secret', '')
    return token == WEBHOOK_SECRET


@app.route('/webhook/alert', methods=['POST'])
def alert_webhook():
    """Общий webhook для всех алертов"""
    if not _verify_secret():
        return jsonify({'status': 'unauthorized'}), 401

    data = request.json
    
    try:
        notifier = get_notifier()
        
        if 'alerts' in data:
            for alert in data['alerts']:
                status = alert.get('status', 'unknown')
                labels = alert.get('labels', {})
                annotations = alert.get('annotations', {})
                
                alertname = labels.get('alertname', 'Unknown')
                severity = labels.get('severity', 'info')
                instance = labels.get('instance', 'N/A')
                summary = annotations.get('summary', 'No summary')
                description = annotations.get('description', '')
                
                # Эмодзи по severity
                emoji_map = {
                    'critical': '🔴',
                    'warning': '⚠️',
                    'info': 'ℹ️'
                }
                emoji = emoji_map.get(severity, '📢')
                
                # Статус алерта
                status_emoji = '🚨' if status == 'firing' else '✅'
                
                message = f"""
{status_emoji} <b>{alertname}</b>

{emoji} <b>Severity:</b> {severity.upper()}
🖥 <b>Instance:</b> {instance}
📊 <b>Status:</b> {status.upper()}

📝 {summary}
"""
                
                if description:
                    message += f"\n💬 {description}"
                
                message += f"\n\n⏰ {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
                
                notifier.send_message(message)
                print(f"✅ Alert sent to Telegram: {alertname}")
        
        return jsonify({'status': 'ok'}), 200
        
    except Exception as e:
        print(f"❌ Error processing alert: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500


@app.route('/webhook/alert/critical', methods=['POST'])
def critical_alert_webhook():
    """Критические алерты"""
    if not _verify_secret():
        return jsonify({'status': 'unauthorized'}), 401
    return alert_webhook()


@app.route('/webhook/alert/warning', methods=['POST'])
def warning_alert_webhook():
    """Предупреждения"""
    if not _verify_secret():
        return jsonify({'status': 'unauthorized'}), 401
    return alert_webhook()


@app.route('/health', methods=['GET'])
def health():
    """Health check"""
    return jsonify({'status': 'healthy'}), 200


if __name__ == '__main__':
    print("=" * 60)
    print("  Alertmanager Webhook Server → Telegram")
    print("=" * 60)
    print("Listening on http://localhost:5001/webhook/alert")
    print("Press Ctrl+C to stop")
    print("=" * 60)
    
    app.run(host='0.0.0.0', port=5001, debug=False)

