-- Query Performance Analysis and Optimization
-- Examples of EXPLAIN ANALYZE for common queries

\echo '======================================'
\echo 'Query Performance Analysis'
\echo '======================================'

-- Enable timing
\timing on

-- ======================================
-- 1. Analyze orders with items (JOIN performance)
-- ======================================
\echo ''
\echo '1. Orders with Items Query'
\echo '--------------------------------------'

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    o.order_id,
    o.order_date,
    o.total_amount,
    o.status,
    e.full_name AS employee_name,
    COUNT(oi.order_item_id) AS item_count,
    SUM(oi.quantity) AS total_items
FROM orders o
JOIN employees e ON o.employee_id = e.employee_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY o.order_id, e.full_name
ORDER BY o.order_date DESC
LIMIT 50;

-- ======================================
-- 2. Product search with category
-- ======================================
\echo ''
\echo '2. Product Search Query'
\echo '--------------------------------------'

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    p.product_id,
    p.product_name,
    p.price,
    p.is_available,
    c.category_name
FROM products p
JOIN categories c ON p.category_id = c.category_id
WHERE p.is_available = true
    AND p.product_name ILIKE '%tea%'
ORDER BY p.price DESC;

-- ======================================
-- 3. Customer loyalty points calculation
-- ======================================
\echo ''
\echo '3. Customer Loyalty Analysis'
\echo '--------------------------------------'

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    c.customer_id,
    c.full_name,
    c.phone,
    c.loyalty_points,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS total_spent,
    MAX(o.order_date) AS last_order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id
HAVING COUNT(o.order_id) > 0
ORDER BY c.loyalty_points DESC
LIMIT 20;

-- ======================================
-- 4. Daily sales aggregation
-- ======================================
\echo ''
\echo '4. Daily Sales Report Query'
\echo '--------------------------------------'

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    DATE(order_date) AS sale_date,
    COUNT(*) AS orders_count,
    SUM(total_amount) AS revenue,
    AVG(total_amount) AS avg_order_value,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '90 days'
    AND status = 'completed'
GROUP BY DATE(order_date)
ORDER BY sale_date DESC;

-- ======================================
-- 5. Popular products (complex aggregation)
-- ======================================
\echo ''
\echo '5. Popular Products Analysis'
\echo '--------------------------------------'

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    p.product_id,
    p.product_name,
    c.category_name,
    COUNT(oi.order_item_id) AS times_ordered,
    SUM(oi.quantity) AS total_quantity,
    SUM(oi.subtotal) AS total_revenue,
    AVG(oi.quantity) AS avg_quantity_per_order
FROM products p
JOIN categories c ON p.category_id = c.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '30 days'
    OR o.order_date IS NULL
GROUP BY p.product_id, p.product_name, c.category_name
ORDER BY total_quantity DESC NULLS LAST
LIMIT 10;

-- ======================================
-- Index Recommendations
-- ======================================
\echo ''
\echo '======================================'
\echo 'Index Recommendations'
\echo '======================================'

-- Check missing indexes on foreign keys
\echo ''
\echo 'Foreign Keys Without Indexes:'
\echo '--------------------------------------'

SELECT 
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table,
    ccu.column_name AS foreign_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu 
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = tc.table_name 
            AND indexname LIKE '%' || kcu.column_name || '%'
    );

-- Suggest indexes for frequent WHERE clauses
\echo ''
\echo 'Suggested Indexes:'
\echo '--------------------------------------'
\echo '-- Based on common query patterns:'
\echo 'CREATE INDEX idx_orders_date_status ON orders(order_date, status);'
\echo 'CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date DESC);'
\echo 'CREATE INDEX idx_order_items_product ON order_items(product_id);'
\echo 'CREATE INDEX idx_products_name_available ON products(product_name, is_available);'
\echo 'CREATE INDEX idx_customers_phone ON customers(phone);'

\echo ''
\echo '======================================'
\echo 'Analysis Complete'
\echo '======================================'


