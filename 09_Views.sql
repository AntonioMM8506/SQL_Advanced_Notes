-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- VIEWS


-- Basic use of CREATE VIEW
-- A view is basically a stored SELECT query.
-- A view does not store the underlying data.
-- We create views because:
    -- * Simplify/replace complex queries.
    -- * Make data easier to use for end-users.
    -- * Avoid "breakage" with schema changes.
    -- * Restrict data access.
CREATE VIEW general_hospital.v_monthly_suregery_stats_by_department AS
SELECT
	to_char(surgical_admission_date, 'YYYY-MM'),
	unit_name,
	COUNT(surgery_id) AS num_surgeries,
	SUM(total_cost) AS total_cost,
	SUM(total_profit) AS total_profit
FROM general_hospital.surgical_encounters
GROUP BY to_char(surgical_admission_date, 'YYYY-MM'), unit_name
ORDER BY unit_name, to_char(surgical_admission_date, 'YYYY-MM');


SELECT * FROM general_hospital.v_monthly_suregery_stats_by_department;


SELECT * FROM information_schema.views;


SELECT * FROM information_schema.views WHERE table_schema= 'general_hospital';



-- Basic use of Modifying and Deleting Views, DROP, REPLACE and ALTER VIEW
-- Views can be modified or deleted much in the same way as normal tables.
-- We can: replace existing views, drop views and/or alter views.
DROP VIEW IF EXISTS general_hospital.v_monthly_suregery_stats_by_department;


CREATE OR REPLACE VIEW general_hospital.v_monthly_surgery_stats AS
SELECT 
	to_char(surgical_admission_date,  'YYYY-MM') AS year_month,
	COUNT(surgery_id) AS num_surgeries,
	SUM(total_cost) AS total_cost,
	SUM(total_profit) AS total_profit
FROM general_hospital.surgical_encounters
GROUP BY 1
ORDER BY 1;


SELECT * FROM general_hospital.v_monthly_surgery_stats;


ALTER VIEW IF EXISTS general_hospital.v_monthly_surgery_stats
	RENAME TO view_monthly_surgery_stats;



-- Basic use of Updatable Views, WITH CHECK OPTION
-- Views an be updated. INSERT, UPDATE, and DELETE will work when certain conditions are met.
-- Statements will be converted to run against the underlying table.
-- Useful for allowing certain users to update certain columns.
	-- * No window functions.
	-- * No aggregate functions.
	-- * No LIMIT
	-- * No GROUP BY, HAVING, etc.
	-- * No set operations, for example: UNION
	-- * Built on single table.
-- To restrict the type of data that can be modified through the view, use WITH CHECK OPTION.
-- This checks that data satisfies view constraints before modifying or inserting data.
-- Data that fails this check will not be modified/inserted.
SELECT DISTINCT department_id FROM general_hospital.encounters ORDER BY 1;


CREATE VIEW general_hospital.v_encounters_department_22100005 AS
SELECT
	patient_encounter_id,
	admitting_provider_id,
	department_id,
	patient_in_icu_flag
FROM general_hospital.encounters
WHERE department_id = 22100005;


SELECT * FROM general_hospital.v_encounters_department_22100005;


-- It will allow to insert into the view without validating. 
INSERT INTO general_hospital.v_encounters_department_22100005 
VALUES( 01234, 5611, 22100006, 'Yes');


SELECT * FROM general_hospital.encounters WHERE patient_encounter_id = 01234;


-- Adding the validation WITH CHECK OPTION.
CREATE OR REPLACE VIEW general_hospital.v_encounters_department_22100005 AS 
SELECT
	patient_encounter_id,
	admitting_provider_id,
	department_id,
	patient_in_icu_flag
FROM general_hospital.encounters
WHERE department_id = 22100005
WITH CHECK OPTION;


-- It will return an error because of the validation.
INSERT INTO general_hospital.v_encounters_department_22100005 
VALUES (01235, 5611, 2210006, 'Yes');


SELECT * FROM general_hospital.v_encounters_department_22100005;


-- It will return an error because of the validation.
UPDATE general_hospital.v_encounters_department_22100005 
	SET department_id = 22100006
	WHERE patient_encounter_id = 4915064;



-- Basic use of MATERIALIZED VIEW
-- Views do not store the underlying data from the SELECT statement by default.
-- Sometimes, we need speed of access in addition to the convenience of a view.
-- With materialized views, we can store the underlying data in a view.
CREATE MATERIALIZED VIEW general_hospital.v_monthly_surgery_stats AS
SELECT
	to_char(surgical_admission_date, 'YYYY-MM'),
	unit_name, 
	COUNT(surgery_id) AS num_surgeries,
	SUM(total_cost) AS total_cost,
	SUM(total_profit) AS total_profit
FROM general_hospital.surgical_encounters
GROUP BY 1, 2
ORDER BY 2, 1
WITH NO DATA; 


-- It will return an error because the table has been created without being populated.
SELECT * FROM general_hospital.v_monthly_surgery_stats;


-- Populates the table
REFRESH MATERIALIZED VIEW general_hospital.v_monthly_surgery_stats;


SELECT * FROM general_hospital.v_monthly_surgery_stats;


ALTER MATERIALIZED VIEW general_hospital.v_monthly_surgery_stats
	RENAME TO mv_monthly_surgery_stats;


ALTER  MATERIALIZED VIEW general_hospital.mv_monthly_surgery_stats
	RENAME COLUMN to_char TO year_month;


-- Query all the Materialized views that exist at the moment.
SELECT * FROM pg_matviews;



-- Basic use of RECURSIVE VIEW
-- Recursive views serve the sam purpose as views in general, but for recursive expressions.
-- For example: WITH statements.
-- Functionally equivalent to creating a normal view with a recursive CTE.
CREATE RECURSIVE VIEW general_hospital.v_fibonacci(a, b) AS
SELECT 1 AS a, 1 AS b
UNION ALL
SELECT b, a+b
FROM v_fibonacci
WHERE b < 200;


SELECT * FROM general_hospital.v_fibonacci;


CREATE RECURSIVE VIEW general_hospital.v_orders (order_procedure_id, order_parent_order_id, level) AS
SELECT 
	order_procedure_id,
	order_parent_order_id,
	0 AS level
FROM general_hospital.orders_procedures
WHERE order_parent_order_id IS null
UNION all
SELECT 
	op.order_procedure_id,
	op.order_parent_order_id,
	o.level + 1 AS level
FROM general_hospital.orders_procedures op
INNER JOIN v_orders o 
	ON op.order_parent_order_id = o.order_procedure_id;
	

SELECT * FROM general_hospital.v_orders WHERE order_parent_order_id IS NOT null;



-- ++++ CHALLENGES ++++
-- Create a view for primary care patients by excluding sensitive geographic/address information
-- but include PCP name.
CREATE VIEW general_hospital.view_patients_primary_care AS
SELECT
	p.master_patient_id,
	p.name AS patient_name,
	p.gender,
	p.primary_language,
	p.date_of_birth,
	p.pcp_id,
	ph.full_name AS pcp_name
FROM general_hospital.patients p
LEFT OUTER JOIN general_hospital.physicians ph
	ON p.pcp_id = ph.id;


SELECT * FROM general_hospital.view_patients_primary_care;


-- Create an unpopulated materialized view mv_hospital_encounters reporting on the number of
-- encounters and ICU patients by year/month by hospital. 
-- Populate the new materialized view and alter the name to mv_hospital_encounters_statistics.
CREATE MATERIALIZED VIEW general_hospital.mv_hospital_encounters AS
SELECT 
	h.hospital_id,
	h.hospital_name,
	to_char(patient_admission_datetime, 'YYYY-MM') AS year_month,
	COUNT(patient_encounter_id) AS num_encounters,
	COUNT(nullif(patient_in_icu_flag, 'No')) AS num_icu_patients
FROM general_hospital.encounters e
LEFT OUTER JOIN general_hospital.departments d
	on e.department_id = d.department_id
LEFT OUTER JOIN general_hospital.hospitals h
	ON d.hospital_id = h.hospital_id
GROUP BY 1, 2, 3
ORDER BY 1, 3
WITH NO DATA; 


REFRESH MATERIALIZED VIEW general_hospital.mv_hospital_encounters;


SELECT * FROM general_hospital.mv_hospital_encounters;


ALTER MATERIALIZED VIEW general_hospital.mv_hospital_encounters
	RENAME TO mv_hospital_encounters_statistics;


-- Create a primary care patients view for pcp_id = 4121 and prevent unwanted inserts/updates.
	-- * Set a default value for pcp_id
	-- * Check that inserts works as expected.
CREATE VIEW general_hospital.view_patients_primary_maleham AS
SELECT
	p.master_patient_id,
	p.name AS patient_name,
	p.gender,
	p.primary_language,
	p.pcp_id,
	p.date_of_birth
FROM general_hospital.patients p
WHERE
	p.pcp_id = 4121
WITH CHECK OPTION;


ALTER VIEW general_hospital.view_patients_primary_maleham 
	ALTER COLUMN pcp_id SET DEFAULT 4121;


ALTER VIEW general_hospital.view_patients_primary_maleham
	RENAME TO view_patients_primary_care_maleham;


INSERT INTO general_hospital.view_patients_primary_care_maleham 
VALUES(1245, 'John Doe', 'Male', 'ENGLISH', default, '2003-01-01');


-- It will return a value because of the validation. 
INSERT INTO general_hospital.view_patients_primary_care_maleham 
VALUES(1246, 'John Doe', 'Male', 'ENGLISH', 4122, '2003-01-01');

