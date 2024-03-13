-- *******************************************************************************************************************
-- Advanced SQL BootCamp

-- SUBQUERIES AND CTEs

-- *** NOTE ***
-- In the case of using PGAdmin or MySQL tool, because the current database contains 2 schemas, then
-- in every query the required schema needs to be indicated, in this case we are working with the schema
-- general_hospital
SELECT * FROM general_hospital.accounts;



-- Basic use of SUBQUERIES
-- Subqueries are queries inside quetries. Can be used in SELECT, UPDATE, CREATE, DELETE statements.
-- There are different types of SubQueries:
	-- * Basic Subquery => FROM clause
	-- * Common table expressions => WITH clauses
	-- * Comparisons with main data set
-- You can nest as many queries as you want.
-- Subqueries enable you to write more complex queries.

-- SubQueries in FROM and JOIN clauses
-- The letter "p" and "se" at the end indicates the name we are giving to the subquery.
SELECT * FROM (
	SELECT * 
	FROM general_hospital.patients 
	WHERE date_of_birth >= '2000-01-01' 
	ORDER BY master_patient_id
) p
WHERE p.name ilike 'm%';


SELECT * FROM (
	SELECT * 
	FROM general_hospital.surgical_encounters 
	WHERE surgical_admission_date 
	BETWEEN '2016-11-01' AND '2016-11-30'
) se
INNER JOIN (
	SELECT master_patient_id
	FROM general_hospital.patients
	WHERE date_of_birth >= '1990-01-01'
) p on se.master_patient_id = p.master_patient_id;



-- Basic use of Common Table Expressions (CTEs)
-- CTEs provide a way to break down complex queries and make them easier to understand.
-- CTEs create tables that only exist for a single query.
-- CTEs can be re-used in a single query.
-- Good for performing complex, multi-step calculations.
-- Identified by a WITH clause => WITH table_name AS...
WITH young_patients as (
	SELECT * 
	FROM general_hospital.patients
	WHERE date_of_birth >= '2000-01-01'
)
SELECT * FROM young_patients WHERE name ilike 'm%';


	-- Concatenating 2 CTEs and then use them with an INNER JOIN
WITH top_counties AS (
	SELECT county, count(*) as num_patients
	FROM general_hospital.patients
	GROUP BY county
	HAVING count(*) > 1500
), 
county_patients AS (
	SELECT p.master_patient_id, p.county
	FROM general_hospital.patients p 
	INNER JOIN top_counties t 
	ON p.county = t.county
)
SELECT p.county, count(s.surgery_id) AS num_surgeries
FROM general_hospital.surgical_encounters s
INNER JOIN county_patients p 
ON s.master_patient_id = p.master_patient_id
GROUP BY p.county;



-- Basic use of Subqueries for Comparisons
-- Subqueries can be used in FROM and JOIN clauses but also in WHERE and HAVING clauses.
-- Useful for writing comparisons against values not known before hand.
WITH total_cost AS (
	SELECT surgery_id, sum(resource_cost) AS total_surgery_cost
	FROM general_hospital.surgical_costs
	GROUP BY surgery_id
)
SELECT *
FROM total_cost
WHERE total_surgery_cost > (
	SELECT AVG(total_surgery_cost)
	FROM total_cost
);


SELECT * 
FROM general_hospital.vitals
WHERE bp_diastolic > (
	SELECT MIN(bp_diastolic) 
	FROM general_hospital.vitals
)
AND bp_systolic < (
	SELECT MAX(bp_systolic) 
	FROM general_hospital.vitals
);



-- Basic use of Subqueries with IN and NOT IN
-- Useful for comparing sets of values where set is not known beforehand.
-- With IN and NOT IN, we select a column, with other comparison operators, we select a single value

-- *** NOTE ***
-- Subqueries with IN and NOT IN can often be written as joins, depending on performance. 

SELECT * 
FROM general_hospital.patients
WHERE master_patient_id IN (
	SELECT DISTINCT master_patient_id
	FROM general_hospital.surgical_encounters 
)
ORDER BY master_patient_id;


SELECT * 
FROM general_hospital.patients
WHERE master_patient_id NOT IN (
	SELECT DISTINCT master_patient_id
	FROM general_hospital.surgical_encounters 
)
ORDER BY master_patient_id;


SELECT DISTINCT p.master_patient_id
FROM general_hospital.patients p
INNER JOIN general_hospital.surgical_encounters s
ON p.master_patient_id = s.master_patient_id
ORDER BY p.master_patient_id;



-- Basic use of Subqueries with ANY and ALL
-- ANY or ALL must be preceded by an operator >, >=, <, <=, =, !=, LIKE
-- The SubQuery for ANY has to return one column. Then the query will check to see if the comparison
-- with any of the value in the subquery evaluates to True. Similar in some ways to a Boolean OR - As
-- long as one comparison is True, expression evaluates to True.
-- SOME is equivalent to ANY
-- IN is equivalent to = ANY
-- If no successes or True values for comparison and at least one null evalution for operator, result
-- will be null.
-- The Subquery for AND also has to return one column. Then, the query will check to see if the comparison
-- with all of the values in the subquery evaluates to True. Similar in some ways to a Boolean AND - All
-- comparisons in the expression must evaluate to True.
-- NOT IN is equivalent to <> ALL. If no False values for comparison and at least one null evaluation for
-- operator, result will be null.
SELECT *
FROM general_hospital.surgical_encounters
WHERE total_profit > ALL(
	SELECT AVG(total_cost)
	FROM general_hospital.surgical_encounters
	GROUP BY diagnosis_description
);


SELECT diagnosis_description, AVG(surgical_discharge_date - surgical_admission_date) AS length_of_stay
FROM general_hospital.surgical_encounters
GROUP BY diagnosis_description
HAVING AVG(surgical_discharge_date - surgical_admission_date) <= 
ALL(
	SELECT AVG (EXTRACT(DAY FROM patient_discharge_datetime - patient_admission_datetime))
	FROM general_hospital.encounters
	GROUP BY department_id
);


SELECT unit_name, string_agg(DISTINCT surgical_type, ',') AS case_types
FROM general_hospital.surgical_encounters
GROUP BY unit_name
HAVING string_agg(DISTINCT surgical_type, ',') 
LIKE ALL(
	SELECT string_agg(DISTINCT surgical_type, ',')
	FROM general_hospital.surgical_encounters
)



-- Basic use of EXISTS in Subqueries
-- Use EXISTS to see whether a subquery returns any results. Used with WHERE clause. 
-- Evaluated only to see if at least one row is returned True
-- EXISTS can be used with NOT keyword, just like IN/NOT IN. 
-- Subqueries with EXISTS can sometimes be inefficient and have poor performance.
-- When a subquery returns null, result of EXISTS evaluates to True
SELECT e.*
FROM general_hospital.encounters e
WHERE EXISTS(
	SELECT 1
	FROM general_hospital.orders_procedures o
	WHERE e.patient_encounter_id = o.patient_encounter_id
);


SELECT p.* 
FROM general_hospital.patients p
WHERE NOT EXISTS(
	SELECT 1
	FROM general_hospital.surgical_encounters s
	WHERE s.master_patient_id = p.master_patient_id
);



-- Basic use of Recursive CTEs
-- Recursion involves a function or process referring to itself.
-- Recursive CTEs provide a powerful tool for constructing or analyzing network or 
-- tree-lile relationships. 
-- It starts with a non-recursive base term in WITH clause, continue with recursive term.
WITH RECURSIVE fibonacci AS (
	SELECT 1 AS a, 1 AS b
	UNION ALL
	SELECT b, a+b
	FROM fibonacci
)
SELECT a,b
FROM fibonacci
LIMIT 15;


WITH RECURSIVE orders AS (
	SELECT order_procedure_id, order_parent_order_id, 0 AS level
	FROM general_hospital.orders_procedures
	WHERE order_parent_order_id IS null
	UNION ALL
	SELECT op.order_procedure_id, op.order_parent_order_id, o.level+1 AS level
	FROM general_hospital.orders_procedures op
	INNER JOIN orders o ON op.order_parent_order_id = o.order_procedure_id
)
SELECT *
FROM orders
WHERE level != 0;



-- ++++ CHALLENGES ++++
-- Find the average number of orders per encounter by provider/physician.
SELECT * FROM general_hospital.encounters; --attending_provider_id, discharging_provider_id, admitting_provider_id
SELECT * FROM general_hospital.orders_procedures; --order_procedure_id, patient_encounter_id
SELECT attending_provider_id, COUNT(attending_provider_id) FROM general_hospital.encounters GROUP BY attending_provider_id;
SELECT * FROM general_hospital.physicians;

WITH avg_orders AS(
	SELECT ordering_provider_id, patient_encounter_id, COUNT(order_procedure_id) AS number_procedures
	FROM general_hospital.orders_procedures
	GROUP BY ordering_provider_id, patient_encounter_id
),
provider_orders AS(
	SELECT ordering_provider_id, AVG(number_procedures) AS avg_number_procedures
	FROM avg_orders
	GROUP BY ordering_provider_id
)
SELECT p.full_name, o.avg_number_procedures
FROM general_hospital.physicians p
LEFT OUTER JOIN provider_orders o
ON p.id = o.ordering_provider_id
WHERE o.avg_number_procedures IS NOT null
ORDER BY o.avg_number_procedures DESC;


-- Find encounters with any of the top 10 most common order codes.
SELECT DISTINCT patient_encounter_id
FROM general_hospital.orders_procedures
WHERE order_cd IN (
	SELECT order_cd 
	FROM general_hospital.orders_procedures
	GROUP BY order_cd
	ORDER BY COUNT(*) DESC
	LIMIT 10
);

-- Find accounts with a total account balance over $10,000 and at least one ICU (intensive Care Unit) encounter. 
SELECT a.account_id, a.total_account_balance
FROM general_hospital.accounts a
WHERE total_account_balance > 10000
	AND EXISTS(
		SELECT 1
		FROM general_hospital.encounters e
		WHERE e.hospital_account_id = a.account_id
			AND patient_in_icu_flag = 'Yes'
	);

-- Find encounters for patients born on or after 1995-01-01 whose length of stay is greater than or
-- equal to the average surgical length of stay for patients 65 or older. 
WITH old_los AS(
	SELECT 
		EXTRACT(YEAR FROM age(now(), p.date_of_birth)) AS age, 
		AVG(s.surgical_discharge_date - s.surgical_admission_date) AS avg_los
	FROM general_hospital.patients p
	INNER JOIN general_hospital.surgical_encounters s
		ON p.master_patient_id = s.master_patient_id
	WHERE p.date_of_birth IS NOT null 
		AND EXTRACT(YEAR FROM age(now(), p.date_of_birth)) >= 65
	GROUP BY EXTRACT(YEAR FROM age(now(), p.date_of_birth)) 
)
SELECT e.*
FROM general_hospital.encounters e
INNER JOIN general_hospital.patients p
	ON e.master_patient_id = p.master_patient_id
	AND p.date_of_birth >= '1995-01-01'
WHERE EXTRACT(days FROM (e.patient_discharge_datetime - e.patient_admission_datetime)) 
	>= ALL(
		SELECT avg_los
		FROM old_los
	); 




