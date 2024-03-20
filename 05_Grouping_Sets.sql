-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- GROUPING SETS


-- Basic use of GROUPING SETS
-- Grouping sets enable us to aggregate data multiple times for multiple groups in a single query. 
-- Grouping sets allow us to specify different ways of grouping data in one query. 
-- Functionality similar to using UNION with multiple queries, but more efficient.
-- Explicit column references can be replaced with implicit column references, for example: "1" instead "of column_1"
SELECT state, county, COUNT(*) AS num_patients
FROM general_hospital.patients
GROUP BY GROUPING SETS(
	(state),
	(state, county),
	()
)
ORDER BY state DESC, county;


SELECT p.full_name, se.admission_type, se.diagnosis_description, 
		COUNT(*) AS num_surgeries, AVG(total_profit) AS avg_total_profit
FROM general_hospital.surgical_encounters se
LEFT OUTER JOIN general_hospital.physicians p
ON se.surgeon_id = p.id
GROUP BY GROUPING SETS(
	(p.full_name),
	(se.admission_type),
	(se.diagnosis_description),
	(p.full_name, se.admission_type),
	(p.full_name, se.diagnosis_description)
);



-- Basic Use of CUBE
-- CUBE provides a shortcut to listing grouping sets one by one.
-- CUBE generates the grouping set for a list of columns and all possible subsets.
SELECT state, county, COUNT(*) AS num_patients
FROM general_hospital.patients
GROUP BY CUBE(state, county)
ORDER BY state DESC, county;


SELECT p.full_name, se.admission_type, se.diagnosis_description, 
		COUNT(*) AS num_surgeries, AVG(total_profit) AS avg_total_profit
FROM general_hospital.surgical_encounters se
LEFT OUTER JOIN general_hospital.physicians p
ON se.surgeon_id = p.id
GROUP BY CUBE(p.full_name, se.admission_type, se.diagnosis_description);



-- Basic use of ROLLUP
-- ROLLUP is another shorthand way of generating sets.
-- ROLLUP generates grouping sets of all listed columns.
-- However, grouping sets for ROLLUP are considered ordered and hierarchical, unlike with CUBE.
SELECT h.state, h.hospital_name, d.department_name, 
		COUNT(e.patient_encounter_id) AS num_encounters
FROM general_hospital.encounters e
LEFT OUTER JOIN general_hospital.departments d ON e.department_id = d.department_id
LEFT OUTER JOIN general_hospital.hospitals h ON d.hospital_id = h.hospital_id
GROUP BY ROLLUP (h.state, h.hospital_name, d.department_name)
ORDER BY h.state DESC, h.hospital_name, d.department_name;


SELECT state, county, city, 
		COUNT(master_patient_id) AS num_patients,
		AVG(EXTRACT(YEAR FROM AGE(now(), date_of_birth)))
FROM general_hospital.patients
GROUP BY ROLLUP(state, county, city)
ORDER BY state, county, city; 



-- ++++ Challenges ++++
-- Find the average pulse and average body surface area by weight, height, and weight/height
SELECT weight, height, AVG(pulse) AS avg_pulse, AVG(body_surface_area) AS avg_bsa
FROM general_hospital.vitals
GROUP BY CUBE(weight, height)
ORDER BY height, weight;


-- Generate a report on surgical admissions by year, month, and day using ROLLUP
SELECT date_part('year', surgical_admission_date) AS year,
		date_part('month', surgical_admission_date) AS month,
		date_part('day', surgical_admission_date) AS day,
		COUNT(surgery_id) AS num_surgeries
FROM general_hospital.surgical_encounters
GROUP BY ROLLUP(1, 2, 3)
ORDER BY 1, 2, 3;


-- Generate a report on the number of patients by primary language, citizenship, primary language/citizenship,
-- and primary language/ethnicity
SELECT primary_language, is_citizen, ethnicity, COUNT(master_patient_id) AS num_patients
FROM general_hospital.patients
GROUP BY GROUPING SETS(
	(primary_language),
	(is_citizen),
	(primary_language, is_citizen),
	(primary_language, ethnicity)
);

