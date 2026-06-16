
-- ----------------------- We will do Nested CTE contains Products --------------------------- --


-- Checking and cleaning the categorical columns.
WITH RawProductsCleaned AS (
    SELECT 
        ProductID,
        TRIM(ProductName) AS ProductName,
        UPPER(TRIM(Category)) AS Category,
        ROUND(ABS(Price), 2) AS Price  -- converting the negative prices into positive prices (ABS alternative of delete beacause we won't change DB)
    FROM Products
),
-- Handling Duplicates..
Products_Deduplicated AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ProductID 
            ORDER BY ProductID
        ) AS rn
    FROM RawProductsCleaned
),

-- Adding analytical column (Price Tiers)  To know eeach price tier has the less interactions 
--  *______ Jean Doe requested in her email______*.
FinalProducts AS (
    SELECT 
        ProductID,
        ProductName,
        Category,
        Price,
        CASE 
            WHEN Price < 50 THEN 'Budget'
            WHEN Price BETWEEN 50 AND 200 THEN 'Mid-Range'
            ELSE 'Premium'
        END AS PriceTier
    FROM Products_Deduplicated
    WHERE rn = 1 
)


-- .........................................................

SELECT 
    ProductID, ProductName, Category, Price, PriceTier
FROM FinalProducts
WHERE ProductID IS NOT NULL;