-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- ADVANCED JOIN OPERATIONS


-- Basic use of Self Joins
-- Joining a table to itself based on a join condition.
-- Self Joins are useful for analyzing hierarchical or network-like data.
-- It is not a distinct join like LEFT, RIGHT, INNER, etc.
-- No special keyword is needed - just use whatever join you need to.
-- Do use table aliases that are more descriptive.
SELECT se1.surgery_id AS surgery_id1, (se1.surgical_discharge_date - se1.surgical_admission_date) AS los1,
		se2.surgery_id AS surgery_id2, (se2.surgical_discharge_date - se2.surgical_admission_date) AS los2
FROM general_hospital.surgical_encounters se1
INNER JOIN general_hospital.surgical_encounters se2
	ON (se1.surgical_discharge_date - se1.surgical_admission_date) = (se2.surgical_discharge_date - se2.surgical_admission_date);
	
	
SELECT o1.order_procedure_id, o1.order_procedure_description, o2.order_parent_order_id, o2.order_procedure_description
FROM general_hospital.orders_procedures o1
INNER JOIN general_hospital.orders_procedures o2
	ON o1.order_parent_order_id = o2.order_procedure_id;
	
	
	
-- Basic use of Cross Joins
-- A cross join generates all combinations of the rows of the table 1 and the rows of the table 2.
-- Sometimes it is referred to as Cartesian product of the data.
-- Useful for generating all combinations of "stuff". 

-- *** NOTE *** --
-- Explicit is better than implicit, avoid accidental cross joins by specifying LEFT, RIGHT, INNER, etc.
-- Avoid cross joins if possiblle, the performance tends to be very poor. 

SELECT h.hospital_name, d.department_name
FROM general_hospital.hospitals h
CROSS JOIN general_hospital.departments d;



-- Basic use of Full Joins
-- Full Join is a combination of a LEFT JOIN and RIGHT JOIN. 
-- Full join return the records that are in: 
	-- * Both tables
	-- * Table 1, but not Table 2
	-- * Table 2, but not Table 1
-- Practically speaking:
	-- 1. Find the records satisfying the join condition.
	-- 2. Add rows from Table 1 that don't satisfy join condition and add null values.
	-- 3. Repeat with Table 1 and Table 2 reversed. 
-- Useful for finding data quality issues. 
SELECT d.department_id, d.department_name
FROM general_hospital.departments d
FULL JOIN general_hospital.hospitals h
	ON d.hospital_id = h.hospital_id
WHERE h.hospital_id IS null; 


SELECT a.account_id, e.patient_encounter_id
FROM general_hospital.accounts a
FULL JOIN general_hospital.encounters e
	ON a.account_id = e.hospital_account_id
WHERE a.account_id IS null OR e.patient_encounter_id IS null;


SELECT a.account_id, e.patient_encounter_id
FROM general_hospital.accounts a
FULL JOIN general_hospital.encounters e
	ON a.account_id = e.hospital_account_id
WHERE a.account_id IS null;



-- Basic use of Natural Joins
-- Databases will often have columns with the same name in multiple tables.
-- NARUTAL JOIN and USING let us take advantage of this for our join conditions.
-- NATURAL JOIN is implicit.
-- USING is explicit.
-- NATURAL JOIN includes all common column names between tables.
-- It acts like an implicit USING clause.
-- It behaves like INNER JOIN by default.
-- If there are no common columns, natural join will behave as a CROSS JOIN, resulting in bad performance.
-- Possible pitfalls:
	-- * Audit columns => created, modified datetimes.
	-- * Schema changes.
-- For all of these reasons, usually is better to use USING.

-- The next queries are exactly the same:
SELECT h.hospital_name, d.department_name
FROM general_hospital.departments d
INNER JOIN general_hospital.hospitals h 
	USING (hospital_id);


SELECT h.hospital_name, d.department_name
FROM general_hospital.departments d
NATURAL JOIN general_hospital.hospitals h;



-- ++++ CHALLENGES ++++
-- Find all combinations of physicians and practices in the database.
SELECT p.full_name AS physician_name, pr.name AS practice_name
FROM general_hospital.physicians p
CROSS JOIN general_hospital.practices pr;

-- Find the average blood pressure (systolic and diastolic) by admitting provider.
SELECT p.full_name, 
		AVG(v.bp_systolic) AS avg_systolic, 
		AVG(v.bp_diastolic) AS avg_diastolic
FROM general_hospital.vitals v
INNER JOIN general_hospital.encounters e USING (patient_encounter_id)
LEFT OUTER JOIN general_hospital.physicians p
	ON e.admitting_provider_id = p.id
GROUP BY p.full_name;

-- Find the number of surgeries in the surgical costs table without data in the surgical encounters table.
SELECT COUNT(DISTINCT sc.surgery_id)
FROM general_hospital.surgical_costs sc
FULL JOIN general_hospital.surgical_encounters se USING (surgery_id)
WHERE se.surgery_id IS null;

