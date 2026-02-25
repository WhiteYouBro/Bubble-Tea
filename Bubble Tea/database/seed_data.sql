-- ========================================
-- Test data for Bubble Tea Cafe "BibaBobaBebe"
-- ========================================

-- Positions
INSERT INTO positions (position_name, base_salary) VALUES
('Barista', 40000.00),
('Senior Barista', 55000.00),
('Shift Manager', 65000.00),
('Administrator', 75000.00),
('Director', 100000.00);

-- Employees
INSERT INTO employees (first_name, last_name, phone, email, position_id, hire_date, salary) VALUES
('Alex', 'Ivanov', '+7-900-123-4567', 'alex.ivanov@bibabobabebe.ru', 5, '2023-01-15', 100000.00),
('Maria', 'Petrova', '+7-900-234-5678', 'maria.petrova@bibabobabebe.ru', 4, '2023-02-01', 75000.00),
('Dmitry', 'Sidorov', '+7-900-345-6789', 'dmitry.sidorov@bibabobabebe.ru', 3, '2023-03-10', 65000.00),
('Anna', 'Kuznetsova', '+7-900-456-7890', 'anna.kuznetsova@bibabobabebe.ru', 2, '2023-04-05', 55000.00),
('Elena', 'Smirnova', '+7-900-567-8901', 'elena.smirnova@bibabobabebe.ru', 1, '2023-05-20', 40000.00),
('Ivan', 'Morozov', '+7-900-678-9012', 'ivan.morozov@bibabobabebe.ru', 1, '2023-06-15', 40000.00);

-- Customers
INSERT INTO customers (first_name, last_name, phone, email, loyalty_points, registration_date) VALUES
('Olga', 'Volkova', '+7-911-111-1111', 'olga.volkova@email.ru', 150, '2024-01-10'),
('Sergey', 'Novikov', '+7-911-222-2222', 'sergey.novikov@email.ru', 230, '2024-01-15'),
('Natalia', 'Fedorova', '+7-911-333-3333', 'natalia.fedorova@email.ru', 89, '2024-02-01'),
('Mikhail', 'Lebedev', '+7-911-444-4444', 'mikhail.lebedev@email.ru', 456, '2024-02-10'),
('Tatiana', 'Sokolova', '+7-911-555-5555', 'tatiana.sokolova@email.ru', 78, '2024-03-05'),
('Andrey', 'Popov', '+7-911-666-6666', 'andrey.popov@email.ru', 312, '2024-03-15'),
('Ekaterina', 'Kozlova', '+7-911-777-7777', 'ekaterina.kozlova@email.ru', 199, '2024-04-01'),
('Vladimir', 'Vasiliev', '+7-911-888-8888', 'vladimir.vasiliev@email.ru', 567, '2024-04-10');

-- Product Categories
INSERT INTO categories (category_name, description) VALUES
('Bubble Tea', 'Classic tea with boba pearls (tapioca)'),
('Fruit Tea', 'Refreshing fruit beverages'),
('Coffee Drinks', 'Coffee and coffee cocktails'),
('Smoothies', 'Fruit and berry smoothies'),
('Desserts', 'Pastries and sweets'),
('Snacks', 'Snacks and light bites');

-- Products (prices in USD)
INSERT INTO products (product_name, category_id, price, description, is_available, preparation_time, image_url) VALUES
-- Bubble Tea
('Classic Milk Tea', 1, 5.50, 'Black tea with milk and tapioca pearls', TRUE, 5, '/images/classic-milk-tea.jpg'),
('Taro Milk Tea', 1, 5.95, 'Tea with taro and tapioca pearls', TRUE, 5, '/images/taro-tea.jpg'),
('Matcha Latte with Boba', 1, 6.50, 'Green matcha tea with milk and tapioca pearls', TRUE, 6, '/images/matcha-boba.jpg'),
('Chocolate Boba', 1, 6.25, 'Chocolate drink with tapioca pearls', TRUE, 5, '/images/chocolate-boba.jpg'),
-- Fruit Tea
('Mango Fresh', 2, 5.25, 'Refreshing tea with fresh mango', TRUE, 4, '/images/mango-fresh.jpg'),
('Strawberry Blast', 2, 5.75, 'Tea with strawberry and fruit pieces', TRUE, 4, '/images/strawberry-blast.jpg'),
('Passion Fruit Tropic', 2, 5.95, 'Tropical tea with passion fruit', TRUE, 4, '/images/passion-tropic.jpg'),
-- Coffee Drinks
('Cappuccino', 3, 4.50, 'Classic Italian cappuccino', TRUE, 4, '/images/cappuccino.jpg'),
('Latte', 3, 4.75, 'Smooth coffee latte', TRUE, 4, '/images/latte.jpg'),
('Caramel Raf', 3, 5.50, 'Raf coffee with caramel syrup', TRUE, 5, '/images/caramel-raf.jpg'),
-- Smoothies
('Berry Mix', 4, 6.25, 'Wild berry smoothie', TRUE, 3, '/images/berry-smoothie.jpg'),
('Banana Paradise', 4, 5.95, 'Smoothie with banana and milk', TRUE, 3, '/images/banana-smoothie.jpg'),
-- Desserts
('Cheesecake', 5, 4.95, 'Classic New York style cheesecake', TRUE, 2, '/images/cheesecake.jpg'),
('Chocolate Muffin', 5, 3.25, 'Moist chocolate chip muffin', TRUE, 1, '/images/choco-muffin.jpg'),
('Macarons (3 pcs)', 5, 4.50, 'French macarons, assorted flavors, 3 pieces', TRUE, 1, '/images/macarons.jpg'),
-- Snacks
('Caramel Popcorn', 6, 3.50, 'Sweet caramel popcorn', TRUE, 2, '/images/popcorn.jpg');

-- Ingredients
INSERT INTO ingredients (ingredient_name, unit, stock_quantity, min_quantity, cost_per_unit) VALUES
('Black Tea (leaf)', 'g', 5000.00, 500.00, 0.50),
('Green Tea', 'g', 3000.00, 300.00, 0.80),
('Milk 3.2%', 'ml', 50000.00, 5000.00, 0.08),
('Tapioca (boba)', 'g', 10000.00, 1000.00, 0.15),
('Taro Syrup', 'ml', 3000.00, 500.00, 0.50),
('Matcha Powder', 'g', 1000.00, 100.00, 3.00),
('Chocolate Syrup', 'ml', 4000.00, 500.00, 0.40),
('Mango Puree', 'ml', 5000.00, 1000.00, 0.60),
('Frozen Strawberry', 'g', 8000.00, 1000.00, 0.30),
('Passion Fruit Puree', 'ml', 3000.00, 500.00, 0.80),
('Arabica Coffee Beans', 'g', 15000.00, 2000.00, 0.70),
('Caramel Syrup', 'ml', 3000.00, 500.00, 0.35),
('Cream 33%', 'ml', 10000.00, 1000.00, 0.15),
('Banana', 'pcs', 100.00, 20.00, 30.00),
('Wild Berry Mix', 'g', 5000.00, 1000.00, 0.50),
('Sugar', 'g', 20000.00, 2000.00, 0.05),
('Ice', 'g', 50000.00, 5000.00, 0.01);

-- Product Ingredients
INSERT INTO product_ingredients (product_id, ingredient_id, quantity) VALUES
-- Classic Milk Tea
(1, 1, 10.00), -- black tea
(1, 3, 200.00), -- milk
(1, 4, 50.00), -- tapioca
(1, 16, 15.00), -- sugar
(1, 17, 100.00), -- ice
-- Taro Milk Tea
(2, 1, 10.00),
(2, 3, 180.00),
(2, 4, 50.00),
(2, 5, 30.00), -- taro syrup
(2, 17, 100.00),
-- Matcha Latte with Boba
(3, 6, 5.00), -- matcha
(3, 3, 250.00),
(3, 4, 50.00),
(3, 16, 10.00),
(3, 17, 50.00),
-- Chocolate Boba
(4, 3, 200.00),
(4, 4, 50.00),
(4, 7, 40.00), -- chocolate syrup
(4, 17, 100.00),
-- Mango Fresh
(5, 2, 8.00), -- green tea
(5, 8, 80.00), -- mango puree
(5, 16, 10.00),
(5, 17, 150.00),
-- Strawberry Blast
(6, 2, 8.00),
(6, 9, 100.00), -- strawberry
(6, 16, 15.00),
(6, 17, 150.00),
-- Passion Fruit Tropic
(7, 2, 8.00),
(7, 10, 70.00), -- passion fruit
(7, 16, 12.00),
(7, 17, 150.00),
-- Cappuccino
(8, 11, 18.00), -- coffee
(8, 3, 150.00),
-- Latte
(9, 11, 18.00),
(9, 3, 200.00),
-- Caramel Raf
(10, 11, 18.00),
(10, 13, 100.00), -- cream
(10, 12, 30.00), -- caramel syrup
-- Berry Mix
(11, 15, 200.00), -- berries
(11, 3, 100.00),
(11, 16, 10.00),
(11, 17, 50.00),
-- Banana Paradise
(12, 14, 1.50), -- banana
(12, 3, 150.00),
(12, 16, 10.00),
(12, 17, 50.00);

-- Orders
INSERT INTO orders (customer_id, employee_id, order_date, total_amount, status, payment_method, notes) VALUES
(1, 5, '2024-10-01 10:30:00', 0, 'completed', 'card', NULL),
(2, 6, '2024-10-01 11:15:00', 0, 'completed', 'cash', NULL),
(3, 5, '2024-10-01 12:45:00', 0, 'completed', 'card', NULL),
(4, 6, '2024-10-02 09:20:00', 0, 'completed', 'online', 'No sugar'),
(5, 5, '2024-10-02 14:30:00', 0, 'completed', 'card', NULL),
(6, 6, '2024-10-03 10:00:00', 0, 'completed', 'cash', NULL),
(7, 5, '2024-10-03 15:45:00', 0, 'completed', 'card', NULL),
(8, 6, '2024-10-04 11:30:00', 0, 'completed', 'online', NULL),
(1, 5, '2024-10-05 13:00:00', 0, 'completed', 'card', NULL),
(2, 6, '2024-10-05 16:20:00', 0, 'completed', 'cash', NULL),
(3, 5, '2024-10-06 10:45:00', 0, 'preparing', 'card', NULL),
(4, 6, '2024-10-06 12:15:00', 0, 'pending', 'cash', NULL);

-- Order Items
INSERT INTO order_items (order_id, product_id, quantity, unit_price, customization) VALUES
-- Order 1
(1, 1, 2, 350.00, NULL),
(1, 13, 1, 250.00, NULL),
-- Order 2
(2, 3, 1, 420.00, NULL),
(2, 14, 2, 180.00, NULL),
-- Order 3
(3, 5, 1, 340.00, NULL),
(3, 6, 1, 360.00, NULL),
-- Order 4
(4, 2, 1, 380.00, 'No sugar'),
(4, 8, 1, 280.00, NULL),
-- Order 5
(5, 9, 2, 290.00, NULL),
(5, 15, 1, 220.00, NULL),
-- Order 6
(6, 4, 1, 390.00, NULL),
(6, 13, 1, 250.00, NULL),
(6, 16, 1, 150.00, NULL),
-- Order 7
(7, 7, 1, 370.00, NULL),
(7, 11, 1, 320.00, NULL),
-- Order 8
(8, 1, 1, 350.00, NULL),
(8, 10, 2, 330.00, NULL),
-- Order 9
(9, 12, 1, 300.00, NULL),
(9, 14, 1, 180.00, NULL),
-- Order 10
(10, 3, 2, 420.00, NULL),
-- Order 11 (in progress)
(11, 5, 1, 340.00, NULL),
(11, 15, 2, 220.00, NULL),
-- Order 12 (new)
(12, 2, 1, 380.00, NULL);

-- Update order totals (triggers will do this automatically, but for initial data load we update manually)
UPDATE orders SET total_amount = (
    SELECT COALESCE(SUM(subtotal), 0)
    FROM order_items
    WHERE order_items.order_id = orders.order_id
);
