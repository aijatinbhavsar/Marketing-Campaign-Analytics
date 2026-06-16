
-- ---------- We will do Nested CTE contains engagement_data (interaction with campaigns) --------------------------- --


-- Checking and cleaning the categorical columns.
WITH RawEngagementCleaned AS (
    SELECT 
        EngagementID,
        ProductID,
        UPPER(TRIM(COALESCE(ContentType, 'OTHER'))) AS ContentType,
        CAST(EngagementDate AS DATE) AS EngagementDate,
        COALESCE(ABS(Likes), 0) AS Likes,
        COALESCE(ViewsClicksCombined, '0-0') AS Combined --it will be a problem if value = NULL ..(how we split the col!!.. so 0-0 is valid).
    FROM engagement_data
),
-- split ViewsClicksCombined into views and clicks:
ParsedData AS (
    SELECT 
        *,
        CAST(LEFT(Combined, CHARINDEX('-', Combined) - 1) AS INT) AS Views,
        CAST(SUBSTRING(Combined, CHARINDEX('-', Combined) + 1, LEN(Combined)) AS INT) AS Clicks
    FROM RawEngagementCleaned
),

 -- Handling Duplicates and Calcuate CTR: (CTR)> "Jane Doe" was complaining that the ROI was low. 
                                              -- When you show her that her campaigns have (high views) but (low clicks) (and therefore a low CTR),
                                              -- it will make her realize that the problem lies in the 'ad content' itself, not in the budget.
EngagementMetrics AS ( 
    SELECT 
        EngagementID, ProductID, ContentType, EngagementDate, Likes, Views, Clicks,

         -- Calcuate CTR [Click-Through Rate]  = (clicks/ views)*100
        CASE 
            WHEN Views > 0 THEN ROUND((CAST(Clicks AS FLOAT) / Views) * 100, 2)  -- view>0 (to avoid devide by 0)
            ELSE 0 
        END AS CTR,

         -- detect Duplicates of the same content in the same day!
        ROW_NUMBER() OVER (
            PARTITION BY  ContentType , EngagementDate 
            ORDER BY Likes DESC
        ) AS rn
    FROM ParsedData
)


-- .........................................................


SELECT 
    EngagementID, ProductID, ContentType, EngagementDate,
    Likes, Views, Clicks, CTR
FROM EngagementMetrics
WHERE rn = 1;