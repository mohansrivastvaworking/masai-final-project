CREATE DATABASE noshowguard; 
USE noshowguard;

CREATE TABLE clinics (
  clinic_id VARCHAR(5) PRIMARY KEY, clinic_name VARCHAR(40) NOT NULL, city VARCHAR(20) NOT NULL,
  tier VARCHAR(10), latitude DECIMAL(8,4), longitude DECIMAL(8,4), temp_c DECIMAL(5,1));
CREATE TABLE appointments (
  appointment_id VARCHAR(8) PRIMARY KEY, patient_id VARCHAR(8) NOT NULL, clinic_id VARCHAR(5) NOT NULL,
  booked_on DATE, appt_date DATE, age INT, gender VARCHAR(1), distance_km DECIMAL(5,1), fee_inr INT,
  booking_channel VARCHAR(10), visit_type VARCHAR(12), reminder_sent VARCHAR(3), prior_no_shows INT,
  status VARCHAR(10), lead_days INT, no_show INT,
  FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id));


select * from appointments;
select * from clinics;

/*
Task 2.1 — Build and load the database (4 marks)
In MySQL Workbench run CREATE DATABASE noshowguard; 
USE noshowguard; (skip in SQLiteOnline). Create the 
two tables below, then run your load_data.sql:
*/

SELECT COUNT(*) AS total_appointments, SUM(no_show) AS total_no_shows 
FROM appointments;

/*
Task 2.2 — No-show rate by clinic (5 marks)
JOIN appointments to clinics; for each clinic show clinic_name, 
city, appointments, no_shows and no_show_pct, where no_show_pct 
is ROUND(100.0 * SUM(no_show) / COUNT(*), 1). Keep only clinics 
with at least 95 appointments (HAVING) and sort by no_show_pct descending. 
Then remove the HAVING line, look at all 8 clinics, and note which 
clinic has the highest rate and how many appointments it has. In Python, 
reproduce the clinic counts and no-show counts with groupby and 
confirm they match the SQL.
*/
SELECT 
    c.clinic_name, 
    c.city, 
    COUNT(a.appointment_id) AS appointments, 
    SUM(a.no_show) AS no_shows, 
    ROUND(100.0 * SUM(a.no_show) / COUNT(a.appointment_id), 1) AS no_show_pct
FROM appointments a
JOIN clinics c ON a.clinic_id = c.clinic_id
GROUP BY c.clinic_name, c.city
HAVING appointments >= 95
ORDER BY no_show_pct DESC;
/*
Use this snippet to prove the SQL aggregates exactly 
match your pandas logic from Part 1.

import pandas as pd

# Load the clean tables
appts = pd.read_csv('appointments_clean.csv')
clinics = pd.read_csv('clinics_enriched.csv')

# Merge and group
merged = appts.merge(clinics, on='clinic_id')
clinic_summary = merged.groupby(['clinic_name', 'city']).agg(
    appointments=('appointment_id', 'count'),
    no_shows=('no_show', 'sum')
).reset_index()

# Calculate percentage and filter/sort
clinic_summary['no_show_pct'] = (100.0 * clinic_summary['no_shows'] / clinic_summary['appointments']).round(1)
print(clinic_summary[clinic_summary['appointments'] >= 95].sort_values('no_show_pct', ascending=False))
*/



/*
Task 2.3 — Does booking far ahead matter? (4 marks)
Using CASE WHEN, put lead_days into four bands (the labels must 
come out of the CASE WHEN, not be typed into the data) — 1-7, 8-14, 
15-30, 31+ (upper limits inclusive: 7, 14 and 30 belong to the lower band) — 
and show appointments, no-shows and no_show_pct per band in band order 
(hint: ORDER BY MIN(lead_days) sorts the bands by how short their lead 
times are, whereas sorting by the band text would put 15-30 before 8-14).
*/
SELECT 
    CASE 
        WHEN lead_days <= 7 THEN '1-7'
        WHEN lead_days <= 14 THEN '8-14'
        WHEN lead_days <= 30 THEN '15-30'
        ELSE '31+' 
    END AS lead_days_band,
    COUNT(*) AS appointments,
    SUM(no_show) AS no_shows,
    ROUND(100.0 * SUM(no_show) / COUNT(*), 1) AS no_show_pct
FROM appointments
GROUP BY 
    CASE 
        WHEN lead_days <= 7 THEN '1-7'
        WHEN lead_days <= 14 THEN '8-14'
        WHEN lead_days <= 30 THEN '15-30'
        ELSE '31+' 
    END
ORDER BY MIN(lead_days);


/*
Task 2.4 — Month-by-month trend (4 marks)
With a CTE named monthly (month = SUBSTR(appt_date,1,7)), compute 
appointments and no_show_pct per month, then use LAG() with 
OVER (ORDER BY month) to show the change in percentage points — 
this month's rate minus the previous month's rate (blank for January).
*/
WITH monthly AS (
    SELECT 
        SUBSTR(appt_date, 1, 7) AS month,
        COUNT(*) AS appointments,
        ROUND(100.0 * SUM(no_show) / COUNT(*), 1) AS no_show_pct
    FROM appointments
    GROUP BY SUBSTR(appt_date, 1, 7)
)
SELECT 
    month,
    appointments,
    no_show_pct,
    ROUND(no_show_pct - LAG(no_show_pct) OVER (ORDER BY month), 1) AS change_in_pct
FROM monthly
ORDER BY month;


/*
Task 2.5 — Rank clinics inside each city (5 marks)
With a CTE clinic_rates (clinic, city, no_show_pct), 
select every clinic with RANK() OVER (PARTITION BY city 
ORDER BY no_show_pct DESC) as rank_in_city, plus a column 
vs_overall that says 'above', 'below' or 'equal' 
(no clinic is exactly equal here, but the query should handle it) 
by comparing the clinic's rate with the overall no-show rate 
computed in a scalar subquery. Order by city, then rank.
*/
WITH clinic_rates AS (
    SELECT 
        c.clinic_name AS clinic,
        c.city,
        ROUND(100.0 * SUM(a.no_show) / COUNT(a.appointment_id), 1) AS no_show_pct
    FROM appointments a
    JOIN clinics c ON a.clinic_id = c.clinic_id
    GROUP BY c.clinic_name, c.city
)
SELECT 
    clinic,
    city,
    no_show_pct,
    RANK() OVER (PARTITION BY city ORDER BY no_show_pct DESC) AS rank_in_city,
    CASE 
        WHEN no_show_pct > (SELECT 100.0 * SUM(no_show) / COUNT(*) FROM appointments) THEN 'above'
        WHEN no_show_pct < (SELECT 100.0 * SUM(no_show) / COUNT(*) FROM appointments) THEN 'below'
        ELSE 'equal'
    END AS vs_overall
FROM clinic_rates
ORDER BY city, rank_in_city;