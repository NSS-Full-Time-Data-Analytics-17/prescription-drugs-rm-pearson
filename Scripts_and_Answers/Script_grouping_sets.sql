-- 1. Write a query which returns the total number of claims for these two groups.

SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber LEFT JOIN prescription USING(npi)
WHERE specialty_description = 'Interventional Pain Management'
	OR specialty_description = 'Pain Management'
GROUP BY specialty_description
;

-- 2. Now, let's say that we want our output to also include the total number of claims between these two groups. 
	-- Combine two queries with the UNION keyword to accomplish this.
SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber LEFT JOIN prescription USING(npi)
GROUP BY specialty_description
	HAVING specialty_description = 'Interventional Pain Management'
		OR specialty_description = 'Pain Management'

UNION

SELECT
	NULL AS specialty_description,
	SUM(total_claim_count) AS total_claims
FROM prescriber LEFT JOIN prescription USING(npi)
WHERE specialty_description = 'Interventional Pain Management'
	OR specialty_description = 'Pain Management'

;

-- 3. Now, instead of using UNION, make use of GROUPING SETS to achieve the same output.
SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber LEFT JOIN prescription USING(npi)
WHERE specialty_description = 'Interventional Pain Management'
	OR specialty_description = 'Pain Management'
GROUP BY GROUPING SETS((specialty_description),())
;


/* 4. 4. In addition to comparing the total number of prescriptions by specialty, let's also bring in information about the 
	number of opioid vs. non-opioid claims by these two specialties. Modify your query (still making use of GROUPING SETS so 
	that your output also shows the total number of opioid claims vs. non-opioid claims by these two specialites */

SELECT specialty_description, opioid_drug_flag, SUM(total_claim_count) AS total_claims
FROM prescriber LEFT JOIN prescription USING(npi)
				LEFT JOIN drug USING(drug_name)
WHERE specialty_description = 'Interventional Pain Management'
	OR specialty_description = 'Pain Management'
GROUP BY GROUPING SETS((specialty_description),(opioid_drug_flag),())
;

--5. Modify your query by replacing the GROUPING SETS with ROLLUP(opioid_drug_flag, specialty_description). 
	-- How is the result different from the output from the previous query?
SELECT specialty_description, opioid_drug_flag, SUM(total_claim_count) AS total_claims
FROM prescriber LEFT JOIN prescription USING(npi)
				LEFT JOIN drug USING(drug_name)
WHERE specialty_description = 'Interventional Pain Management'
	OR specialty_description = 'Pain Management'
GROUP BY ROLLUP(specialty_description, opioid_drug_flag)
; --This also shows the cross-sections of total claims for the two specialties when opioid_drug_flag is Y, or N, as 
	--well as the total by specialty and the overall total, but does not include the total by drug_flag without specialty grouping.
	
-- 6. Switch the order of the variables inside the ROLLUP. That is, use ROLLUP(specialty_description, opioid_drug_flag). 
	-- How does this change the result?
SELECT specialty_description, opioid_drug_flag, SUM(total_claim_count) AS total_claims
FROM prescriber LEFT JOIN prescription USING(npi)
				LEFT JOIN drug USING(drug_name)
WHERE specialty_description = 'Interventional Pain Management'
	OR specialty_description = 'Pain Management'
GROUP BY ROLLUP(opioid_drug_flag, specialty_description)
; -- It switches which one is treated as the "main" category so that the results show the cross-sections for opioid and non-opioid claims by specialty.

--7. Finally, change your query to use the CUBE function instead of ROLLUP. How does this impact the output?
SELECT specialty_description, opioid_drug_flag, SUM(total_claim_count) AS total_claims
FROM prescriber LEFT JOIN prescription USING(npi)
				LEFT JOIN drug USING(drug_name)
WHERE specialty_description = 'Interventional Pain Management'
	OR specialty_description = 'Pain Management'
GROUP BY CUBE(opioid_drug_flag, specialty_description)
; -- this gives the full matrix of results between the specialties and the drug flag, as well as totals for each category without considering 
	--the other, and the full total.

/* 8. In this question, your goal is to create a pivot table showing [sic - 'total prescriptions'] for each of the 4 largest cities in Tennessee 
	(Nashville, Memphis, Knoxville, and Chattanooga), the total claim count for each of six common types of opioids: 
	Hydrocodone, Oxycodone, Oxymorphone, Morphine, Codeine, and Fentanyl. */

-- NOTE: the question doesn't ask us to filter for opioid_drug_flag = 'Y', so I didn't.  

SELECT * FROM CROSSTAB('
SELECT nppes_provider_city AS city, 
	CASE WHEN drug_name ILIKE ''%Hydrocodone%'' THEN ''Hydrocodone''
		 WHEN drug_name ILIKE ''%Oxycodone%'' THEN ''Oxycodone''
		 WHEN drug_name ILIKE ''%Oxymorphone%'' THEN ''Oxymorphone''
		 WHEN drug_name ILIKE ''%Morphine%'' THEN ''Morphine''
		 WHEN drug_name ILIKE ''%Codeine%'' THEN ''Codeine''
		 WHEN drug_name ILIKE ''%Fentanyl%'' THEN ''Fentanyl''
		 ELSE NULL END AS opioid_type,
	SUM(total_claim_count) AS total_claims
FROM prescription LEFT JOIN drug USING(drug_name)
				  LEFT JOIN prescriber USING(npi)
WHERE nppes_provider_city IN (''NASHVILLE'',''MEMPHIS'',''KNOXVILLE'',''CHATTANOOGA'')
GROUP BY nppes_provider_city, opioid_type
ORDER BY nppes_provider_city, opioid_type
') AS Opioid_Prescriptions(city text, Codeine numeric, Fentanyl numeric, Hydrocodone numeric, Morphine numeric, Oxycodone numeric, Oxymorphone numeric)
; 

--For reference:
/*
SELECT nppes_provider_city AS city, 
	CASE WHEN drug_name ILIKE '%Hydrocodone%' THEN 'Hydrocodone'
		 WHEN drug_name ILIKE '%Oxycodone%' THEN 'Oxycodone'
		 WHEN drug_name ILIKE '%Oxymorphone%' THEN 'Oxymorphone'
		 WHEN drug_name ILIKE '%Morphine%' THEN 'Morphine'
		 WHEN drug_name ILIKE '%Codeine%' THEN 'Codeine'
		 WHEN drug_name ILIKE '%Fentanyl%' THEN 'Fentanyl'
		 ELSE NULL END AS opioid_type,
	SUM(total_claim_count) AS total_claims
FROM prescription LEFT JOIN drug USING(drug_name)
				  LEFT JOIN prescriber USING(npi)
WHERE nppes_provider_city IN ('NASHVILLE','MEMPHIS','KNOXVILLE','CHATTANOOGA')
GROUP BY nppes_provider_city, opioid_type
ORDER BY nppes_provider_city, opioid_type
;
*/