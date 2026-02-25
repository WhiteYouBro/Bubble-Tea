-- ========================================
-- Database for Bubble Tea Cafe "BibaBobaBebe"
-- PostgreSQL 17
-- ========================================

-- Drop existing tables if any
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS product_ingredients CASCADE;
DROP TABLE IF EXISTS ingredients CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS positions CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ========================================
-- TABLE: Users (Authentication)
-- ========================================
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    phone VARCHAR(20),
    role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('admin', 'manager', 'user')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- ========================================
-- TABLE: Employee Positions
-- ========================================
CREATE TABLE positions (
    position_id SERIAL PRIMARY KEY,
    position_name VARCHAR(50) NOT NULL UNIQUE,
    base_salary DECIMAL(10, 2) NOT NULL CHECK (base_salary >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================================
-- TABLE: Employees
-- ========================================
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20) UNIQUE,
    email VARCHAR(100) UNIQUE,
    position_id INTEGER NOT NULL,
    hire_date DATE NOT NULL DEFAULT CURRENT_DATE,
    salary DECIMAL(10, 2) NOT NULL CHECK (salary >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_employee_position FOREIGN KEY (position_id) 
        REFERENCES positions(position_id) ON DELETE RESTRICT
);

-- ========================================
-- TABLE: Customers
-- ========================================
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE,
    loyalty_points INTEGER DEFAULT 0 CHECK (loyalty_points >= 0),
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================================
-- TABLE: Product Categories
-- ========================================
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================================
-- TABLE: Products (beverages and food)
-- ========================================
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category_id INTEGER NOT NULL,
    price DECIMAL(10, 2) NOT NULL CHECK (price > 0),
    description TEXT,
    is_available BOOLEAN DEFAULT TRUE,
    preparation_time INTEGER CHECK (preparation_time > 0), -- in minutes
    image_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_product_category FOREIGN KEY (category_id) 
        REFERENCES categories(category_id) ON DELETE RESTRICT
);

-- ========================================
-- TABLE: Ingredients
-- ========================================
CREATE TABLE ingredients (
    ingredient_id SERIAL PRIMARY KEY,
    ingredient_name VARCHAR(100) NOT NULL UNIQUE,
    unit VARCHAR(20) NOT NULL, -- ml, g, pcs
    stock_quantity DECIMAL(10, 2) NOT NULL CHECK (stock_quantity >= 0),
    min_quantity DECIMAL(10, 2) NOT NULL CHECK (min_quantity >= 0),
    cost_per_unit DECIMAL(10, 2) NOT NULL CHECK (cost_per_unit >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================================
-- TABLE: Product-Ingredient Relations
-- ========================================
CREATE TABLE product_ingredients (
    product_ingredient_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    ingredient_id INTEGER NOT NULL,
    quantity DECIMAL(10, 2) NOT NULL CHECK (quantity > 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pi_product FOREIGN KEY (product_id) 
        REFERENCES products(product_id) ON DELETE CASCADE,
    CONSTRAINT fk_pi_ingredient FOREIGN KEY (ingredient_id) 
        REFERENCES ingredients(ingredient_id) ON DELETE RESTRICT,
    CONSTRAINT unique_product_ingredient UNIQUE (product_id, ingredient_id)
);

-- ========================================
-- TABLE: Orders
-- ========================================
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    user_id INTEGER,
    customer_id INTEGER,
    employee_id INTEGER NOT NULL,
    order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10, 2) NOT NULL CHECK (total_amount >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' 
        CHECK (status IN ('pending', 'preparing', 'ready', 'completed', 'cancelled')),
    payment_method VARCHAR(20) NOT NULL 
        CHECK (payment_method IN ('cash', 'card', 'online')),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_order_user FOREIGN KEY (user_id) 
        REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_order_customer FOREIGN KEY (customer_id) 
        REFERENCES customers(customer_id) ON DELETE SET NULL,
    CONSTRAINT fk_order_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(employee_id) ON DELETE RESTRICT
);

-- ========================================
-- TABLE: Order Items
-- ========================================
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price >= 0),
    subtotal DECIMAL(10, 2) NOT NULL CHECK (subtotal >= 0),
    customization TEXT, -- additions, special requests
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_oi_order FOREIGN KEY (order_id) 
        REFERENCES orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_oi_product FOREIGN KEY (product_id) 
        REFERENCES products(product_id) ON DELETE RESTRICT
);

-- ========================================
-- INDEXES for query optimization
-- ========================================
CREATE INDEX idx_employees_position ON employees(position_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_employee ON orders(employee_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

-- ========================================
-- VIEWS
-- ========================================

-- View: Full product information
CREATE OR REPLACE VIEW v_products_full AS
SELECT 
    p.product_id,
    p.product_name,
    c.category_name,
    p.price,
    p.description,
    p.is_available,
    p.preparation_time
FROM products p
JOIN categories c ON p.category_id = c.category_id;

-- View: Daily sales statistics
CREATE OR REPLACE VIEW v_daily_sales AS
SELECT 
    DATE(order_date) as sale_date,
    COUNT(*) as total_orders,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_order_value
FROM orders
WHERE status = 'completed'
GROUP BY DATE(order_date)
ORDER BY sale_date DESC;

-- View: Popular products
CREATE OR REPLACE VIEW v_popular_products AS
SELECT 
    p.product_id,
    p.product_name,
    c.category_name,
    COUNT(oi.order_item_id) as times_ordered,
    SUM(oi.quantity) as total_quantity_sold,
    SUM(oi.subtotal) as total_revenue
FROM products p
JOIN categories c ON p.category_id = c.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.status = 'completed'
GROUP BY p.product_id, p.product_name, c.category_name
ORDER BY times_ordered DESC;

-- ========================================
-- TRIGGERS
-- ========================================

-- Function to automatically calculate subtotal in order_items
CREATE OR REPLACE FUNCTION calculate_subtotal()
RETURNS TRIGGER AS $$
BEGIN
    NEW.subtotal := NEW.quantity * NEW.unit_price;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_calculate_subtotal
BEFORE INSERT OR UPDATE ON order_items
FOR EACH ROW
EXECUTE FUNCTION calculate_subtotal();

-- Function to update total_amount in orders
CREATE OR REPLACE FUNCTION update_order_total()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE orders
    SET total_amount = (
        SELECT COALESCE(SUM(subtotal), 0)
        FROM order_items
        WHERE order_id = NEW.order_id
    )
    WHERE order_id = NEW.order_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_order_total_insert
AFTER INSERT ON order_items
FOR EACH ROW
EXECUTE FUNCTION update_order_total();

CREATE TRIGGER trg_update_order_total_update
AFTER UPDATE ON order_items
FOR EACH ROW
EXECUTE FUNCTION update_order_total();

-- Function to add loyalty points to customers
CREATE OR REPLACE FUNCTION add_loyalty_points()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' AND NEW.customer_id IS NOT NULL THEN
        UPDATE customers
        SET loyalty_points = loyalty_points + FLOOR(NEW.total_amount / 10)
        WHERE customer_id = NEW.customer_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_add_loyalty_points
AFTER UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION add_loyalty_points();

-- ========================================
-- TABLE COMMENTS
-- ========================================
COMMENT ON TABLE users IS 'System users for authentication';
COMMENT ON TABLE positions IS 'Employee positions';
COMMENT ON TABLE employees IS 'Employee information';
COMMENT ON TABLE customers IS 'Customers with loyalty program';
COMMENT ON TABLE categories IS 'Product categories';
COMMENT ON TABLE products IS 'Products and beverages';
COMMENT ON TABLE ingredients IS 'Ingredients for preparation';
COMMENT ON TABLE product_ingredients IS 'Product composition';
COMMENT ON TABLE orders IS 'Customer orders';
COMMENT ON TABLE order_items IS 'Order line items';

