-- coffee_sales

SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
    city_name,
    ROUND((population * 0.25) / 1000000, 2) AS coffee_consumers_in_millions,
    city_rank
FROM 
    city
ORDER BY 
    2 DESC;


-- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?


SELECT 
    SUM(total) AS total_revenue
FROM 
    sales
WHERE 
    EXTRACT(YEAR FROM sale_date) = 2023
    AND EXTRACT(QUARTER FROM sale_date) = 4;

SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue
FROM 
    sales AS s
JOIN 
    customers AS c ON s.customer_id = c.customer_id
JOIN 
    city AS ci ON ci.city_id = c.city_id
WHERE 
    EXTRACT(YEAR FROM s.sale_date) = 2023
    AND EXTRACT(QUARTER FROM s.sale_date) = 4
GROUP BY 
    1
ORDER BY 
    2 DESC;


-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
    p.product_name,
    COUNT(s.sale_id) AS total_orders
FROM 
    products AS p
LEFT JOIN 
    sales AS s ON s.product_id = p.product_id
GROUP BY 
    1
ORDER BY 
    2 DESC;


-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- city abd total sale
-- no cx in each these city


SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS total_cx,
    ROUND(
        SUM(s.total)::NUMERIC / COUNT(DISTINCT s.customer_id)::NUMERIC,
        2
    ) AS avg_sale_pr_cx
FROM 
    sales AS s
JOIN 
    customers AS c ON s.customer_id = c.customer_id
JOIN 
    city AS ci ON ci.city_id = c.city_id
GROUP BY 
    1
ORDER BY 
    2 DESC;



-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

WITH city_table AS (
    SELECT 
        city_name,
        ROUND((population * 0.25) / 1000000, 2) AS coffee_consumers
    FROM 
        city
),
customers_table AS (
    SELECT 
        ci.city_name,
        COUNT(DISTINCT c.customer_id) AS unique_cx
    FROM 
        sales AS s
    JOIN 
        customers AS c ON c.customer_id = s.customer_id
    JOIN 
        city AS ci ON ci.city_id = c.city_id
    GROUP BY 
        1
)
SELECT 
    customers_table.city_name,
    city_table.coffee_consumers AS coffee_consumer_in_millions,
    customers_table.unique_cx
FROM 
    city_table
JOIN 
    customers_table ON city_table.city_name = customers_table.city_name;




-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT * 
FROM (
    SELECT 
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) AS rank
    FROM 
        sales AS s
    JOIN 
        products AS p ON s.product_id = p.product_id
    JOIN 
        customers AS c ON c.customer_id = s.customer_id
    JOIN 
        city AS ci ON ci.city_id = c.city_id
    GROUP BY 
        1, 2
) AS t1
WHERE 
    rank <= 3;




-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT * 
FROM products;


SELECT 
    ci.city_name,
    COUNT(DISTINCT c.customer_id) AS unique_cx
FROM 
    city AS ci
LEFT JOIN
    customers AS c ON c.city_id = ci.city_id
JOIN 
    sales AS s ON s.customer_id = c.customer_id
WHERE 
    s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 
    1;



-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

WITH city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(
            SUM(s.total)::NUMERIC / COUNT(DISTINCT s.customer_id)::NUMERIC,
            2
        ) AS avg_sale_pr_cx
    FROM 
        sales AS s
    JOIN 
        customers AS c ON s.customer_id = c.customer_id
    JOIN 
        city AS ci ON ci.city_id = c.city_id
    GROUP BY 
        1
    ORDER BY 
        2 DESC
),
city_rent AS (
    SELECT 
        city_name, 
        estimated_rent
    FROM 
        city
)
SELECT 
    cr.city_name,
    cr.estimated_rent,
    ct.total_cx,
    ct.avg_sale_pr_cx,
    ROUND(
        cr.estimated_rent::NUMERIC / ct.total_cx::NUMERIC,
        2
    ) AS avg_rent_per_cx
FROM 
    city_rent AS cr
JOIN 
    city_table AS ct ON cr.city_name = ct.city_name
ORDER BY 
    4 DESC;



-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly) by each city

WITH monthly_sales AS (
    SELECT 
        ci.city_name,
        EXTRACT(MONTH FROM sale_date) AS month,
        EXTRACT(YEAR FROM sale_date) AS year,
        SUM(s.total) AS total_sale
    FROM 
        sales AS s
    JOIN 
        customers AS c ON c.customer_id = s.customer_id
    JOIN 
        city AS ci ON ci.city_id = c.city_id
    GROUP BY 
        1, 2, 3
    ORDER BY 
        1, 3, 2
),
growth_ratio AS (
    SELECT
        city_name,
        month,
        year,
        total_sale AS cr_month_sale,
        LAG(total_sale, 1) OVER (PARTITION BY city_name ORDER BY year, month) AS last_month_sale
    FROM 
        monthly_sales
)
SELECT
    city_name,
    month,
    year,
    cr_month_sale,
    last_month_sale,
    ROUND(
        (cr_month_sale - last_month_sale)::NUMERIC / last_month_sale::NUMERIC * 100,
        2
    ) AS growth_ratio
FROM 
    growth_ratio
WHERE 
    last_month_sale IS NOT NULL;



-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer



WITH city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(
            SUM(s.total)::NUMERIC / COUNT(DISTINCT s.customer_id)::NUMERIC,
            2
        ) AS avg_sale_pr_cx
    FROM 
        sales AS s
    JOIN 
        customers AS c ON s.customer_id = c.customer_id
    JOIN 
        city AS ci ON ci.city_id = c.city_id
    GROUP BY 
        1
    ORDER BY 
        2 DESC
),
city_rent AS (
    SELECT 
        city_name, 
        estimated_rent,
        ROUND((population * 0.25) / 1000000, 3) AS estimated_coffee_consumer_in_millions
    FROM 
        city
)
SELECT 
    cr.city_name,
    total_revenue,
    cr.estimated_rent AS total_rent,
    ct.total_cx,
    estimated_coffee_consumer_in_millions,
    ct.avg_sale_pr_cx,
    ROUND(
        cr.estimated_rent::NUMERIC / ct.total_cx::NUMERIC,
        2
    ) AS avg_rent_per_cx
FROM 
    city_rent AS cr
JOIN 
    city_table AS ct ON cr.city_name = ct.city_name
ORDER BY 
    2 DESC;

-- Q.11
-- Top 5 Customers by Total Spend
-- Which customers have spent the most on coffee products overall?

SELECT 
    c.customer_name,
    SUM(s.total) AS total_spent
FROM 
    sales s
JOIN 
    customers c ON s.customer_id = c.customer_id
GROUP BY 
    c.customer_name
ORDER BY 
    total_spent DESC
LIMIT 5;

-- Q.12
-- Average Product Rating by Product
-- What is the average customer rating for each coffee product?

SELECT 
    p.product_name,
    ROUND(AVG(s.rating)::numeric, 2) AS avg_rating
FROM 
    sales s
JOIN 
    products p ON s.product_id = p.product_id
GROUP BY 
    p.product_name
ORDER BY 
    avg_rating DESC;

-- Q.13
-- Sales Distribution by Quarter for 2023
-- How much revenue was generated each quarter in 2023?

SELECT 
    EXTRACT(QUARTER FROM sale_date) AS quarter,
    SUM(total) AS total_revenue
FROM 
    sales
WHERE 
    EXTRACT(YEAR FROM sale_date) = 2023
GROUP BY 
    quarter
ORDER BY 
    quarter;

-- Q.14 
-- Cities with No Sales in the Last Quarter of 2023
-- Which cities did not have any coffee sales in Q4 of 2023?

SELECT 
    ci.city_name
FROM 
    city ci
LEFT JOIN 
    customers c ON c.city_id = ci.city_id
LEFT JOIN 
    sales s ON s.customer_id = c.customer_id
    AND EXTRACT(YEAR FROM s.sale_date) = 2023
    AND EXTRACT(QUARTER FROM s.sale_date) = 4
WHERE 
    s.sale_id IS NULL;
	
-- Q.15 
-- Repeat Customers Count by City
-- How many customers in each city made more than one purchase?

SELECT 
    ci.city_name,
    COUNT(DISTINCT s.customer_id) AS repeat_customers
FROM 
    sales s
JOIN 
    customers c ON s.customer_id = c.customer_id
JOIN 
    city ci ON c.city_id = ci.city_id
GROUP BY 
    ci.city_name
HAVING 
    COUNT(s.sale_id) > COUNT(DISTINCT s.customer_id)
ORDER BY 
    repeat_customers DESC;


/*
-- Recommendation

City 1: Pune
    1. Highest total revenue: ₹1,258,290.
    2. Very low average rent per customer: ₹294.23.
    3. High average sales per customer: ₹24,197.88.

City 2: Delhi
    1. Largest estimated coffee consumer base: 7.75 million.
    2. Highest number of customers: 68.
    3. Moderate average rent per customer: ₹330.88 (well below ₹500).

City 3: Jaipur
    1. Highest number of customers: 69.
    2. Very low average rent per customer: ₹156.52.
    3. Healthy average sales per customer: ₹11,644.20.
*/



