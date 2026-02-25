-- Create Optimized Indexes for Bubble Tea Database
-- Based on query analysis and performance testing

\echo '======================================'
\echo 'Creating Optimized Indexes'
\echo '======================================'

-- ======================================
-- Orders Table Indexes
-- ======================================
\echo ''
\echo 'Orders table indexes...'

-- Composite index for date range queries with status filter
CREATE INDEX IF NOT EXISTS idx_orders_date_status 
    ON orders(order_date DESC, status)
    WHERE status IN ('pending', 'preparing', 'ready');

-- Index for customer order history
CREATE INDEX IF NOT EXISTS idx_orders_customer_date 
    ON orders(customer_id, order_date DESC)
    WHERE customer_id IS NOT NULL;

-- Index for user orders
CREATE INDEX IF NOT EXISTS idx_orders_user_date 
    ON orders(user_id, order_date DESC)
    WHERE user_id IS NOT NULL;

-- Index for employee performance queries
CREATE INDEX IF NOT EXISTS idx_orders_employee_status 
    ON orders(employee_id, status, order_date DESC);

-- Partial index for active orders
CREATE INDEX IF NOT EXISTS idx_orders_active 
    ON orders(order_date DESC, status)
    WHERE status NOT IN ('completed', 'cancelled');

\echo '[OK] Orders indexes created'

-- ======================================
-- Order Items Table Indexes
-- ======================================
\echo ''
\echo 'Order items table indexes...'

-- Index for product sales analysis
CREATE INDEX IF NOT EXISTS idx_order_items_product 
    ON order_items(product_id, order_id);

-- Covering index for order details
CREATE INDEX IF NOT EXISTS idx_order_items_order_covering 
    ON order_items(order_id) 
    INCLUDE (product_id, quantity, unit_price, subtotal);

\echo '[OK] Order items indexes created'

-- ======================================
-- Products Table Indexes
-- ======================================
\echo ''
\echo 'Products table indexes...'

-- Text search index for product names
CREATE INDEX IF NOT EXISTS idx_products_name_search 
    ON products USING gin(to_tsvector('english', product_name || ' ' || COALESCE(description, '')));

-- Index for available products by category
CREATE INDEX IF NOT EXISTS idx_products_category_available 
    ON products(category_id, is_available)
    WHERE is_available = true;

-- Index for price-based queries
CREATE INDEX IF NOT EXISTS idx_products_price 
    ON products(price)
    WHERE is_available = true;

\echo '[OK] Products indexes created'

-- ======================================
-- Customers Table Indexes
-- ======================================
\echo ''
\echo 'Customers table indexes...'

-- Index for phone number lookups (loyalty system)
CREATE INDEX IF NOT EXISTS idx_customers_phone 
    ON customers(phone)
    WHERE phone IS NOT NULL;

-- Index for email lookups
CREATE INDEX IF NOT EXISTS idx_customers_email 
    ON customers(email)
    WHERE email IS NOT NULL;

-- Index for loyalty points queries
CREATE INDEX IF NOT EXISTS idx_customers_loyalty 
    ON customers(loyalty_points DESC)
    WHERE loyalty_points > 0;

\echo '[OK] Customers indexes created'

-- ======================================
-- Users Table Indexes
-- ======================================
\echo ''
\echo 'Users table indexes...'

-- Index for login queries
CREATE INDEX IF NOT EXISTS idx_users_username 
    ON users(username)
    WHERE is_active = true;

-- Index for email lookups
CREATE INDEX IF NOT EXISTS idx_users_email 
    ON users(email)
    WHERE is_active = true;

-- Index for role-based queries
CREATE INDEX IF NOT EXISTS idx_users_role_active 
    ON users(role, is_active);

\echo '[OK] Users indexes created'

-- ======================================
-- Employees Table Indexes
-- ======================================
\echo ''
\echo 'Employees table indexes...'

-- Index for active employees by position
CREATE INDEX IF NOT EXISTS idx_employees_position_active 
    ON employees(position_id, is_active)
    WHERE is_active = true;

\echo '[OK] Employees indexes created'

-- ======================================
-- Inventory Table Indexes
-- ======================================
\echo ''
\echo 'Inventory table indexes...'

-- Index for low stock alerts
CREATE INDEX IF NOT EXISTS idx_inventory_stock_level 
    ON inventory(current_stock)
    WHERE current_stock <= reorder_level;

-- Index for supplier queries
CREATE INDEX IF NOT EXISTS idx_inventory_supplier 
    ON inventory(supplier_id)
    WHERE supplier_id IS NOT NULL;

\echo '[OK] Inventory indexes created'

-- ======================================
-- Statistics Update
-- ======================================
\echo ''
\echo 'Updating table statistics...'

ANALYZE orders;
ANALYZE order_items;
ANALYZE products;
ANALYZE customers;
ANALYZE users;
ANALYZE employees;
ANALYZE inventory;

\echo '[OK] Statistics updated'

-- ======================================
-- Display Created Indexes
-- ======================================
\echo ''
\echo '======================================'
\echo 'Created Indexes Summary'
\echo '======================================'

SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes
WHERE schemaname = 'public'
    AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;

\echo ''
\echo '======================================'
\echo 'Index Creation Complete!'
\echo '======================================'


