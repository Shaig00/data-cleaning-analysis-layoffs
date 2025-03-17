Documenting Data cleaning and exploration with SQL Server on layoffs data
=====================

- [Project Overview](#project-overview)
- [Data](#data)
- [Tools](#tools)
- [Data Cleaning Stage](#data-cleaning-stage)
- [EDA Stage](#eda-stage)
- [Code Snippets](#code-snippets)
- [Key Findings](#key-findings)
- [Analysis Limiations](#analysis-limitations)

-----------------------------------------
Repository Files:
=================

|Data Cleaning|Exploratory Data Analysis (EDA)|Data File|
|---|---|---|
|SqlServer_layoffs_cleaning.sql|SqlServer_layoffs_EDA.sql|layoffs.csv|

## Project Overview

The purpose of this project is to showcase data cleaning and analysis skills on relatively unclean/unprepared data using SQL Server. These 2 steps are the initial steps of getting familiar with the data and making it suitable for analysis. Thereafter, it is easy to use prepared and explored data to create visualisations or get the cleaned data on dashboarding tools (e.g. Power BI), as we are already aware of some insights from EDA.

## Data

Columns/Attributes of **layoffs** dataset:

`company` `location` `industry` `total_laid_off` `percentage_laid_off` `date` `stage` `country` `funds_raised_millions` 

- Data is imported raw with all column data types being varchar(50).
- Data contains layoff records of companies worldwide from year 2020 till early 2023.


## Tools

**SQL Server** | *Data Cleaning and Data Exploration*


## Data Cleaning Stage

The initial phase is preparing the data and making entries as consistent as possible:

1. Remove Duplicates
2. Standardize the Data - correct any inconsistent and change key datatypes if needed 
3. Null values or blank values - substitute if it is possible.
4. Remove Any Columns - if not necessary for analysis


## EDA Stage

Key questions that were addressed:

- Which companies have been completely laid off?
- Which company/industry/country has the largest layoffs?
- How did layoffs progress throughout the data timeline? Finding monthly running total of layoffs.
- What companies had the top 5 largest layoffs each year?

## Code Snippets

Snippets of SQL queries that were used to carry out Data Cleaning and Exploration:

#### Trying to substitute empty fields

While looking into empty and `NULL` values, I have discovered that records from companies like *Carvana*, *Airbnb* and *Juul*, *Bally's Interactive* had missing `industry` field. 
```sql
SELECT *
FROM layoffs_staging
WHERE industry = 'NULL' OR industry = ''
```

However, `industry` attribute was not missing all the time, which means it could be substituted from other fields of the same companies that contained the value. The only `company` that could not be substituted was *Bally's Interactive*, as it had only one entry with missing `industry` field.

I wrote following query in order to fix this problem:

```sql
SELECT t2.industry, t2.company, t1.industry, t1.company
FROM layoffs_staging t1
JOIN layoffs_staging t2
	ON t1.company = t2.company
	AND t1.[location] = t2.[location]
WHERE (t1.industry = '') 
AND (t2.industry <> '')
```
I have implemented `SELF JOIN`  of rows of the unique companies (i.e. having same `company` name and same `country`), where 1st table t1 was missing `industry` field AND second table was not missing it. This way same companies would substitute/fill in those empty fields with the `industry` name. After examining this query, I updated the table t1 `industry` attribute to fill in these values.

```sql
UPDATE t1
SET t1.industry = t2.industry
FROM layoffs_staging t1
JOIN layoffs_staging t2
	ON t1.company = t2.company
	AND t1.[location] = t2.[location]
WHERE (t1.industry = '') 
AND (t2.industry <> '')
```

-----------

#### Data Exploration queries

##### Running monthly sum of layoffs

```sql
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
```

##### Ranking the top 5 companies with most layoffs by partitioned by year

```sql
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
```
I used 2 CTEs:
1. company_year_layoffs:
	- This serves as table of total layoffs of each company by year.
2. ranked_yearly_layoffs:
	- With `DENSE_RANK()` create ranking partitioned by year and ordered by most to least layoffs.

Finally, selecting only top 5 ranking each year.



## Key findings

- In total 116 companies has been laid of completely in the time span that dataset covers, *Katerra* being the largest company that has been totally laid off. *Britishvolt* raised 2400 millions but got laid off completely. On 4th place is again Katerra with 1600 millions raised.
- Amazon, Google and Meta are the top companies with largest layoffs
- Top 3 specifically are Consumer, Retail and Transportation.
	- **Challenge**: 3rd largest total layoffs occur in other industries that are unspecified or not in this dataset.
- United States have the largest layoffs of around 256 thousand employees (2020-2023). This is very large compared to the 2nd place being India with only 35 thousand layoffs.
- Most layoffs took place in 2022 and 2023, reaching in total around 300 thousand. Given that for the year 2023, data only shows first three months, this perhaps indicates large layoffs starting at the end of 2022 going into early 2023. For further development of these numbers, running sum has been implemented (see [monthly running total](#running-monthly-sum-of-layoffs)).

Top 3 biggest layoff rankings by year:

<table>
  <tr>
    <th>Year</th>
    <th>Company</th>
    <th>Ranking</th>
  </tr>
  <tr>
    <td rowspan="3" align="center">2020</td>
    <td>Uber</td>
    <td>1</td>
  </tr>
  <tr> 
    <td>Booking.com</td>
    <td>2</td>
  </tr>
  <tr>
    <td>Groupon</td>
    <td>3</td>
  </tr>
  <tr>
    <td rowspan="3" align="center">2021</td>
    <td>Bytedance</td>
    <td>1</td>
  </tr>
  <tr>
    <td>Katerra</td>
    <td>2</td>
  </tr>
  <tr>
    <td>Zillow</td>
    <td>3</td>
  </tr>
  <tr>
    <td rowspan="3" align="center">2022</td>
    <td>Meta</td>
    <td>1</td>
  </tr>
  <tr>
    <td>Amazon</td>
    <td>2</td>
  </tr>
  <tr>
    <td>Cisco</td>
    <td>3</td>
  </tr>
  <tr>
    <td rowspan="3" align="center">2023</td>
    <td>Google</td>
    <td>1</td>
  </tr>
  <tr>
    <td>Microsoft</td>
    <td>2</td>
  </tr>
  <tr>
    <td>Ericsson</td>
    <td>3</td>
  </tr>
</table>

## Analysis Limitations
- Some records had `NULL` values both in `total_laid_off` AND `percentage_laid_off`. I created the copy of the table and removed those values for exploratary data analysis stage. This decision was made, as without these 2 attributes existing, it is difficult to analyse these records.
- Further analysis into `stage` attribute of the company would be desirable. However, it has been avoided due to lack of expertise about these stages. Focus has been set on numbers of laid off employees.
- One possible further analysis would be to look into smaller companies and focus on `percentage_laid_off`. This would show us if smaller companies has been affected more than big cooperations.


[Back to the Top](#documenting-data-cleaning-and-exploration-with-sql-server-on-layoffs-data)

