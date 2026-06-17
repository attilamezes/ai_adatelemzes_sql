-- ============================================================
-- WEBSHOP ELEMZÉS — SQLite lekérdezések
-- Adatbázis: webshop.db (orders: 50 sor, customers: 45 sor)
-- Készítette: AI-asszisztált elemzés, 2024-06
-- ============================================================

-- 1. TÁBLAMÉRET
SELECT COUNT(*) AS orders_count FROM orders;
SELECT COUNT(*) AS customers_count FROM customers;

-- 2. SZERKEZET
SELECT * FROM orders LIMIT 5;
SELECT * FROM customers LIMIT 5;
PRAGMA table_info(orders);
PRAGMA table_info(customers);

-- 3. ADATMINŐSÉG
SELECT dq_flag, COUNT(*) AS count FROM orders GROUP BY dq_flag;

SELECT order_id, quantity, unit_price, discount, revenue,
    ROUND(quantity * unit_price * (1 - discount), 2) AS szamitott_revenue,
    ROUND(revenue - quantity * unit_price * (1 - discount), 2) AS elteres
FROM orders
WHERE ROUND(revenue - quantity * unit_price * (1 - discount), 2) != 0.00 LIMIT 10;

SELECT is_returned, COUNT(*) AS db, ROUND(SUM(revenue), 2) AS total_revenue
FROM orders GROUP BY is_returned;

SELECT o.order_id, o.customer_id, o.order_date, c.signup_date
FROM orders o LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_date < c.signup_date;

-- 4. KAPCSOLATOK ÉS ORPHAN CHECK
SELECT COUNT(*) AS orders_elott FROM orders;

SELECT COUNT(*) AS left_join_count
FROM orders o LEFT JOIN customers c ON o.customer_id = c.customer_id;

SELECT COUNT(*) AS inner_join_count
FROM orders o INNER JOIN customers c ON o.customer_id = c.customer_id;

SELECT o.order_id, o.customer_id, o.revenue, o.dq_flag
FROM orders o LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS rendeles_nelkuli_customers
FROM customers c LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- 5. ELEMZÉSI LEKÉRDEZÉSEK

-- Q12: Revenue channel-enként (nettó)
SELECT channel, COUNT(*) AS orders_db,
    SUM(CASE WHEN is_returned = 'yes' THEN 1 ELSE 0 END) AS visszaru_db,
    ROUND(100.0 * SUM(CASE WHEN is_returned = 'yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS return_rate_pct,
    ROUND(SUM(CASE WHEN is_returned = 'no' THEN revenue ELSE 0 END), 2) AS netto_revenue,
    ROUND(AVG(CASE WHEN is_returned = 'no' THEN revenue END), 2) AS aov,
    ROUND(AVG(discount), 3) AS atlag_discount
FROM orders GROUP BY channel ORDER BY netto_revenue DESC;

-- Q13: Revenue category-nként (nettó)
SELECT category, COUNT(*) AS orders_db,
    ROUND(SUM(CASE WHEN is_returned = 'no' THEN revenue ELSE 0 END), 2) AS netto_revenue,
    ROUND(AVG(CASE WHEN is_returned = 'no' THEN revenue END), 2) AS aov
FROM orders GROUP BY category ORDER BY netto_revenue DESC;

-- Q13b: Channel × Category mátrix, súlyozott átlagárral
SELECT channel, category, COUNT(*) AS orders_db,
    SUM(CASE WHEN is_returned = 'no' THEN quantity ELSE 0 END) AS teljesult_db,
    ROUND(SUM(CASE WHEN is_returned = 'no' THEN revenue ELSE 0 END), 2) AS netto_revenue,
    ROUND(SUM(CASE WHEN is_returned = 'no' THEN revenue ELSE 0 END) /
        NULLIF(SUM(CASE WHEN is_returned = 'no' THEN quantity ELSE 0 END), 0), 2) AS sulyozott_atlagár
FROM orders GROUP BY channel, category ORDER BY channel, netto_revenue DESC;

-- Q13c: Marketplace-Clothing anomália
SELECT order_id, product_name, quantity, unit_price, discount, is_returned, revenue
FROM orders WHERE channel = 'marketplace' AND category = 'Clothing' ORDER BY revenue DESC;

-- Q13d: Marketplace-Clothing elvesztett revenue
SELECT ROUND(SUM(revenue), 2) AS brutto_revenue,
    ROUND(SUM(CASE WHEN is_returned = 'no' THEN revenue ELSE 0 END), 2) AS netto_revenue,
    ROUND(SUM(CASE WHEN is_returned = 'yes' THEN revenue ELSE 0 END), 2) AS elveszett_revenue,
    COUNT(*) AS osszes_order,
    SUM(CASE WHEN is_returned = 'yes' THEN 1 ELSE 0 END) AS visszaru_db
FROM orders WHERE channel = 'marketplace' AND category = 'Clothing';

-- Q13e: Elvesztett revenue %
SELECT ROUND(SUM(CASE WHEN is_returned = 'no' THEN revenue ELSE 0 END), 2) AS teljes_netto_revenue,
    ROUND(SUM(CASE WHEN channel = 'marketplace' AND category = 'Clothing'
        AND is_returned = 'yes' THEN revenue ELSE 0 END), 2) AS elveszett_revenue,
    ROUND(100.0 * SUM(CASE WHEN channel = 'marketplace' AND category = 'Clothing'
        AND is_returned = 'yes' THEN revenue ELSE 0 END) /
        SUM(CASE WHEN is_returned = 'no' THEN revenue ELSE 0 END), 1) AS elveszett_pct
FROM orders;

-- Q14: Revenue szegmens szerint (LEFT JOIN)
SELECT COALESCE(c.segment, 'UNKNOWN') AS segment, COUNT(*) AS orders_db,
    ROUND(SUM(CASE WHEN o.is_returned = 'no' THEN o.revenue ELSE 0 END), 2) AS netto_revenue,
    ROUND(AVG(CASE WHEN o.is_returned = 'no' THEN o.revenue END), 2) AS aov
FROM orders o LEFT JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.segment ORDER BY netto_revenue DESC;

-- Q15: Havi trend
SELECT strftime('%Y-%m', order_date) AS honap, COUNT(*) AS orders_db,
    ROUND(SUM(CASE WHEN is_returned = 'no' THEN revenue ELSE 0 END), 2) AS netto_revenue
FROM orders GROUP BY honap ORDER BY honap;

-- Q15b: Napi átlagos revenue
SELECT strftime('%Y-%m', order_date) AS honap,
    COUNT(DISTINCT order_date) AS aktiv_napok, COUNT(*) AS orders_db,
    ROUND(SUM(CASE WHEN is_returned = 'no' THEN revenue ELSE 0 END), 2) AS netto_revenue,
    ROUND(SUM(CASE WHEN is_returned = 'no' THEN revenue ELSE 0 END) /
        COUNT(DISTINCT order_date), 2) AS napi_atlag_revenue
FROM orders GROUP BY honap ORDER BY honap;

-- Q15e: Channel-category pivot havi összehasonlítással
SELECT channel || ' | ' || category AS channel_category,
    ROUND(SUM(CASE WHEN strftime('%Y-%m', order_date) = '2024-01'
        AND is_returned = 'no' THEN revenue ELSE 0 END), 2) AS "2024-01",
    ROUND(SUM(CASE WHEN strftime('%Y-%m', order_date) = '2024-02'
        AND is_returned = 'no' THEN revenue ELSE 0 END), 2) AS "2024-02",
    ROUND(SUM(CASE WHEN strftime('%Y-%m', order_date) = '2024-02' AND is_returned = 'no' THEN revenue ELSE 0 END) -
        SUM(CASE WHEN strftime('%Y-%m', order_date) = '2024-01' AND is_returned = 'no' THEN revenue ELSE 0 END), 2) AS variance
FROM orders GROUP BY channel, category ORDER BY variance ASC;

-- 6. VARIANCE ELEMZÉS

-- Q16a: Termék szinten
SELECT product_name,
    ROUND(SUM(CASE WHEN strftime('%Y-%m', order_date) = '2024-01' AND is_returned = 'no' THEN revenue ELSE 0 END), 2) AS jan_revenue,
    ROUND(SUM(CASE WHEN strftime('%Y-%m', order_date) = '2024-02' AND is_returned = 'no' THEN revenue ELSE 0 END), 2) AS feb_revenue,
    ROUND(SUM(CASE WHEN strftime('%Y-%m', order_date) = '2024-02' AND is_returned = 'no' THEN revenue ELSE 0 END) -
        SUM(CASE WHEN strftime('%Y-%m', order_date) = '2024-01' AND is_returned = 'no' THEN revenue ELSE 0 END), 2) AS variance
FROM orders GROUP BY product_name ORDER BY variance ASC;

-- Q16b: Category szinten
SELECT category,
    ROUND(SUM(CASE WHEN strftime('%Y-%m', order_date) = '2024-01' AND is_returned = 'no' THEN revenue ELSE 0 END), 2) AS jan_revenue,
    ROUND(SUM(CASE WHEN strftime('%Y-%m', order_date) = '2024-02' AND is_returned = 'no' THEN revenue ELSE 0 END), 2) AS feb_revenue,
    ROUND(SUM(CASE WHEN strftime('%Y-%m', order_date) = '2024-02' AND is_returned = 'no' THEN revenue ELSE 0 END) -
        SUM(CASE WHEN strftime('%Y-%m', order_date) = '2024-01' AND is_returned = 'no' THEN revenue ELSE 0 END), 2) AS variance
FROM orders GROUP BY category ORDER BY variance ASC;

-- Q16c: Channel szinten
SELECT channel,
    ROUND(SUM(CASE WHEN strftime('%Y-%m', order_date) = '2024-01' AND is_returned = 'no' THEN revenue ELSE 0 END), 2) AS jan_revenue,
    ROUND(SUM(CASE WHEN strftime('%Y-%m', order_date) = '2024-02' AND is_returned = 'no' THEN revenue ELSE 0 END), 2) AS feb_revenue,
    ROUND(SUM(CASE WHEN strftime('%Y-%m', order_date) = '2024-02' AND is_returned = 'no' THEN revenue ELSE 0 END) -
        SUM(CASE WHEN strftime('%Y-%m', order_date) = '2024-01' AND is_returned = 'no' THEN revenue ELSE 0 END), 2) AS variance
FROM orders GROUP BY channel ORDER BY variance ASC;
