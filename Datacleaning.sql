-- SQL PROJECT - FOR DATA CLEANING

CREATE DATABASE IF NOT EXISTS world_layoffs;

USE world_layoffs; -- Use created database



-- ----------------- Data cleaning ------------------------------
-- 1. Check for and Remove duplicates
-- 2. Standardize the Data - finding issues in data and fixing it
-- 3. Dealing with Null values or blank values
-- 4. Remove any Rows/columns that are not necessary

-- imported Data using table Data import wizard into MYSQL

-- Create new table from existing table and this will be the one to work on and clean the data.
CREATE TABLE layoffs_stagging 
LIKE layoffs;

INSERT layoffs_stagging
SELECT *
from layoffs;


-- ------------------------------------------------------------------------------
-- ----------- stage 1: Check for duplicates in our Data ------------------------

# First lets check for duplicates in our data
WITH duplicate_cte AS
(
SELECT *, row_number() OVER (
partition by company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) row_num
FROM layoffs_stagging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- We created a new column inside a new table called row_num to help in deleling duplicates
CREATE TABLE `layoffs_stagging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- Now we insert data into our new table

INSERT layoffs_stagging2
SELECT *, row_number() OVER (
partition by company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) row_num
FROM layoffs_stagging;

SELECT *
FROM layoffs_stagging2
WHERE row_num > 1;

delete from layoffs_stagging2
where row_num > 1;


-- -----------------------------------------------------------------------------------
-- -------------------- stage 2: standardised the Data -------------------------------

SELECT company, trim(company) -- Trim help to remove white spaces in company column
FROM layoffs_stagging2;

UPDATE layoffs_stagging2
SET company = TRIM(company);

SELECT distinct country
from layoffs_stagging2
order by 1;

SELECT distinct country, trim(trailing '.' FROM country) -- Trailing removes (.) from the end of country united states
FROM layoffs_stagging2
ORDER BY 1;

UPDATE layoffs_stagging2
SET country = trim(trailing '.' FROM country)
WHERE country LIKE 'United States%';


-- let's take a look at our datatypes and correct them.
DESC layoffs_stagging2; -- function describes each column

SELECT date, str_to_date(date, '%m/%d/%Y') 
FROM layoffs_stagging2;

UPDATE layoffs_stagging2 -- changing from text to date format
SET date = str_to_date(date, '%m/%d/%Y');

-- change datatype of actual date table
ALTER TABLE layoffs_stagging2
MODIFY COLUMN date DATE;


-- -------------------------------------------------------------------------------
-- ----------- 3. Dealing with Null values or blank values -----------------------
SELECT *
FROM layoffs_stagging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_stagging2
WHERE industry IS NULL
OR industry = '';

-- Identify which industry is Airbnb to update empty/null values for industry column 
SELECT *
FROM layoffs_stagging2
WHERE company = 'Airbnb';

-- we conduct a self join to replace null values in industry column
SELECT *
FROM layoffs_stagging2 t1
JOIN layoffs_stagging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE layoffs_stagging2
SET industry = null
WHERE industry = '';

UPDATE layoffs_stagging2 t1
JOIN layoffs_stagging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
	AND t2.industry IS NOT NULL;
    
    
-- we continue to remove null values
SELECT *
FROM layoffs_stagging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;
    
DELETE FROM layoffs_stagging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

  
  
 -- ---------------------------------------------------------------------------------
 -- ----- 4. Remove any Rows/columns that are not necessary -------------------------
 ALTER TABLE layoffs_stagging2
 DROP COLUMN row_num;

SELECT *
FROM layoffs_stagging2;