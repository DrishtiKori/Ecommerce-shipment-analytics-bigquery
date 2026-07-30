# E-Commerce Shipment Analytics (BigQuery)

End-to-end SQL analytics project in Google BigQuery: data quality validation, star schema design, and business analysis on 10,999 e-commerce shipments to identify drivers of late delivery.

## Business Problem

An e-commerce company wants to understand which factors — warehouse location, shipment mode, discount level, product importance — are associated with late deliveries and lower customer satisfaction, so Operations can prioritize where to focus improvement efforts.

**Dataset:** [Kaggle — Customer Analytics / E-Commerce Shipping Data](https://www.kaggle.com/datasets/prachi13/customer-analytics) (10,999 rows, 12 columns)

## Repository Structure

```
ecommerce-shipment-analytics-bigquery/
├── README.md
├── sql/
│   ├── 01_data_quality.sql        -- validation before any modeling
│   ├── 02_star_schema.sql         -- dimension + fact table build
│   ├── 03_business_analysis.sql   -- CTEs, window functions, business questions
│   └── 04_dashboard_view.sql      -- flat view for Tableau/Power BI
└── docs/
    └── executive_eda_report.md
```

## Data Quality

Validated before any analysis (`sql/01_data_quality.sql`):
- 10,999 rows, primary key (`ID`) confirmed unique, no full duplicate rows
- Zero nulls or blank values across all 12 columns
- All categorical fields clean on load: `Warehouse_block` (A/B/C/D/F), `Mode_of_Shipment` (Ship/Flight/Road), `Product_importance` (high/low/medium), `Gender` (F/M)
- Numeric ranges sane throughout (no negative weights or costs, ratings within 1–5)
- No revenue/profit field or persistent customer key exists — this rules out metrics like Customer Lifetime Value or Repeat Customer Rate, called out explicitly rather than approximated

## Data Model

Built as a star schema rather than querying the flat file directly (`sql/02_star_schema.sql`):

- **Fact table:** `fact_shipments` — one row per shipment, holding measures (customer care calls, rating, cost, prior purchases, discount, weight, on-time flag) plus foreign keys
- **Dimension tables:** `dim_warehouse`, `dim_shipment_mode`, `dim_product_importance`, `dim_gender` — each with a `ROW_NUMBER()`-generated surrogate key
- **Dashboard view:** `vw_shipments_dashboard` — flat join of fact + all dimensions for BI-tool consumption

All joins validated to preserve the full 10,999-row grain with zero drops or fan-outs.

## Key Finding

**Warehouse location is not a meaningful driver of on-time delivery.**

| Rank | Warehouse | On-Time Rate |
|---|---|---|
| 1 | B | 60.2% |
| 2 | F | 59.8% |
| 3 | D | 59.8% |
| 4 | C | 59.7% |
| 5 | A | 58.6% |

All five blocks fall within roughly 1.6 percentage points of each other — if warehouse operations were the cause of late deliveries, a clearer spread would be expected. This rules out one hypothesis and points investigation toward other variables (shipment mode, discount level, order volume).

*(Further findings — overall on-time rate, discount-vs-lateness relationship, rating by delivery status — in progress; see `docs/executive_eda_report.md` for the current state of the analysis.)*

## SQL Techniques Used

- Data quality auditing (`COUNTIF`, `GROUP BY ALL` for duplicate detection, `INFORMATION_SCHEMA.COLUMNS`)
- Star schema design with `ROW_NUMBER()`-generated surrogate keys
- Multi-table joins across fact and dimension tables
- CTEs (`WITH`) for layered aggregation
- Window functions: `RANK()`, `NTILE()`
- Conditional segmentation with `CASE WHEN`
- View creation for BI-tool consumption

## Recommendations

- Deprioritize warehouse-specific process audits as a fix for late deliveries — the data doesn't support warehouse location as a driver
- Investigate shipment mode and discount level next, given the flat warehouse result
- Do not attempt CLV or repeat-customer reporting from this dataset — the necessary fields don't exist

## How to Run

1. Load `Train.csv` into a BigQuery table (e.g. `your_project.your_dataset.shipping`)
2. Update the project/dataset reference in each `.sql` file to match your own BigQuery project
3. Run the files in order: `01_data_quality.sql` → `02_star_schema.sql` → `03_business_analysis.sql` → `04_dashboard_view.sql`

## Tech Stack

Google BigQuery (GoogleSQL)

## Future Improvements

- Complete the remaining business analysis (overall on-time rate, discount vs. lateness, rating quartiles) and fold results into this README
- Build out the Tableau/Power BI dashboard from `vw_shipments_dashboard`
- If a customer key or revenue field becomes available, extend to CLV and repeat-purchase analysis
