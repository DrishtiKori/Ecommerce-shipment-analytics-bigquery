-- =====================================================================
-- 01_data_quality.sql
-- Purpose: Validate the raw shipping table before any modeling or analysis.
-- Confirms: row count, schema, primary key integrity, no duplicates,
-- no nulls/blanks, clean categorical values, sane numeric ranges.
-- =====================================================================

-- Preview the raw data
SELECT * FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.shipping` LIMIT 1000;

-- Row count: confirms the full CSV loaded (expected: 10,999)
SELECT COUNT(*) AS total_rows
FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.shipping`;

-- Schema check: confirms BigQuery inferred types as expected on load
SELECT column_name, data_type
FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'shipping'
ORDER BY ordinal_position;

-- Primary key integrity: ID should be unique. Any rows returned here
-- would mean the assumed grain (one row per shipment) is broken.
SELECT ID, COUNT(*) AS occurrences
FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.shipping`
GROUP BY ID
HAVING COUNT(*) > 1;

-- Full duplicate rows: catches upstream export duplication even if ID is unique.
-- GROUP BY ALL groups by every non-aggregated column (BigQuery-specific shorthand).
SELECT
  * EXCEPT(ID),
  COUNT(*) AS occurrences
FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.shipping`
GROUP BY ALL
HAVING COUNT(*) > 1;

-- Nulls and blanks across every column in one pass
SELECT
  COUNTIF(Warehouse_block IS NULL) AS null_warehouse_block,
  COUNTIF(TRIM(Warehouse_block) = '') AS blank_warehouse_block,
  COUNTIF(Mode_of_Shipment IS NULL) AS null_mode_of_shipment,
  COUNTIF(TRIM(Mode_of_Shipment) = '') AS blank_mode_of_shipment,
  COUNTIF(Customer_care_calls IS NULL) AS null_customer_care_calls,
  COUNTIF(Customer_rating IS NULL) AS null_customer_rating,
  COUNTIF(Cost_of_the_Product IS NULL) AS null_cost_of_product,
  COUNTIF(Prior_purchases IS NULL) AS null_prior_purchases,
  COUNTIF(Product_importance IS NULL) AS null_product_importance,
  COUNTIF(TRIM(Product_importance) = '') AS blank_product_importance,
  COUNTIF(Gender IS NULL) AS null_gender,
  COUNTIF(Discount_offered IS NULL) AS null_discount_offered,
  COUNTIF(Weight_in_gms IS NULL) AS null_weight,
  COUNTIF(Reached_on_Time_Y_or_N IS NULL) AS null_reached_on_time
FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.shipping`;

-- Category sanity checks: confirms no stray casing, whitespace, or unexpected values
SELECT DISTINCT Warehouse_block FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.shipping`;
SELECT DISTINCT Mode_of_Shipment FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.shipping`;
SELECT DISTINCT Product_importance FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.shipping`;
SELECT DISTINCT Gender FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.shipping`;

-- Numeric range sanity check: early scan for impossible values (negatives, out-of-bounds)
SELECT
  MIN(Customer_care_calls) AS min_calls, MAX(Customer_care_calls) AS max_calls,
  MIN(Customer_rating) AS min_rating, MAX(Customer_rating) AS max_rating,
  MIN(Cost_of_the_Product) AS min_cost, MAX(Cost_of_the_Product) AS max_cost,
  MIN(Prior_purchases) AS min_prior_purchases, MAX(Prior_purchases) AS max_prior_purchases,
  MIN(Discount_offered) AS min_discount, MAX(Discount_offered) AS max_discount,
  MIN(Weight_in_gms) AS min_weight, MAX(Weight_in_gms) AS max_weight
FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.shipping`;
