-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- SCHEMA STRUCTURES AND TABLE RELATIONSHIPS
-- Postgres has a "meta" schema exposing the database structure: information_schema.
	

-- Basic use of information_schema
	-- SELECT * FROM information_schema.{{TABLE_NAME}} WHERE ...
-- information_schema has dozens of tables. A few useful ones:
	-- * tables => Data on tables (ex: name, schema, etc.)
	-- * columns => Data on columns (ex: position, data type, maximum length, etc.)
	-- * table_constraints => Data on constraints (ex: primary keys, foreign keys, etc.)
SELECT *
FROM information_schema.tables;


SELECT *
FROM information_schema.tables
WHERE table_schema = 'general_hospital'
ORDER BY table_name;


SELECT *
FROM information_schema.columns;


SELECT * 
FROM information_schema.columns
WHERE table_schema = 'general_hospital'
ORDER BY table_name, ordinal_position;


SELECT *
FROM information_schema.columns
WHERE table_schema = 'general_hospital' AND column_name LIKE '%id'
ORDER BY table_name;


SELECT table_name, data_type, COUNT(*) AS num_columns
FROM information_schema.columns
WHERE table_schema = 'general_hospital'
GROUP BY table_name, data_type
ORDER BY table_name, 3 DESC;



-- Basic use of COMMENT
-- information_schema is a good source for basic metadata about the database schema.
-- However, it can't answer "business" questions about schema structure. Like:
	-- What does this column mean?
	-- What is this table used for?
-- Comments are used for documenting the database. 
-- You can ad comments to any database object using COMMENT command, whether they are: tables
-- columns, schemas, databases, indexes, etc. 
-- To remove a comment, simply set to NULL.
-- The "how" and "how much" of documentation is an ongoing debate in software. 
-- Think of COMMENT as a tool, not a solution.
-- Things that might not need comments: 
	-- * id/primary key fields
	-- * Aufit fields, ex: created_datetime
-- Things that might need comments:
	-- * Fields with abbreviations/acronyms
	-- * Calculated fields/metrics
COMMENT ON TABLE general_hospital.vitals IS
'Patient vital sign data taken at the beginning of the encounter';
 
 
SELECT obj_description('general_hospital.vitals'::regclass);


COMMENT ON COLUMN general_hospital.accounts.primary_icd IS 
'Primary International Classification of Diseases (ICD) code for the account';


SELECT *
FROM information_schema.columns
WHERE table_schema = 'general_hospital'
AND table_name='accounts';


SELECT col_description('general_hospital.accounts'::regclass, 1);



-- Basic use of Adding and Dropping Constraints
-- Databases are only as useful as the data in them - "garbage in, garbae out"
-- One way to keep the "garbage" out is with constraints.
-- Constraints restrict the data that can be added to your database by specifying crittria it must meet.
-- Basic types of constraints
	-- * UNIQUE - No duplicate values allowed in column.
	-- * NOT NULL - No NULL values allowed in column.
	-- * CHECK - Allows definition of expressions to check whether the data is acceptable or not. 
ALTER TABLE general_hospital.surgical_encounters
ADD CONSTRAINT check_positive_cost
CHECK(total_cost > 0);


SELECT * 
FROM information_schema.table_constraints
WHERE table_schema = 'general_hospital' AND table_name='surgical_encounters';


ALTER TABLE general_hospital.surgical_encounters
DROP CONSTRAINT check_psoitive_cost;



-- Basic use of Adding Foreign Keys
-- Foreign Keys in SQL specify that the values of one column in one table ("child") must be contained in  
-- the column of another table ("parent"). Although FKs can be created when a table is created, they can 
-- be added later as well. 
ALTER TABLE general_hospital.encounters
ADD CONSTRAINT encounters_attending_id_fk
FOREIGN KEY (attending_provider_id)
REFERENCES general_hospital.physicians (id);


SELECT *
FROM information_schema.table_constraints
WHERE table_schema = 'general_hospital' 
		AND table_name='encounters'
		AND constraint_type='FOREIGN KEY'
ORDER BY constraint_name;


ALTER TABLE general_hospital.encounters
DROP CONSTRAINT encounters_attending_id_fk;



-- ++++ CHALLENGES ++++
-- Verify the constraints were added and then drop them.
-- Add a comment for admitting ICD and verify it was added. (ICD = International Classification of Diseases).
COMMENT ON COLUMN general_hospital.accounts.admit_icd IS
'Admiting diagnosis code from the International Classification of Diseases (ICD)';

SELECT col_description('general_hospital.accounts'::regclass, 1);


-- ADD NOT NULL constraint on surgical_admission_date field.
ALTER TABLE general_hospital.surgical_encounters
ALTER COLUMN surgical_admission_date
SET NOT NULL;

ALTER TABLE general_hospital.surgical_encounters
ALTER COLUMN surgical_admission_date
DROP NOT NULL;


-- Add constraint to ensure that patient_discharge_datetime is after patient_admission_datetime OR empty.
ALTER TABLE general_hospital.encounters
ADD CONSTRAINT check_discharge_after_admission
CHECK (
	(patient_admission_datetime < patient_discharge_datetime) OR
	(patient_discharge_datetime IS NULL)
);

ALTER TABLE general_hospital.encounters
DROP CONSTRAINT check_discharge_after_admission;
