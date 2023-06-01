/*
Cleaning Data in SQL Queries
*/

SELECT *
FROM sql_cleaning_nashville_housing.dbo.nashville_housing_cleaning

---------------------------------------------------------------------------------------

-- Standardize Date Format

SELECT saledate, sale_date_converted, CONVERT(date, saledate)
FROM sql_cleaning_nashville_housing.dbo.nashville_housing_cleaning

UPDATE nashville_housing_cleaning
SET saledate = CONVERT(date, saledate)

ALTER TABLE nashville_housing_cleaning
ADD sale_date_converted date;

UPDATE nashville_housing_cleaning
SET sale_date_converted = CONVERT(date, saledate)

--------------------------------------------------------------------------------------------------

-- Populate Property Address Data

SELECT *
FROM sql_cleaning_nashville_housing.dbo.nashville_housing_cleaning
--WHERE propertyaddress IS NULL
ORDER BY parcelID

SELECT a.uniqueid, a.parcelID, a.propertyaddress, b.uniqueid, b.parcelID, b.propertyaddress, 
	ISNULL(a.propertyaddress, b.propertyaddress) 
FROM sql_cleaning_nashville_housing.dbo.nashville_housing_cleaning AS a
JOIN sql_cleaning_nashville_housing.dbo.nashville_housing_cleaning AS b
	ON a.parcelID = b.parcelID
	AND a.uniqueid <> b.uniqueid 
WHERE a.propertyaddress IS NULL

UPDATE a
SET propertyaddress = ISNULL(a.propertyaddress, b.propertyaddress)
FROM sql_cleaning_nashville_housing.dbo.nashville_housing_cleaning AS a
JOIN sql_cleaning_nashville_housing.dbo.nashville_housing_cleaning AS b
	ON a.parcelID = b.parcelID
	AND a.uniqueid <> b.uniqueid 
WHERE a.propertyaddress IS NULL

-----------------------------------------------------------------------------------------------------------------------

--Breaking out address into individual Columns (Address, City, State)

-- substring, charindex

SELECT propertyaddress
FROM sql_cleaning_nashville_housing.dbo.nashville_housing_cleaning

SELECT SUBSTRING(propertyaddress, 1, CHARINDEX(',', propertyaddress) -1) AS address,
	   SUBSTRING(propertyaddress, CHARINDEX(',', propertyaddress) +1, LEN(propertyaddress)) AS city
FROM sql_cleaning_nashville_housing.dbo.nashville_housing_cleaning


ALTER TABLE nashville_housing_cleaning
ADD property_split_address Nvarchar(255);

UPDATE nashville_housing_cleaning
SET property_split_address = SUBSTRING(propertyaddress, 1, CHARINDEX(',', propertyaddress) -1)

ALTER TABLE nashville_housing_cleaning
ADD property_split_city Nvarchar(255);

UPDATE nashville_housing_cleaning
SET property_split_city = SUBSTRING(propertyaddress, CHARINDEX(',', propertyaddress) +1, LEN(propertyaddress))

SELECT *
FROM sql_cleaning_nashville_housing.dbo.nashville_housing_cleaning

-- Breaking out owner address into it's seperate columns
SELECT owneraddress
FROM sql_cleaning_nashville_housing.dbo.nashville_housing_cleaning

SELECT 
	PARSENAME(REPLACE(owneraddress, ',' , '.') , 3),
	PARSENAME(REPLACE(owneraddress, ',' , '.') , 2),
	PARSENAME(REPLACE(owneraddress, ',' , '.') , 1) 
FROM sql_cleaning_nashville_housing.dbo.nashville_housing_cleaning

ALTER TABLE nashville_housing_cleaning
ADD owner_split_address Nvarchar(255);

UPDATE nashville_housing_cleaning
SET owner_split_address = PARSENAME(REPLACE(owneraddress, ',' , '.') , 3)

ALTER TABLE nashville_housing_cleaning
ADD owner_split_city Nvarchar(255);

UPDATE nashville_housing_cleaning
SET owner_split_city = PARSENAME(REPLACE(owneraddress, ',' , '.') , 2)

ALTER TABLE nashville_housing_cleaning
ADD owner_split_state Nvarchar(255);

UPDATE nashville_housing_cleaning
SET owner_split_state = PARSENAME(REPLACE(owneraddress, ',' , '.') , 1)

SELECT *
FROM sql_cleaning_nashville_housing.dbo.nashville_housing_cleaning

-------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field.
-- Using a CASE statement

SELECT DISTINCT soldasvacant, COUNT(soldasvacant)
FROM sql_cleaning_nashville_housing.dbo.nashville_housing_cleaning
GROUP BY soldasvacant
ORDER BY 2

SELECT soldasvacant,
	CASE WHEN soldasvacant = 'Y' THEN 'Yes'
		 WHEN soldasvacant = 'N' THEN 'No'
		 ELSE soldasvacant
		 END
FROM sql_cleaning_nashville_housing.dbo.nashville_housing_cleaning


UPDATE nashville_housing_cleaning
SET soldasvacant = CASE 
		 WHEN soldasvacant = 'Y' THEN 'Yes'
		 WHEN soldasvacant = 'N' THEN 'No'
		 ELSE soldasvacant
		 END


----------------------------------------------------------------------------------------------

-- Remove Duplicates
-- In standard practice you dont delete data from the working database
-- CTE and Windows functions
-- rank, order rank and row number methods used
-- watch video from 37:37 - 47:11
-- WITH CTE you just created a temp like table.

WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY parcelid,
				 propertyaddress,
				 saleprice,
				 saledate,
				 legalreference
				 ORDER BY
					uniqueid
					) AS row_num
FROM sql_cleaning_nashville_housing.dbo.nashville_housing_cleaning
--ORDER BY parcelid
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1 -- filtering for only the duplicates. results in values of 2. meaning 104 rows with value of 2 are duplicates.
ORDER BY propertyaddress

--Adjust CTE query to delete duplicates

WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY parcelid,
				 propertyaddress,
				 saleprice,
				 saledate,
				 legalreference
				 ORDER BY
					uniqueid
					) AS row_num
FROM sql_cleaning_nashville_housing.dbo.nashville_housing_cleaning
--ORDER BY parcelid
)
DELETE
FROM RowNumCTE
WHERE row_num > 1 -- filtering for only the duplicates. results in values of 2. meaning 104 rows with value of 2 are duplicates.
--ORDER BY propertyaddress

-------------------------------------------------------------------------------------------------------------

-- Delete Unused Columns
-- you'll use this technique on Views but never on the raw data from database

SELECT *
FROM sql_cleaning_nashville_housing.dbo.nashville_housing_cleaning

ALTER TABLE sql_cleaning_nashville_housing.dbo.nashville_housing_cleaning
DROP COLUMN owneraddress, taxdistrict, propertyaddress

ALTER TABLE sql_cleaning_nashville_housing.dbo.nashville_housing_cleaning
DROP COLUMN saledate