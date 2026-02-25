"""
Unit-тесты для веб-приложения Bubble Tea "BibaBobaBebe"
Запуск: python tests.py
Или:    python -m unittest tests -v

Тесты используют SQLite in-memory базу данных — PostgreSQL не требуется.
"""

import unittest
import os
from decimal import Decimal

# Переопределяем SQLALCHEMY_DATABASE_URI ДО импорта app
# Flask-SQLAlchemy подхватит его вместо PostgreSQL URL
os.environ['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
# Заглушки для переменных, которые app.py читает при старте
os.environ.setdefault('DB_USER', 'test')
os.environ.setdefault('DB_PASSWORD', 'test')
os.environ.setdefault('DB_HOST', 'localhost')
os.environ.setdefault('DB_PORT', '5432')
os.environ.setdefault('DB_NAME', 'test_db')

import app as application
from app import app, db, User, Product, Category, Ingredient, ProductIngredient, Order, Employee, Position, Notification
from app import check_product_availability, deduct_ingredients, create_notification


# ============================================================
# КОНФИГУРАЦИЯ ТЕСТОВОЙ СРЕДЫ
# ============================================================

def configure_test_app():
    """Финальная конфигурация для тестового режима"""
    app.config.update({
        'TESTING': True,
        'SQLALCHEMY_DATABASE_URI': 'sqlite:///:memory:',
        'WTF_CSRF_ENABLED': False,
        'SECRET_KEY': 'test-secret-key',
        'LOGIN_DISABLED': False,
        'SQLALCHEMY_ENGINE_OPTIONS': {'connect_args': {'check_same_thread': False}},
    })


# ============================================================
# БАЗОВЫЙ КЛАСС ДЛЯ ВСЕХ ТЕСТОВ
# ============================================================

class BaseTestCase(unittest.TestCase):
    """Базовый класс: создаёт/удаляет схему БД перед каждым тестом"""

    @classmethod
    def setUpClass(cls):
        configure_test_app()

    def setUp(self):
        self.app = app
        self.client = app.test_client()
        with app.app_context():
            db.create_all()
            self._seed_base_data()

    def tearDown(self):
        with app.app_context():
            db.session.remove()
            db.drop_all()

    def _seed_base_data(self):
        """Создать минимальный набор данных для тестов"""
        # Позиция и сотрудник (нужны для заказов)
        position = Position(position_name='Barista', base_salary=Decimal('150000'))
        db.session.add(position)
        db.session.flush()

        employee = Employee(
            first_name='Test', last_name='Employee',
            phone='+77001112233', email='emp@test.com',
            position_id=position.position_id,
            salary=Decimal('150000'),
            hire_date=__import__('datetime').date.today()
        )
        db.session.add(employee)

        # Категория и продукт
        category = Category(category_name='Drinks', description='Test drinks')
        db.session.add(category)
        db.session.flush()

        product = Product(
            product_name='Test Boba', category_id=category.category_id,
            price=Decimal('800'), is_available=True,
            description='Тестовый напиток для unit-тестов'
        )
        db.session.add(product)

        # Ингредиент
        ingredient = Ingredient(
            ingredient_name='Tapioca Pearls', unit='g',
            stock_quantity=Decimal('500'), min_quantity=Decimal('50'),
            cost_per_unit=Decimal('1.5')
        )
        db.session.add(ingredient)
        db.session.commit()

    def _create_admin(self, username='admin', password='Admin123!'):
        """Создать администратора и вернуть объект"""
        with app.app_context():
            user = User(
                username=username,
                email=f'{username}@test.com',
                role='admin',
                full_name='Test Admin'
            )
            user.set_password(password)
            db.session.add(user)
            db.session.commit()
            return user.user_id

    def _login(self, username, password):
        """Выполнить POST /login через тестовый клиент"""
        return self.client.post('/login', data={
            'username': username,
            'password': password
        }, follow_redirects=True)


# ============================================================
# ТЕСТ 1: МОДЕЛЬ ПОЛЬЗОВАТЕЛЯ И БЕЗОПАСНОСТЬ ПАРОЛЕЙ
# ============================================================

class TestUserModel(BaseTestCase):
    """
    Тестирует модель User:
    - хеширование паролей (не хранятся в открытом виде)
    - проверку корректного пароля
    - отклонение неверного пароля
    - уникальность username/email
    - назначение ролей
    """

    def test_password_is_hashed_not_stored_as_plaintext(self):
        """Пароль должен храниться как хеш, а не открытым текстом"""
        with app.app_context():
            user = User(username='hashtest', email='hash@test.com', role='user')
            user.set_password('MySecret123')
            db.session.add(user)
            db.session.commit()

            # Хеш не равен исходному паролю
            self.assertNotEqual(user.password_hash, 'MySecret123')
            # Хеш существует и не пустой
            self.assertIsNotNone(user.password_hash)
            self.assertTrue(len(user.password_hash) > 20)

    def test_correct_password_accepted(self):
        """check_password должен возвращать True для правильного пароля"""
        with app.app_context():
            user = User(username='passtest', email='pass@test.com', role='user')
            user.set_password('CorrectPass999')
            db.session.add(user)
            db.session.commit()

            self.assertTrue(user.check_password('CorrectPass999'))

    def test_wrong_password_rejected(self):
        """check_password должен возвращать False для неверного пароля"""
        with app.app_context():
            user = User(username='wrongtest', email='wrong@test.com', role='user')
            user.set_password('RealPassword')
            db.session.add(user)
            db.session.commit()

            self.assertFalse(user.check_password('WrongPassword'))
            self.assertFalse(user.check_password(''))
            self.assertFalse(user.check_password('realpassword'))  # регистр важен

    def test_user_roles_assigned_correctly(self):
        """Роли admin и user должны присваиваться и читаться корректно"""
        with app.app_context():
            admin = User(username='adminuser', email='admin@test.com', role='admin')
            regular = User(username='regularuser', email='regular@test.com', role='user')
            admin.set_password('pass'); regular.set_password('pass')
            db.session.add_all([admin, regular])
            db.session.commit()

            fetched_admin = User.query.filter_by(username='adminuser').first()
            fetched_user = User.query.filter_by(username='regularuser').first()

            self.assertEqual(fetched_admin.role, 'admin')
            self.assertEqual(fetched_user.role, 'user')
            self.assertNotEqual(fetched_admin.role, fetched_user.role)

    def test_duplicate_username_raises_error(self):
        """Два пользователя с одинаковым username не должны быть сохранены"""
        with app.app_context():
            u1 = User(username='duplicate', email='u1@test.com', role='user')
            u1.set_password('pass1')
            db.session.add(u1)
            db.session.commit()

            u2 = User(username='duplicate', email='u2@test.com', role='user')
            u2.set_password('pass2')
            db.session.add(u2)

            from sqlalchemy.exc import IntegrityError
            with self.assertRaises(IntegrityError):
                db.session.commit()


# ============================================================
# ТЕСТ 2: БИЗНЕС-ЛОГИКА ИНГРЕДИЕНТОВ И ДОСТУПНОСТЬ ПРОДУКТОВ
# ============================================================

class TestIngredientBusinessLogic(BaseTestCase):
    """
    Тестирует бизнес-логику работы со складом:
    - проверка доступности продукта при достаточном запасе
    - проверка недоступности при нехватке ингредиентов
    - корректное списание ингредиентов после заказа
    - срабатывание флага needs_restock
    """

    def _link_ingredient_to_product(self, quantity_needed=100):
        """Привязать ингредиент к продукту с указанным количеством"""
        with app.app_context():
            product = Product.query.filter_by(product_name='Test Boba').first()
            ingredient = Ingredient.query.filter_by(ingredient_name='Tapioca Pearls').first()
            link = ProductIngredient(
                product_id=product.product_id,
                ingredient_id=ingredient.ingredient_id,
                quantity=Decimal(str(quantity_needed))
            )
            db.session.add(link)
            db.session.commit()
            return product.product_id, ingredient.ingredient_id

    def test_product_available_when_enough_stock(self):
        """Продукт должен быть доступен если запаса ингредиента достаточно"""
        with app.app_context():
            # Привязываем: нужно 100г, есть 500г
            product_id, _ = self._link_ingredient_to_product(quantity_needed=100)

            available, reason = check_product_availability(product_id, quantity=1)

            self.assertTrue(available, f"Ожидали доступность, получили: {reason}")
            self.assertIsNone(reason)

    def test_product_unavailable_when_stock_insufficient(self):
        """Продукт должен быть недоступен если запаса не хватает"""
        with app.app_context():
            # Привязываем: нужно 600г, есть только 500г
            product_id, _ = self._link_ingredient_to_product(quantity_needed=600)

            available, reason = check_product_availability(product_id, quantity=1)

            self.assertFalse(available)
            self.assertIsNotNone(reason)
            self.assertIn('Tapioca Pearls', reason)

    def test_ingredients_deducted_after_order(self):
        """После успешного списания остаток ингредиента должен уменьшиться"""
        with app.app_context():
            product_id, ingredient_id = self._link_ingredient_to_product(quantity_needed=100)

            before = float(Ingredient.query.get(ingredient_id).stock_quantity)
            success, result = deduct_ingredients(product_id, quantity=1)
            after = float(Ingredient.query.get(ingredient_id).stock_quantity)

            self.assertTrue(success, f"deduct_ingredients вернул ошибку: {result}")
            self.assertEqual(after, before - 100.0)

    def test_needs_restock_flag_triggers_correctly(self):
        """Флаг needs_restock должен срабатывать когда запас ≤ минимума"""
        with app.app_context():
            ingredient = Ingredient.query.filter_by(ingredient_name='Tapioca Pearls').first()

            # Запас выше минимума (500 > 50) — не требует пополнения
            self.assertFalse(ingredient.needs_restock)

            # Снижаем запас до минимума
            ingredient.stock_quantity = Decimal('50')
            db.session.commit()
            self.assertTrue(ingredient.needs_restock)

            # Снижаем ниже минимума
            ingredient.stock_quantity = Decimal('10')
            db.session.commit()
            self.assertTrue(ingredient.needs_restock)


# ============================================================
# ТЕСТ 3: HTTP-МАРШРУТЫ И КОДЫ ОТВЕТОВ
# ============================================================

class TestRoutes(BaseTestCase):
    """
    Тестирует HTTP-маршруты приложения:
    - публичные страницы возвращают 200
    - защищённые страницы возвращают redirect 302 без аутентификации
    - /health возвращает JSON статус
    - /metrics возвращает текст в формате Prometheus
    - несуществующие страницы возвращают 404
    """

    def test_index_page_returns_200(self):
        """Главная страница должна открываться без авторизации"""
        response = self.client.get('/')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'BibaBobaBebe', response.data)

    def test_menu_page_returns_200(self):
        """Страница меню должна быть доступна публично"""
        response = self.client.get('/menu')
        self.assertEqual(response.status_code, 200)

    def test_login_page_returns_200(self):
        """Страница входа должна быть доступна без авторизации"""
        response = self.client.get('/login')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'login', response.data.lower())

    def test_health_endpoint_returns_json(self):
        """Эндпоинт /health должен возвращать JSON со статусом"""
        response = self.client.get('/health')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.content_type, 'application/json')

        import json
        data = json.loads(response.data)
        self.assertIn('status', data)
        self.assertEqual(data['status'], 'healthy')

    def test_metrics_endpoint_returns_prometheus_format(self):
        """/metrics должен возвращать данные в формате Prometheus (text/plain)"""
        response = self.client.get('/metrics')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'flask', response.data.lower())

    def test_protected_admin_redirects_to_login(self):
        """Страница /admin без авторизации должна редиректить на /login"""
        response = self.client.get('/admin')
        # 302 редирект или 401
        self.assertIn(response.status_code, [302, 401])

    def test_protected_orders_redirects_to_login(self):
        """Страница /orders без авторизации должна редиректить"""
        response = self.client.get('/orders')
        self.assertIn(response.status_code, [302, 401])

    def test_nonexistent_page_returns_404(self):
        """Несуществующий URL должен возвращать 404"""
        response = self.client.get('/this-page-does-not-exist-xyz')
        self.assertEqual(response.status_code, 404)

    def test_api_products_returns_json_list(self):
        """API /api/products должен возвращать список продуктов в JSON"""
        response = self.client.get('/api/products')
        self.assertEqual(response.status_code, 200)

        import json
        data = json.loads(response.data)
        self.assertIsInstance(data, list)
        # Если есть продукты — проверяем структуру
        if data:
            self.assertIn('id', data[0])
            self.assertIn('name', data[0])
            self.assertIn('price', data[0])


# ============================================================
# ТЕСТ 4: АУТЕНТИФИКАЦИЯ, АВТОРИЗАЦИЯ И УВЕДОМЛЕНИЯ
# ============================================================

class TestAuthAndNotifications(BaseTestCase):
    """
    Тестирует систему аутентификации и уведомлений:
    - успешный вход создаёт сессию
    - неверный пароль не даёт доступ
    - защищённые страницы доступны после входа
    - регистрация нового пользователя
    - уведомления сохраняются в БД
    """

    def test_successful_login(self):
        """При правильных данных пользователь должен войти в систему"""
        self._create_admin(username='logintest', password='TestPass123!')

        response = self._login('logintest', 'TestPass123!')

        # После успешного логина — редирект на главную (200 с follow)
        self.assertEqual(response.status_code, 200)
        # Не должны видеть форму входа
        self.assertNotIn(b'Invalid username or password', response.data)

    def test_wrong_password_fails_login(self):
        """При неверном пароле вход должен быть отклонён"""
        self._create_admin(username='failtest', password='RealPass123!')

        response = self._login('failtest', 'WrongPassword999')

        self.assertEqual(response.status_code, 200)
        self.assertIn(b'Invalid username or password', response.data)

    def test_nonexistent_user_fails_login(self):
        """Вход несуществующего пользователя должен быть отклонён"""
        response = self._login('ghost_user_xyz', 'AnyPassword')

        self.assertEqual(response.status_code, 200)
        self.assertIn(b'Invalid username or password', response.data)

    def test_admin_can_access_protected_pages_after_login(self):
        """Администратор после входа должен видеть защищённые страницы"""
        self._create_admin(username='adminaccess', password='AdminPass123!')

        with self.client:
            self._login('adminaccess', 'AdminPass123!')

            response = self.client.get('/admin', follow_redirects=True)
            self.assertEqual(response.status_code, 200)
            # Должен видеть дашборд, а не редирект на логин
            self.assertNotIn(b'Please log in', response.data)

    def test_user_registration_creates_account(self):
        """Регистрация нового пользователя должна создать запись в БД"""
        with app.app_context():
            before_count = User.query.count()

        response = self.client.post('/register', data={
            'username': 'newuser_test',
            'email': 'newuser@test.com',
            'full_name': 'New Test User',
            'password': 'NewPass123!',
            'confirm_password': 'NewPass123!'
        }, follow_redirects=True)

        self.assertEqual(response.status_code, 200)

        with app.app_context():
            after_count = User.query.count()
            new_user = User.query.filter_by(username='newuser_test').first()

        self.assertEqual(after_count, before_count + 1)
        self.assertIsNotNone(new_user)
        self.assertEqual(new_user.role, 'user')   # новые пользователи — не admin

    def test_notification_saved_to_database(self):
        """create_notification должен сохранять запись в таблицу notifications"""
        with app.app_context():
            before = Notification.query.count()

            create_notification(
                title='Тест уведомление',
                message='Это тестовое сообщение для unit-теста',
                category='system',
                level='info',
                created_by='test_runner'
            )

            after = Notification.query.count()
            last = Notification.query.order_by(Notification.notification_id.desc()).first()

        self.assertEqual(after, before + 1)
        self.assertEqual(last.title, 'Тест уведомление')
        self.assertEqual(last.category, 'system')
        self.assertEqual(last.level, 'info')
        self.assertFalse(last.is_read)   # по умолчанию непрочитанное

    def test_logout_ends_session(self):
        """После выхода из системы защищённые страницы должны быть закрыты"""
        self._create_admin(username='logouttest', password='LogoutPass123!')

        with self.client:
            self._login('logouttest', 'LogoutPass123!')

            # Проверяем что вошли
            resp_before = self.client.get('/admin', follow_redirects=True)
            self.assertEqual(resp_before.status_code, 200)

            # Выходим
            self.client.get('/logout', follow_redirects=True)

            # Теперь /admin должен снова редиректить
            resp_after = self.client.get('/admin')
            self.assertIn(resp_after.status_code, [302, 401])


# ============================================================
# ЗАПУСК ТЕСТОВ
# ============================================================

if __name__ == '__main__':
    print("=" * 65)
    print("  Unit-тесты Bubble Tea 'BibaBobaBebe'")
    print("  База данных: SQLite in-memory (PostgreSQL не нужен)")
    print("=" * 65)
    print()

    loader = unittest.TestLoader()
    suite = unittest.TestSuite()

    # Добавляем все тест-классы
    for test_class in [
        TestUserModel,
        TestIngredientBusinessLogic,
        TestRoutes,
        TestAuthAndNotifications,
    ]:
        suite.addTests(loader.loadTestsFromTestCase(test_class))

    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)

    print()
    print("=" * 65)
    if result.wasSuccessful():
        print(f"  ✅ ВСЕ ТЕСТЫ ПРОЙДЕНЫ — {result.testsRun} тестов")
    else:
        print(f"  ❌ ТЕСТЫ ПРОВАЛИЛИСЬ:")
        print(f"     Провалено: {len(result.failures)}")
        print(f"     Ошибки:    {len(result.errors)}")
        print(f"     Всего:     {result.testsRun} тестов")
    print("=" * 65)

    exit(0 if result.wasSuccessful() else 1)
