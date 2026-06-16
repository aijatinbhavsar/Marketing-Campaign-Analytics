"""
Sentiment Analysis – ShopEasy Customer Reviews
================================================
Uses NLTK VADER to score customer reviews on a scale of 1–10.
Output is saved as an Excel file for import into Power BI.

Author: ShopEasy Analytics Team
Hackathon: Orange Digital Center – [i]NSTANT
"""

import os
import pandas as pd
import nltk
from nltk.sentiment.vader import SentimentIntensityAnalyzer
import sqlalchemy
import urllib

# ─────────────────────────────────────────────────────────────
# CONFIGURATION — Update these before running
# ─────────────────────────────────────────────────────────────
SERVER_NAME   = r'YOUR_SERVER\SQLEXPRESS'          # e.g. r'LAPTOP\SQLEXPRESS'
DATABASE_NAME = 'PortfolioProject_MarketingAnalytics'
OUTPUT_FILE   = 'full_score_reviews.xlsx'
# ─────────────────────────────────────────────────────────────


def get_sentiment_score(text: str) -> int:
    """
    Converts raw review text to a 1–10 integer score using VADER.

    VADER compound score range: [-1.0, 1.0]
    Mapping formula: ((compound + 1) / 2) * 9 + 1  → maps to [1, 10]

    Returns 5 (neutral) for empty / null reviews.
    """
    if not text or str(text).strip() in ("", "None"):
        return 5

    compound = analyzer.polarity_scores(str(text))["compound"]
    score = int(round(((compound + 1) / 2) * 9 + 1))
    return max(1, min(10, score))  # clamp to [1, 10]


# ── 1. Load VADER lexicon ─────────────────────────────────────
try:
    analyzer = SentimentIntensityAnalyzer()
except LookupError:
    nltk.download("vader_lexicon")
    analyzer = SentimentIntensityAnalyzer()


# ── 2. Connect to SQL Server ──────────────────────────────────
print("Connecting to SQL Server...")

conn_str = urllib.parse.quote_plus(
    f"DRIVER={{SQL Server}};"
    f"SERVER={SERVER_NAME};"
    f"DATABASE={DATABASE_NAME};"
    f"Trusted_Connection=yes;"
)
engine = sqlalchemy.create_engine(f"mssql+pyodbc:///?odbc_connect={conn_str}")


# ── 3. Pull review data ───────────────────────────────────────
query = "SELECT ReviewID, CustomerID, ReviewText FROM customer_reviews"
df = pd.read_sql(query, engine)
print(f"✅ Loaded {len(df):,} reviews from database.")


# ── 4. Detect review text column (flexible naming) ───────────
possible_cols = ["ReviewText", "review_text", "Review_Text", "review", "Review"]
text_col = next((c for c in df.columns if c in possible_cols), None)

if not text_col:
    raise ValueError(
        f"Could not find review text column. "
        f"Available columns: {df.columns.tolist()}"
    )


# ── 5. Apply sentiment scoring ────────────────────────────────
print("Scoring reviews...")
df["Customer_Feedback_Score"] = df[text_col].apply(get_sentiment_score)


# ── 6. Summary statistics ─────────────────────────────────────
print("\n── RESULTS ──────────────────────────────────────────")
print(f"Total rows processed : {len(df):,}")
print(f"Average score        : {df['Customer_Feedback_Score'].mean():.2f} / 10")
print(f"\nScore distribution (1–10):")
print(df["Customer_Feedback_Score"].value_counts().sort_index().to_string())


# ── 7. Export to Excel ────────────────────────────────────────
output_path = os.path.join(os.getcwd(), OUTPUT_FILE)
df[["ReviewID", "CustomerID", "Customer_Feedback_Score"]].to_excel(
    output_path, index=False
)
print(f"\n💾 Saved to: {output_path}")
print("Import this file into Power BI and join on ReviewID.")
