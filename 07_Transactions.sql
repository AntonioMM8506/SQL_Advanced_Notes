-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TRASACTIONS


-- Transactions help to protect database integrity.
-- Transactions are logical units of work in a database.
-- One transaction can contain multuple SQL statements - any combination of SELECT, INSERT, CREATE and/or UPDATE.
-- Transactions are usually handled "behind the scenes".
-- Transactions are called ACID compliant:
    -- * Atomicity: transactions are "all or nothing".
    -- * Consistency: succesful transactions change DB state.
    -- * Isolation: Transactions are independent from each other.
    -- * Durability: succesful transactions persist after system failure. 


-- Basic use of UPDATE and SET
-- Updating data in a table/row in Postgres is done with the UPDATE command.
-- The specific data to update and how they will be updated is stated in the SET command.
-- You should (almost) always use a WHERE clause eith and UPDATE statement - 
-- otherwise, you will update the entire table.
SELECT * FROM general_hospital.vitals;
UPDATE general_hospital.vitals SET bp_diastolic = 100 WHERE patient_encounter_id = 1854663;
SELECT * FROM general_hospital.vitals WHERE patient_encounter_id=1854663;


SELECT * FROM general_hospital.accounts;
UPDATE general_hospital.accounts SET total_account_balance = 0 WHERE account_id = 11417340;
SELECT * FROM general_hospital.accounts WHERE account_id = 11417340;


-- *** NOTE ***
-- Be sure to run each command at the time when creating transactions. So, first run the "BEGIN"
-- Then run the query, then run the END, ROLLBACK or commit. Do not create a whole block for the
-- transaction hoping it will run everything in order.

-- Basic use of Beginning and Ending Transactions
-- We can start a transaction with BEGIN.
-- We can end a transaction with COMMIT or END.
-- We can interrupt or cancel a transaction with ROLLBACK.
BEGIN transaction;
UPDATE general_hospital.physicians 
	SET first_name = 'Bill',
	full_name = CONCAT(last_name, ', Bill')
	WHERE id = 1;
END transaction;

SELECT * FROM general_hospital.physicians WHERE id=1;

BEGIN;
SELECT NOW();
UPDATE general_hospital.physicians 
	SET first_name = 'Gage',
	full_name = CONCAT(last_name, ', Gage')
	WHERE id = 1;
ROLLBACK; -- DOES NOT commit the changes of this transaction because of the Rollback.

SELECT * FROM general_hospital.physicians WHERE id=1;



-- Basic use of SAVEPOINT
-- Within Transactions, we may want to save the state of a transaction at various points.
-- Aditionally, we may want to undo certain operations without aborting the entire transaction.
-- Savepoints allow us to do bot of these.
BEGIN;
UPDATE general_hospital.vitals 
	SET bp_diastolic = 120
	WHERE patient_encounter_id = 2570046;
SAVEPOINT vitals_updated;

UPDATE general_hospital.accounts
	SET total_account_balance = 1000
	WHERE account_id = 11417340;
ROLLBACK TO vitals_updated;	
COMMIT;


SELECT * FROM general_hospital.vitals WHERE patient_encounter_id = 2570046;
SELECT * FROM general_hospital.accounts WHERE account_id = 11417340;

-- *** NOTE ***
-- Everything that is queried after the BEGIN will be included into the transaction
-- until whether a COMMIT or an END statement is found. 
BEGIN;
UPDATE general_hospital.vitals
	SET bp_diastolic = 52
	WHERE patient_encounter_id = 1854663;
SAVEPOINT vitals_updated;

UPDATE general_hospital.accounts
	SET total_account_balance = 1000
	WHERE account_id = 11417340;
RELEASE SAVEPOINT vitals_updated;	
COMMIT;


SELECT * FROM general_hospital.vitals WHERE patient_encounter_id = 1854663;
SELECT * FROM general_hospital.accounts WHERE account_id = 11417340;



-- Basic use of Database Locks
-- Database Locks prevent users from modifying data that is being modified by a 
-- different transaction. Once a transaction is complete, the lock will be lifted.
-- We can use LOCK TABLE to lock tables manually.
BEGIN; 
LOCK TABLE general_hospital.physicians;
SELECT * FROM general_hospital.physicians;
ROLLBACK;



-- ++++ CHALLENGES ++++
-- Revert our update to the physicians tabñe inside a transaction using LOCK TABLE. 
	-- Krollman, Bill => Krollman, Gage
BEGIN transaction;
LOCK TABLE general_hospital.physicians;
UPDATE general_hospital.physicians 
	SET first_name = 'Gage',
	full_name = CONCAT(last_name, ', Gage')
	WHERE id=1;
COMMIT;

SELECT * FROM general_hospital.physicians WHERE id=1;


-- Try dropping a table inside a transaction with ROLLBACK and confirm the table was not dropped.
BEGIN;
DROP TABLE general_hospital.practices;
ROLLBACK;

SELECT * FROM general_hospital.practices;


-- Do the following inside a transaction:
	-- Update the account balance for account_id 11417340 to be $15,077.90.
	-- Create a Savepoint.
	-- Drop any table.
	-- Rollback to the savepoint.
	-- Commit the transaction.
	-- Verify the changes mad/not made. 
BEGIN transaction;
UPDATE general_hospital.accounts
	SET total_account_balance = 15077.90
	WHERE account_id = 11417340;
SAVEPOINT account_updated;
DROP TABLE general_hospital.vitals;
ROLLBACK TO account_updated;
COMMIT;
END;

SELECT * FROM general_hospital.accounts WHERE account_id=11417340;
SELECT * FROM general_hospital.vitals;

