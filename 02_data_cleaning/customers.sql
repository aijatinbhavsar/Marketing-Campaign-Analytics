

-- ----------------------- We will do Nested CTE contains (Customers, Geography) --------------------------- --


-- Checking and cleaning the categorical columns.
WITH RawCustomerData AS (
    SELECT 
        CustomerID,
        GeographyID,
        TRIM(CustomerName) AS CustomerName,
        LOWER(TRIM(Email)) AS Email,
        -- I have a problem about Gender (there are women their gender are 'Male'!!)
        CASE 
            WHEN TRIM(CustomerName) LIKE 'Robert%' OR TRIM(CustomerName) LIKE 'David%' 
                 OR TRIM(CustomerName) LIKE 'Daniel%' OR TRIM(CustomerName) LIKE 'James%' 
                 OR TRIM(CustomerName) LIKE 'Michael%' OR TRIM(CustomerName) LIKE 'Chris%' 
                 OR TRIM(CustomerName) LIKE 'John%' OR TRIM(CustomerName) LIKE 'Alex%' THEN 'Male'
            WHEN TRIM(CustomerName) LIKE 'Emma%' OR TRIM(CustomerName) LIKE 'Sarah%' 
                 OR TRIM(CustomerName) LIKE 'Laura%' OR TRIM(CustomerName) LIKE 'Olivia%' 
                 OR TRIM(CustomerName) LIKE 'Emily%' OR TRIM(CustomerName) LIKE 'Jane%'
                 OR TRIM(CustomerName) LIKE 'Sophia%' OR TRIM(CustomerName) LIKE 'Isabella%' THEN 'Female'
            ELSE TRIM(Gender)
        END AS Gender,
        -- Constraint and check if the range of age doesn't meet the standards (doesn't meet the needed customers)..
        CASE 
            WHEN Age < 10 OR Age > 95 THEN NULL 
            ELSE Age 
        END AS Age
    FROM Customers
),

-- join Customers and Geography to make a one CTE includes all customers data..
EnrichedCustomerData AS ( 
    SELECT 
        c.*, 
        g.Country, 
        g.City
    FROM RawCustomerData c
    LEFT JOIN Geography g ON c.GeographyID = g.GeographyID
),

-- Handling duplicates..
DistinctCustomers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID 
            ORDER BY CustomerID
        ) AS row_num
    FROM EnrichedCustomerData
)

-- .........................................................


SELECT 
    CustomerID, CustomerName, Email, Gender, Age, 
    Country, City
FROM DistinctCustomers
WHERE row_num = 1 
      AND CustomerID IS NOT NULL;

