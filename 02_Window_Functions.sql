-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- WINDOW FUNCTIONS

-- Two uses of window functions:
	-- * Aggregating data by group within data (AVG, SUM, MIN, MAX, COUNT, STRING_AGG, ARRAY_AGG)
	-- * Performing dynamic calculations on data within groups (RANK, ROW_NUMBER, LAG, LEAD)



-- Basic use of OVER, PARTITION BY and ORDER BY
-- Window Functions always have an OVER clause.
-- The contents of the OVER clause determine how it divides and sorts data for window
-- function calculations.
-- OVER() with no aditional arguments applies window function to entire selection.
-- PARTITION BY clause determines how data is grouped. 
-- No PARTITION BY - group is the entire table.
-- Include all other columns - group isone row.
-- ORDER BY clause determines how data is sorted for calculations.

-- *** NOTE ***
-- Window functions are executed after all other filters, aggregations, etc. Window Functions
-- are not allowed in WHERE, HAVING, or GROUP BU clauses. To filter results based on Window
-- Function outputs, we can use subqueries or CTEs

SELECT surgery_id, 
		(surgical_discharge_date - surgical_admission_date) AS los,
		AVG(surgical_discharge_date - surgical_admission_date)
			OVER() AS avg_los
FROM general_hospital.surgical_encounters;


WITH surgical_los AS(
	SELECT surgery_id, 
			(surgical_discharge_date - surgical_admission_date) AS los,
			AVG(surgical_discharge_date - surgical_admission_date)
				OVER() AS avg_los
	FROM general_hospital.surgical_encounters
)
SELECT *, ROUND(los-avg_los, 2) AS over_under
FROM surgical_los;


SELECT account_id, primary_icd, total_account_balance, RANK()
		OVER(PARTITION BY primary_icd ORDER BY total_account_balance DESC)
		AS account_rank_by_icd
FROM general_hospital.accounts;



-- Basic use of WINDOW
-- WINDOW clause enables us to define a reusable window after the FROM clause.
SELECT s.surgery_id, 
		p.full_name, 
		s.total_profit,
		AVG(total_profit) OVER w AS avg_total_profit,
		s.total_cost, 
		SUM(total_cost) OVER w AS total_surgeron_cost
FROM general_hospital.surgical_encounters s
LEFT OUTER JOIN general_hospital.physicians p
ON s.surgeon_id = p.id
WINDOW w AS (PARTITION BY s.surgeon_id);


SELECT s.surgery_id,
		p.full_name,
		s.total_cost,
		RANK() OVER(PARTITION BY surgeon_id ORDER BY total_cost ASC) AS cost_rank,
		diagnosis_description,
		total_profit,
		ROW_NUMBER() OVER(PARTITION BY surgeon_id, diagnosis_description ORDER BY total_profit DESC) profit_row_number
FROM general_hospital.surgical_encounters s
LEFT OUTER JOIN general_hospital.physicians p
ON s.surgeon_id = p.id
ORDER BY s.surgeon_id, s.diagnosis_description;


SELECT patient_encounter_id, 
		master_patient_id,
		patient_admission_datetime,
		patient_discharge_datetime,
		LAG(patient_discharge_datetime) OVER w AS previous_discharge_datetime,
		LEAD(patient_admission_datetime) OVER w AS next_admission_date
FROM general_hospital.encounters
WINDOW w AS (PARTITION BY master_patient_id ORDER BY patient_admission_datetime)
ORDER BY master_patient_id, patient_admission_datetime;



-- ++++ CHALLENGES ++++
-- Find all surgeries that occurred within 30 days of a previous surgery.
WITH surgeries_lagged AS(
	SELECT surgery_id, master_patient_id, surgical_admission_date, surgical_discharge_date,
			LAG(surgical_discharge_date) 
			OVER (PARTITION BY master_patient_id ORDER BY surgical_admission_date) AS previous_discharge_date
	FROM general_hospital.surgical_encounters
)
SELECT *, (surgical_admission_date - previous_discharge_date) AS days_between_surgeries
FROM surgeries_lagged
WHERE (surgical_admission_date - previous_discharge_date) <= 30;


-- For each department, find the 3 physicians with the most admissions.
WITH provider_department AS(
	SELECT admitting_provider_id, department_id, COUNT(*) AS num_encounters
	FROM general_hospital.encounters
	GROUP BY admitting_provider_id, department_id
),
pd_ranked AS(
	SELECT *, ROW_NUMBER() OVER(PARTITION BY department_id ORDER BY num_encounters DESC) AS encounter_rank
	FROM provider_department
)
SELECT d.department_name, p.full_name AS physician_name, num_encounters, encounter_rank
FROM pd_ranked pd
LEFT OUTER JOIN general_hospital.physicians p
	ON p.id = pd.admitting_provider_id
LEFT OUTER JOIN general_hospital.departments d
	ON d.department_id = pd.department_id
WHERE encounter_rank <= 3;


-- For each surgery, find any resources that accounted for more than 50% of total surgery cost
WITH total_cost AS(
	SELECT surgery_id, resource_name, resource_cost, 
			SUM(resource_cost) OVER(PARTITION BY surgery_id) AS total_surgery_cost
	FROM general_hospital.surgical_costs
)
SELECT *, (resource_cost/total_surgery_cost)*100 AS pct_total_cost
FROM total_cost
WHERE (resource_cost/total_surgery_cost)*100 > 50;
