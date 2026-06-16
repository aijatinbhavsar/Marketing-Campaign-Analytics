# ⚔️ Challenges & Key Decisions

## The Real Story Behind This Project

This document captures the honest journey — the decisions made under pressure, the dead ends, and how we adapted. It's the part that doesn't show up in dashboards.

---

## Challenge 1: The MySQL Dead End (~1.5 Days Lost)

**What happened:**
The database arrived as a `.bak` file (SQL Server backup format). Our initial plan was to migrate it to MySQL, which is what we were most comfortable with.

We successfully opened the `.bak` in SQL Server, performed the data migration, and spent significant time building out the entire cleaning logic — normalization, PK constraints, FK relationships between tables, proper indexing.

The next morning, we showed our instructor. His feedback: *"Your work is technically correct and very clean — but as a Data Analyst, you're not expected to modify the source database to this extent. And also, the project must run on SQL Server."*

**Impact:**
- ~1.5 days out of 3 were gone
- Every other team had already started building dashboards
- We had essentially nothing to show yet

**Decision:**
Don't start over from scratch. Take the cleaning logic we already wrote for MySQL and **port it to SQL Server CTEs**. Instead of applying changes permanently to tables, wrap everything in CTEs — same transformations, same logic, but as a non-destructive abstraction layer.

**Outcome:**
This decision ended up being *better* than the original plan. CTEs are more transparent, don't touch source data, and are directly usable in Power BI's Import Mode. What looked like a setback became a stronger technical approach.

---

## Challenge 2: Time Pressure

**What happened:**
With 1.5 days lost and ~30 teams already ahead of us, the natural reaction would be to rush and try to cover as much ground as possible.

**Decision:**
We chose depth over breadth. Instead of trying to build as many visuals as possible, we focused on:
1. Understanding the business problem deeply
2. Making sure each insight was tied to a specific KPI and a specific stakeholder request
3. Being able to *explain* every number — not just show it

**Outcome:**
In the presentation Q&A, we were able to answer every question about how our numbers were derived, why we chose specific cleaning approaches, and what the business implication of each finding was.

---

## Challenge 3: Gender Data Corruption

**What happened:**
The `Customers` table had a `Gender` column, but female customers had been incorrectly recorded as `Male`. The data had no reliable pattern — it wasn't consistent enough to fix with a simple rule.

**Decision:**
Use first-name pattern matching. We mapped common Arabic and English female names to `Female` and common male names to `Male`, and fell back to the original value for names that didn't match any pattern.

```sql
CASE 
    WHEN TRIM(CustomerName) LIKE 'Emma%' OR ... THEN 'Female'
    WHEN TRIM(CustomerName) LIKE 'Robert%' OR ... THEN 'Male'
    ELSE TRIM(Gender)  -- keep original if unknown
END AS Gender
```

**Limitation acknowledged:**
This approach is not perfect — names outside our list retain their potentially wrong value. We flagged this explicitly in the presentation as a known limitation.

---

## Challenge 4: Splitting a Combined Column

**What happened:**
The `Engagement_Data` table stored views and clicks in a single string column: `ViewsClicksCombined` formatted as `"1250-47"`.

**Decision:**
Split using `CHARINDEX` and string functions inside the CTE, with a `COALESCE` to `'0-0'` for NULL values before splitting (to avoid runtime errors on NULL CHARINDEX operations).

```sql
COALESCE(ViewsClicksCombined, '0-0') AS Combined,
-- Then in the next CTE:
CAST(LEFT(Combined, CHARINDEX('-', Combined) - 1) AS INT) AS Views,
CAST(SUBSTRING(Combined, CHARINDEX('-', Combined) + 1, LEN(Combined)) AS INT) AS Clicks
```

---

## Lessons Learned

1. **Understand the environment constraints before building** — knowing that `.bak` requires SQL Server from day one would have saved 1.5 days.
2. **CTEs are underrated for data analysis workflows** — they're transparent, non-destructive, and composable.
3. **Time lost doesn't have to mean quality lost** — the pressure forced us to be more focused and intentional.
4. **Document your decisions** — being able to explain *why* you did something is as important as the output itself.
5. **Bonus features should not compromise core KPIs** — we did the sentiment analysis only after the main dashboard was solid.
