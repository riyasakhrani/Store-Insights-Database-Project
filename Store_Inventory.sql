-- Coffee Shop Database Project --
-- by Riya Sakhrani --

-- Select database 
USE Store_Project

-- Load in the data using import wizard
-- Check whether the data has been imported 
SELECT *
FROM dbo.salesreciepts

-- Clean the data by checking for null values and removing them
SELECT transaction_date, transaction_time
FROM dbo.salesreciepts
GROUP BY transaction_id, transaction_date, transaction_time, customer_id
HAVING COUNT(*) > 1

SELECT *
FROM dbo.pastryinventory
WHERE start_of_day IS NULL OR product_id IS NULL

DELETE FROM dbo.pastryinventory
WHERE start_of_day IS NULL OR product_id IS NULL

SELECT *
FROM dbo.customers
WHERE customer_id IS NULL

DELETE FROM dbo.customers
WHERE customer_id IS NULL

SELECT *
FROM dbo.salesreciepts
WHERE transaction_id IS NULL

DELETE FROM dbo.salesreciepts
WHERE transaction_id IS NULL

-- Add primary keys 
ALTER TABLE dbo.salesreciepts
ADD CONSTRAINT PK_transaction PRIMARY KEY (transaction_id)

ALTER TABLE dbo.customers
ADD CONSTRAINT PK_customer PRIMARY KEY (customer_id)

ALTER TABLE dbo.pastryinventory
ADD CONSTRAINT PK_date_product PRIMARY KEY (sales_outlet_id, transaction_date, product_id)

ALTER TABLE dbo.product
ADD CONSTRAINT PK_product PRIMARY KEY (product_id)

ALTER TABLE dbo.salestargets
ADD CONSTRAINT PK_sales_outlet PRIMARY KEY (sales_outlet_id)

-- Add foreign keys 
ALTER TABLE dbo.salesreciepts
ADD CONSTRAINT FK_sales_outlet_id FOREIGN KEY (sales_outlet_id) REFERENCES salestargets(sales_outlet_id)

ALTER TABLE dbo.salesreciepts
ADD CONSTRAINT FK_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id)

ALTER TABLE dbo.salesreciepts
ADD CONSTRAINT FK_product FOREIGN KEY (product_id) REFERENCES product(product_id)

ALTER TABLE dbo.pastryinventory
ADD CONSTRAINT FK_sales_outlet_idp FOREIGN KEY (sales_outlet_id) REFERENCES salestargets(sales_outlet_id)

-- Sales Analysis -- 

-- Calculate sales revenue per day
SELECT transaction_date, 
    CAST(SUM(line_item_amount) AS DECIMAL(10,2)) as total_sales
FROM dbo.salesreciepts
GROUP BY transaction_date
ORDER BY 1 ASC

-- Calculate sales revenue for each store location 
-- Show which outlet has highest sales 
SELECT sales_outlet_id, 
    CAST(SUM(line_item_amount) AS DECIMAL(10,2)) as total_sales
FROM dbo.salesreciepts
GROUP BY sales_outlet_id
ORDER BY 1 ASC 

-- Calculate top selling product by revenue
SELECT dbo.salesreciepts.sales_outlet_id,
    dbo.product.product,
    CAST(SUM(dbo.product.profit) AS DECIMAL (10,2)) as 'product_revenue'
FROM dbo.salesreciepts
LEFT JOIN dbo.product on 
    dbo.product.product_id = dbo.salesreciepts.product_id
GROUP BY dbo.salesreciepts.sales_outlet_id,
    dbo.product.product
ORDER BY 3 DESC

-- Calculate top selling product by quantity 
SELECT dbo.salesreciepts.sales_outlet_id,
    dbo.product.product,
    SUM(dbo.salesreciepts.quantity) as 'quantity_sold'
FROM dbo.salesreciepts
LEFT JOIN dbo.product on 
    dbo.product.product_id = dbo.salesreciepts.product_id
GROUP BY dbo.salesreciepts.sales_outlet_id,
    dbo.product.product
ORDER BY 3 DESC

-- Calculate top selling products for Retail Store ID 3
SELECT dbo.salesreciepts.product_id,
    dbo.product.product,
    COUNT(dbo.salesreciepts.product_id) as 'CountofProducts'
FROM dbo.salesreciepts
LEFT JOIN dbo.product on 
    dbo.product.product_id = dbo.salesreciepts.product_id
WHERE dbo.salesreciepts.sales_outlet_id = 3
GROUP BY dbo.salesreciepts.product_id,
    dbo.product.product
ORDER BY 3 DESC

-- Calculate top selling products for Retail Store ID 5
SELECT dbo.salesreciepts.product_id,
    dbo.product.product,
    COUNT(dbo.salesreciepts.product_id) as 'CountofProducts'
FROM dbo.salesreciepts
LEFT JOIN dbo.product on 
    dbo.product.product_id = dbo.salesreciepts.product_id
WHERE dbo.salesreciepts.sales_outlet_id = 5
GROUP BY dbo.salesreciepts.product_id,
    dbo.product.product
ORDER BY 3 DESC

-- Calculate top selling products for Retail Store ID 8
SELECT dbo.salesreciepts.product_id,
    dbo.product.product,
    COUNT(dbo.salesreciepts.product_id) as 'CountofProducts'
FROM dbo.salesreciepts
LEFT JOIN dbo.product on 
    dbo.product.product_id = dbo.salesreciepts.product_id
WHERE dbo.salesreciepts.sales_outlet_id = 8
GROUP BY dbo.salesreciepts.product_id,
    dbo.product.product
ORDER BY 3 DESC

-- Calculate total sales for the month
SELECT CAST(SUM(line_item_amount) AS DECIMAL (10,2)) as 'Monthly_Online_Sales'
FROM dbo.salesreciepts

-- Calculate in store vs online sales
-- Online sales for the month 
SELECT CAST(SUM(line_item_amount) AS DECIMAL (10,2)) as 'Monthly_Online_Sales'
FROM dbo.salesreciepts
WHERE instore_yn = 'N'

-- In store sales for the month 
SELECT CAST(SUM(line_item_amount) AS DECIMAL (10,2)) as 'Monthly_Online_Sales'
FROM dbo.salesreciepts
WHERE instore_yn = 'Y'
-- In store does slightly better

-- Average transaction value by store
SELECT sales_outlet_id,
    CAST(AVG(quantity * unit_price) AS DECIMAL (10,2)) AS average_transaction
FROM dbo.salesreciepts
GROUP BY sales_outlet_id

-- Store with highest sales 
SELECT sales_outlet_id, 
    CAST(SUM(line_item_amount) AS DECIMAL (10,2)) AS sum_all_transactions
FROM dbo.salesreciepts
WHERE instore_yn = 'Y'
GROUP BY sales_outlet_id
ORDER BY 2 DESC

-- Check which stores have met their sales targets
SELECT dbo.salesreciepts.sales_outlet_id,
    CAST(SUM(line_item_amount) AS DECIMAL (10,2)) AS sum_all_transactions,
    dbo.salestargets.total_goal
FROM dbo.salesreciepts
LEFT JOIN dbo.salestargets ON
    dbo.salestargets.sales_outlet_id = dbo.salesreciepts.sales_outlet_id
WHERE instore_yn = 'Y'
GROUP BY dbo.salesreciepts.sales_outlet_id,
    dbo.salestargets.total_goal
ORDER BY 2 DESC
-- All stores exceeded their monthly sales goals for April

-- Profit Calculations 
-- Add a profit column to product table 
ALTER TABLE dbo.product
ADD profit FLOAT

-- Calculate profit of each product 
UPDATE dbo.product
SET dbo.product.profit = current_retail_price - current_wholesale_price

-- Calculate profit for every transaction
SELECT dbo.salesreciepts.transaction_id,
    CAST(SUM(dbo.salesreciepts.quantity * dbo.product.profit) AS DECIMAL (10,2)) as profit_by_transac
FROM dbo.salesreciepts
LEFT JOIN dbo.product ON 
    dbo.product.product_id = dbo.salesreciepts.product_id
GROUP BY dbo.salesreciepts.transaction_id,
    dbo.salesreciepts.product_id, 
    dbo.product.profit

-- Total profit for each store 
SELECT dbo.salesreciepts.sales_outlet_id,
    CAST(SUM(dbo.salesreciepts.quantity * dbo.product.profit) AS DECIMAL (10,2)) as total_profit
FROM dbo.salesreciepts
LEFT JOIN dbo.product ON 
    dbo.product.product_id = dbo.salesreciepts.product_id
GROUP BY dbo.salesreciepts.sales_outlet_id

-- Calculate profit margin for each store 
SELECT t.sales_outlet_id,
    t.total_profit,
    s.total_sales,
    CAST((t.total_profit / s.total_sales) * 100 AS DECIMAL(10,2)) as profit_margin
FROM 
    (SELECT dbo.salesreciepts.sales_outlet_id,
    CAST(SUM(dbo.salesreciepts.quantity * dbo.product.profit) AS DECIMAL (10,2)) as total_profit
    FROM dbo.salesreciepts
    LEFT JOIN dbo.product ON 
        dbo.product.product_id = dbo.salesreciepts.product_id
    GROUP BY dbo.salesreciepts.sales_outlet_id) t
JOIN 
    (SELECT sales_outlet_id, 
    CAST(SUM(line_item_amount) AS DECIMAL(10,2)) as total_sales
    FROM dbo.salesreciepts
    GROUP BY sales_outlet_id) s ON t.sales_outlet_id = s.sales_outlet_id

-- Inventory Analysis -- 

-- Wastage Analysis for Retail Store ID 3 
SElECT sales_outlet_id, dbo.pastryinventory.transaction_date, dbo.pastryinventory.product_id, product, start_of_day, quantity_sold, waste, waste1, product_type, product
FROM dbo.pastryinventory
LEFT JOIN dbo.product on 
    dbo.pastryinventory.product_id = dbo.product.product_id
WHERE CAST(SUBSTRING(waste1, 1, LEN(waste1) - 1) AS INT) > 50 AND sales_outlet_id = 3
ORDER BY waste1 DESC

-- Wastage Analysis for Retail Store ID 5
SElECT sales_outlet_id, dbo.pastryinventory.transaction_date, dbo.pastryinventory.product_id, product, start_of_day, quantity_sold, waste, waste1
FROM dbo.pastryinventory
LEFT JOIN dbo.product on 
    dbo.pastryinventory.product_id = dbo.product.product_id
WHERE CAST(SUBSTRING(waste1, 1, LEN(waste1) - 1) AS INT) > 50 AND sales_outlet_id = 5
ORDER BY waste1 DESC

-- Wastage Analysis for Retail Store ID 8
SElECT sales_outlet_id, dbo.pastryinventory.transaction_date, dbo.pastryinventory.product_id, product, start_of_day, quantity_sold, waste, waste1
FROM dbo.pastryinventory
LEFT JOIN dbo.product on 
    dbo.pastryinventory.product_id = dbo.product.product_id
WHERE CAST(SUBSTRING(waste1, 1, LEN(waste1) - 1) AS INT) > 50 AND sales_outlet_id = 8
ORDER BY waste1 DESC

-- Best selling pastries
SELECT sales_outlet_id, transaction_date, product, start_of_day, quantity_sold, waste1
FROM dbo.pastryinventory
LEFT JOIN dbo.product on 
    dbo.pastryinventory.product_id = dbo.product.product_id
WHERE CAST(SUBSTRING(waste1, 1, LEN(waste1) - 1) AS INT) < 20
ORDER BY quantity_sold DESC

-- Calculate profit margin per unit of the product 
SELECT product, 
    CAST(SUM(current_retail_price - current_wholesale_price) AS DECIMAL (10,2)) AS profit_margin
FROM dbo.product
GROUP BY product
ORDER BY 2 DESC



