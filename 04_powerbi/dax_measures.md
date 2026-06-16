# 📐 DAX Measures – ShopEasy Marketing Analytics

All measures are stored in an **isolated `DAX Measures` table** to keep the data model clean and organized.

---

## 🛒 Revenue & Sales

### Total Revenue
```dax
Total Revenue = 
SUMX(
    FILTER(Customer_journy, Customer_journy[Action] = "PURCHASE"),
    RELATED(Products[Price])
)
```
**Purpose:** Calculates total revenue by looking up the product price for every PURCHASE action in the journey fact table.

---

### Average Order Value (AOV)
```dax
Avg order Value = DIVIDE([Total Revenue], [purchases Num], 0)
```
**Purpose:** One of the 5 required KPIs. Measures average spend per transaction. DIVIDE() safely handles division by zero.

---

### Purchases Count
```dax
purchases Num = 
CALCULATE(
    COUNT(Customer_journy[JourneyID]),
    Customer_journy[Action] = "PURCHASE"
)
```

---

## 🔄 Conversion & Funnel

### Conversion Rate
```dax
Convertion rate = 
DIVIDE(
    [purchases Num],
    CALCULATE(COUNT(Customer_journy[JourneyID]), Customer_journy[Action] = "VIEW")
)
```
**Purpose:** Core KPI — % of viewers who completed a purchase. Reveals the overall health of the sales funnel.

---

### Total Visits
```dax
Total Visits = DISTINCTCOUNT(Customer_journy[JourneyID])
```

---

### Funnel Stage Counts
```dax
Total Home page = 
CALCULATE(COUNT(Customer_journy[CustomerID]), Customer_journy[Stage] = "Home Page")

Total Product page = 
CALCULATE(COUNT(Customer_journy[CustomerID]), Customer_journy[Stage] = "Product page")
```
**Purpose:** Used to build the conversion funnel visual showing drop-off between stages.

---

### Drop-off Analysis
```dax
Drop offs at Checkout = 
CALCULATE(
    COUNT(Customer_journy[JourneyID]),
    Customer_journy[Action] = "DROP-OFF"
)

Drop Offs Per. = DIVIDE([Drop offs at Checkout], [Total Visits])

Lost Deals = 
DIVIDE(
    [Drop offs at Checkout],
    CALCULATE(COUNT(Customer_journy[JourneyID]), Customer_journy[Stage] = "CHECKOUT"),
    0
)
```
**Purpose:** `Lost Deals` specifically measures drop-offs *at checkout* — this was a key insight showing that users were abandoning at the final payment step, not during browsing.

---

## 📣 Engagement & Campaign Performance

### CTR (Click-Through Rate)
```dax
CTR = DIVIDE(SUM(engagement_data[Clicks]), SUM(engagement_data[Views]), 0)
```
**Purpose:** Critical KPI for Jane Doe (Marketing Manager). High views + low CTR = problem with ad *content*, not budget. This measure helped identify where marketing spend was being wasted.

---

### Engagement Rate
```dax
Engagement_Rate = DIVIDE([Total Interactions], SUM(engagement_data[Views]))
```

### Total Interactions
```dax
Total Interactions = SUM(engagement_data[Likes]) + SUM(engagement_data[Clicks])
```

### Total Views & Clicks
```dax
Total Views = SUM(engagement_data[Views])
Total Clicks = SUM(engagement_data[Clicks])
Total views per journey = CALCULATE(COUNT(Customer_journy[JourneyID]), Customer_journy[Action] = "view")
```

---

## 👥 Customer Behavior & Churn

### Churn Indicator (per customer)
```dax
Churned customer = IF([Days Since Last Visit] > 30, 1, 0)
```
**Purpose:** Flags customers who haven't visited in over 30 days as churned.

---

### Days Since Last Visit
```dax
Days Since Last Visit = 
DATEDIFF(
    MAX(Customer_journy[VisitDate]),
    TODAY(),
    DAY
)
```

### Last Visit Date
```dax
Last Visit Date = 
CALCULATE(
    MAX(Customer_journy[VisitDate]),
    ALLEXCEPT(Customer_journy, Customer_journy[CustomerID])
)
```

### Total Churned Customers
```dax
Total churned customers = 
CALCULATE(
    DISTINCTCOUNT(Customer_journy[CustomerID]),
    FILTER(
        VALUES(Customer_journy[CustomerID]),
        [Churned customer] = 1
    )
)
```
**Purpose:** Used to quantify the recoverable segment — customers who were engaged but went silent.

---

## ⭐ Customer Feedback

### Feedback Score
```dax
feebbacks core = CALCULATE(AVERAGE(customer_reviews[Rating]))
```
**Purpose:** Maps to the Customer Feedback Score KPI. Combined with sentiment analysis output from Python for a richer view.

---

## 📝 Notes on Measures Table

- All measures are stored in a **dedicated `DAX Measures` table** (no data, just measures) — this keeps the field list clean and prevents measures from being scattered across fact tables.
- `Total_Revenue_Column` is a helper column mirror of `[Total Revenue]` used for specific visual contexts where a measure reference wasn't directly supported.
- `Measure` and `Measure 4` are intermediate exploration measures kept for transparency — they can be cleaned up in a production version.
