-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- SET OPERATIONS
-- Set Operations let us combine results of different queries.


-- Basic use of UNION
-- UNION ad the result of one query to the result of another query. 
-- Both queries must have the same number of columns.
-- Columns muts have the same of similar data types; ex: not datetime and text at the same time.
-- Duplicate values will be removed unless UNION ALL is used.
SELECT surgery_id 
FROM general_hospital.surgical_encounters
UNION 
SELECT surgery_id
FROM general_hospital.surgical_costs
ORDER BY surgery_id;


SELECT surgery_id 
FROM general_hospital.surgical_encounters
UNION ALL
SELECT surgery_id
FROM general_hospital.surgical_costs
ORDER BY surgery_id;



-- Basic use of INTERSECT
-- Like UNION, INTERSECT enables us to combine the results of two queries.
-- It will get rid of all the duplicates by default.
-- INTERSECT returns rows that are in the result of both query 1 and query 2.
-- Queries must have the same number of columns and convertible data types.
-- Duplicate values will be removed unless INTERSECT ALL is used.
SELECT surgery_id
FROM general_hospital.surgical_encounters
INTERSECT
SELECT surgery_id
FROM general_hospital.surgical_costs
ORDER BY surgery_id;


WITH all_patients AS (
	SELECT master_patient_id
	FROM general_hospital.encounters
	INTERSECT
	SELECT master_patient_id
	FROM general_hospital.surgical_encounters
)
SELECT ap.master_patient_id, p.name
FROM all_patients ap
LEFT OUTER JOIN general_hospital.patients p
ON ap.master_patient_id = p.master_patient_id;



-- Basic use of EXCEPT
-- EXCEPT returns rows that are in the result of query 1 but not query 2.
-- Queries must have the same number of columns and convertible data types.
-- Duplicate values will be removed unless EXCEPT ALL is used.
SELECT surgery_id
FROM general_hospital.surgical_costs
EXCEPT
SELECT surgery_id
FROM general_hospital.surgical_encounters
ORDER BY surgery_id;


WITH missing_departments AS(
	SELECT department_id
	FROM general_hospital.departments
	EXCEPT
	SELECT department_id
	FROM general_hospital.encounters
)
SELECT m.department_id, d.department_name
FROM missing_departments m
LEFT OUTER JOIN general_hospital.departments d
ON m.department_id = d.department_id;



-- ++++ CHALLENGES ++++
-- Generate a list of all physicians and physician types in the encounters table, including their names.
WITH providers AS(
	SELECT admitting_provider_id AS provider_id, 'Admitting' AS provider_type
	FROM general_hospital.encounters
	UNION 
	SELECT discharging_provider_id, 'Discharging' 
	FROM general_hospital.encounters
	UNION
	SELECT attending_provider_id, 'Attending'
	FROM general_hospital.encounters
)
SELECT p.provider_id, p.provider_type, ph.full_name
FROM providers p
LEFT OUTER JOIN general_hospital.physicians ph
ON p.provider_id = ph.id
ORDER BY ph.full_name;


-- Find all primary care physicians (PCPs) who also are admitting providers.
WITH admitting_pcps AS(
	SELECT pcp_id
	FROM general_hospital.patients
	INTERSECT
	SELECT admitting_provider_id
	FROM general_hospital.encounters
)
SELECT a.pcp_id, p.full_name
FROM admitting_pcps a
LEFT OUTER JOIN general_hospital.physicians p
ON a.pcp_id = p.id;


-- Determine whether there are any surgeons in the surgical_encounters table who are not in the physicians table. 
SELECT surgeon_id
FROM general_hospital.surgical_encounters
EXCEPT 
SELECT id
FROM general_hospital.physicians;

