--EN ÇOK SATAN ÜRÜN ANALİZİ
SELECT 
    p.product_name,
    SUM(od.quantity) AS TotalQuantity
FROM 
    order_details od
JOIN 
    products p ON od.product_id = p.product_id
GROUP BY 
    p.product_name
ORDER BY 
    TotalQuantity DESC
LIMIT 10;

--MÜŞTERİ SEGMENTASYONU
WITH CustomerTotals AS (
    SELECT
        c.customer_id,
        c.company_name,
        SUM(od.quantity * od.unit_price) AS TotalSpent
    FROM
        orders o
    JOIN
        order_details od ON o.order_id = od.order_id
    JOIN
        customers c ON o.customer_id = c.customer_id
    GROUP BY
        c.customer_id, c.company_name
),
Percentiles AS (
    SELECT
        PERCENTILE_CONT(0.33) WITHIN GROUP (ORDER BY TotalSpent) AS P33,
        PERCENTILE_CONT(0.66) WITHIN GROUP (ORDER BY TotalSpent) AS P66
    FROM
        CustomerTotals
)
SELECT
    ct.customer_id,
    ct.company_name,
    ct.TotalSpent,
    CASE
        WHEN ct.TotalSpent > p.P66 THEN 'Üst Segment'
        WHEN ct.TotalSpent > p.P33 THEN 'Orta Sehment'
        ELSE 'Alt Segment'
    END AS CustomerCategory
FROM
    CustomerTotals ct
JOIN
    Percentiles p ON 1=1
ORDER BY 
    ct.TotalSpent DESC;

--SİPARİŞ TRENDLERİ
SELECT 
    TO_CHAR(o.order_date, 'YYYY-MM') AS YearMonth,
    COUNT(o.order_id) AS OrderCount,
    SUM(od.quantity * od.unit_price) AS TotalSales
FROM 
    orders o
JOIN 
    order_details od ON o.order_id = od.order_id
GROUP BY 
    YearMonth
ORDER BY 
    YearMonth;

--ÜRÜN ANALİZİ
SELECT 
    product_name, 
    unit_price,
    CASE
        WHEN unit_price >= 150 THEN 'Yüksek'
        WHEN unit_price BETWEEN 50 AND 149.99 THEN 'Orta'
        ELSE 'Düşük'
    END AS price_category
FROM Products
WHERE unit_price >= 150 OR unit_price < 50
ORDER BY unit_price DESC;

--ORTALAMA FİYATIN ÜZERİNDEKİ ÜRÜNLER
SELECT product_name, unit_price
FROM products
WHERE unit_price > (
    SELECT AVG(unit_price)
    FROM products
    );

--EN YÜKSEK SİPARİŞ DEĞERLERİ
SELECT 
    o.order_id,
    SUM(od.quantity * od.unit_price * (1 - od.discount)) AS order_value,
    o.order_date,
    o.ship_country
FROM 
    orders o
JOIN 
    order_details od ON o.order_id = od.order_id
GROUP BY 
    o.order_id, o.order_date, o.ship_country
ORDER BY 
    order_value DESC
LIMIT 10;

--AYLIK VE YILLIK ORTALAMA SİPARİŞ DEĞERLERİ
SELECT 
    EXTRACT(YEAR FROM orders.order_date) AS year,
    EXTRACT(MONTH FROM orders.order_date) AS month,
    AVG(order_details.quantity * order_details.unit_price * (1 - order_details.discount)) AS average_order_value
FROM order_details
JOIN orders ON orders.order_id = order_details.order_id
GROUP BY 
    EXTRACT(YEAR FROM orders.order_date),
    EXTRACT(MONTH FROM orders.order_date)
ORDER BY 
    year DESC,
    month DESC;

--ÜLKE BAZINDA TOPLAM SİPARİŞ DEĞERLERİ
SELECT 
	SUM(order_details.product_id * order_details.unit_price - order_details.discount) AS order_value,
	orders.ship_country
FROM order_details
JOIN orders on orders.order_id = order_details.order_id
GROUP BY orders.ship_country
ORDER BY order_value DESC;

--ÜLKE BAZINDA ORTALAMA SİPARİŞ DEĞERLERİ
SELECT 
	AVG(order_details.product_id * order_details.unit_price - order_details.discount) AS order_value,
	orders.ship_country
FROM order_details
JOIN orders on orders.order_id = order_details.order_id
GROUP BY orders.ship_country
ORDER BY order_value DESC;

--TESLİMAT SÜRELERİNE GÖRE KARGO FİRMALARININ PERFORMANS ANALİZİ
SELECT 
    ship_name,
    AVG((shipped_date - order_date)::numeric) AS average_delivery_days,
    CASE
        WHEN AVG((shipped_date - order_date)::numeric) <= 2 THEN 'İyi'
        WHEN AVG((shipped_date - order_date)::numeric) <= 5 THEN 'Orta'
        ELSE 'Kötü'
    END AS delivery_rating
FROM 
    orders
GROUP BY 
    ship_name;

--MÜŞTERİ MEMNUNİYET ANALİZİ
SELECT 
    o.customer_id,
    c.company_name,
    COUNT(o.order_id) AS order_count,
    SUM(od.quantity * od.unit_price) AS total_spent,
    AVG(od.quantity * od.unit_price) AS average_order_value,
    CASE
        WHEN COUNT(o.order_id) = 1 THEN 'Yeni Müşteri'
        WHEN COUNT(o.order_id) BETWEEN 2 AND 5 THEN 'Orta'
        ELSE 'Sadık Müşteri'
    END AS customer_type
FROM 
    orders o
JOIN 
    order_details od ON o.order_id = od.order_id
JOIN 
    customers c ON o.customer_id = c.customer_id
GROUP BY 
    o.customer_id, c.company_name
ORDER BY 
    order_count DESC;

--KAMPANYA PERFORMANSI
SELECT
    CASE
        WHEN od.discount > 0 THEN 'Kampanyalı'
        ELSE 'Kampanyasız'
    END AS campaign_type,
    COUNT(o.order_id) AS order_count,
    SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_sales,
    AVG(od.quantity * od.unit_price * (1 - od.discount)) AS average_order_value
FROM
    orders o
JOIN
    order_details od ON o.order_id = od.order_id
GROUP BY
    CASE
        WHEN od.discount > 0 THEN 'Kampanyalı'
        ELSE 'Kampanyasız'
    END;


