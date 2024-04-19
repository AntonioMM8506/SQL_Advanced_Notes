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
