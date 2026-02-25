"""
Скрипт для тестирования доступности эндпоинтов Flask приложения
"""
import requests
import sys

def test_endpoint(url, name):
    """Тестирует доступность эндпоинта"""
    try:
        response = requests.get(url, timeout=5)
        print(f"✅ {name}: {response.status_code}")
        if response.status_code == 200:
            print(f"   Содержимое: {response.text[:200]}...")
        else:
            print(f"   Ошибка: {response.text[:200]}")
        return response.status_code == 200
    except requests.exceptions.RequestException as e:
        print(f"❌ {name}: Ошибка подключения - {e}")
        return False

def main():
    """Основная функция тестирования"""
    print("=" * 60)
    print("Тестирование Flask приложения")
    print("=" * 60)
    
    base_url = "http://localhost:5000"
    
    tests = [
        (f"{base_url}/", "Главная страница"),
        (f"{base_url}/health", "Health Check"),
        (f"{base_url}/metrics", "Prometheus Metrics"),
    ]
    
    results = []
    for url, name in tests:
        print(f"\nПроверка: {name}")
        results.append(test_endpoint(url, name))
    
    print("\n" + "=" * 60)
    print("РЕЗУЛЬТАТЫ:")
    print("=" * 60)
    for (url, name), result in zip(tests, results):
        status = "✅ OK" if result else "❌ FAIL"
        print(f"{status} - {name}")
    
    print("\n" + "=" * 60)
    if all(results):
        print("✅ Все тесты пройдены успешно!")
        print("Prometheus теперь должен успешно собирать метрики.")
        return 0
    else:
        print("❌ Некоторые тесты провалились.")
        print("\nРекомендации:")
        print("1. Убедитесь что Flask приложение запущено: python app.py")
        print("2. Проверьте что порт 5000 не занят")
        print("3. Перезапустите приложение после изменений")
        return 1

if __name__ == "__main__":
    sys.exit(main())

