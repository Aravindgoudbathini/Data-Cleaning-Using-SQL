-- ================================
-- WORLD LIFE EXPECTANCY DATA CLEANING
-- ================================

-- 1. INITIAL DATA EXPLORATION
-- View all records in the worldlifexpectancy table to understand the dataset structure
SELECT * 
FROM worldlifexpectancy;

-- 2. IDENTIFY DUPLICATE RECORDS
-- Find duplicate records based on Country and Year combination
-- This query shows countries/years that appear more than once in the dataset
SELECT Country, Year, CONCAT(Country, Year), COUNT(CONCAT(Country, Year))
FROM worldlifexpectancy
GROUP BY Country, Year
HAVING COUNT(CONCAT(Country, Year)) > 1;

-- 3. REMOVE DUPLICATE RECORDS
-- Delete duplicate records, keeping only the first occurrence of each Country-Year combination
-- Uses ROW_NUMBER() window function to identify duplicates
DELETE FROM worldlifexpectancy 
WHERE Row_ID IN (
    SELECT Row_ID
    FROM (
        SELECT Row_ID, 
               CONCAT(Country, Year),
               (ROW_NUMBER() OVER(PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year))) AS row_numb
        FROM worldlifexpectancy
    ) AS T_able 
    WHERE row_numb > 1
);

-- 4. IDENTIFY MISSING STATUS VALUES
-- Find records where the Status field is empty/blank
SELECT * 
FROM worldlifexpectancy
WHERE Status = '';

-- 5. EXPLORE EXISTING STATUS VALUES
-- View unique countries and their status values to understand the data patterns
-- This helps determine how to fill in missing status values
SELECT DISTINCT(Country), Status
FROM worldlifexpectancy
WHERE Status <> '';

-- 6. UPDATE MISSING STATUS - DEVELOPING COUNTRIES
-- Fill in blank Status fields with 'Developing' for countries that have 'Developing' status in other records
-- Uses self-join to match countries with their existing status values
UPDATE worldlifexpectancy t1
JOIN worldlifexpectancy t2
    ON t1.Country = t2.Country
SET t1.Status = 'Developing'
WHERE t1.Status = ''
    AND t2.Status <> ''
    AND t2.Status = 'Developing';

-- 7. UPDATE MISSING STATUS - DEVELOPED COUNTRIES
-- Fill in blank Status fields with 'Developed' for countries that have 'Developed' status in other records
-- Uses self-join to match countries with their existing status values
UPDATE worldlifexpectancy t1
JOIN worldlifexpectancy t2
    ON t1.Country = t2.Country
SET t1.Status = 'Developed'
WHERE t1.Status = ''
    AND t2.Status <> ''
    AND t2.Status = 'Developed';

-- 8. INTERPOLATE MISSING LIFE EXPECTANCY VALUES
-- Fill in missing life expectancy values by calculating the average of the previous and next year's values
-- This technique is called linear interpolation and provides reasonable estimates for missing data points
UPDATE worldlifexpectancy t1
JOIN worldlifexpectancy t2
    ON t1.Country = t2.Country
    AND t1.Year = t2.Year - 1  -- t2 represents the year AFTER t1 (next year)
JOIN worldlifexpectancy t3
    ON t1.Country = t3.Country
    AND t1.Year = t3.Year + 1  -- t3 represents the year BEFORE t1 (previous year)
SET t1.Lifeexpectancy = ROUND((t2.Lifeexpectancy + t3.Lifeexpectancy)/2, 1)
WHERE t1.Lifeexpectancy = 0 OR t1.Lifeexpectancy IS NULL;

-- ================================
-- DATA CLEANING SUMMARY:
-- 1. Removed duplicate Country-Year combinations
-- 2. Filled missing Status values using existing country data
-- 3. Interpolated missing Life Expectancy values using adjacent years
-- ================================