"""
Веб-приложение для кофейни Bubble Tea "BibaBobaBebe"
Flask + PostgreSQL
"""

from flask import Flask, render_template, request, redirect, url_for, flash, jsonify, send_from_directory, Response
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
from datetime import datetime
from functools import wraps
import os
from decimal import Decimal
from dotenv import load_dotenv

# Загружаем переменные из .env ДО обращения к os.getenv()
load_dotenv()

# Try to import Prometheus libraries
try:
    from prometheus_flask_exporter import PrometheusMetrics
    from prometheus_client import generate_latest, REGISTRY, Counter, Histogram
    PROMETHEUS_AVAILABLE = True
    print("✅ Prometheus libraries loaded successfully")
except ImportError as e:
    print(f"⚠️ Warning: Prometheus libraries not available: {e}")
    print("⚠️ Run: install_prometheus.bat to install them")
    PROMETHEUS_AVAILABLE = False

# Try to import Telegram notifier
try:
    from telegram_notifier import get_notifier
    TELEGRAM_AVAILABLE = True
    print("✅ Telegram notifier loaded successfully")
except ImportError as e:
    print(f"⚠️ Warning: Telegram notifier not available: {e}")
    TELEGRAM_AVAILABLE = False

app = Flask(__name__)

# Register Backup Manager Blueprint
try:
    from backup_manager import bp as backup_bp
    app.register_blueprint(backup_bp)
    print("✅ Backup Manager registered successfully")
except ImportError as e:
    print(f"⚠️ Warning: Could not import backup_manager: {e}")
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'change-this-in-production-use-env-var')
app.config['UPLOAD_FOLDER'] = os.path.join(os.path.dirname(__file__), 'static', 'images', 'products')
app.config['MAX_CONTENT_LENGTH'] = 5 * 1024 * 1024  # 5MB max file size
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}

# Конфигурация базы данных PostgreSQL из .env
DB_USER = os.getenv('DB_USER', 'postgres')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'your_password')
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = os.getenv('DB_PORT', '5432')
DB_NAME = os.getenv('DB_NAME', 'bibabobabebe')

app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv(
    'SQLALCHEMY_DATABASE_URI',
    f'postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}'
)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# ── Безопасность сессий ──────────────────────────────────────────────────────
app.config['SESSION_COOKIE_HTTPONLY'] = True          # JS не может читать куки
app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'         # Защита от CSRF через cookie
app.config['SESSION_COOKIE_SECURE'] = (               # HTTPS-only в production
    os.getenv('FLASK_ENV', 'development') == 'production'
)
app.config['PERMANENT_SESSION_LIFETIME'] = 3600        # Сессия 1 час

db = SQLAlchemy(app)
login_manager = LoginManager(app)
login_manager.login_view = 'login'
login_manager.login_message = 'Please log in to access this page.'

# Initialize Prometheus metrics AFTER all configurations
if PROMETHEUS_AVAILABLE:
    try:
        # This ensures /metrics endpoint is properly registered
        metrics = PrometheusMetrics(app, path='/metrics')
        print("✅ Prometheus metrics endpoint registered at /metrics")
    except Exception as e:
        print(f"⚠️ Failed to initialize PrometheusMetrics: {e}")
        PROMETHEUS_AVAILABLE = False
else:
    metrics = None
    print("⚠️ Prometheus metrics will use fallback endpoint")

# ── Security headers (для каждого ответа) ────────────────────────────────────
@app.after_request
def set_security_headers(response):
    response.headers.setdefault('X-Content-Type-Options', 'nosniff')
    response.headers.setdefault('X-Frame-Options', 'SAMEORIGIN')
    response.headers.setdefault('X-XSS-Protection', '1; mode=block')
    response.headers.setdefault('Referrer-Policy', 'strict-origin-when-cross-origin')
    return response

# ========================================
# МОДЕЛИ (Models)
# ========================================

# Helper function for file uploads
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# Admin decorator
def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated or current_user.role != 'admin':
            flash('Для доступа к этой странице нужны права администратора.', 'danger')
            return redirect(url_for('index'))
        return f(*args, **kwargs)
    return decorated_function

class User(UserMixin, db.Model):
    __tablename__ = 'users'
    user_id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), nullable=False, unique=True)
    email = db.Column(db.String(100), nullable=False, unique=True)
    password_hash = db.Column(db.String(255), nullable=False)
    full_name = db.Column(db.String(100))
    phone = db.Column(db.String(20))
    role = db.Column(db.String(20), default='user')
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.now)
    last_login = db.Column(db.DateTime)
    orders = db.relationship('Order', backref='user', lazy=True)
    
    def get_id(self):
        return str(self.user_id)
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

class Position(db.Model):
    __tablename__ = 'positions'
    position_id = db.Column(db.Integer, primary_key=True)
    position_name = db.Column(db.String(50), nullable=False, unique=True)
    base_salary = db.Column(db.Numeric(10, 2), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.now)
    employees = db.relationship('Employee', backref='position', lazy=True)

class Employee(db.Model):
    __tablename__ = 'employees'
    employee_id = db.Column(db.Integer, primary_key=True)
    first_name = db.Column(db.String(50), nullable=False)
    last_name = db.Column(db.String(50), nullable=False)
    phone = db.Column(db.String(20), unique=True)
    email = db.Column(db.String(100), unique=True)
    position_id = db.Column(db.Integer, db.ForeignKey('positions.position_id'), nullable=False)
    hire_date = db.Column(db.Date, nullable=False, default=datetime.now().date)
    salary = db.Column(db.Numeric(10, 2), nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.now)
    orders = db.relationship('Order', backref='employee', lazy=True)

    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"

class Customer(db.Model):
    __tablename__ = 'customers'
    customer_id = db.Column(db.Integer, primary_key=True)
    first_name = db.Column(db.String(50), nullable=False)
    last_name = db.Column(db.String(50), nullable=False)
    phone = db.Column(db.String(20), unique=True, nullable=False)
    email = db.Column(db.String(100), unique=True)
    loyalty_points = db.Column(db.Integer, default=0)
    registration_date = db.Column(db.Date, nullable=False, default=datetime.now().date)
    created_at = db.Column(db.DateTime, default=datetime.now)
    orders = db.relationship('Order', backref='customer', lazy=True)

    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"

class Category(db.Model):
    __tablename__ = 'categories'
    category_id = db.Column(db.Integer, primary_key=True)
    category_name = db.Column(db.String(50), nullable=False, unique=True)
    description = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.now)
    products = db.relationship('Product', backref='category', lazy=True)

class Product(db.Model):
    __tablename__ = 'products'
    product_id = db.Column(db.Integer, primary_key=True)
    product_name = db.Column(db.String(100), nullable=False)
    category_id = db.Column(db.Integer, db.ForeignKey('categories.category_id'), nullable=False)
    price = db.Column(db.Numeric(10, 2), nullable=False)
    description = db.Column(db.Text)
    is_available = db.Column(db.Boolean, default=True)
    preparation_time = db.Column(db.Integer)
    image_url = db.Column(db.String(255))
    created_at = db.Column(db.DateTime, default=datetime.now)
    order_items = db.relationship('OrderItem', backref='product', lazy=True)

class Ingredient(db.Model):
    __tablename__ = 'ingredients'
    ingredient_id = db.Column(db.Integer, primary_key=True)
    ingredient_name = db.Column(db.String(100), nullable=False, unique=True)
    unit = db.Column(db.String(20), nullable=False)
    stock_quantity = db.Column(db.Numeric(10, 2), nullable=False)
    min_quantity = db.Column(db.Numeric(10, 2), nullable=False)
    cost_per_unit = db.Column(db.Numeric(10, 2), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.now)

    @property
    def needs_restock(self):
        return self.stock_quantity <= self.min_quantity
    
    def can_use(self, quantity):
        """Check if enough stock is available"""
        return self.stock_quantity >= quantity
    
    def use(self, quantity):
        """Deduct quantity from stock"""
        if not self.can_use(quantity):
            raise ValueError(f"Not enough {self.ingredient_name} in stock")
        self.stock_quantity -= Decimal(str(quantity))
    
    def restock(self, quantity):
        """Add quantity to stock"""
        self.stock_quantity += Decimal(str(quantity))

class ProductIngredient(db.Model):
    __tablename__ = 'product_ingredients'
    product_ingredient_id = db.Column(db.Integer, primary_key=True)
    product_id = db.Column(db.Integer, db.ForeignKey('products.product_id'), nullable=False)
    ingredient_id = db.Column(db.Integer, db.ForeignKey('ingredients.ingredient_id'), nullable=False)
    quantity = db.Column(db.Numeric(10, 2), nullable=False)
    
    # Relationships
    product = db.relationship('Product', backref=db.backref('ingredients_list', lazy=True))
    ingredient = db.relationship('Ingredient', backref=db.backref('used_in_products', lazy=True))

class Order(db.Model):
    __tablename__ = 'orders'
    order_id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.user_id'))
    customer_id = db.Column(db.Integer, db.ForeignKey('customers.customer_id'))
    employee_id = db.Column(db.Integer, db.ForeignKey('employees.employee_id'), nullable=False)
    order_date = db.Column(db.DateTime, nullable=False, default=datetime.now)
    total_amount = db.Column(db.Numeric(10, 2), nullable=False, default=0)
    status = db.Column(db.String(20), nullable=False, default='pending')
    payment_method = db.Column(db.String(20), nullable=False)
    notes = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.now)
    order_items = db.relationship('OrderItem', backref='order', lazy=True, cascade='all, delete-orphan')

class OrderItem(db.Model):
    __tablename__ = 'order_items'
    order_item_id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.Integer, db.ForeignKey('orders.order_id'), nullable=False)
    product_id = db.Column(db.Integer, db.ForeignKey('products.product_id'), nullable=False)
    quantity = db.Column(db.Integer, nullable=False)
    unit_price = db.Column(db.Numeric(10, 2), nullable=False)
    subtotal = db.Column(db.Numeric(10, 2), nullable=False)
    customization = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.now)

class Notification(db.Model):
    __tablename__ = 'notifications'
    notification_id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    message = db.Column(db.Text, nullable=False)
    category = db.Column(db.String(30), default='system')  # order, inventory, backup, auth, system, product
    level = db.Column(db.String(20), default='info')       # info, warning, error, critical, success
    is_read = db.Column(db.Boolean, default=False)
    related_id = db.Column(db.Integer, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.now)
    created_by = db.Column(db.String(50), default='system')

# ========================================
# HELPER FUNCTIONS FOR INGREDIENTS
# ========================================

def check_product_availability(product_id, quantity=1):
    """Check if product can be made with current ingredient stock"""
    product_ingredients = ProductIngredient.query.filter_by(product_id=product_id).all()
    
    if not product_ingredients:
        # Product has no ingredients defined, assume available
        return True, None
    
    for pi in product_ingredients:
        required = Decimal(str(pi.quantity)) * Decimal(str(quantity))
        if pi.ingredient.stock_quantity < required:
            return False, f"Not enough {pi.ingredient.ingredient_name} (need {required} {pi.ingredient.unit}, have {pi.ingredient.stock_quantity})"
    
    return True, None

def deduct_ingredients(product_id, quantity=1):
    """Deduct ingredients for product from stock"""
    product_ingredients = ProductIngredient.query.filter_by(product_id=product_id).all()
    
    deducted = []
    low_stock_ingredients = []
    
    try:
        for pi in product_ingredients:
            required = Decimal(str(pi.quantity)) * Decimal(str(quantity))
            pi.ingredient.use(required)
            deducted.append({
                'ingredient': pi.ingredient.ingredient_name,
                'amount': float(required),
                'unit': pi.ingredient.unit
            })
            
            # Check if ingredient is now below minimum
            if pi.ingredient.needs_restock:
                low_stock_ingredients.append({
                    'name': pi.ingredient.ingredient_name,
                    'current': float(pi.ingredient.stock_quantity),
                    'minimum': float(pi.ingredient.min_quantity),
                    'unit': pi.ingredient.unit
                })
        
        # Send Telegram notification if any ingredient is low
        if low_stock_ingredients and TELEGRAM_AVAILABLE:
            try:
                notifier = get_notifier()
                
                items_text = []
                for ing in low_stock_ingredients:
                    items_text.append(
                        f"• <b>{ing['name']}</b>: {ing['current']}/{ing['minimum']} {ing['unit']}"
                    )
                
                message = f"""
⚠️ <b>НИЗКИЙ ОСТАТОК ИНГРЕДИЕНТОВ!</b>

Необходимо пополнение:
{chr(10).join(items_text)}

📦 Перейдите в раздел Inventory для пополнения запасов

⏰ {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""
                notifier.send_message(message)
                print(f"📱 Telegram: низкий остаток ингредиентов")
            except Exception as e:
                print(f"⚠️ Telegram notification failed: {e}")
        
        # Уведомление на сайте о низком остатке
        if low_stock_ingredients:
            names = ', '.join(ing['name'] for ing in low_stock_ingredients)
            create_notification(
                title='⚠️ Низкий остаток ингредиентов',
                message=f'Необходимо пополнение: {names}',
                category='inventory', level='warning'
            )
        
        return True, deducted
    except ValueError as e:
        # Rollback if any ingredient fails
        db.session.rollback()
        return False, str(e)

def update_product_availability():
    """Update product availability based on ingredient stock"""
    products = Product.query.all()
    updated = 0
    
    for product in products:
        available, reason = check_product_availability(product.product_id, 1)
        if product.is_available != available:
            product.is_available = available
            updated += 1
    
    if updated > 0:
        db.session.commit()
    
    return updated

def create_notification(title, message, category='system', level='info', related_id=None, created_by='system'):
    """Сохранить уведомление в базу данных для отображения на сайте"""
    try:
        notif = Notification(
            title=title,
            message=message,
            category=category,
            level=level,
            related_id=related_id,
            created_by=created_by
        )
        db.session.add(notif)
        db.session.commit()
    except Exception as e:
        print(f"⚠️ Не удалось создать уведомление: {e}")
        db.session.rollback()

# ========================================
# МАРШРУТЫ (Routes)
# ========================================

@app.route('/health')
def health_check():
    """Health check endpoint for monitoring"""
    try:
        db_status = 'connected' if db.session.execute(db.text('SELECT 1')).scalar() == 1 else 'disconnected'
    except:
        db_status = 'error'
    
    return jsonify({
        'status': 'healthy',
        'service': 'bubble-tea-app',
        'database': db_status,
        'prometheus': 'enabled' if PROMETHEUS_AVAILABLE else 'fallback'
    }), 200

@app.route('/metrics')
def metrics_endpoint():
    """Fallback metrics endpoint if PrometheusMetrics is not available"""
    if PROMETHEUS_AVAILABLE:
        # PrometheusMetrics already handles this, but just in case
        try:
            return Response(generate_latest(REGISTRY), mimetype='text/plain')
        except:
            pass
    
    # Fallback: simple text metrics
    metrics_text = """# HELP flask_app_info Flask application information
# TYPE flask_app_info gauge
flask_app_info{version="1.0",service="bubble-tea"} 1

# HELP flask_app_health Application health status (1=healthy, 0=unhealthy)
# TYPE flask_app_health gauge
flask_app_health 1

# HELP flask_database_status Database connection status (1=connected, 0=disconnected)
# TYPE flask_database_status gauge
"""
    try:
        db_check = db.session.execute(db.text('SELECT 1')).scalar()
        metrics_text += "flask_database_status 1\n"
    except:
        metrics_text += "flask_database_status 0\n"
    
    # Add product count
    try:
        product_count = Product.query.count()
        metrics_text += f"\n# HELP flask_products_total Total number of products\n"
        metrics_text += f"# TYPE flask_products_total gauge\n"
        metrics_text += f"flask_products_total {product_count}\n"
    except:
        pass
    
    # Add order count
    try:
        order_count = Order.query.count()
        metrics_text += f"\n# HELP flask_orders_total Total number of orders\n"
        metrics_text += f"# TYPE flask_orders_total gauge\n"
        metrics_text += f"flask_orders_total {order_count}\n"
    except:
        pass
    
    return Response(metrics_text, mimetype='text/plain; version=0.0.4')

@app.route('/')
def index():
    """Главная страница"""
    categories = Category.query.all()
    featured_products = Product.query.filter_by(is_available=True).limit(6).all()
    return render_template('index.html', categories=categories, products=featured_products)

@app.route('/menu')
def menu():
    """Страница меню"""
    categories = Category.query.all()
    category_id = request.args.get('category', type=int)
    
    if category_id:
        products = Product.query.filter_by(category_id=category_id, is_available=True).all()
    else:
        products = Product.query.filter_by(is_available=True).all()
    
    return render_template('menu.html', categories=categories, products=products, selected_category=category_id)

@app.route('/product/<int:product_id>')
def product_detail(product_id):
    """Product detail page"""
    product = Product.query.get_or_404(product_id)
    return render_template('product_detail.html', product=product)

@app.route('/order/new', methods=['GET', 'POST'])
def new_order():
    """Create new order"""
    if request.method == 'POST':
        try:
            # Get form data
            customer_phone = request.form.get('customer_phone')
            payment_method = request.form.get('payment_method')
            notes = request.form.get('notes')
            
            # Find or create customer
            customer = None
            if customer_phone:
                customer = Customer.query.filter_by(phone=customer_phone).first()
                if not customer and request.form.get('customer_name'):
                    name_parts = request.form.get('customer_name').split(' ', 1)
                    customer = Customer(
                        first_name=name_parts[0],
                        last_name=name_parts[1] if len(name_parts) > 1 else '',
                        phone=customer_phone
                    )
                    db.session.add(customer)
                    db.session.flush()
            
            # Create order
            employee = Employee.query.filter_by(is_active=True).first()
            if not employee:
                flash('Нет доступных сотрудников', 'error')
                return redirect(url_for('menu'))
            
            order = Order(
                user_id=current_user.user_id if current_user.is_authenticated else None,
                customer_id=customer.customer_id if customer else None,
                employee_id=employee.employee_id,
                payment_method=payment_method,
                notes=notes,
                status='pending'
            )
            db.session.add(order)
            db.session.flush()
            
            # Add order items and check ingredients
            cart_items = request.form.getlist('product_id')
            quantities = request.form.getlist('quantity')
            total = Decimal('0')
            
            # First pass: Check all ingredients availability
            ingredients_check = []
            for i, product_id in enumerate(cart_items):
                quantity = int(quantities[i])
                if quantity > 0:
                    available, reason = check_product_availability(product_id, quantity)
                    if not available:
                        ingredients_check.append((product_id, reason))
            
            # If any product lacks ingredients, abort
            if ingredients_check:
                error_messages = []
                for product_id, reason in ingredients_check:
                    product = Product.query.get(product_id)
                    error_messages.append(f"{product.product_name}: {reason}")
                flash(f'Невозможно создать заказ: {"; ".join(error_messages)}', 'error')
                return redirect(url_for('new_order'))
            
            # Second pass: Add items and deduct ingredients
            for i, product_id in enumerate(cart_items):
                quantity = int(quantities[i])
                product = Product.query.get(product_id)
                
                if product and quantity > 0:
                    # Deduct ingredients
                    success, result = deduct_ingredients(product_id, quantity)
                    if not success:
                        db.session.rollback()
                        flash(f'Ошибка списания ингредиентов: {result}', 'error')
                        return redirect(url_for('new_order'))
                    
                    # Add order item
                    subtotal = product.price * quantity
                    order_item = OrderItem(
                        order_id=order.order_id,
                        product_id=product.product_id,
                        quantity=quantity,
                        unit_price=product.price,
                        subtotal=subtotal
                    )
                    db.session.add(order_item)
                    total += subtotal
            
            order.total_amount = total
            db.session.commit()
            
            # Update product availability after ingredient deduction
            update_product_availability()
            
            # Send Telegram notification about new order
            if TELEGRAM_AVAILABLE:
                try:
                    notifier = get_notifier()
                    
                    # Формируем список товаров
                    items_list = []
                    for item in order.order_items:
                        items_list.append(f"• {item.product.product_name} x{item.quantity} (${float(item.subtotal):.2f})")
                    
                    customer_name = customer.full_name if customer else "Guest"
                    
                    message = f"""
🛒 <b>НОВЫЙ ЗАКАЗ #{order.order_id}</b>

👤 <b>Клиент:</b> {customer_name}
💰 <b>Сумма:</b> ${float(total):.2f}
💳 <b>Оплата:</b> {payment_method}

<b>Товары:</b>
{chr(10).join(items_list)}

⏰ {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""
                    notifier.send_message(message)
                    print(f"📱 Telegram: новый заказ #{order.order_id}")
                except Exception as e:
                    print(f"⚠️ Telegram notification failed: {e}")
            
            create_notification(
                title=f'🛒 Новый заказ #{order.order_id}',
                message=f'Клиент: {customer.full_name if customer else "Гость"} | Сумма: ${float(total):.2f} | Оплата: {payment_method}',
                category='order', level='info',
                related_id=order.order_id,
                created_by=current_user.username if current_user.is_authenticated else 'guest'
            )
            
            flash(f'Заказ #{order.order_id} успешно создан! Ингредиенты списаны.', 'success')
            return redirect(url_for('order_detail', order_id=order.order_id))
            
        except Exception as e:
            db.session.rollback()
            print(f"[ERROR] create order: {e}")
            flash('Ошибка при создании заказа. Попробуйте снова.', 'error')
            return redirect(url_for('menu'))
    
    products = Product.query.filter_by(is_available=True).all()
    return render_template('new_order.html', products=products)

@app.route('/order/<int:order_id>')
@login_required
def order_detail(order_id):
    """Order detail page"""
    order = Order.query.get_or_404(order_id)
    # Только администратор или владелец заказа может просматривать детали
    if current_user.role != 'admin' and order.user_id != current_user.user_id:
        flash('Доступ запрещён: вы можете просматривать только свои заказы.', 'danger')
        return redirect(url_for('index'))
    return render_template('order_detail.html', order=order)

@app.route('/orders')
@login_required
@admin_required
def orders_list():
    """All orders list"""
    status = request.args.get('status')
    page = request.args.get('page', 1, type=int)
    per_page = 20
    
    query = Order.query
    if status:
        query = query.filter_by(status=status)
    
    orders = query.order_by(Order.order_date.desc()).paginate(page=page, per_page=per_page, error_out=False)
    return render_template('orders_list.html', orders=orders, current_status=status)

@app.route('/customers')
@login_required
@admin_required
def customers_list():
    """Customers list"""
    customers = Customer.query.order_by(Customer.loyalty_points.desc()).all()
    return render_template('customers_list.html', customers=customers)

@app.route('/employees')
@login_required
@admin_required
def employees_list():
    """Employees list"""
    employees = Employee.query.filter_by(is_active=True).all()
    return render_template('employees_list.html', employees=employees)

@app.route('/inventory')
@login_required
@admin_required
def inventory():
    """Inventory management"""
    ingredients = Ingredient.query.order_by(Ingredient.ingredient_name).all()
    low_stock = [ing for ing in ingredients if ing.needs_restock]
    
    # Check if any products became unavailable
    update_product_availability()
    
    return render_template('inventory.html', ingredients=ingredients, low_stock=low_stock)

@app.route('/inventory/restock/<int:ingredient_id>', methods=['POST'])
@login_required
@admin_required
def restock_ingredient(ingredient_id):
    """Restock ingredient"""
    try:
        ingredient = Ingredient.query.get_or_404(ingredient_id)
        quantity = request.form.get('quantity', type=float)
        
        if not quantity or quantity <= 0:
            flash('Некорректное количество', 'error')
            return redirect(url_for('inventory'))
        
        old_quantity = float(ingredient.stock_quantity)
        ingredient.restock(quantity)
        db.session.commit()
        
        # Update product availability after restocking
        updated = update_product_availability()
        
        create_notification(
            title=f'📦 Пополнение склада',
            message=f'{ingredient.ingredient_name}: {old_quantity} → {float(ingredient.stock_quantity)} {ingredient.unit}',
            category='inventory', level='success',
            created_by=current_user.username
        )
        
        flash(f'Склад пополнен: {ingredient.ingredient_name}: {old_quantity} → {float(ingredient.stock_quantity)} {ingredient.unit}. Обновлено продуктов: {updated}.', 'success')
    except Exception as e:
        db.session.rollback()
        print(f"[ERROR] restock ingredient: {e}")
        flash('Ошибка пополнения склада. Попробуйте ещё раз.', 'error')
    
    return redirect(url_for('inventory'))

@app.route('/inventory/check-availability')
@login_required
@admin_required
def check_inventory_availability():
    """Check and update product availability based on ingredients"""
    try:
        updated = update_product_availability()
        flash(f'Проверка наличия завершена. Обновлено продуктов: {updated}.', 'info')
    except Exception as e:
        flash(f'Ошибка проверки наличия: {str(e)}', 'error')
    
    return redirect(url_for('inventory'))

@app.route('/analytics')
@login_required
@admin_required
def analytics():
    """Analytics and statistics"""
    # General statistics
    total_orders = Order.query.filter_by(status='completed').count()
    total_revenue = db.session.query(db.func.sum(Order.total_amount)).filter_by(status='completed').scalar() or 0
    total_customers = Customer.query.count()
    
    # Popular products
    popular_products = db.session.query(
        Product.product_name,
        db.func.sum(OrderItem.quantity).label('total_sold'),
        db.func.sum(OrderItem.subtotal).label('revenue')
    ).join(OrderItem).join(Order).filter(
        Order.status == 'completed'
    ).group_by(Product.product_id, Product.product_name).order_by(
        db.desc('total_sold')
    ).limit(10).all()
    
    return render_template('analytics.html', 
                         total_orders=total_orders,
                         total_revenue=total_revenue,
                         total_customers=total_customers,
                         popular_products=popular_products)

# ========================================
# API Routes
# ========================================

@app.route('/api/products')
def api_products():
    """API: products list"""
    products = Product.query.filter_by(is_available=True).all()
    return jsonify([{
        'id': p.product_id,
        'name': p.product_name,
        'price': float(p.price),
        'category': p.category.category_name
    } for p in products])

@app.route('/api/order/<int:order_id>/status', methods=['PUT'])
@login_required
@admin_required
def api_update_order_status(order_id):
    """API: update order status"""
    order = Order.query.get_or_404(order_id)
    data = request.get_json()
    
    new_status = data.get('status')
    if new_status in ['pending', 'preparing', 'ready', 'completed', 'cancelled']:
        order.status = new_status
        db.session.commit()
        return jsonify({'success': True, 'status': new_status})
    
    return jsonify({'success': False, 'error': 'Invalid status'}), 400

@app.route('/api/search/products')
def api_search_products():
    """API: Full-text search for products"""
    query = request.args.get('q', '')
    if not query:
        return jsonify({'error': 'Search query is required'}), 400
    
    try:
        result = db.session.execute(
            db.text("SELECT * FROM search_products(:query)"),
            {'query': query}
        )
        products = []
        for row in result:
            products.append({
                'product_id': row[0],
                'product_name': row[1],
                'category_name': row[2],
                'price': float(row[3]) if row[3] else 0,
                'description': row[4],
                'relevance': float(row[5]) if row[5] else 0
            })
        return jsonify({'success': True, 'results': products, 'count': len(products)})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/search/customers')
def api_search_customers():
    """API: Full-text search for customers"""
    query = request.args.get('q', '')
    if not query:
        return jsonify({'error': 'Search query is required'}), 400
    
    try:
        result = db.session.execute(
            db.text("SELECT * FROM search_customers(:query)"),
            {'query': query}
        )
        customers = []
        for row in result:
            customers.append({
                'customer_id': row[0],
                'full_name': row[1],
                'phone': row[2],
                'email': row[3],
                'loyalty_points': row[4],
                'relevance': float(row[5]) if row[5] else 0
            })
        return jsonify({'success': True, 'results': customers, 'count': len(customers)})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/search/orders')
def api_search_orders():
    """API: Full-text search for orders"""
    query = request.args.get('q', '')
    if not query:
        return jsonify({'error': 'Search query is required'}), 400
    
    try:
        result = db.session.execute(
            db.text("SELECT * FROM search_orders(:query)"),
            {'query': query}
        )
        orders = []
        for row in result:
            orders.append({
                'order_id': row[0],
                'order_date': row[1].isoformat() if row[1] else None,
                'customer_name': row[2],
                'employee_name': row[3],
                'total_amount': float(row[4]) if row[4] else 0,
                'status': row[5],
                'payment_method': row[6],
                'relevance': float(row[7]) if row[7] else 0
            })
        return jsonify({'success': True, 'results': orders, 'count': len(orders)})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/search/employees')
def api_search_employees():
    """API: Full-text search for employees"""
    query = request.args.get('q', '')
    if not query:
        return jsonify({'error': 'Search query is required'}), 400
    
    try:
        result = db.session.execute(
            db.text("SELECT * FROM search_employees(:query)"),
            {'query': query}
        )
        employees = []
        for row in result:
            employees.append({
                'employee_id': row[0],
                'full_name': row[1],
                'position_name': row[2],
                'phone': row[3],
                'email': row[4],
                'salary': float(row[5]) if row[5] else 0,
                'relevance': float(row[6]) if row[6] else 0
            })
        return jsonify({'success': True, 'results': employees, 'count': len(employees)})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# ========================================
# Search Route
# ========================================

@app.route('/search')
def search():
    """Full-text search page"""
    return render_template('search.html')

# ========================================
# Authentication Routes
# ========================================

@app.route('/login', methods=['GET', 'POST'])
def login():
    """Login page"""
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        user = User.query.filter_by(username=username).first()
        
        if user and user.check_password(password) and user.is_active:
            login_user(user)
            user.last_login = datetime.now()
            db.session.commit()
            
            create_notification(
                title=f'🔑 Вход в систему',
                message=f'Пользователь {user.username} ({user.role}) вошёл в систему',
                category='auth', level='info',
                created_by=user.username
            )
            
            next_page = request.args.get('next')
            # Защита от open redirect: разрешаем только относительные пути
            if next_page and (not next_page.startswith('/') or next_page.startswith('//')):
                next_page = None
            flash(f'С возвращением, {user.full_name or user.username}!', 'success')
            return redirect(next_page if next_page else url_for('index'))
        else:
            flash('Неверное имя пользователя или пароль', 'danger')
    
    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    """Registration page"""
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    
    if request.method == 'POST':
        username = request.form.get('username')
        email = request.form.get('email')
        full_name = request.form.get('full_name')
        password = request.form.get('password')
        confirm_password = request.form.get('confirm_password')
        
        if password != confirm_password:
            flash('Пароли не совпадают', 'danger')
            return render_template('register.html')
        
        if User.query.filter_by(username=username).first():
            flash('Имя пользователя уже занято', 'danger')
            return render_template('register.html')
        
        if User.query.filter_by(email=email).first():
            flash('Этот email уже зарегистрирован', 'danger')
            return render_template('register.html')
        
        new_user = User(
            username=username,
            email=email,
            full_name=full_name,
            role='user'
        )
        new_user.set_password(password)
        
        db.session.add(new_user)
        db.session.commit()
        
        flash('Регистрация прошла успешно! Войдите в систему.', 'success')
        return redirect(url_for('login'))
    
    return render_template('register.html')

@app.route('/logout')
@login_required
def logout():
    """Logout"""
    logout_user()
    flash('Вы вышли из системы.', 'info')
    return redirect(url_for('index'))

# ========================================
# User Profile Routes
# ========================================

@app.route('/profile')
@login_required
def profile():
    """User profile page"""
    # Get user's orders
    user_orders = Order.query.filter_by(user_id=current_user.user_id).order_by(Order.order_date.desc()).limit(10).all()
    total_orders = Order.query.filter_by(user_id=current_user.user_id).count()
    total_spent = db.session.query(db.func.sum(Order.total_amount)).filter_by(
        user_id=current_user.user_id, 
        status='completed'
    ).scalar() or 0
    
    return render_template('profile.html', 
                         user_orders=user_orders,
                         total_orders=total_orders,
                         total_spent=total_spent)

@app.route('/profile/settings', methods=['GET', 'POST'])
@login_required
def profile_settings():
    """User settings page"""
    if request.method == 'POST':
        action = request.form.get('action')
        
        if action == 'update_profile':
            current_user.full_name = request.form.get('full_name')
            current_user.email = request.form.get('email')
            current_user.phone = request.form.get('phone')
            
            db.session.commit()
            flash('Профиль успешно обновлён!', 'success')
            return redirect(url_for('profile_settings'))
        
        elif action == 'change_password':
            old_password = request.form.get('old_password')
            new_password = request.form.get('new_password')
            confirm_password = request.form.get('confirm_password')
            
            if not current_user.check_password(old_password):
                flash('Текущий пароль неверен', 'danger')
            elif new_password != confirm_password:
                flash('Новые пароли не совпадают', 'danger')
            elif len(new_password) < 8:
                flash('Пароль должен содержать минимум 8 символов', 'danger')
            else:
                current_user.set_password(new_password)
                db.session.commit()
                flash('Пароль успешно изменён!', 'success')
                return redirect(url_for('profile_settings'))
    
    return render_template('profile_settings.html')

@app.route('/profile/orders')
@login_required
def profile_orders():
    """User order history"""
    page = request.args.get('page', 1, type=int)
    per_page = 10
    
    orders = Order.query.filter_by(user_id=current_user.user_id).order_by(
        Order.order_date.desc()
    ).paginate(page=page, per_page=per_page, error_out=False)
    
    return render_template('profile_orders.html', orders=orders)

# ========================================
# Admin Panel Routes
# ========================================

@app.route('/admin/users')
@login_required
@admin_required
def admin_users_list():
    """Admin: List all users"""
    page = request.args.get('page', 1, type=int)
    per_page = 20
    
    users = User.query.order_by(User.created_at.desc()).paginate(
        page=page, per_page=per_page, error_out=False
    )
    
    return render_template('admin/users_list.html', users=users)

@app.route('/admin/user/<int:user_id>')
@login_required
@admin_required
def admin_view_user(user_id):
    """Admin: View user profile"""
    user = User.query.get_or_404(user_id)
    
    # Get user's orders
    user_orders = Order.query.filter_by(user_id=user.user_id).order_by(Order.order_date.desc()).limit(10).all()
    total_orders = Order.query.filter_by(user_id=user.user_id).count()
    total_spent = db.session.query(db.func.sum(Order.total_amount)).filter_by(
        user_id=user.user_id, 
        status='completed'
    ).scalar() or 0
    
    return render_template('admin/user_profile.html', 
                         user=user,
                         user_orders=user_orders,
                         total_orders=total_orders,
                         total_spent=total_spent)

@app.route('/admin')
@login_required
@admin_required
def admin_panel():
    """Admin dashboard"""
    total_products = Product.query.count()
    total_users = User.query.count()
    total_orders = Order.query.count()
    total_customers = Customer.query.count()
    
    recent_products = Product.query.order_by(Product.created_at.desc()).limit(5).all()
    recent_orders = Order.query.order_by(Order.order_date.desc()).limit(5).all()
    
    return render_template('admin/dashboard.html',
                         total_products=total_products,
                         total_users=total_users,
                         total_orders=total_orders,
                         total_customers=total_customers,
                         recent_products=recent_products,
                         recent_orders=recent_orders)

@app.route('/admin/products')
@login_required
@admin_required
def admin_products():
    """Admin: Product management"""
    products = Product.query.order_by(Product.product_name).all()
    categories = Category.query.all()
    return render_template('admin/products.html', products=products, categories=categories)

@app.route('/admin/product/add', methods=['GET', 'POST'])
@login_required
@admin_required
def admin_product_add():
    """Admin: Add new product"""
    if request.method == 'POST':
        product_name = request.form.get('product_name')
        category_id = request.form.get('category_id')
        price = request.form.get('price')
        description = request.form.get('description')
        preparation_time = request.form.get('preparation_time')
        is_available = request.form.get('is_available') == 'on'
        
        # Handle image upload
        image_url = None
        if 'image' in request.files:
            file = request.files['image']
            if file and file.filename and allowed_file(file.filename):
                filename = secure_filename(file.filename)
                # Add timestamp to make filename unique
                filename = f"{datetime.now().strftime('%Y%m%d%H%M%S')}_{filename}"
                filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
                os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
                file.save(filepath)
                image_url = f"/static/images/products/{filename}"
        
        new_product = Product(
            product_name=product_name,
            category_id=category_id,
            price=price,
            description=description,
            preparation_time=preparation_time,
            is_available=is_available,
            image_url=image_url
        )
        
        db.session.add(new_product)
        db.session.commit()
        
        create_notification(
            title=f'✅ Новый продукт добавлен',
            message=f'Продукт "{product_name}" добавлен администратором {current_user.username}',
            category='product', level='success',
            related_id=new_product.product_id,
            created_by=current_user.username
        )
        
        flash(f'Продукт "{product_name}" успешно добавлен!', 'success')
        return redirect(url_for('admin_products'))
    
    categories = Category.query.all()
    return render_template('admin/product_form.html', product=None, categories=categories)

@app.route('/admin/product/edit/<int:product_id>', methods=['GET', 'POST'])
@login_required
@admin_required
def admin_product_edit(product_id):
    """Admin: Edit product"""
    product = Product.query.get_or_404(product_id)
    
    if request.method == 'POST':
        product.product_name = request.form.get('product_name')
        product.category_id = request.form.get('category_id')
        product.price = request.form.get('price')
        product.description = request.form.get('description')
        product.preparation_time = request.form.get('preparation_time')
        product.is_available = request.form.get('is_available') == 'on'
        
        # Handle image upload
        if 'image' in request.files:
            file = request.files['image']
            if file and file.filename and allowed_file(file.filename):
                filename = secure_filename(file.filename)
                filename = f"{datetime.now().strftime('%Y%m%d%H%M%S')}_{filename}"
                filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
                os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
                file.save(filepath)
                product.image_url = f"/static/images/products/{filename}"
        
        db.session.commit()
        flash(f'Продукт "{product.product_name}" успешно обновлён!', 'success')
        return redirect(url_for('admin_products'))
    
    categories = Category.query.all()
    return render_template('admin/product_form.html', product=product, categories=categories)

@app.route('/admin/product/delete/<int:product_id>', methods=['POST'])
@login_required
@admin_required
def admin_product_delete(product_id):
    """Admin: Delete product"""
    product = Product.query.get_or_404(product_id)
    product_name = product.product_name
    
    db.session.delete(product)
    db.session.commit()
    
    create_notification(
        title=f'Продукт удалён',
        message=f'Продукт "{product_name}" удалён администратором {current_user.username}',
        category='product', level='warning',
        created_by=current_user.username
    )
    
    flash(f'Продукт "{product_name}" успешно удалён!', 'success')
    return redirect(url_for('admin_products'))

# ========================================
# Admin Logs & Notifications
# ========================================

@app.route('/admin/logs')
@login_required
@admin_required
def admin_logs():
    """Admin: System logs and notifications"""
    page = request.args.get('page', 1, type=int)
    per_page = 30
    category = request.args.get('category', '')
    level = request.args.get('level', '')
    search = request.args.get('search', '')

    query = Notification.query

    if category:
        query = query.filter_by(category=category)
    if level:
        query = query.filter_by(level=level)
    if search:
        query = query.filter(
            db.or_(
                Notification.title.ilike(f'%{search}%'),
                Notification.message.ilike(f'%{search}%')
            )
        )

    notifications = query.order_by(Notification.created_at.desc()).paginate(
        page=page, per_page=per_page, error_out=False
    )

    # Stats
    stats = {
        'total': Notification.query.count(),
        'unread': Notification.query.filter_by(is_read=False).count(),
        'today': Notification.query.filter(
            Notification.created_at >= datetime.now().replace(hour=0, minute=0, second=0)
        ).count(),
        'by_level': {
            'info': Notification.query.filter_by(level='info').count(),
            'success': Notification.query.filter_by(level='success').count(),
            'warning': Notification.query.filter_by(level='warning').count(),
            'error': Notification.query.filter_by(level='error').count(),
            'critical': Notification.query.filter_by(level='critical').count(),
        },
        'by_category': {
            'order': Notification.query.filter_by(category='order').count(),
            'inventory': Notification.query.filter_by(category='inventory').count(),
            'backup': Notification.query.filter_by(category='backup').count(),
            'auth': Notification.query.filter_by(category='auth').count(),
            'product': Notification.query.filter_by(category='product').count(),
            'system': Notification.query.filter_by(category='system').count(),
        }
    }

    # Mark shown notifications as read
    Notification.query.filter_by(is_read=False).update({'is_read': True})
    db.session.commit()

    return render_template('admin/logs.html',
                           notifications=notifications,
                           stats=stats,
                           current_category=category,
                           current_level=level,
                           search=search)


# ========================================
# Notification API
# ========================================

@app.route('/api/notifications')
@login_required
def api_notifications():
    """API: получить последние уведомления для колокольчика"""
    if current_user.role != 'admin':
        return jsonify({'error': 'Forbidden'}), 403

    unread_count = Notification.query.filter_by(is_read=False).count()
    recent = Notification.query.order_by(Notification.created_at.desc()).limit(8).all()

    items = []
    for n in recent:
        items.append({
            'id': n.notification_id,
            'title': n.title,
            'message': n.message[:80] + '...' if len(n.message) > 80 else n.message,
            'category': n.category,
            'level': n.level,
            'is_read': n.is_read,
            'created_at': n.created_at.strftime('%d.%m %H:%M'),
            'created_by': n.created_by
        })

    return jsonify({'unread': unread_count, 'notifications': items})


@app.route('/api/notifications/read-all', methods=['POST'])
@login_required
def api_notifications_read_all():
    """API: отметить все уведомления прочитанными"""
    if current_user.role != 'admin':
        return jsonify({'error': 'Forbidden'}), 403
    Notification.query.filter_by(is_read=False).update({'is_read': True})
    db.session.commit()
    return jsonify({'status': 'ok'})


@app.route('/api/notifications/<int:notif_id>/read', methods=['POST'])
@login_required
def api_notification_read(notif_id):
    """API: отметить одно уведомление прочитанным"""
    if current_user.role != 'admin':
        return jsonify({'error': 'Forbidden'}), 403
    notif = Notification.query.get_or_404(notif_id)
    notif.is_read = True
    db.session.commit()
    return jsonify({'status': 'ok'})

# ========================================
# Обработчики ошибок
# ========================================

@app.errorhandler(404)
def not_found(error):
    return render_template('404.html'), 404

@app.errorhandler(500)
def internal_error(error):
    db.session.rollback()
    return render_template('500.html'), 500

# ========================================
# Фильтры шаблонов
# ========================================

@app.template_filter('currency')
def currency_filter(value):
    """Format currency in Tenge"""
    return f"{value:,.0f} ₸"

@app.template_filter('status_text')
def status_text_filter(status):
    """Status translation"""
    status_map = {
        'pending': 'Ожидание',
        'preparing': 'Готовится',
        'ready': 'Готов',
        'completed': 'Завершён',
        'cancelled': 'Отменён'
    }
    return status_map.get(status, status)

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    debug_mode = os.getenv('FLASK_DEBUG', 'false').lower() == 'true'
    app.run(debug=debug_mode, host='127.0.0.1', port=5000)

