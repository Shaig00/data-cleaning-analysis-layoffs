
--- Exploratory Data Analysis ---

SELECT *
FROM layoffs_staging;

SELECT MAX(percentage_laid_off), MAX(total_laid_off)
FROM layoffs_staging;

-- 1.0000 means company has been completely laid off
-- let's check those companies

SELECT *
FROM layoffs_staging
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- Katerra is the largest company that has been totally laid off

-- check for funds raised

SELECT *
FROM layoffs_staging
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- Britishvolt raised 2400 millions but got laid off completely (went bankrupt possibly).
-- On 4th place we also see Katerra with 1600 millions raised

--Which company is has largest total layoffs?

SELECT company, SUM(total_laid_off)
FROM layoffs_staging
GROUP BY company
ORDER BY 2 DESC;

-- Amazon, Google and Meta are the top companies with largest layoffs

-- timeline
SELECT MIN([date]), MAX([date])
FROM layoffs_staging;
-- between 2020/03 and 2023/03 march


-- Checking by industry
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging
GROUP BY industry
ORDER BY 2 DESC;

-- Top 3 specifically are Consumer, Retail and Transportation. 3rd largest layoffs are in total in other
-- industries that is unspecified or not in this database.

-- By country
SELECT country, SUM(total_laid_off)
FROM layoffs_staging
GROUP BY country
ORDER BY 2 DESC;

-- United States have the largest layoffs of around 256 thousand employees. This is very large
-- compared to the 2nd place being India with only 35 thousand layoffs.

-- Layoffs by year?
SELECT YEAR([date]), SUM(total_laid_off)
FROM layoffs_staging
GROUP BY YEAR([date])
ORDER BY 1 DESC;

-- Most layoffs took place in 2022 and 2023, reaching in total around 300 thousand,
-- considering that data only shows first three months of 2023.

-- layoffs by month and rolling SUM to see how layoffs change over months.
-- first by month
-- need: (yyyy-mm)
SELECT CAST(YEAR([date]) AS VARCHAR(4)) + '-' + CAST(MONTH([date]) AS VARCHAR(2)) AS [MONTH],
SUM(total_laid_off)
FROM layoffs_staging
WHERE CAST(YEAR([date]) AS VARCHAR(4)) + '-' + CAST(MONTH([date]) AS VARCHAR(2)) IS NOT NULL
GROUP BY CAST(YEAR([date]) AS VARCHAR(4)) + '-' + CAST(MONTH([date]) AS VARCHAR(2))
ORDER BY 1 ASC;

-- add running sum with CTE
WITH running_monthly_layoffs AS
(
SELECT CAST(YEAR([date]) AS VARCHAR(4)) + '-' + CAST(MONTH([date]) AS VARCHAR(2)) AS [MONTH],
SUM(total_laid_off) AS monthly_layoffs
FROM layoffs_staging
WHERE CAST(YEAR([date]) AS VARCHAR(4)) + '-' + CAST(MONTH([date]) AS VARCHAR(2)) IS NOT NULL
GROUP BY CAST(YEAR([date]) AS VARCHAR(4)) + '-' + CAST(MONTH([date]) AS VARCHAR(2))
)
SELECT [MONTH], monthly_layoffs,
SUM(monthly_layoffs) OVER(ORDER BY [MONTH]) AS running_total_layoffs
FROM running_monthly_layoffs;

-- Each company layoffs by year

SELECT company, YEAR([date]), SUM(total_laid_off)
FROM layoffs_staging
GROUP BY company, YEAR([date])
HAVING YEAR([date]) IS NOT NULL
ORDER BY 1, 2 ASC;

-- Use this table to rank companies by layoffs each year

WITH company_year_layoffs (company, [year], yearly_total_laid_off) AS
(
SELECT company, YEAR([date]), SUM(total_laid_off)
FROM layoffs_staging
GROUP BY company, YEAR([date])
), ranked_yearly_layoffs AS
(
SELECT *, DENSE_RANK() OVER(PARTITION BY [year] ORDER BY yearly_total_laid_off DESC) as ranking
FROM company_year_layoffs
WHERE [year] IS NOT NULL
)
SELECT *
FROM ranked_yearly_layoffs
WHERE ranking <= 5
ORDER BY [year] ASC, ranking ASC;

-- Year 2020:
-- Top 3 biggest layoffs: Uber, Booking.com, Groupon
-- Year 2021:
-- Top 3 biggest layoffs: Bytedance, Katerra, Zillow
-- Year 2022: Meta, Amazon, Cisco
-- Year 2023 (only first 3 month): Google, Microsoft, Ericsson

-- Due to DENSE_RANK(), there is 2 4th place for year 2023, Amazon and Salesforce.


-- Further, percentage_laid_off can be used 
-- to analyze if small companies has been affected more than big companies