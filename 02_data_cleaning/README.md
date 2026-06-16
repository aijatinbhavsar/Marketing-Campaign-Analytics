# 🧹 Data Cleaning – SQL Server CTEs

## Strategy: Abstraction Layer via Nested CTEs

The source database arrived as a `.bak` file with multiple data quality issues. Rather than modifying the source tables directly, we used **Nested CTEs as a read-only abstraction layer**.

This means:
- ✅ Source data is **never touched**
- ✅ Every transformation is **transparent and documented**
- ✅ Each CTE handles **one single responsibility** (separation of concerns)
- ✅ Easy to **debug, maintain, and explain** to non-technical stakeholders
- ✅ Used directly in **Power BI Import Mode** as the native SQL query

---

## Issues Found Per Table

### `Customers`
| Issue | Fix |
|---|---|
| Gender mismatch (female names marked as Male) | CASE WHEN on first name patterns |
| Unrealistic ages (< 10 or > 95) | Nullified out-of-range values |
| Extra whitespace in names/emails | TRIM() + LOWER() |
| No geography data on the customer record | LEFT JOIN with Geography table inside CTE |
| Duplicate CustomerIDs | ROW_NUMBER() PARTITION BY CustomerID |

### `Customer_Journey`
| Issue | Fix |
|---|---|
| Inconsistent Stage names ('PRODUCTPAGE' vs 'Product Page') | CASE WHEN + UPPER + TRIM normalization |
| NULL Duration values | AVG imputation per Stage using window function |
| Duplicate journey records | ROW_NUMBER() PARTITION BY CustomerID, ProductID, VisitDate, Stage, Action |
| Date stored as DATETIME | Cast to DATE |

### `Customer_Reviews`
| Issue | Fix |
|---|---|
| Ratings outside 1–5 range | CASE WHEN clamp to [1, 5] |
| Future review dates | WHERE ReviewDate <= GETDATE() |
| Extra whitespace in review text | Nested REPLACE + TRIM |
| Duplicate reviews | ROW_NUMBER() PARTITION BY CustomerID, ProductID, ReviewDate, ReviewText |

### `Engagement_Data`
| Issue | Fix |
|---|---|
| NULL ContentType | COALESCE to 'OTHER' |
| NULL Likes | COALESCE(ABS(Likes), 0) |
| `ViewsClicksCombined` stored as single string "views-clicks" | CHARINDEX + LEFT + SUBSTRING to split into Views and Clicks |
| NULL combined column | COALESCE to '0-0' before splitting |
| Duplicates (same content on same day) | ROW_NUMBER() keeping highest Likes row |
| CTR not pre-calculated | Calculated as (Clicks/Views)*100 inside CTE |

### `Products`
| Issue | Fix |
|---|---|
| Negative price values | `ABS(Price)` — converts negatives to positive instead of deleting (preserves source) |
| Extra whitespace in ProductName | `TRIM(ProductName)` |
| Inconsistent Category casing | `UPPER(TRIM(Category))` |
| No price segmentation for analysis | Added `PriceTier` column: Budget (< 50) / Mid-Range (50–200) / Premium (> 200) |
| Duplicate ProductIDs | `ROW_NUMBER() PARTITION BY ProductID` |

---

## CTE Pattern Used

```sql
WITH Step1_RawCleaned AS (
    -- Standardize types, casing, trim whitespace
    SELECT ...
),
Step2_HandleNulls AS (
    -- Window functions for imputation
    SELECT *, AVG(...) OVER (PARTITION BY ...) AS AvgValue
    FROM Step1_RawCleaned
),
Step3_Deduplicated AS (
    -- Remove exact duplicates
    SELECT *, ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ID) AS rn
    FROM Step2_HandleNulls
)
-- Final clean output
SELECT [columns]
FROM Step3_Deduplicated
WHERE rn = 1 AND ID IS NOT NULL;
```

---

## Files

| File | Table Cleaned |
|---|---|
| `customers.sql` | Customers + Geography join |
| `customer_journey.sql` | Customer_Journey (funnel data) |
| `customer_reviews.sql` | Customer_Reviews (ratings + text) |
| `engagement_data.sql` | Engagement_Data (campaign metrics) |
| `Product.sql` | Products (our services) |
