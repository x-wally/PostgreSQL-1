
\! clear

\c postgres
DROP DATABASE ecommerce;
CREATE DATABASE ecommerce WITH OWNER wally;
\c ecommerce

SET client_min_messages = 'ERROR';
-- \pset pager off
\set QUIET

-- customer
CREATE TABLE customer(
first_name VARCHAR(30) NOT NULL,
last_name VARCHAR(30) NOT NULL,
email VARCHAR(60) NOT NULL,
company VARCHAR(60) NULL,
street VARCHAR(50) NOT NULL,
city VARCHAR(40) NOT NULL,
state CHAR(2) NOT NULL DEFAULT 'PA',
zip SMALLINT NOT NULL,
phone VARCHAR(20) NOT NULL,
birth_date DATE NULL,
sex CHAR(1) NOT NULL,
date_entered TIMESTAMP NOT NULL,
id SERIAL PRIMARY KEY
);

INSERT INTO customer(first_name, last_name, email, company, street, city, state, zip, phone, birth_date, sex, date_entered) VALUES ('Christopher', 'Jones', 'christopherjones@bp.com', 'BP', '347 Cedar St', 'Lawrenceville', 'GA', '30044', '348-848-8291', '1938-09-11', 'M', current_timestamp);

CREATE TYPE sex_type as enum('M', 'F');

alter table customer
alter column sex type sex_type USING sex::sex_type;

-- sales_person
CREATE TABLE sales_person(
first_name VARCHAR(30) NOT NULL,
last_name VARCHAR(30) NOT NULL,
email VARCHAR(60) NOT NULL,
street VARCHAR(50) NOT NULL,
city VARCHAR(40) NOT NULL,
state CHAR(2) NOT NULL DEFAULT 'PA',
zip SMALLINT NOT NULL,
phone VARCHAR(20) NOT NULL,
birth_date DATE NULL,
sex sex_type NOT NULL,
date_hired TIMESTAMP NOT NULL,
id SERIAL PRIMARY KEY
);

-- product_type
CREATE TABLE product_type(
name VARCHAR(30) NOT NULL,
id SERIAL PRIMARY KEY
);

-- product
CREATE TABLE product( --> product_type
type_id INTEGER REFERENCES product_type(id),
name VARCHAR(30) NOT NULL,
supplier VARCHAR(30) NOT NULL,
description TEXT NOT NULL,
id SERIAL PRIMARY KEY
);

-- item
CREATE TABLE item( --> product
product_id INTEGER REFERENCES product(id),
size INTEGER NOT NULL,
color VARCHAR(30) NOT NULL,
picture VARCHAR(256) NOT NULL,
price NUMERIC(6,2) NOT NULL,
id SERIAL PRIMARY KEY
);

-- sales_order
CREATE TABLE sales_order( --> customer, --> sales_person
cust_id INTEGER REFERENCES customer(id),
sales_person_id INTEGER REFERENCES sales_person(id),
time_order_taken TIMESTAMP NOT NULL,
purchase_order_number BIGINT NOT NULL,
credit_card_number VARCHAR(16) NOT NULL,
credit_card_exper_month SMALLINT NOT NULL,
credit_card_exper_day SMALLINT NOT NULL,
credit_card_secret_code SMALLINT NOT NULL,
name_on_card VARCHAR(100) NOT NULL,
id SERIAL PRIMARY KEY
);

-- sales_item
CREATE TABLE sales_item( --> item, --> sales_order
item_id INTEGER REFERENCES item(id),
sales_order_id INTEGER REFERENCES sales_order(id),
quantity INTEGER NOT NULL,
discount NUMERIC(3,2) NULL DEFAULT 0,
taxable BOOLEAN NOT NULL DEFAULT FALSE,
sales_tax_rate NUMERIC(5,2) NOT NULL DEFAULT 0,
id SERIAL PRIMARY KEY
);

ALTER TABLE sales_item ADD day_of_week VARCHAR(8);

ALTER TABLE sales_item ALTER COLUMN day_of_week SET NOT NULL;

ALTER TABLE sales_item RENAME COLUMN day_of_week TO weekday;

ALTER TABLE sales_item DROP COLUMN weekday;

-- transaction_type
CREATE TABLE transaction_type(
name VARCHAR(30) NOT NULL,
payment_type VARCHAR(30) NOT NULL,
id SERIAL PRIMARY KEY
);

ALTER TABLE transaction_type RENAME TO transaction;

CREATE INDEX transaction_id ON transaction(name);

CREATE INDEX transaction_id_2 ON transaction(name, payment_type);

TRUNCATE TABLE transaction;

DROP TABLE transaction;

INSERT INTO product_type (name) VALUES ('Business');
INSERT INTO product_type (name) VALUES ('Casual');
INSERT INTO product_type (name) VALUES ('Athletic');
\echo 'PRODUCT TYPE'
-- select * from product_type;

\i 'data/product_data'
\echo 'PRODUCT'
-- select * from product;

ALTER TABLE customer ALTER COLUMN zip TYPE INTEGER;

\i 'data/customer_data'
\echo 'CUSTOMER'
-- select * from customer;

ALTER TABLE sales_person ALTER COLUMN zip TYPE INTEGER;

\i 'data/sales_person_data'
\echo 'SALES PERSON'
-- select * from sales_person;

\i 'data/item_data'
\echo 'ITEM'
-- select * from item;

\i 'data/sales_order_data'
\echo 'SALES ORDER'
-- select * from sales_order;

\i 'data/sales_item_data'
\echo 'SALES ITEM'
-- SELECT * FROM sales_item;

-- tutti i sales_item con discount > 15%
SELECT * FROM sales_item WHERE discount > .15 ORDER BY discount DESC LIMIT 5;

-- tutti i time_order_taken in sales_order con ( 2018-12-01 < time_order_taken < 2018-12-31 )
SELECT time_order_taken
FROM sales_order
WHERE time_order_taken > '2018-12-01' AND time_order_taken < '2018-12-31';

SELECT time_order_taken
FROM sales_order
WHERE time_order_taken BETWEEN '2018-12-01' AND '2018-12-31';

-- i primi 5 sales_item con discount > 15% ordinati per discount decrescente
SELECT * FROM sales_item WHERE discount > .15 ORDER BY discount DESC LIMIT 5;

-- '<first_name> <last_name>', phone, state di tutti i costumer con state = 'TX' 
SELECT CONCAT(first_name, ' ', last_name) AS Name, phone, state FROM customer WHERE state = 'TX';

-- product_id e somma dei price degli item con product_id = 1 raggruppati per product_id
SELECT product_id, SUM(price) AS Total FROM item WHERE product_id=1 GROUP BY product_id;

-- tutti gli stati distinti in customer
SELECT DISTINCT state FROM customer ORDER BY state;

-- tutti gli stati distinti in customer diversi da 'CA'
SELECT DISTINCT state FROM customer WHERE state != 'CA' ORDER BY state; 

-- tutti gli stati in customer tra 'CA' e 'NJ'
SELECT DISTINCT state FROM customer WHERE state IN ('CA', 'NJ') ORDER BY state;

-- item_id e price da
SELECT item_id, price FROM 
-- item e sales_item
item INNER JOIN sales_item
-- dove item.id = sales_item.item_id e price > 123
ON item.id = sales_item.item_id AND price>120
ORDER BY item_id;

SELECT sales_order.id, sales_item.quantity, item.price, (sales_item.quantity*item.price) AS Total
FROM sales_order 
    JOIN sales_item ON sales_item.sales_order_id = sales_order.id
    JOIN item ON item.id = sales_item.item_id
ORDER BY sales_order.id;

SELECT item_id, price 
FROM item, sales_item 
WHERE item.id = sales_item.item_id AND price>120.00 
ORDER BY item_id;

SELECT name, supplier, price
FROM product 
    LEFT JOIN item ON item.product_id = product.id
ORDER BY name;

SELECT sales_order_id, quantity, product_id
FROM item CROSS JOIN sales_item
ORDER BY sales_order_id;

SELECT first_name, last_name, street, city, zip, birth_date
FROM customer
WHERE EXTRACT(MONTH FROM birth_date) = 12
UNION
    SELECT first_name, last_name, street, city, zip, birth_date
    FROM sales_person
    WHERE EXTRACT(MONTH FROM birth_date) = 12
ORDER BY birth_date;

SELECT product_id , price FROM item WHERE price = NULL;

/*
REGEX
.     : 1 char
_     : 1 char
*     : 0+ char
+     : 1+ char
^     : start
$     : end
[^a]  : not a
m|n   : m or n 
[ab]  : a and b
[A-Z] : all uppercase letters
[a-z] : all lowercase letters
[0-9] : all numbers
{n}   : n instances of
{m,n} : between n and m instances of
*/

-- SIMILAR TO
SELECT first_name, last_name FROM customer WHERE first_name SIMILAR TO 'M%';
-- LIKE
SELECT first_name, last_name FROM customer WHERE first_name LIKE '%n';
-- ILIKE
SELECT first_name, last_name FROM customer WHERE first_name ILIKE '%IN';
-- ~
SELECT first_name, last_name FROM customer WHERE first_name ~ '^Ma';

SELECT EXTRACT(MONTH FROM birth_date) AS Month, COUNT(*) AS Amount
FROM customer GROUP BY Month ORDER BY Month;

SELECT EXTRACT(MONTH FROM birth_date) AS Month, COUNT(*) AS Amount
FROM customer GROUP BY Month HAVING COUNT(*)>1 ORDER BY Month;

SELECT id, SUM(price) AS Total FROM item GROUP BY id ORDER BY id;

SELECT 
COUNT(*) AS Items, 
SUM(price) AS Total,
ROUND( AVG(price), 2 ) AS Average,
MIN(price) AS Min,
MAX(price) AS Max
FROM item;

CREATE VIEW purchase_order_overview AS
SELECT 
    sales_order.purchase_order_number, customer.company, 
    sales_item.quantity, product.supplier, product.name, item.price,
    CONCAT(sales_person.first_name, ' ', sales_person.last_name) AS Salesperson
FROM sales_order 
    JOIN sales_item ON sales_item.sales_order_id = sales_order.id
    JOIN item ON sales_item.item_id = item.id
    JOIN customer ON sales_order.cust_id = customer.id
    JOIN product ON item.product_id = product.id
    JOIN sales_person ON sales_order.sales_person_id = sales_person.id 
ORDER BY purchase_order_number;

SELECT *, (quantity*price) AS Total FROM purchase_order_overview;
DROP VIEW purchase_order_overview;

CREATE OR REPLACE FUNCTION fn_add_ints(int, int) 
RETURNS int as
$body$
SELECT $1 + $2;
$body$
LANGUAGE SQL;

SELECT fn_add_ints(4,5);

CREATE OR REPLACE FUNCTION fn_update_state() 
RETURNS void as
$body$
UPDATE sales_person SET state = 'PA' WHERE state IS NULL;
$body$
LANGUAGE SQL;

SELECT fn_update_state();

CREATE OR REPLACE FUNCTION fn_max_product_price() 
RETURNS NUMERIC as
$body$
    SELECT MAX(price) FROM item;
$body$
LANGUAGE SQL;

SELECT fn_max_product_price();

CREATE OR REPLACE FUNCTION fn_sum_product_price() 
RETURNS NUMERIC as
$body$
    SELECT SUM(price) FROM item;
$body$
LANGUAGE SQL;

SELECT fn_sum_product_price();

CREATE OR REPLACE FUNCTION fn_num_customers() 
RETURNS NUMERIC as
$body$
    SELECT COUNT(*) FROM customer;
$body$
LANGUAGE SQL;

SELECT fn_num_customers();

CREATE OR REPLACE FUNCTION fn_num_customers_no_phone() 
RETURNS NUMERIC as
$body$
    SELECT COUNT(*) FROM customer WHERE phone IS NULL;
$body$
LANGUAGE SQL;

SELECT fn_num_customers_no_phone();

CREATE OR REPLACE FUNCTION fn_num_customers_from(state_name char(2)) 
RETURNS NUMERIC as
$body$
    SELECT COUNT(*) FROM customer WHERE state = state_name;
$body$
LANGUAGE SQL;

SELECT fn_num_customers_from('TX');

CREATE OR REPLACE FUNCTION fn_num_orders_from_customer(cust_name varchar, cust_surname varchar) 
RETURNS NUMERIC as
$body$
    SELECT COUNT(*) FROM sales_order NATURAL JOIN customer
    WHERE 
        customer.first_name = cust_name AND
        customer.last_name = cust_surname ;
$body$
LANGUAGE SQL;

SELECT fn_num_orders_from_customer('Christopher', 'Jones');

CREATE OR REPLACE FUNCTION fn_get_last_order() 
RETURNS sales_order as
$body$
    SELECT * FROM sales_order 
    ORDER BY time_order_taken DESC LIMIT 1;
$body$
LANGUAGE SQL;

SELECT (fn_get_last_order()).*;
SELECT (fn_get_last_order()).time_order_taken;

CREATE OR REPLACE FUNCTION fn_get_sales_person_from(loc char(2)) 
RETURNS SETOF sales_person as
$body$
    SELECT * FROM sales_person
    WHERE state = loc;
$body$
LANGUAGE SQL;

SELECT (fn_get_sales_person_from('CA')).*;

SELECT first_name, last_name, phone
FROM fn_get_sales_person_from('CA');

CREATE OR REPLACE FUNCTION fn_get_price_product_name(prod_name varchar) 
RETURNS numeric AS
$body$
	BEGIN
	
    RETURN item.price FROM item NATURAL JOIN product
	WHERE product.name = prod_name;
	
    END
$body$
LANGUAGE plpgsql;

SELECT fn_get_price_product_name('Grandview');

CREATE OR REPLACE FUNCTION fn_get_sum(val1 int, val2 int) 
RETURNS int AS
$body$
	DECLARE
		ans int;
	BEGIN
		ans := val1 + val2;
		RETURN ans;
	END;
$body$
LANGUAGE plpgsql;

SELECT fn_get_sum(4,5);

CREATE OR REPLACE FUNCTION fn_get_random_number(min_val int, max_val int) 
RETURNS int AS
$body$
	DECLARE
		rand int;
	BEGIN
		SELECT random()*(max_val - min_val) + min_val INTO rand;
		RETURN rand;
	END;
$body$
LANGUAGE plpgsql;

SELECT fn_get_random_number(1, 5);

CREATE OR REPLACE FUNCTION fn_get_random_salesperson() 
RETURNS varchar AS
$body$
	DECLARE
		rand int;
		emp record;
	BEGIN
		SELECT random()*(5 - 1) + 1 INTO rand;
		SELECT * FROM sales_person INTO emp WHERE id = rand;
		RETURN CONCAT(emp.first_name, ' ', emp.last_name);
		
	END;
$body$
LANGUAGE plpgsql;

SELECT fn_get_random_salesperson();

CREATE OR REPLACE FUNCTION 
fn_get_sum_2(IN v1 int, IN v2 int, OUT ans int) AS
$body$
	BEGIN
		ans := v1 + v2;
	END;
$body$
LANGUAGE plpgsql;

SELECT fn_get_sum_2(4,5);

CREATE OR REPLACE FUNCTION fn_get_cust_birthday(
    IN the_month int, OUT bd_month int, 
    OUT bd_day int, OUT f_name varchar, OUT l_name varchar
) AS
$body$
	BEGIN
		SELECT EXTRACT(MONTH FROM birth_date), EXTRACT(DAY FROM birth_date), 
		first_name, last_name 
		INTO bd_month, bd_day, f_name, l_name
    	FROM customer
    	WHERE EXTRACT(MONTH FROM birth_date) = the_month
		LIMIT 1;
		END;
$body$
LANGUAGE plpgsql;

SELECT (fn_get_cust_birthday(12)).*;

CREATE OR REPLACE FUNCTION fn_get_sales_people() 
RETURNS SETOF sales_person AS
$body$
	BEGIN
		RETURN QUERY SELECT * FROM sales_person;
	END;
$body$
LANGUAGE plpgsql;

SELECT (fn_get_sales_people()).*;

CREATE OR REPLACE FUNCTION fn_get_10_expensive_prods() 
RETURNS TABLE (
	name varchar,
	supplier varchar,
	price numeric
) AS
$body$
	BEGIN
		RETURN QUERY
		SELECT product.name, product.supplier, item.price
		FROM item
		NATURAL JOIN product
		ORDER BY item.price DESC
		LIMIT 10;
	END;
$body$
LANGUAGE plpgsql;

SELECT (fn_get_10_expensive_prods()).*;

CREATE OR REPLACE FUNCTION fn_check_month_orders(the_month int) 
RETURNS varchar AS
$body$
	DECLARE
		total_orders int;
	BEGIN
		SELECT COUNT(purchase_order_number)
    	INTO total_orders
		FROM sales_order
		WHERE EXTRACT(MONTH FROM time_order_taken) = the_month;
		IF total_orders > 5 THEN
			RETURN CONCAT(total_orders, ' Orders : Doing Good');
		ELSEIF total_orders < 5 THEN
			RETURN CONCAT(total_orders, ' Orders : Doing Bad');
		ELSE
			RETURN CONCAT(total_orders, ' Orders : On Target');
		END IF;	
	END;
$body$
LANGUAGE plpgsql;

SELECT fn_check_month_orders(10);

CREATE OR REPLACE FUNCTION fn_check_month_orders(the_month int) 
RETURNS varchar AS
$body$
	DECLARE
		total_orders int;
	BEGIN
		SELECT COUNT(purchase_order_number)
    	INTO total_orders
		FROM sales_order
		WHERE EXTRACT(MONTH FROM time_order_taken) = the_month;
		CASE
			WHEN total_orders < 1 THEN
				RETURN CONCAT(total_orders, ' Orders : Terrible');
			WHEN total_orders > 1 AND total_orders < 5 THEN
				RETURN CONCAT(total_orders, ' Orders : Get Better');
			WHEN total_orders = 5 THEN
				RETURN CONCAT(total_orders, ' Orders : On Target');
			ELSE
				RETURN CONCAT(total_orders, ' Orders : Doing Good');
		END CASE;	
	END;
$body$
LANGUAGE plpgsql;

SELECT fn_check_month_orders(11);

CREATE OR REPLACE FUNCTION fn_loop_test(max_num int) 
RETURNS int AS
$body$
	DECLARE
		j INT DEFAULT 1;
		tot_sum INT DEFAULT 0;
	BEGIN
		LOOP
			tot_sum := tot_sum + j;
			j := j + 1;
			EXIT WHEN j > max_num;
		END LOOP;
	RETURN tot_sum;
    END;
$body$
LANGUAGE plpgsql;

SELECT fn_loop_test(5);

CREATE OR REPLACE FUNCTION fn_for_test(max_num int) 
RETURNS int AS
$body$
	DECLARE
		tot_sum INT DEFAULT 0;
	BEGIN
		FOR i IN 1 .. max_num BY 2
		LOOP
			tot_sum := tot_sum + i;
		END LOOP;
	RETURN tot_sum;
END;
$body$
LANGUAGE plpgsql;

SELECT fn_for_test(5);

CREATE OR REPLACE FUNCTION fn_for_test(max_num int) 
RETURNS int AS
$body$
	DECLARE
		tot_sum INT DEFAULT 0;
	BEGIN
		FOR i IN REVERSE max_num .. 1 BY 2
		LOOP
			tot_sum := tot_sum + i;
		END LOOP;
	RETURN tot_sum;
END;
$body$
LANGUAGE plpgsql;

SELECT fn_for_test(5);

DO
$body$
	DECLARE
		rec record;
	BEGIN
		FOR rec IN
			SELECT first_name, last_name
			FROM sales_person
			LIMIT 5
		LOOP
			RAISE NOTICE '%, %', rec.first_name, rec.last_name;
		END LOOP;
	END;
$body$
LANGUAGE plpgsql;

DO
$body$
	DECLARE
		arr1 int[] := array[1,2,3];
		i int;
	
	BEGIN
		FOREACH i IN ARRAY arr1
		LOOP
			RAISE NOTICE '%', i;
		END LOOP;
	END;
$body$
LANGUAGE plpgsql;

DO
$body$
	DECLARE
		j INT DEFAULT 1;
		tot_sum INT DEFAULT 0;
	
	BEGIN
		WHILE j <= 10
		LOOP
			tot_sum := tot_sum + j;
			j := j + 1;
		END LOOP;
		RAISE NOTICE '%', tot_sum;
	END;
$body$
LANGUAGE plpgsql;

DO
$body$
	DECLARE
		i int DEFAULT 1;
	BEGIN
		LOOP
			i := i + 1;
		EXIT WHEN i > 10;
		CONTINUE WHEN MOD(i, 2) = 0;
		RAISE NOTICE 'Num : %', i;
		END LOOP;
	END;
$body$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_get_supplier_value(the_supplier varchar) 
RETURNS varchar AS
$body$
DECLARE
	supplier_name varchar;
	price_sum numeric;
BEGIN
	SELECT product.supplier, SUM(item.price)
 	INTO supplier_name, price_sum
	FROM product, item
	WHERE product.supplier = the_supplier
	GROUP BY product.supplier;
	RETURN CONCAT(supplier_name, ' Inventory Value : $', price_sum);
END;
$body$
LANGUAGE plpgsql;

SELECT fn_get_supplier_value('Nike');

/*
CREATE OR REPLACE PROCEDURE procedure_name(parameters)
AS
$body$
DECLARE
BEGIN
END;
$body$
LANGUAGE PLPGSQL;
*/

CREATE TABLE past_due (
    id SERIAL PRIMARY KEY,
    cust_id INTEGER NOT NULL,
    balance NUMERIC(6,2) NOT NULL
);

INSERT INTO past_due(cust_id, balance)
VALUES (1, 123.45), (2, 324.50);

CREATE OR REPLACE PROCEDURE pr_debt_paid(
	past_due_id int,
	payment numeric
) AS
$body$
DECLARE
    BEGIN
        UPDATE past_due
        SET balance = balance - payment
        WHERE id = past_due_id;
        COMMIT;
    END;
$body$
LANGUAGE PLPGSQL;

CALL pr_debt_paid(1, 10.00);

/*
CREATE FUNCTION trigger_function()
	RETURNS TRIGGER
	LANGUAGE PLPGSQL
AS
$body$
BEGIN
END;
$body$
CREATE TRIGGER trigger_name
	{BEFORE | AFTER} {event}
ON table_name
	[FOR [EACH] {ROW | STATEMENT}]
		EXECUTE PROCEDURE trigger_function
*/

CREATE TABLE distributor(
	id SERIAL PRIMARY KEY,
	name VARCHAR(100)
);
INSERT INTO distributor (name) VALUES ('Parawholesale'), ('J & B Sales'), ('Steel City Clothing');

CREATE TABLE distributor_audit(
	id SERIAL PRIMARY KEY,
	dist_id INT NOT NULL,
	name VARCHAR(100) NOT NULL,
	edit_date TIMESTAMP NOT NULL
);

CREATE OR REPLACE FUNCTION fn_log_dist_name_change()
	RETURNS TRIGGER
	LANGUAGE PLPGSQL
AS
$body$
BEGIN
	IF NEW.name <> OLD.name THEN
		INSERT INTO distributor_audit
		(dist_id, name, edit_date)
		VALUES
		(OLD.id, OLD.name, NOW());
	END IF;	
	RAISE NOTICE 'Trigger Name : %', TG_NAME;
	RAISE NOTICE 'Table Name : %', TG_TABLE_NAME;
	RAISE NOTICE 'Operation : %', TG_OP;
	RAISE NOTICE 'When Executed : %', TG_WHEN;
	RAISE NOTICE 'Row or Statement : %', TG_LEVEL;
	RAISE NOTICE 'Table Schema : %', TG_TABLE_SCHEMA;
	RETURN NEW;
END;
$body$;

CREATE TRIGGER tr_dist_name_changed
	BEFORE UPDATE ON distributor
	    FOR EACH ROW
	        EXECUTE PROCEDURE fn_log_dist_name_change();

UPDATE distributor SET name = 'Western Clothing' WHERE id = 2;

SELECT * FROM distributor_audit; 

CREATE OR REPLACE FUNCTION fn_block_weekend_changes()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS
$body$
BEGIN
	RAISE NOTICE 'No database changes allowed on the weekend';
	RETURN NULL;
END;
$body$;

CREATE TRIGGER tr_block_weekend_changes
	BEFORE UPDATE OR INSERT OR DELETE OR TRUNCATE 
	ON distributor
	FOR EACH STATEMENT
	WHEN(EXTRACT('DOW' FROM CURRENT_TIMESTAMP) IN (0, 6))
	EXECUTE PROCEDURE fn_block_weekend_changes();

UPDATE distributor SET name = 'Western Clothing' WHERE id = 2;
DROP TRIGGER tr_block_weekend_changes ON distributor;

DO $body$
DECLARE 
    cur_products CURSOR FOR 
    SELECT name, supplier FROM product;
BEGIN END $body$;

DO $body$
DECLARE 
    cur_products CURSOR FOR
        SELECT name, supplier FROM product WHERE supplier = $1;
BEGIN END $body$;

DO $body$
DECLARE
    cur_customers CURSOR FOR 
        SELECT first_name, last_name, phone, state FROM customer WHERE state = 'CA';
BEGIN
    OPEN cur_customers;
    --- 
    CLOSE cur_customers;
END $body$;

DO
$body$
	DECLARE
		msg text DEFAULT '';
		rec_customer record;
		cur_customers CURSOR
		FOR
			SELECT * FROM customer;
	BEGIN
		OPEN cur_customers;
		LOOP
			FETCH cur_customers INTO rec_customer;
			EXIT WHEN NOT FOUND;
			msg := msg || rec_customer.first_name || ' ' || rec_customer.last_name || E'\n';
		END LOOP;
	RAISE NOTICE E'\nCustomers:\n%', msg;
END $body$;


CREATE OR REPLACE FUNCTION fn_get_cust_by_state(c_state varchar)
RETURNS text
LANGUAGE PLPGSQL
AS
$body$
DECLARE
	cust_names text DEFAULT '';
	rec_customer record;
	cur_cust_by_state CURSOR (c_state varchar)
	FOR
		SELECT
			first_name, last_name, state
		FROM customer
		WHERE state = c_state;
BEGIN
	OPEN cur_cust_by_state(c_state);
	LOOP
		FETCH cur_cust_by_state INTO rec_customer;
		EXIT WHEN NOT FOUND;
		cust_names := cust_names || rec_customer.first_name || ' ' || rec_customer.last_name || E',\n';
	END LOOP;
	CLOSE cur_cust_by_state;
	RETURN cust_names;
END $body$;

SELECT fn_get_cust_by_state('CA');





