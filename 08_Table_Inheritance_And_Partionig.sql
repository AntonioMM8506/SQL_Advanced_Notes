-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TABLE INHERITANCE AND PARTIONING


-- As a database table sizes grow, sometimes we face performance issues. One way of solving this is with Partitions.
-- Partitions allow us to divide a base table into smaller tables using:
	-- * Ranges
	-- * Lists
	-- * Hash


-- Basic use of Range Partitioning
-- In range partitioning, partitions are divided by non-overlapping intervals.
-- Indexes created on a partitioned table will cascade to all partitions.
-- CHECK and NOT NULL constraints ae inherited by partitions.
-- Unique/primary key constraints must include all partitioning columns.
-- Foreign Keys work as usual on partitioned tables. 
CREATE TABLE general_hospital.surgical_encounters_partitioned (
	surgery_id INTEGER NOT NULL,
	master_patient_id INTEGER NOT NULL,
	surgical_admission_date DATE NOT NULL,
	surgical_discharge_discharge DATE
) PARTITION BY RANGE(surgical_admission_date);


SELECT DISTINCT EXTRACT(YEAR FROM surgical_admission_date) FROM general_hospital.surgical_encounters;


CREATE TABLE general_hospital.surgical_encounters_y2016 
	PARTITION OF general_hospital.surgical_encounters_partitioned
	FOR VALUES FROM('2016-01-01') TO ('2017-01-01');


CREATE TABLE general_hospital.surgical_encounters_y2017 
	PARTITION OF general_hospital.surgical_encounters_partitioned
	FOR VALUES FROM('2017-01-01') TO ('2018-01-01');
	
	
CREATE TABLE general_hospital.surgical_encounters_default
	PARTITION OF general_hospital.surgical_encounters_partitioned
	DEFAULT;
	
	
INSERT INTO general_hospital.surgical_encounters_partitioned
	SELECT surgery_id, master_patient_id, surgical_admission_date, surgical_discharge_date
	FROM general_hospital.surgical_encounters;
	

CREATE INDEX ON general_hospital.surgical_encounters_partitioned (surgical_admission_date);


SELECT EXTRACT(YEAR FROM surgical_admission_date), COUNT(*)
	FROM general_hospital.surgical_encounters
	GROUP BY 1;
	
	
SELECT COUNT(*), MIN(surgical_admission_date), MAX(surgical_admission_date)
	FROM general_hospital.surgical_encounters_y2016;
	
	
SELECT COUNT(*), MIN(surgical_admission_date), MAX(surgical_admission_date)
	FROM general_hospital.surgical_encounters_y2017;



-- Basic use of List Patitioning
-- Partitioning explicity by lists is another way to partition tables. Useful when there are a small,
-- known number of values for the partition field in the base table.
CREATE TABLE general_hospital.departments_partitioned(
	hospital_id INTEGER NOT NULL,
	department_id INTEGER NOT NULL,
	department_name TEXT,
	specialty_description TEXT
) PARTITION BY LIST (hospital_id);
	
	
SELECT DISTINCT hospital_id FROM general_hospital.departments;


CREATE TABLE general_hospital.departments_h111000 
	PARTITION OF general_hospital.departments_partitioned
	FOR VALUES IN (111000);
	

CREATE TABLE general_hospital.departments_h112000 
	PARTITION OF general_hospital.departments_partitioned
	FOR VALUES IN (112000);
	
	
CREATE TABLE general_hospital.departments_default
	PARTITION OF general_hospital.departments_partitioned
	DEFAULT;
	
	
INSERT INTO general_hospital.departments_partitioned
	SELECT hospital_id, department_id, department_name, specialty_description
	FROM general_hospital.departments;


SELECT hospital_id, COUNT(*)
	FROM general_hospital.departments_h111000
	GROUP BY 1;



-- Basic use of Hash Partitioning
-- Partitioning by hashes is useful when there is no obvious/natural way to divide your data.
-- Based on modular arithmetic.
	-- 5 % 5 = 0
	-- 13 % 5 = 3
	-- 1 mod 5 = 1
CREATE TABLE general_hospital.orders_procedures_partitioned(
	order_procedure_id INT NOT NULL,
	patient_encounter_id INT NOT NULL,
	ordering_provider_id INT REFERENCES general_hospital.physicians(id),
	order_cd TEXT,
	order_procedure_description TEXT
) PARTITION BY HASH(order_procedure_id, patient_encounter_id);


CREATE TABLE general_hospital.orders_procedures_hash0
	PARTITION OF general_hospital.orders_procedures_partitioned
	FOR VALUES WITH (modulus 3, remainder 0);


CREATE TABLE general_hospital.orders_procedures_hash1
	PARTITION OF general_hospital.orders_procedures_partitioned
	FOR VALUES WITH (modulus 3, remainder 1);
	
	
CREATE TABLE general_hospital.orders_procedures_hash2
	PARTITION OF general_hospital.orders_procedures_partitioned
	FOR VALUES WITH (modulus 3, remainder 2);


INSERT INTO general_hospital.orders_procedures_partitioned 
	SELECT 	order_procedure_id,
	patient_encounter_id,
	ordering_provider_id,
	order_cd,
	order_procedure_description
	FROM general_hospital.orders_procedures;
	

SELECT 'hash0', COUNT(*) FROM general_hospital.orders_procedures_hash0
UNION
SELECT 'hash1', COUNT(*) FROM general_hospital.orders_procedures_hash1
UNION
SELECT 'hash2', COUNT(*) FROM general_hospital.orders_procedures_hash2;



-- Basic use of Table Inheritance
-- Object-oriented programming (OOP) is a popilar paradigm for writing software.
-- An important feature/concept in OOP is inheritance.
-- SQL provides table inheritance for constructing parent-child table relationships.
-- Similar (but not the same) as OOP inheritance.
-- Child tables can inherit from more than one parent table.
-- CHCK and NOT NULL constraints are inherited.

-- UPDATE, DELETE and INSERT operations work differently depending on whether they're
-- performed on parent or child tables.
-- For Parent
	-- INSERT
		-- * Data exists in parent table.
		-- * No effect on child table.
	-- UPDATE
		-- * Data updated in table where it exists.
	-- DELETE
		-- * Data deleted in table where it exists.
-- For Child
	-- INSERT
		-- * Data exists in child table.
		-- * Inherited column values visible in parent table.
	-- UPDATE
		-- * Data updated in child table.
		-- * Changes visible in parent table.
	-- DELETE
		-- * Data deleted in child table.
		-- * Changes visible in parent table.

-- Limitations of table inheritance:
	-- * Primary key, foreign keys, and indexes are not inherited in child tables.
	-- * Data inserted in child table is not routed into parent table.
-- Benefits of table inheritance:
	-- * Performance.
	-- * Database management.
	
CREATE TABLE general_hospital.visit(
	id serial NOT NULL PRIMARY KEY,
	start_datetime TIMESTAMP,
	end_datetime TIMESTAMP
);


CREATE TABLE general_hospital.emergency_visit(
	emergency_department_id INT NOT NULL,
	triage_level INT,
	triage_datetime TIMESTAMP
) INHERITS (general_hospital.visit);


-- a Combination of parent and child.
-- id, start_datetime, end_datetime, emergency_department_id, triage_level, triage_datetime
INSERT INTO general_hospital.emergency_visit VALUES(
	default, '2022-01-01 12:00:00', null, 12, 3, null
);


SELECT * FROM general_hospital.emergency_visit;


SELECT * FROM general_hospital.visit;


INSERT INTO general_hospital.visit VALUES (
	default, '2022-03-01 11:00:00', '2022-03-03 13:00:00'
);


INSERT INTO general_hospital.emergency_visit VALUES (
	2, '2022-03-01 11:00:00', '2022-03-03 13:00:00', 1, 1, null
);


SELECT * FROM general_hospital.emergency_visit;


SELECT * FROM general_hospital.visit;



-- ++++ CHALLENGES ++++
-- Create and populate a new encounters table partitioned by hospital_id.
CREATE TABLE general_hospital.encounters_partitioned(
	hospital_id INT NOT NULL,
	patient_encounter_id INT NOT NULL,
	master_patient_id INT,
	admitting_provider_id INT REFERENCES general_hospital.physicians(id),
	department_id INT REFERENCES general_hospital.departments(department_id),
	patient_admission_datetime TIMESTAMP,
	patient_discharge_datetime TIMESTAMP,
	CONSTRAINT encounters_partitioned_pk PRIMARY KEY (hospital_id, patient_encounter_id)
) PARTITION BY list (hospital_id);


SELECT DISTINCT d.hospital_id
FROM general_hospital.encounters e
LEFT OUTER JOIN general_hospital.departments d
	ON e.department_id = d.department_id
ORDER BY 1;


CREATE TABLE general_hospital.encounters_h111000
	PARTITION OF general_hospital.encounters_partitioned
	FOR VALUES IN (111000);
	
CREATE TABLE general_hospital.encounters_h112000
	PARTITION OF general_hospital.encounters_partitioned
	FOR VALUES IN (112000);


CREATE TABLE general_hospital.encounters_h114000
	PARTITION OF general_hospital.encounters_partitioned
	FOR VALUES IN (114000);


CREATE TABLE general_hospital.encounters_h115000
	PARTITION OF general_hospital.encounters_partitioned
	FOR VALUES IN (115000);


CREATE TABLE general_hospital.encounters_h9900006
	PARTITION OF general_hospital.encounters_partitioned
	FOR VALUES IN (9900006);


CREATE TABLE general_hospital.encounters_default
	PARTITION OF general_hospital.encounters_partitioned
	DEFAULT;


INSERT INTO general_hospital.encounters_partitioned
SELECT
	d.hospital_id,
	e.patient_encounter_id,
	e.master_patient_id,
	e.admitting_provider_id,
	e.department_id,
	e.patient_admission_datetime,
	e.patient_discharge_datetime
FROM general_hospital.encounters e
LEFT OUTER JOIN general_hospital.departments d
	ON e.department_id = d.department_id;
	

SELECT * FROM general_hospital.encounters_h112000;


CREATE INDEX ON general_hospital.encounters_partitioned (patient_encounter_id);


-- Create a new vitals table partitioned by a datetime field (hint: try the 
-- patient_admission_datetime field in encounters)
CREATE TABLE general_hospital.vitals_partitioned(
	patient_encounter_id INT NOT NULL REFERENCES general_hospital.encounters (patient_encounter_id),
	collection_datetime TIMESTAMP NOT NULL,
	bp_diastolic INT,
	bd_systolic INT,
	bmi NUMERIC,
	temperature NUMERIC,
	weight INT
) PARTITION BY RANGE(collection_datetime);


SELECT DISTINCT EXTRACT(YEAR FROM patient_admission_datetime) FROM general_hospital.encounters;


CREATE TABLE general_hospital.vitals_y2015
	PARTITION OF general_hospital.vitals_partitioned
	FOR VALUES FROM ('2015-01-01') TO ('2016-01-01');


CREATE TABLE general_hospital.vitals_y2016
	PARTITION OF general_hospital.vitals_partitioned
	FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');
	
	
CREATE TABLE general_hospital.vitals_y2017
	PARTITION OF general_hospital.vitals_partitioned
	FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');


CREATE TABLE general_hospital.vitals_default
	PARTITION OF general_hospital.vitals_partitioned
	DEFAULT;
	
	
INSERT INTO general_hospital.vitals_partitioned
SELECT
	e.patient_encounter_id,
	e.patient_admission_datetime AS collection_datetime,
	v.bp_diastolic,
	v.bp_systolic,
	v.bmi,
	v.temperature,
	v.weight
FROM general_hospital.vitals v
LEFT OUTER JOIN general_hospital.encounters e
	ON v.patient_encounter_id = e.patient_encounter_id;
	

SELECT * FROM general_hospital.vitals_y2016;


SELECT DISTINCT EXTRACT(YEAR FROM collection_datetime) FROM general_hospital.vitals_y2017;
