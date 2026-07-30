-- =====================================================================
-- 02_star_schema.sql
-- Purpose: Build a star schema on top of the flat shipping table.
-- Rationale: Warehouse_block, Mode_of_Shipment, Product_importance, and
-- Gender are low-cardinality, repeatable attributes -- good candidates
-- for dimension tables. Everything else is a per-shipment measure and
-- belongs in the fact table. Prior_purchases describes the customer,
-- not the shipment, but this dataset has no persistent customer key,
-- so it can't be normalized out -- it stays in the fact table.
-- =====================================================================

-- Dimension tables: each gets a surrogate key via ROW_NUMBER() OVER().
-- An empty OVER() is fine here since these are small static lookup
-- tables where row order doesn't matter.

CREATE OR REPLACE TABLE `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.dim_warehouse` AS
SELECT
  ROW_NUMBER() OVER() AS warehouse_key,
  Warehouse_block
FROM (SELECT DISTINCT Warehouse_block FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.shipping`);

CREATE OR REPLACE TABLE `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.dim_shipment_mode` AS
SELECT
  ROW_NUMBER() OVER() AS shipment_mode_key,
  Mode_of_Shipment
FROM (SELECT DISTINCT Mode_of_Shipment FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.shipping`);

CREATE OR REPLACE TABLE `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.dim_product_importance` AS
SELECT
  ROW_NUMBER() OVER() AS importance_key,
  Product_importance
FROM (SELECT DISTINCT Product_importance FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.shipping`);

CREATE OR REPLACE TABLE `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.dim_gender` AS
SELECT
  ROW_NUMBER() OVER() AS gender_key,
  Gender
FROM (SELECT DISTINCT Gender FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.shipping`);

-- Fact table: one row per shipment, holding measures plus foreign keys
-- back to each dimension.
CREATE OR REPLACE TABLE `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.fact_shipments` AS
SELECT
  s.ID,
  w.warehouse_key,
  m.shipment_mode_key,
  p.importance_key,
  g.gender_key,
  s.Customer_care_calls,
  s.Customer_rating,
  s.Cost_of_the_Product,
  s.Prior_purchases,
  s.Discount_offered,
  s.Weight_in_gms,
  s.Reached_on_Time_Y_or_N
FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.shipping` s
JOIN `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.dim_warehouse` w
  ON s.Warehouse_block = w.Warehouse_block
JOIN `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.dim_shipment_mode` m
  ON s.Mode_of_Shipment = m.Mode_of_Shipment
JOIN `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.dim_product_importance` p
  ON s.Product_importance = p.Product_importance
JOIN `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.dim_gender` g
  ON s.Gender = g.Gender;

-- Validation: row count must match the source (10,999). A mismatch here
-- would mean a join key dropped or fanned out rows.
SELECT COUNT(*) FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.fact_shipments`;

-- Referential integrity check: every fact row should resolve to exactly
-- one dimension row. Repeat this LEFT JOIN pattern for the other three keys.
SELECT COUNT(*) AS orphan_warehouse
FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.fact_shipments` f
LEFT JOIN `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.dim_warehouse` w
  ON f.warehouse_key = w.warehouse_key
WHERE w.warehouse_key IS NULL;
