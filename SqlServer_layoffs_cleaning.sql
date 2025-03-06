
-- Data Cleaning

SELECT *
FROM layoffs;

-- data is imported raw with all column data types being varchar(50)



-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null values or blank values
-- 4. Remove Any Columns


-- Creating a copy of the table to clean
SELECT *
INTO layoffs_staging
FROM layoffs
WHERE 1=0;


INSERT INTO layoffs_staging
SELECT *
FROM layoffs;


-- 1. Remove Duplicates

SELECT *
FROM layoffs_staging;


-- Finding Duplicates using Row_number(), partitioned over all columns, which have row_num > 1
-- After Selection, and checking, DELETE those duplicates
WITH duplicate_CTE AS
(
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, [location], industry, 
total_laid_off, percentage_laid_off, 
[date], stage, country, funds_raised_millions
ORDER BY (SELECT NULL)) AS row_num
FROM layoffs_staging
)
DELETE -- SELECT *
FROM duplicate_CTE
WHERE row_num >1;


-- Checking the duplicates
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';


-- 2. Standardizing columns

---------------
-- col: company
---------------

SELECT DISTINCT company, TRIM(company)
FROM layoffs_staging
ORDER BY 1;

UPDATE layoffs_staging
SET company = TRIM(company);

----------------
-- col: location
----------------

SELECT DISTINCT [location]
FROM layoffs_staging

-----------------
-- col: country
-----------------

-- before filling in the missing data standardize easy columns
SELECT DISTINCT country
FROM layoffs_staging
ORDER BY 1;

-- United States have another variant written as "United States."

SELECT DISTINCT country, TRIM('.' FROM country)
FROM layoffs_staging
WHERE country LIKE 'United States%'
ORDER BY 1;

UPDATE layoffs_staging
SET country = TRIM('.' FROM country);

-------------
-- col: date
-------------

SELECT [date]
FROM layoffs_staging;

-- date is a varchar(50). Need to convert to date variable
-- data_style 101 is "mm/dd/yyyy"

SELECT [date], TRY_CONVERT(DATE, [date], 101)
FROM layoffs_staging;

UPDATE layoffs_staging
SET [date] = TRY_CONVERT(DATE, [date], 101);

SELECT [date]
FROM layoffs_staging;

-- change column data type

ALTER TABLE layoffs_staging
ALTER COLUMN [date] DATE;


-- col: total_laid_off

-- We go with data type INT
SELECT total_laid_off, TRY_CAST(total_laid_off AS INT)
FROM layoffs_staging;

UPDATE layoffs_staging
SET total_laid_off = TRY_CAST(total_laid_off AS INT);

ALTER TABLE layoffs_staging
ALTER COLUMN total_laid_off INT;

-- col: [percentage_laid_off] and [funds_raised_millions]

SELECT percentage_laid_off, TRY_CAST(percentage_laid_off AS DECIMAL(5,4))
FROM layoffs_staging;

UPDATE layoffs_staging
SET percentage_laid_off = TRY_CAST(percentage_laid_off AS DECIMAL(5,4));

ALTER TABLE layoffs_staging
ALTER COLUMN percentage_laid_off DECIMAL(5,4);

-- col: funds_raised_millions
SELECT MIN(funds_raised_millions), MAX(funds_raised_millions)
FROM layoffs_staging
WHERE funds_raised_millions <> 'NULL';

-- smallint can work for this (or regular int if unsure)

UPDATE layoffs_staging
SET funds_raised_millions = TRY_CAST(funds_raised_millions AS SMALLINT);

ALTER TABLE layoffs_staging
ALTER COLUMN funds_raised_millions SMALLINT;

-- col: stage

SELECT DISTINCT stage
FROM layoffs_staging

SELECT *
FROM layoffs_staging
WHERE stage = 'Unknown'
OR stage = 'NULL'
ORDER BY stage

UPDATE layoffs_staging
SET stage = NULL
WHERE stage = 'NULL'

--we can either make stage: 'Unknown' a NULL value or vice versa 
-- but for now we just turn string 'NULL' to NULL


-- 3. NULL values or Blanks

SELECT *
FROM layoffs_staging
WHERE industry = 'NULL' OR industry = ''

SELECT company, industry
FROM layoffs_staging
WHERE company IN ('Carvana', 'Airbnb', 'Juul', 'Bally''s Interactive')
-- Carvana is in industry of Transportation
-- Airbnb is in travel industry
-- Juul in Consumer

-- We can leave Bally's Interactive out as it is the only entry from this company 
-- and has NULL value

-- Self join
SELECT t2.industry, t2.company, t1.industry, t1.company
FROM layoffs_staging t1
JOIN layoffs_staging t2
	ON t1.company = t2.company
	AND t1.[location] = t2.[location]
WHERE (t1.industry = '') 
AND (t2.industry <> '')

-- Update now the industry

UPDATE t1
SET t1.industry = t2.industry
FROM layoffs_staging t1
JOIN layoffs_staging t2
	ON t1.company = t2.company
	AND t1.[location] = t2.[location]
WHERE (t1.industry = '') 
AND (t2.industry <> '')

-- 3 rows affected
-- check now NULL numbers and blanks
-- Only Bally's Interactive shows up;

-- set 'NULL' string to NULL
UPDATE layoffs_staging
SET industry = NULL
WHERE industry = 'NULL'


-- Missing values of total_laid_off and percentage_laid _off
SELECT *
FROM layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- When both of these columns are missing, data is not useful
-- We may keep them or delete them. 

-- In our case we delete them. As it won't be useful in EDA later.

DELETE
FROM layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;
--361 rows affected/deleted



-- Cleaned data has 1995 rows 
SELECT COUNT(*)
FROM layoffs_staging;
-- Raw data has 2361 rows
SELECT COUNT(*)
FROM layoffs;

------- THE END ------

-- It is possible to go into details and fix even more
-- but until it is necessary in Exploratory Data Analysis, we leave it be here.
SELECT *
FROM layoffs_staging;