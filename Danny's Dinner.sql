-- 1
-- What is the total amount each customer spent at the restaurant ?
SELECT customer_id, SUM(price) AS total_expense
FROM sales as t1
JOIN menu AS t2
ON t1.product_id = t2.product_id
GROUP BY customer_id
ORDER BY customer_id
-------------------------------------------------------------------------------------------------------------------

-- 2
-- How many days has each customer visited the restaurant ?
SELECT customer_id, COUNT( DISTINCT order_date) AS no_of_days
FROM sales
GROUP BY customer_id
ORDER BY customer_id
-------------------------------------------------------------------------------------------------------------------

-- 3 
-- What was the first item from the menu purchased by each customer ?
WITH cte AS(
     SELECT customer_id, order_date, product_name,
            ROW_NUMBER()OVER(PARTITION BY customer_id ORDER BY order_date) AS ranking
     FROM sales AS t1
     JOIN menu AS t2
     ON t1.product_id = t2.product_id)
	 
SELECT customer_id, product_name
FROM cte
WHERE ranking = 1
-------------------------------------------------------------------------------------------------------------------

-- 4
-- What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT t2.product_name, COUNT(*) AS no_of_items
FROM sales AS t1
JOIN menu AS t2
ON t1.product_id=t2.product_id
GROUP BY t2.product_name
ORDER BY no_of_items DESC
LIMIT 1
-------------------------------------------------------------------------------------------------------------------

-- 5
-- Which item was the most popular for each customer ?
WITH cte AS (
     SELECT t1.customer_id, t2.product_name, COUNT(*) AS no_of_items
     FROM sales AS t1
     JOIN menu AS t2
     ON t1.product_id = t2.product_id
     GROUP BY t1.customer_id, t2.product_name
     ORDER BY customer_id ASC, no_of_items DESC),
new_cte AS (
     SELECT *, ROW_NUMBER()OVER(PARTITION BY customer_id ORDER BY no_of_items DESC) AS ranking
     FROM cte)
	 
SELECT customer_id, product_name, no_of_items
FROM new_cte
WHERE ranking = 1
-------------------------------------------------------------------------------------------------------------------

-- 6 
-- Which item was purchased first by the customer after they became a member ?
WITH cte AS (
     SELECT *, RANK()OVER(PARTITION BY customer_id ORDER BY date_diff) AS ranking
     FROM (SELECT t1.customer_id, t3.product_name, t2.order_date, t1.join_date, order_date-join_date AS date_diff
           FROM members AS t1
           JOIN sales AS t2
           ON t1.customer_id = t2.customer_id
           JOIN menu AS t3
           ON t2.product_id = t3.product_id
           WHERE order_date-join_date>=0) AS became_member)
		   
SELECT customer_id, product_name
FROM cte
WHERE ranking = 1
-------------------------------------------------------------------------------------------------------------------

-- 7
-- Which item was purchased just before the customer became a member ?
WITH cte AS (
     SELECT *, RANK()OVER(PARTITION BY customer_id ORDER BY date_diff DESC) AS ranking
     FROM (SELECT t1.customer_id, t3.product_name, t2.order_date, t1.join_date, order_date-join_date AS date_diff
           FROM members AS t1
           JOIN sales AS t2
           ON t1.customer_id = t2.customer_id
           JOIN menu AS t3
           ON t2.product_id = t3.product_id
           WHERE order_date-join_date<0) AS became_member)
		   
SELECT customer_id, product_name
FROM cte
WHERE ranking = 1
-------------------------------------------------------------------------------------------------------------------
		   
-- 8
-- What is the total items and amount spent for each member before they became a member ?
SELECT customer_id, COUNT(*), SUM(price)
FROM (SELECT t1.customer_id, t3.product_name, t3.price, t2.order_date, t1.join_date, order_date-join_date AS date_diff
      FROM members AS t1
      JOIN sales AS t2
      ON t1.customer_id = t2.customer_id
      JOIN menu AS t3
      ON t2.product_id = t3.product_id
      WHERE order_date-join_date<0) AS became_member
GROUP BY customer_id
ORDER BY customer_id
-------------------------------------------------------------------------------------------------------------------

-- 9
/* If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
how many points would each customer have ? */
WITH cte AS (
SELECT *, 
       (CASE
	    WHEN product_name='sushi' THEN price*20
		ELSE price*10 END ) AS points
FROM menu)

SELECT customer_id, SUM(points)
FROM cte AS t1
JOIN sales AS t2
ON t1.product_id = t2.product_id
GROUP BY customer_id
ORDER BY customer_id
-------------------------------------------------------------------------------------------------------------------

-- 10
/* In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
just sushi - how many points do customer A and B have at the end of January ? */
SELECT customer_id, SUM(CASE
              WHEN date_diff >= 0 AND date_diff < 7 THEN price*20
		      ELSE price*10 END) AS total_points
FROM (SELECT t1.customer_id, t1.product_id, t2.product_name, t1.order_date, t3.join_date, order_date-join_date AS date_diff, t2.price
FROM sales AS t1
JOIN menu AS t2
ON t1.product_id = t2.product_id
JOIN members AS t3
ON t1.customer_id = t3.customer_id) AS sub
WHERE EXTRACT(MONTH FROM order_date) = 1
GROUP BY customer_id
-------------------------------------------------------------------------------------------------------------------

-- Extra question
-- Create a table with members as "yes" or "no"
SELECT customer_id, order_date, product_name, price,
       (CASE 
	   WHEN date_diff>=0 THEN 'Y'
	   ELSE 'N' END) AS member
FROM (SELECT t1.customer_id, t3.product_name, t3.price, t1.order_date, t2.join_date, order_date-join_date AS date_diff
      FROM sales AS t1
      LEFT JOIN members AS t2
      ON t1.customer_id = t2.customer_id
      JOIN menu AS t3
      ON t1.product_id = t3.product_id) AS new_tbl
ORDER BY customer_id, order_date