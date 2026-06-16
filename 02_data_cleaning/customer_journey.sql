
-- ---------- We will do Nested CTE contains Customer_journy (secrets behind the conversion rate) --------------------------- --


-- Checking and cleaning the categorical columns.
WITH RawJourneyCleaned AS (
    SELECT 
        JourneyID,
        CustomerID,
        ProductID,
        CAST(VisitDate AS DATE) AS VisitDate,
        -- Standarization of 'stage' names:
        CASE 
            WHEN UPPER(TRIM(Stage)) = 'PRODUCTPAGE' THEN 'Product Page'
            WHEN UPPER(TRIM(Stage)) = 'HOMEPAGE' THEN 'Home Page'
            ELSE UPPER(TRIM(Stage)) 
        END AS Stage,
        UPPER(TRIM(Action)) AS Action,
        Duration
    FROM customer_journey
),

-- Handling nulls step1:  we will count the average duration of ervery stage:
StageAverages AS (
    SELECT 
        *,
        AVG(CAST(Duration AS FLOAT)) OVER (PARTITION BY Stage) AS AvgStageDuration -- avg for every stage
    FROM RawJourneyCleaned
),

-- Handling nulls step2: (imputation using the AVG of every STAGE)
-- Handling duplicates: (remove Duplicates)
ImputedJourney AS (
    SELECT 
        JourneyID,
        CustomerID,
        ProductID,
        VisitDate,
        Stage,
        Action,
        -- if (duration is null) impute with AVG of stage , if (duration still null) impute with 0
        ROUND(COALESCE(CAST(Duration AS FLOAT), AvgStageDuration, 0), 2) AS Duration,

       -- check duplicates:
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID, ProductID, VisitDate, Stage, Action 
            ORDER BY JourneyID
        ) AS JourneyRank
    FROM StageAverages
)

-- .........................................................

SELECT 
    JourneyID, CustomerID, ProductID, VisitDate, Stage, Action, Duration
FROM ImputedJourney
WHERE JourneyRank = 1 
      AND JourneyID IS NOT NULL;




