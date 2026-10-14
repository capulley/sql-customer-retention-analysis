# SQL Customer Retention & Revenue Analysis

## Business question
Which customer acquisition channels generate repeat buyers, and where should a fictional retailer investigate retention improvements?

**Data:** Synthetic customer and order records created for this educational portfolio project. These are not real customers, employer data, or observed business outcomes.

## Tools and concepts
- **SQLite / SQL:** `LEFT JOIN`, CTEs, conditional aggregation, `NULLIF`, `LAG`, `DENSE_RANK`, date functions
- **Python (standard library):** Reproducible SQL execution and CSV export
- **Metrics:** Repeat purchase rate, cohort month-1 retention, revenue by channel, days between purchases

## Dataset
- 1,200 synthetic customers
- 3,557 synthetic orders
- Transactions from January 2024 through December 2025
- Tables: `customers` (customer attributes) and `orders` (purchases)

## Analysis approach
1. Join customers to orders while preserving customers with no purchases.
2. Calculate repeat purchase rate among **purchasing customers** (at least one order).
3. Rank customers by observed revenue with `DENSE_RANK`.
4. Build first-purchase cohorts and calculate **next-calendar-month** retention, excluding the final month without a complete follow-up window.
5. Use `LAG` to measure elapsed days between consecutive orders.

## Findings from the synthetic dataset
| Acquisition channel | Purchasing customers | Repeat buyers | Repeat purchase rate | Revenue |
|---|---:|---:|---:|---:|
| Referral | 284 | 281 | 98.9% | $119,795.36 |
| Organic Search | 362 | 356 | 98.3% | $133,909.00 |
| Paid Search | 254 | 226 | 89.0% | $72,728.37 |
| Social | 154 | 128 | 83.1% | $41,585.16 |

**Interpretation:** In this *simulated* dataset, Referral and Organic Search have higher repeat purchase rates than Social and Paid Search. This is a descriptive comparison, not evidence that a channel causes retention.

**Important limitation:** The synthetic data generator intentionally varies repeat-purchase behavior by channel. These differences are designed into the simulation; they should not be presented as discoveries about real customers.

## Recommendations to investigate
- Compare acquisition cost with repeat purchase rate before reallocating marketing budgets.
- Examine onboarding and follow-up experiences for Social and Paid Search customers.
- Evaluate month-1 retention by cohort to distinguish early repeat purchases from longer-term repeat behavior.
- Test retention interventions on real data before drawing causal conclusions.

## Project structure
```text
data/
  customers.csv
  orders.csv
  customer_retention.db
sql/
  analysis.sql
outputs/
  channel_retention_summary.csv
run_analysis.py
README.md
```

## Reproduce the results
Requires Python 3; no third-party packages needed.

```bash
python3 run_analysis.py
```

To run all SQL queries, open `data/customer_retention.db` in a SQLite client and execute the statements in `sql/analysis.sql`, or use the SQLite CLI:

```bash
sqlite3 -header -column data/customer_retention.db < sql/analysis.sql
```

## Skills demonstrated
Relational data modeling, SQL joins, CTEs, conditional aggregations, window functions, cohort definitions, careful metric denominators, reproducible reporting, and translating analysis into business questions.

## Next improvements
Create a month-by-month cohort heatmap, introduce acquisition cost data for channel ROI, and validate findings against real publicly available retail data.
