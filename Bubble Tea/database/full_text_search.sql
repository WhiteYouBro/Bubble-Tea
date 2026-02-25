-- ========================================
-- Full-Text Search для Bubble Tea БД
-- PostgreSQL 17 - расширенный текстовый поиск
-- ========================================

-- ========================================
-- 1. Поиск по продуктам
-- ========================================

-- Создаем GIN индекс для полнотекстового поиска по продуктам
CREATE INDEX IF NOT EXISTS idx_products_fulltext 
ON products USING gin(
    to_tsvector('english', 
        product_name || ' ' || 
        COALESCE(description, '')
    )
);

-- Создаем функцию для поиска продуктов
CREATE OR REPLACE FUNCTION search_products(search_query TEXT)
RETURNS TABLE (
    product_id INTEGER,
    product_name VARCHAR(100),
    category_name VARCHAR(50),
    price DECIMAL(10, 2),
    description TEXT,
    relevance REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        p.price,
        p.description,
        ts_rank(
            to_tsvector('english', p.product_name || ' ' || COALESCE(p.description, '')),
            plainto_tsquery('english', search_query)
        ) as relevance
    FROM products p
    JOIN categories c ON p.category_id = c.category_id
    WHERE to_tsvector('english', p.product_name || ' ' || COALESCE(p.description, '')) 
        @@ plainto_tsquery('english', search_query)
    ORDER BY relevance DESC, p.product_name;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 2. Поиск по клиентам
-- ========================================

-- GIN индекс для поиска клиентов
CREATE INDEX IF NOT EXISTS idx_customers_fulltext 
ON customers USING gin(
    to_tsvector('english', 
        first_name || ' ' || 
        last_name || ' ' || 
        COALESCE(phone, '') || ' ' ||
        COALESCE(email, '')
    )
);

-- Функция поиска клиентов
CREATE OR REPLACE FUNCTION search_customers(search_query TEXT)
RETURNS TABLE (
    customer_id INTEGER,
    full_name TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    loyalty_points INTEGER,
    relevance REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.customer_id,
        (c.first_name || ' ' || c.last_name) as full_name,
        c.phone,
        c.email,
        c.loyalty_points,
        ts_rank(
            to_tsvector('english', 
                c.first_name || ' ' || c.last_name || ' ' || 
                COALESCE(c.phone, '') || ' ' || COALESCE(c.email, '')
            ),
            plainto_tsquery('english', search_query)
        ) as relevance
    FROM customers c
    WHERE to_tsvector('english', 
            c.first_name || ' ' || c.last_name || ' ' || 
            COALESCE(c.phone, '') || ' ' || COALESCE(c.email, '')
        ) @@ plainto_tsquery('english', search_query)
    ORDER BY relevance DESC, c.last_name, c.first_name;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 3. Поиск по заказам
-- ========================================

-- GIN индекс для поиска заказов
CREATE INDEX IF NOT EXISTS idx_orders_fulltext 
ON orders USING gin(
    to_tsvector('english', 
        order_id::TEXT || ' ' || 
        status || ' ' ||
        payment_method || ' ' ||
        COALESCE(notes, '')
    )
);

-- Функция поиска заказов
CREATE OR REPLACE FUNCTION search_orders(search_query TEXT)
RETURNS TABLE (
    order_id INTEGER,
    order_date TIMESTAMP,
    customer_name TEXT,
    employee_name TEXT,
    total_amount DECIMAL(10, 2),
    status VARCHAR(20),
    payment_method VARCHAR(20),
    relevance REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        o.order_id,
        o.order_date,
        COALESCE(cu.first_name || ' ' || cu.last_name, 'Guest') as customer_name,
        e.first_name || ' ' || e.last_name as employee_name,
        o.total_amount,
        o.status,
        o.payment_method,
        ts_rank(
            to_tsvector('english', 
                o.order_id::TEXT || ' ' || 
                o.status || ' ' || 
                o.payment_method || ' ' ||
                COALESCE(o.notes, '') || ' ' ||
                COALESCE(cu.first_name || ' ' || cu.last_name, '') || ' ' ||
                e.first_name || ' ' || e.last_name
            ),
            plainto_tsquery('english', search_query)
        ) as relevance
    FROM orders o
    LEFT JOIN customers cu ON o.customer_id = cu.customer_id
    JOIN employees e ON o.employee_id = e.employee_id
    WHERE to_tsvector('english', 
            o.order_id::TEXT || ' ' || 
            o.status || ' ' || 
            o.payment_method || ' ' ||
            COALESCE(o.notes, '') || ' ' ||
            COALESCE(cu.first_name || ' ' || cu.last_name, '') || ' ' ||
            e.first_name || ' ' || e.last_name
        ) @@ plainto_tsquery('english', search_query)
    ORDER BY relevance DESC, o.order_date DESC;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 4. Поиск по сотрудникам
-- ========================================

-- GIN индекс для поиска сотрудников
CREATE INDEX IF NOT EXISTS idx_employees_fulltext 
ON employees USING gin(
    to_tsvector('english', 
        first_name || ' ' || 
        last_name || ' ' ||
        COALESCE(phone, '') || ' ' ||
        COALESCE(email, '')
    )
);

-- Функция поиска сотрудников
CREATE OR REPLACE FUNCTION search_employees(search_query TEXT)
RETURNS TABLE (
    employee_id INTEGER,
    full_name TEXT,
    position_name VARCHAR(50),
    phone VARCHAR(20),
    email VARCHAR(100),
    salary DECIMAL(10, 2),
    relevance REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.employee_id,
        (e.first_name || ' ' || e.last_name) as full_name,
        p.position_name,
        e.phone,
        e.email,
        e.salary,
        ts_rank(
            to_tsvector('english', 
                e.first_name || ' ' || e.last_name || ' ' ||
                COALESCE(e.phone, '') || ' ' || COALESCE(e.email, '') || ' ' ||
                p.position_name
            ),
            plainto_tsquery('english', search_query)
        ) as relevance
    FROM employees e
    JOIN positions p ON e.position_id = p.position_id
    WHERE to_tsvector('english', 
            e.first_name || ' ' || e.last_name || ' ' ||
            COALESCE(e.phone, '') || ' ' || COALESCE(e.email, '') || ' ' ||
            p.position_name
        ) @@ plainto_tsquery('english', search_query)
        AND e.is_active = TRUE
    ORDER BY relevance DESC, e.last_name, e.first_name;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 5. Комментарии
-- ========================================

COMMENT ON FUNCTION search_products(TEXT) IS 'Full-text search for products by name and description';
COMMENT ON FUNCTION search_customers(TEXT) IS 'Full-text search for customers by name, phone, and email';
COMMENT ON FUNCTION search_orders(TEXT) IS 'Full-text search for orders by ID, status, and customer';
COMMENT ON FUNCTION search_employees(TEXT) IS 'Full-text search for employees by name, position, and contact';

COMMENT ON INDEX idx_products_fulltext IS 'GIN index for full-text search on products';
COMMENT ON INDEX idx_customers_fulltext IS 'GIN index for full-text search on customers';
COMMENT ON INDEX idx_orders_fulltext IS 'GIN index for full-text search on orders';
COMMENT ON INDEX idx_employees_fulltext IS 'GIN index for full-text search on employees';

-- ========================================
-- 6. Примеры использования
-- ========================================

-- Поиск продуктов:
-- SELECT * FROM search_products('tea milk');

-- Поиск клиентов:
-- SELECT * FROM search_customers('john');

-- Поиск заказов:
-- SELECT * FROM search_orders('completed card');

-- Поиск сотрудников:
-- SELECT * FROM search_employees('manager');

