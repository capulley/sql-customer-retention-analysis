from pathlib import Path
import sqlite3
import csv

ROOT = Path(__file__).resolve().parent
db = sqlite3.connect(ROOT / "data" / "customer_retention.db")
query = """
WITH cm AS (
 SELECT c.acquisition_channel, c.customer_id, COUNT(o.order_id) AS n,
 COALESCE(SUM(o.order_amount),0) AS revenue
 FROM customers c LEFT JOIN orders o USING(customer_id)
 GROUP BY c.customer_id
)
SELECT acquisition_channel, COUNT(*) AS acquired_customers,
 SUM(n>=1) AS purchasing_customers, SUM(n>=2) AS repeat_customers,
 ROUND(100.0*SUM(n>=2)/NULLIF(SUM(n>=1),0),1) AS repeat_purchase_pct,
 ROUND(SUM(revenue),2) AS revenue_usd
FROM cm GROUP BY acquisition_channel ORDER BY repeat_purchase_pct DESC
"""
rows = db.execute(query).fetchall()
headers = [col[0] for col in db.execute(query).description]
out = ROOT / "outputs" / "channel_retention_summary.csv"
with out.open("w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(headers)
    writer.writerows(rows)
print("Channel retention summary")
for row in rows:
    print(row)
print(f"Saved: {out}")
db.close()
