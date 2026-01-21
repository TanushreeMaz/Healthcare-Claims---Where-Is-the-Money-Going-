## Notice
This repository is intended for viewing and evaluation purpose only.
Unauthorized copying, reuse, or redistribution of the content is not permitted.

	
use health_care; 

SELECT * FROM claims;
SELECT * FROM members;

SELECT DISTINCT claim_date
FROM claims;

# Duplicate the Table
CREATE TABLE claims_staging
LIKE claims;

SELECT * FROM claims_staging;

# Insert Data like claims
INSERT claims_staging
SELECT * FROM claims;

# Check Duplicates 
WITH dup_claims AS (
	SELECT *,
    ROW_NUMBER() OVER(PARTITION BY 
    claim_id, member_id, provider_id, claim_date, claim_type, cpt_code, icd_code, billed_amount, paid_amount)
    AS Row_num
    FROM claims_staging
)
SELECT * 
FROM dup_claims
WHERE Row_num > 1;

SELECT DISTINCT claim_date
FROM claims;

## Created Duplicate Tables to avoid Deletion in future

# Check Duplicates 
WITH dup_members AS (
	SELECT *,
    ROW_NUMBER() OVER(PARTITION BY 
    member_id, member_age, member_gender, plan_type, enrollment_start_date, enrollment_end_date)
    AS Row_num
    FROM members_staging
)
SELECT * 
FROM dup_members
WHERE Row_num > 1;

SELECT 
	enrollment_start_date  
FROM members_staging
WHERE STR_TO_DATE(enrollment_start_date, '%m/%d/%Y') IS NULL
	AND enrollment_start_date IS NOT NULL;

## Formatted End Date and cleaned data

## Created Final Analysis Table and Improted to Tableau

SELECT * FROM members_clean;
SELECT * FROM claims_clean;

# Which claim types are the most expensive?
SELECT
	claim_type,
	SUM(billed_amount) AS Total_billed_amount,
	SUM(paid_amount) AS Total_paid_amount,
	COUNT(claim_id) AS Number_of_claims,
DENSE_RANK() OVER(ORDER BY SUM(paid_amount) DESC) AS paid_rank
FROM claims_clean
GROUP BY claim_type
ORDER BY paid_rank DESC;


# Which CPT and ICD codes drive the highest spending?
SELECT
	cpt_code,
	SUM(paid_amount) AS Total_paid_amount,
	COUNT(claim_id) AS Claim_count,
    AVG(paid_amount) AS Avg_paid
FROM claims_clean
GROUP BY cpt_code
ORDER BY Total_paid_amount 
LIMIT 10;

SELECT
	icd_code,
	SUM(paid_amount) AS Total_paid_amount,
	COUNT(claim_id) AS Claim_count,
    AVG(paid_amount) AS Avg_paid
FROM claims_clean
GROUP BY icd_code
ORDER BY Total_paid_amount 
LIMIT 10;


SELECT
	cpt_code,
	SUM(paid_amount) / COUNT(claim_id) AS Avg_paid_per_claim
FROM claims_clean
GROUP BY cpt_code
ORDER BY Avg_paid_per_claim 
LIMIT 10;

SELECT
	icd_code,
	SUM(paid_amount) AS Total_paid_amount,
	COUNT(claim_id) AS Claim_count,
    AVG(paid_amount) AS Avg_paid
FROM claims_clean
GROUP BY icd_code
ORDER BY Total_paid_amount DESC;

# Which members account for the largest share of total costs?
CREATE TEMPORARY TABLE top_members AS
SELECT
    member_id
FROM claims_clean
GROUP BY member_id
ORDER BY SUM(paid_amount) DESC
LIMIT 10;

SELECT
    c.member_id,
    c.claim_type,
    SUM(c.paid_amount) AS paid_amount_by_claim_type
FROM claims_clean c
JOIN top_members t
    ON c.member_id = t.member_id
GROUP BY c.member_id, c.claim_type
ORDER BY c.member_id, paid_amount_by_claim_type DESC;

# How do billed amounts compare to paid amounts?
SELECT
    claim_type,
    provider_id,
    cpt_code,
    SUM(paid_amount) / SUM(billed_amount) AS paid_ratio
FROM claims_clean
GROUP BY claim_type, provider_id, cpt_code
HAVING SUM(billed_amount) > 0
ORDER BY paid_ratio DESC;

# Look for claim types, insurer pays significantly less or significantly more than the billed amount.
SELECT 
	claim_type,
    SUM(paid_amount) / SUM(billed_amount) AS Avg_Paid_Ratio,
    CASE
		WHEN SUM(paid_amount) / SUM(billed_amount) < 0.8 THEN 'Underpaid'
        WHEN SUM(paid_amount) / SUM(billed_amount) > 1.0 THEN 'Paid'
		ELSE 'Within Expected Range'
	END AS Payment_flag
FROM claims_clean
GROUP BY claim_type
HAVING SUM(billed_amount) > 0
ORDER BY Avg_Paid_Ratio; 



## Uploaded the Clean Tables to Tableau








