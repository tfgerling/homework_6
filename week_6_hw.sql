1.	Show all customers whose last names start with T. Order them by first name from A-Z.
--Selecting first and last name of customers from customer table
SELECT first_name, last_name
FROM customer
--using LIKE to show those with last names starting with a T
WHERE last_name LIKE 'T%'
--sorting by first name from A-Z
ORDER BY first_name;

2.	Show all rentals returned from 5/28/2005 to 6/1/2005
--selecting all rentals from rental table
SELECT *
FROM rental
--using where clause to select those from 5/28/2005 to 6/1/2005
WHERE return_date >= '2005-5-28' AND 
return_date <= '2005-06-01';

3.	How would you determine which movies are rented the most?
--using film table to show which movies have been rented most
--doing inner join with inventory, then rental as the film
--table does not have a key into the rental table directly
SELECT title, f.film_id, COUNT(*)
FROM film AS f
INNER JOIN inventory AS i
ON f.film_id = i.film_id
	INNER JOIN rental as r
	ON i.inventory_id = r.inventory_id
GROUP BY title, f.film_id
ORDER BY count DESC;

4.	Show how much each customer spent on movies (for all time) . Order them from least to most.
--To see how much each customer spent, selecting from customer table
--and concatenating the first and last name together
--then inner join to payment and sum the amount paid
--group on the name and order by the summed payment amount
SELECT CONCAT(first_name, ' ', last_name) AS name, 
	sum(p.amount) AS pay_amount
FROM customer AS cust
INNER JOIN payment AS p
ON cust.customer_id = p.customer_id
GROUP BY name
ORDER BY pay_amount;

5.	Which actor was in the most movies in 2006 (based on this dataset)? Be sure to alias the actor name and 
count as a more descriptive name. Order the results from most to least.
--Selecting actor name from actor table, concatenating them and giving 
--the result an alias of actor_name
--Inner join with film_actor table to get the film_id to use in 
--inner join with film. In the film table, use the release_year to
--determine which actors starred in the most movies in 2006
--ordered by the count of number of movies in descending order to 
--show those with the most films at the top
SELECT CONCAT(first_name, ' ', last_name) AS actor_name, 
	count(*) AS no_2006_movies
FROM actor AS act
INNER JOIN film_actor AS fa
ON act.actor_id = fa.actor_id
	INNER JOIN film AS f
	ON fa.film_id = f.film_id
WHERE f.release_year = 2006
GROUP BY actor_name
ORDER BY no_2006_movies DESC;

6.	Write an explain plan for 4 and 5. Show the queries and explain what is happening in each one. 
Use the following link to understand how this works http://postgresguide.com/performance/explain.html
--#4
EXPLAIN ANALYZE
SELECT CONCAT(first_name, ' ', last_name) AS name, 
	sum(p.amount) AS pay_amount
FROM customer AS cust
INNER JOIN payment AS p
ON cust.customer_id = p.customer_id
GROUP BY name
ORDER BY pay_amount;

--explanation for #4 EXPLAIN 
--the cost, rows affected and actual times for the select, inner join, group by and sort are listed out.
--in addition, it shows the planning time and execution time.
--The select from the customer table is done as a sequential scan, cost of 0.00..14.99, rows of 599, actual time 0.008..0.075
--the scan for data from the payment table was also done as a sequential scan, cost 0.00..253.96, rows 14596, 
-- actual time 0.008..0.632
--the join cost was 22.48..351.51, rows matched the payment table (14596) time 0.167..4.763
--the key being grouped on shows (concat from above) with cost of 424.49..433.47, rows of 599, time 7.157..7.298
--sort information shows that the key used was sum(p.amount), cost wss 461.11..462.60, rows of 599, time 7.467..7.484
--each additional action adds to the time to execute

--#5
EXPLAIN ANALYZE
SELECT CONCAT(first_name, ' ', last_name) AS actor_name, 
	count(*) AS no_2006_movies
FROM actor AS act
INNER JOIN film_actor AS fa
ON act.actor_id = fa.actor_id
	INNER JOIN film AS f
	ON fa.film_id = f.film_id
WHERE f.release_year = 2006
GROUP BY actor_name
ORDER BY no_2006_movies DESC;

--explanation for #5 EXPLAIN 
--additional information shows for this query since there are 2 inner joins
--the cost, rows affected and actual times for the select, inner join, group by and sort are listed out.
--in addition, it shows the planning time and execution time.
--The select from the film table is done as a sequential scan, cost of 0.00..66.50, rows of 1000, actual time 0.004..1.031
--the actor table scan is a sequential scan, cost 0.00..4.00, rows 200, actual time 0.010..0.024
--the film_actor scan is a sequential scan, cost 0.00..84.62, rows 5462, actual time 0.206..0.617
--the join on actor_id between the film_actor table and the actor table had a cost of 6.50..105.76, rows 5462, time 0.266..1.438
--the join on film_id between the film_actor table and the film table had a cost of 85.50..212.81, rows 5462, time 1.718..4.172
--the key being grouped on concatenation of first and last name had a cost of 240.12..241.72, rows of 128, time 5.284..5.301
--sorting by count descending, cost wss 246.20..246.52, rows of 128, time 5.344..5.350
--each additional action adds to the time to execute


7.	What is the average rental rate per genre?
--rental rate is on the film table and genre (category) is on the category table
--since there isn't a direct key between those 2 tables, I included film_category
--selecting the category name from category and computing the average rental rate from film
--by using an inner join on category_id between the category table and the film_category table
--and then another inner join on film_id between the film_category table and film table to 
--be able to access the rental rate on the film table
--group by category name puts the data together and ordering by rental rate puts them in ascending order
SELECT cat.name, AVG(f.rental_rate) AS rate
FROM category AS cat
	INNER JOIN film_category AS fcat
	ON cat.category_id = fcat.category_id
		INNER JOIN film AS f
		ON fcat.film_id = f.film_id
GROUP BY cat.name
ORDER BY rate;

8.	How many films were returned late? Early? On time? 
--Using CASE WHEN with SUM aggregator to get the number of rentals that were returned early,
--late, and on time.
--Comparison between rental_duration from the film table and the difference in days between 
--the return_date and rental_date from the rental table is done in each CASE WHEN statement, 
--counting each time the criterion is met. Inner joins are needed to get all the information together. 
--Inner join on film_id is done between the film table and the inventory table. Another inner join 
--on inventory_id between the inventory and rental table allowed access to the return_date and rental_date
SELECT 
SUM (CASE WHEN rental_duration > (return_date::date - rental_date::date) THEN 1
	 ELSE 0
	 END) AS "Early",
SUM (CASE WHEN rental_duration < (return_date::date - rental_date::date) THEN 1
	 ELSE 0
	 END) AS "Late",
SUM (CASE WHEN rental_duration = (return_date::date - rental_date::date) THEN 1
	 ELSE 0
	 END) AS "On-Time"
FROM film as f
INNER JOIN inventory as i
ON f.film_id = i.film_id
	INNER JOIN rental as r
	ON i.inventory_id = r.inventory_id;
	
9.	What categories are the most rented and what are their total sales?	
--Tables used here - category (for the name of the category), film_category, inventory, rental, and payment (to get
--the amount spent in order to total it per category). film_category, inventory and rental were used as a way to get
--from the category table to the payment table by way of inner joins on the keys/columns in each table.
--Inner join on category_id between category and film_category
--Inner join on film_id between film_category and inventory
--Inner join on inventory_id between inventory and rental
--Final inner join on rental_id between rental and payment
--Grouped by category name 
--Ordered by total sales from most to least using DESC keyword (descending order) 
SELECT cat.name, SUM(p.amount) AS total_sales
FROM category AS cat
	INNER JOIN film_category AS fcat
	ON cat.category_id = fcat.category_id
		INNER JOIN inventory AS i
		ON fcat.film_id = i.film_id
			INNER JOIN rental AS r
			ON i.inventory_id = r.inventory_id
				INNER JOIN payment AS p
				ON r.rental_id = p.rental_id
GROUP BY cat.name
ORDER BY total_sales DESC;

10.	Create a view for 8 and a view for 9. Be sure to name them appropriately. 
--for #8, using the CREATE VIEW command, created a view of the results from the query in #8
--called rental_returns. This view has 3 columns; Early, Late, and On-Time.
CREATE VIEW rental_returns AS 
SELECT 
SUM (CASE WHEN rental_duration > (return_date::date - rental_date::date) THEN 1
	 ELSE 0
	 END) AS "Early",
SUM (CASE WHEN rental_duration < (return_date::date - rental_date::date) THEN 1
	 ELSE 0
	 END) AS "Late",
SUM (CASE WHEN rental_duration = (return_date::date - rental_date::date) THEN 1
	 ELSE 0
	 END) AS "On-Time"
FROM film as f
INNER JOIN inventory as i
ON f.film_id = i.film_id
	INNER JOIN rental as r
	ON i.inventory_id = r.inventory_id;

--#9, using the CREATE VIEW command, created a view of the results from the query in #9
--called top_cat_sales. This view has 2 columns; name and total_sales.
CREATE VIEW top_cat_sales AS 
SELECT cat.name, SUM(p.amount) AS total_sales
FROM category AS cat
	INNER JOIN film_category AS fcat
	ON cat.category_id = fcat.category_id
		INNER JOIN inventory AS i
		ON fcat.film_id = i.film_id
			INNER JOIN rental AS r
			ON i.inventory_id = r.inventory_id
				INNER JOIN payment AS p
				ON r.rental_id = p.rental_id
GROUP BY cat.name
ORDER BY total_sales DESC;

Bonus:
Write a query that shows how many films were rented each month. Group them by category and month. 
--Tables used: rental, inventory, film_category, and category
--get name from category, use the TO_CHAR command to convert the month portion of the rental_date field to text value,
--use DATE_PART in COUNT command to count the number of times each month shows up in rental_date for the films rented
--rental and inventory are joined on inventory_id, inventory and film_category are joined on film_id, and
--film_category and category are joined on category_id.
--group by puts the count associated with category and month together
SELECT cat.name, TO_CHAR(rental_date, 'Month') AS month_of_year, COUNT(DATE_PART('month', rental_date)) AS times_rented_month
FROM rental AS r
	INNER JOIN inventory AS i
	ON r.inventory_id = i.inventory_id
		INNER JOIN film_category AS fcat
		ON i.film_id = fcat.film_id
			INNER JOIN category AS cat
			ON fcat.category_id = cat.category_id
GROUP BY cat.name, month_of_year;