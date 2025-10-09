--1. How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT COUNT(npi) FROM
	(SELECT npi FROM prescriber
	EXCEPT
	SELECT npi FROM prescription)
;


-- 2.a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT generic_name
FROM prescription LEFT JOIN prescriber USING(npi)
				  INNER JOIN drug USING(drug_name)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY SUM(total_claim_count) DESC NULLS LAST
LIMIT 5
;

-- 2.b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
SELECT generic_name
FROM prescription LEFT JOIN prescriber USING(npi)
				  INNER JOIN drug USING(drug_name)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY SUM(total_claim_count) DESC NULLS LAST
LIMIT 5
;

-- 2.c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? 
	-- Combine what you did for parts a and b into a single query to answer this question.

(SELECT generic_name
FROM prescription LEFT JOIN prescriber USING(npi)
				  INNER JOIN drug USING(drug_name)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY SUM(total_claim_count) DESC NULLS LAST
LIMIT 5)

INTERSECT

(SELECT generic_name
FROM prescription LEFT JOIN prescriber USING(npi)
				  INNER JOIN drug USING(drug_name)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY SUM(total_claim_count) DESC NULLS LAST
LIMIT 5)
;



/* 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
    a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. 
		Report the npi, the total number of claims, and include a column showing the city. */

SELECT npi, MAX(nppes_provider_city) AS city, SUM(total_claim_count) AS total_claim_sum
FROM prescription LEFT JOIN prescriber USING(npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi
ORDER BY total_claim_sum DESC NULLS LAST
LIMIT 5
;
    
-- 3.b. Now, report the same for Memphis.

SELECT npi, MAX(nppes_provider_city) AS city, SUM(total_claim_count) AS total_claim_sum
FROM prescription LEFT JOIN prescriber USING(npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY npi
ORDER BY total_claim_sum DESC NULLS LAST
LIMIT 5
;

    
-- 3.c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
(SELECT npi, MAX(nppes_provider_city) AS city, SUM(total_claim_count) AS total_claim_sum
FROM prescription LEFT JOIN prescriber USING(npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi
ORDER BY total_claim_sum DESC NULLS LAST
LIMIT 5)

UNION ALL

(SELECT npi, MAX(nppes_provider_city) AS city, SUM(total_claim_count) AS total_claim_sum
FROM prescription LEFT JOIN prescriber USING(npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY npi
ORDER BY total_claim_sum DESC NULLS LAST
LIMIT 5)

UNION ALL

(SELECT npi, MAX(nppes_provider_city) AS city, SUM(total_claim_count) AS total_claim_sum
FROM prescription LEFT JOIN prescriber USING(npi)
WHERE nppes_provider_city = 'KNOXVILLE'
GROUP BY npi
ORDER BY total_claim_sum DESC NULLS LAST
LIMIT 5)

UNION ALL

(SELECT npi, MAX(nppes_provider_city) AS city, SUM(total_claim_count) AS total_claim_sum
FROM prescription LEFT JOIN prescriber USING(npi)
WHERE nppes_provider_city = 'CHATTANOOGA'
GROUP BY npi
ORDER BY total_claim_sum DESC NULLS LAST
LIMIT 5)
;

-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

SELECT county, ROUND(AVG((overdose_deaths/population) * 100000), 2) AS avg_annual_od_per_100k
FROM overdose_deaths AS od LEFT JOIN population AS p ON od.fipscounty = CAST(p.fipscounty AS integer)
						   LEFT JOIN fips_county ON od.fipscounty = CAST(fips_county.fipscounty AS integer)
GROUP BY county
	HAVING AVG((overdose_deaths/population) * 100000) > 
		(SELECT AVG((overdose_deaths/population) * 100000)
	 	 FROM overdose_deaths LEFT JOIN population ON overdose_deaths.fipscounty = CAST(population.fipscounty AS integer))
ORDER BY avg_annual_od_per_100k DESC
;

-- 5.a. Write a query that finds the total population of Tennessee.

SELECT SUM(population) AS TN_population
FROM fips_county LEFT JOIN population USING(fipscounty)
WHERE state = 'TN'
;
    
-- 5.b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and 
	-- the percentage of the total population of Tennessee that is contained in that county.

SELECT 
	county,
	population,
	ROUND((population * 100) /(SELECT SUM(population) FROM fips_county LEFT JOIN population USING(fipscounty) WHERE state = 'TN'), 2) AS perc_of_TN
FROM fips_county LEFT JOIN population USING(fipscounty)
WHERE state = 'TN'
		AND county <> 'STATEWIDE'
ORDER BY county ASC;