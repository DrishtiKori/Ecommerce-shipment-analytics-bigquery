# Data Dictionary — E-Commerce Shipping Dataset

Source: [Kaggle — Customer Analytics / E-Commerce Shipping Data](https://www.kaggle.com/datasets/prachi13/customer-analytics)
Grain: one row = one shipment. Primary key: `ID`.

| Column | Type | Role | Description |
|---|---|---|---|
| `ID` | INT64 | Primary Key | Unique identifier for each shipment |
| `Warehouse_block` | STRING | Dimension | The warehouse block the shipment originated from (A, B, C, D, F) |
| `Mode_of_Shipment` | STRING | Dimension | How the shipment was sent (Ship, Flight, Road) |
| `Customer_care_calls` | INT64 | Measure | Number of calls made to customer service about this shipment |
| `Customer_rating` | INT64 | Measure (ordinal) | Customer satisfaction rating, 1 (lowest) to 5 (highest) — a categorical/ordinal scale rather than a continuous measure |
| `Cost_of_the_Product` | INT64 | Measure | Cost of the product in this shipment (no currency specified in source) |
| `Prior_purchases` | INT64 | Measure | Number of prior purchases by the customer. Describes customer history rather than the shipment itself, but the dataset has no persistent customer key, so it can't be normalized into a separate customer dimension |
| `Product_importance` | STRING | Dimension | Importance tier assigned to the product (low, medium, high) |
| `Gender` | STRING | Dimension | Customer gender (F, M) |
| `Discount_offered` | INT64 | Measure | Discount offered on this shipment. Unit (flat amount vs. percentage) is not specified in the source data |
| `Weight_in_gms` | INT64 | Measure | Weight of the shipment in grams |
| `Reached_on_Time_Y_or_N` | INT64 (binary flag) | Measure / Outcome | 1 = shipment reached ON TIME, 0 = shipment reached LATE. **Note:** this encoding was adjusted in Excel prior to loading into BigQuery and differs from some public descriptions of the original Kaggle source — confirm this encoding before reusing any query from this repo against a fresh copy of the raw dataset |

## Known Limitations

- No revenue, price, or profit field beyond `Cost_of_the_Product` — financial metrics like profit margin can't be calculated
- No persistent customer identifier — `Prior_purchases` and `Gender` describe the customer but can't be used to track the same customer across multiple shipments, ruling out Customer Lifetime Value or Repeat Customer Rate analysis
- No timestamp or date field — trend analysis over time (daily/weekly/monthly patterns) is not possible with this dataset
