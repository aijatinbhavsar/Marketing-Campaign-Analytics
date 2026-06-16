
-- ----- We will do Nested CTE contains customer_reviews (analysis reviews , Sentiment Analysis ,understand pain points) ---------- --


-- Checking and cleaning the categorical columns.
WITH RawReviewsCleaned AS (
    SELECT 
        ReviewID,
        CustomerID,
        ProductID,
        CAST(ReviewDate AS DATE) AS ReviewDate,
        -- control Rating to be between 1:5
        CASE 
            WHEN Rating > 5 THEN 5 
            WHEN Rating < 1 THEN 1 
            ELSE Rating 
        END AS Rating,

        TRIM(REPLACE(REPLACE(REPLACE(ReviewText, '  ', ' '), '  ', ' '), '  ', ' ')) AS ReviewText
    FROM customer_reviews
    WHERE ReviewDate <= GETDATE() -- Excluding any future date..
),

-- Handling duplicates:
ReviewDeduplicated AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID, ProductID, ReviewDate, ReviewText 
            ORDER BY ReviewID
        ) AS rn
    FROM RawReviewsCleaned
)


-- .........................................................

SELECT 
    ReviewID, CustomerID, ProductID, ReviewDate, Rating, ReviewText
FROM ReviewDeduplicated
WHERE rn = 1 AND ReviewID IS NOT NULL;

