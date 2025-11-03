-- Find the prescribers who prescribe opioids at twice the rate or higher compared to others in their specialty
	-- Report the prescriber's name, city, specialty, opioid claims, opioid claim rate, and specialty opioid rate


WITH 
--First, the number of opioid claims per row of the prescription table
opioid_claims AS 
	(SELECT npi, total_claim_count, 
		CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count
			 ELSE 0 END AS opioid_claim_count
	FROM prescription LEFT JOIN drug USING(drug_name)
	), 

--Then find the total opioid claims and rates of prescription per provider
npi_opioid_rates AS	
	(SELECT npi, specialty_description AS specialty, SUM(opioid_claim_count) AS total_opioid_claims, (SUM(opioid_claim_count)*100)/SUM(total_claim_count) AS opioid_rate
	FROM opioid_claims LEFT JOIN prescriber USING(npi)
	GROUP BY npi, specialty_description
	),

--Then find the rates per specialty
specialty_opioid_rates AS
	(SELECT specialty, AVG(opioid_rate) AS spec_avg_opioid_rate
	FROM npi_opioid_rates
	GROUP BY specialty
	)

--Add it all together and filter for providers who prescribe opioids at twice the rate or higher of the specialty average
SELECT nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, total_opioid_claims, ROUND(opioid_rate, 2) AS opioid_rate, ROUND(spec_avg_opioid_rate, 2) AS spec_avg_opioid_rate
FROM npi_opioid_rates INNER JOIN specialty_opioid_rates USING(specialty)
					  INNER JOIN prescriber USING(npi)
WHERE opioid_rate >= (2 * spec_avg_opioid_rate)
ORDER BY total_opioid_claims DESC
;

-- Doing this again with a window fxn
-- Find the prescribers who prescribe opioids at twice the rate or higher compared to others in their specialty
	-- Report the prescriber's name, city, specialty, opioid claims, opioid claim rate, and specialty opioid rate
WITH prescriber_totals AS
	(SELECT 
		npi, 
		specialty_description,
		SUM(total_claim_count) 															AS total_claims,
		SUM(CASE WHEN opioid_drug_flag ='Y' THEN total_claim_count ELSE 0 END) 			AS total_opioid_claims
	FROM prescription INNER JOIN drug USING(drug_name)
					  INNER JOIN prescriber USING(npi)
	GROUP BY npi, specialty_description),
	
spec_averages AS
	(SELECT *, 
		(total_opioid_claims/total_claims) * 100 												AS perc_opioid_claims,
		AVG((total_opioid_claims/total_claims) * 100) OVER(PARTITION BY specialty_description) 	AS specialty_avg
	FROM prescriber_totals)

SELECT 
	nppes_provider_first_name 			AS first_name, 
	nppes_provider_last_org_name 		AS last_name, 
	specialty_description 				AS specialty, 
	total_opioid_claims, 
	ROUND(perc_opioid_claims, 2) 		AS perc_opioid_claims, 
	ROUND(specialty_avg, 2)				AS specialty_avg
FROM spec_averages INNER JOIN prescriber USING(npi, specialty_description)
WHERE perc_opioid_claims >= (2 * specialty_avg)
ORDER BY total_opioid_claims DESC
;