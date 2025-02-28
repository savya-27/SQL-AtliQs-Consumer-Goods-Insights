-- 1. Provide the list of markets in which customer  "Atliq  Exclusive"  operates its 
-- business in the  APAC  region. 

SELECT market AS Market 
FROM dim_customer
WHERE customer = "Atliq Exclusive" AND region = "APAC"
GROUP BY market
ORDER BY market;

-- 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, 
-- unique_products_2020 
-- unique_products_2021 
-- percentage_chg 


SELECT
A.U_2020 AS Unique_products_2020,
B.U_2021 AS Unique_products_2021,
ROUND((B.U_2021-A.U_2020)*100/A.U_2020,2) as Percentage_Chg
FROM 
(
(SELECT COUNT(DISTINCT(product_code)) AS U_2020
FROM fact_sales_monthly
WHERE fiscal_year = 2020) A,

(SELECT COUNT(DISTINCT(product_code)) AS U_2021
FROM fact_sales_monthly
WHERE fiscal_year = 2021) B
);

-- 3. Provide a report with all the unique product counts for each segment and sort them in descending order of 
-- product counts. The final output contains 2 fields, 
-- segment 
-- product_count 

SELECT Segment, COUNT(DISTINCT(product_code)) AS Product_Count FROM dim_product
GROUP BY segment
ORDER BY Product_Count DESC;

-- 4.  Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
-- The final output contains these fields, 
-- segment 
-- product_count_2020 
-- product_count_2021 
-- difference 

WITH 2020_prod AS
(
SELECT p.segment, s.fiscal_year, COUNT(DISTINCT(p.product_code)) AS Product_Count_2020
FROM dim_product p
JOIN fact_sales_monthly s
ON s.product_code = p.product_code
WHERE fiscal_year = 2020
GROUP BY segment),
2021_prod AS
(SELECT p.segment, s.fiscal_year, COUNT(DISTINCT(p.product_code)) AS Product_Count_2021
FROM dim_product p
JOIN fact_sales_monthly s
ON s.product_code = p.product_code
WHERE fiscal_year = 2021
GROUP BY segment)

SELECT 
	  2021_prod.segment AS Segment, 
      2020_prod.Product_Count_2020, 
      2021_prod.Product_Count_2021,
      (2021_prod.Product_Count_2021 - 2020_prod.Product_Count_2020) AS Difference
FROM 2020_prod, 2021_prod
WHERE 2020_prod.segment = 2021_prod.segment;

-- 5.   Get the products that have the highest and lowest manufacturing costs. 
-- The final output should contain these fields, 
-- product_code 
-- product 
-- manufacturing_cost


SELECT 
	  p.product_code `Product Code`, 
      p.product `Product`, 
      m.manufacturing_cost `Manufacturing Cost`
FROM fact_manufacturing_cost m
JOIN dim_product p
ON p.product_code = m.product_code
WHERE manufacturing_cost IN 
(SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost UNION 
SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;

-- 6.  Generate a report which contains the top 5 customers who received an average high  pre_invoice_discount_pct  
-- for the  fiscal  year 2021  and in the Indian  market. The final output contains these fields, 
-- customer_code 
-- customer 
-- average_discount_percentage

SELECT 
	  d.customer_code `Customer Code`, 
      c.customer `Customer`, 
      ROUND(AVG(d.pre_invoice_discount_pct), 4) Average_discount_percentage
FROM fact_pre_invoice_deductions d
JOIN dim_customer c
ON c.customer_code = d.customer_code
WHERE fiscal_year = 2021 AND c.market = "India"
GROUP BY `Customer Code`
ORDER BY Average_discount_percentage DESC
LIMIT 5;

-- 7.  Get the complete report of the Gross sales amount for the customer  “Atliq Exclusive”  for each month.  
-- This analysis helps to  get an idea of low and high-performing months and take strategic decisions. 
-- The final report contains these columns: 
-- Month 
-- Year 
-- Gross sales Amount 

SELECT 
	  CONCAT(MONTHNAME(date), " ", "(", YEAR(date), ")") AS Month,
      s.fiscal_year,
      ROUND(SUM(g.gross_price*s.sold_quantity), 2) AS `Gross sales Amount`
FROM fact_sales_monthly s
JOIN dim_customer c
ON c.customer_code = s.customer_code
JOIN fact_gross_price g
ON s.product_code = g.product_code
WHERE customer = "Atliq Exclusive"
GROUP BY Month, s.fiscal_year
ORDER BY fiscal_year;

-- 8. In which quarter of 2020, got the maximum total_sold_quantity? 
-- The final output contains these fields sorted by the total_sold_quantity, 
-- Quarter 
-- total_sold_quantity 

SELECT 
	  CASE 
		  WHEN MONTH(date) IN ( 9 , 10 , 11) THEN "Q1"
          WHEN MONTH(date) IN (12 , 1 , 2) THEN "Q2"
          WHEN MONTH(date) IN(3 , 4, 5) THEN "Q3"
          WHEN MONTH(date)IN (6 , 7 , 8) THEN "Q4"
	  END Quarters, 
SUM(sold_quantity) AS `Total Sold Quantity`
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarters
ORDER BY `Total Sold Quantity` DESC;

-- 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?  
-- The final output  contains these fields, 
-- channel 
-- gross_sales_mln 
-- percentage 

WITH cte1 AS (
    SELECT 
        c.channel,
        CONCAT(ROUND(SUM(g.gross_price * s.sold_quantity) / 1000000, 2), "M") AS Gross_sales_mln
    FROM fact_sales_monthly s
    JOIN dim_customer c ON s.customer_code = c.customer_code
    JOIN fact_gross_price g ON s.product_code = g.product_code
    WHERE s.fiscal_year = 2021
    GROUP BY c.channel
), 
Total AS (
    SELECT SUM(Gross_sales_mln) AS Total_sales FROM cte1
)

SELECT 
    cte1.channel, 
    cte1.Gross_sales_mln,
    CONCAT(ROUND(cte1.Gross_sales_mln * 100 / T.total_sales, 2), ' %') AS percentage
FROM cte1
JOIN Total T
ORDER BY cte1.Gross_sales_mln DESC;

-- 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
-- The final output contains these fields, 
-- division 
-- product_code 
-- product 
-- total_sold_quantity 
-- rank_order 

WITH cte1 AS
(
SELECT p.division, p.product_code, p.product, p.variant, SUM(s.sold_quantity) AS total_sold_quantity
FROM dim_product p 
JOIN fact_sales_monthly s 
ON s.product_code = p.product_code
WHERE fiscal_year = 2021
GROUP BY product_code),
cte2 AS
(
SELECT  division, product_code, product, variant, total_sold_quantity,
RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS `Rank Order`
FROM cte1)
SELECT * FROM cte2 WHERE `Rank Order` <=3;
